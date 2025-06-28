import Foundation
import llama

/// Errors that can occur when using SwiftLlamaEmbed
public enum LlamaEmbedError: Error, LocalizedError {
    case modelLoadFailed(String)
    case contextCreationFailed
    case tokenizationFailed
    case encodingFailed
    case invalidModelPath
    case backendInitializationFailed
    
    public var errorDescription: String? {
        switch self {
        case .modelLoadFailed(let path):
            return "Failed to load model from path: \(path)"
        case .contextCreationFailed:
            return "Failed to create llama context"
        case .tokenizationFailed:
            return "Failed to tokenize input text"
        case .encodingFailed:
            return "Failed to encode tokens to embeddings"
        case .invalidModelPath:
            return "Invalid model path provided"
        case .backendInitializationFailed:
            return "Failed to initialize llama backend"
        }
    }
}

/// Configuration for embedding model
public struct EmbeddingConfig {
    /// Context size (number of tokens)
    public let contextSize: Int32
    /// Number of threads to use
    public let threads: Int32
    /// Pooling type for embeddings
    public let poolingType: llama_pooling_type
    
    public init(
        contextSize: Int32 = 512,  // 遵循 embedding.cpp 的預設值，通常 embedding 不需要很大的 context
        threads: Int32 = 0, // 0 = auto-detect
        poolingType: llama_pooling_type = LLAMA_POOLING_TYPE_MEAN
    ) {
        self.contextSize = contextSize
        self.threads = threads
        self.poolingType = poolingType
    }
}

/// Main class for handling embedding models using llama.cpp
public class EmbeddingModel {
    private var model: OpaquePointer?
    private var context: OpaquePointer?
    var vocab: OpaquePointer? // internal for test access
    private let config: EmbeddingConfig
    
    /// Initialize the embedding model
    /// - Parameters:
    ///   - modelPath: Path to the GGUF model file
    ///   - config: Configuration for the model
    public init(modelPath: String, config: EmbeddingConfig = EmbeddingConfig()) throws {
        self.config = config
        
        // Initialize llama backend
        llama_backend_init()
        
        // Verify model file exists
        guard FileManager.default.fileExists(atPath: modelPath) else {
            throw LlamaEmbedError.invalidModelPath
        }
        
        // Load model
        var modelParams = llama_model_default_params()
        modelParams.vocab_only = false
        
        guard let loadedModel = llama_model_load_from_file(modelPath, modelParams) else {
            throw LlamaEmbedError.modelLoadFailed(modelPath)
        }
        self.model = loadedModel
        
        // Get vocabulary
        self.vocab = llama_model_get_vocab(loadedModel)
        
        // Create context - 遵循 embedding.cpp 的參數設置
        var contextParams = llama_context_default_params()
        contextParams.n_ctx = UInt32(config.contextSize)
        contextParams.n_threads = config.threads
        
        // 遵循 embedding.cpp：當 n_batch < n_ctx 時，設置 n_batch = n_ctx
        contextParams.n_batch = UInt32(config.contextSize)
        // 對於 non-causal models，n_ubatch = n_batch
        contextParams.n_ubatch = UInt32(config.contextSize)
        
        contextParams.embeddings = true
        contextParams.pooling_type = config.poolingType
        // 不強制設置 attention_type，讓它保持 UNSPECIFIED
        contextParams.offload_kqv = true  // 使用預設值，不強制關閉
        //print("Context params: \(contextParams)")
        guard let createdContext = llama_init_from_model(loadedModel, contextParams) else {
            llama_model_free(loadedModel)
            throw LlamaEmbedError.contextCreationFailed
        }
        self.context = createdContext
    }
    
    deinit {
        if let context = context {
            llama_free(context)
        }
        if let model = model {
            llama_model_free(model)
        }
        llama_backend_free()
    }
    
    /// Get the embedding dimension
    public var embeddingDimension: Int32 {
        guard let model = model else { return 0 }
        return llama_model_n_embd(model)
    }
    
    /// Generate embeddings for the given text
    /// - Parameter text: Input text to generate embeddings for
    /// - Returns: Array of Float values representing the embedding
    public func embed(text: String) throws -> [Float] {
        guard let context = context, let vocab = vocab else {
            throw LlamaEmbedError.contextCreationFailed
        }
        
        // 若 text 為空或全為空白，直接丟出 tokenizationFailed
        if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            throw LlamaEmbedError.tokenizationFailed
        }
        
        let maxTokens = Int32(text.utf8.count) + 8
        var tokens = Array<llama_token>(repeating: 0, count: Int(maxTokens))
        let tokenCount = llama_tokenize(
            vocab,
            text,
            Int32(text.utf8.count),
            &tokens,
            maxTokens,
            true,  // add_special (BOS)
            false  // parse_special
        )
        guard tokenCount > 0 else {
            throw LlamaEmbedError.tokenizationFailed
        }
        
        // 遵循 embedding.cpp：檢查 token 數量是否超過 batch size
        if tokenCount > config.contextSize {
            // 截斷到 context size，但這可能影響 embedding 品質
            print("Warning: Input text has \(tokenCount) tokens, exceeding context size \(config.contextSize). Truncating.")
        }
        
        let nTokens = min(Int(tokenCount), Int(config.contextSize))
        let finalTokens = Array(tokens.prefix(nTokens))

        // 根據 embedding.cpp 的做法，用 context size 初始化 batch
        var batch = llama_batch_init(Int32(config.contextSize), 0, 1)
        defer {
            llama_batch_free(batch)
        }
        
        // 遵循 embedding.cpp 的 batch_add_seq 函數，使用 common_batch_add 邏輯
        batch.n_tokens = 0
        for i in 0..<nTokens {
            // 確保不會超出 batch 容量
            guard batch.n_tokens < Int32(config.contextSize) else { break }
            
            let batchIndex = Int(batch.n_tokens)
            batch.token[batchIndex] = finalTokens[i]
            batch.pos[batchIndex] = Int32(i)
            batch.n_seq_id[batchIndex] = 1
            batch.seq_id[batchIndex]![0] = 0  // seq_id = 0
            batch.logits[batchIndex] = 1      // 對於 embedding，所有 token 都需要 logits = true
            batch.n_tokens += 1
        }

        // 設置 embeddings 模式並清理記憶體
        llama_set_embeddings(context, true)
        llama_memory_clear(llama_get_memory(context), true)
        
        // 使用 llama_decode 進行推論（遵循 server 實作）
        let result = llama_decode(context, batch)
        guard result == 0 else {
            throw LlamaEmbedError.encodingFailed
        }

        let embeddingSize = Int(embeddingDimension)
        
        // For sequence embeddings with pooling, use llama_get_embeddings_seq
        guard let embeddingsPtr = llama_get_embeddings_seq(context, 0) else {
            throw LlamaEmbedError.encodingFailed
        }
        
        let embeddings = Array(UnsafeBufferPointer(start: embeddingsPtr, count: embeddingSize))
        return embeddings
    }
    
    /// Compute cosine similarity between two embeddings
    /// - Parameters:
    ///   - embedding1: First embedding vector
    ///   - embedding2: Second embedding vector
    /// - Returns: Cosine similarity value between -1 and 1
    public static func cosineSimilarity(_ embedding1: [Float], _ embedding2: [Float]) -> Float {
        guard embedding1.count == embedding2.count else { return 0.0 }
        
        let dotProduct = zip(embedding1, embedding2).map(*).reduce(0, +)
        let norm1 = sqrt(embedding1.map { $0 * $0 }.reduce(0, +))
        let norm2 = sqrt(embedding2.map { $0 * $0 }.reduce(0, +))
        
        guard norm1 > 0, norm2 > 0 else { return 0.0 }
        
        return dotProduct / (norm1 * norm2)
    }
    
    /// Normalize an embedding vector to unit length
    /// - Parameter embedding: Input embedding vector
    /// - Returns: Normalized embedding vector
    public static func normalize(_ embedding: [Float]) -> [Float] {
        let norm = sqrt(embedding.map { $0 * $0 }.reduce(0, +))
        guard norm > 0 else { return embedding }
        return embedding.map { $0 / norm }
    }
} 