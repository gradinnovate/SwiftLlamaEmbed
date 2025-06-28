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
    /// Number of tokens to process at once
    public let n_ubatch: UInt32
    
    public init(
        contextSize: Int32 = 256,
        threads: Int32 = 0, // 0 = auto-detect
        poolingType: llama_pooling_type = LLAMA_POOLING_TYPE_MEAN,
        n_ubatch: UInt32 = 1024
    ) {
        self.contextSize = contextSize
        self.threads = threads
        self.poolingType = poolingType
        self.n_ubatch = n_ubatch
    }
}

/// Main class for handling embedding models using llama.cpp
public class EmbeddingModel {
    private var model: OpaquePointer?
    private var context: OpaquePointer?
    private var vocab: OpaquePointer?
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
        
        // Create context
        var contextParams = llama_context_default_params()
        contextParams.n_ctx = UInt32(config.contextSize)
        contextParams.n_threads = config.threads
        contextParams.n_batch = config.n_ubatch
        contextParams.n_ubatch = config.n_ubatch
        contextParams.embeddings = true
        contextParams.pooling_type = config.poolingType
        contextParams.attention_type = LLAMA_ATTENTION_TYPE_NON_CAUSAL
        contextParams.offload_kqv = false // Keep KV cache on CPU for embeddings
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
        
        // Tokenize
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
        tokens = Array(tokens.prefix(Int(tokenCount)))
        
        // Create batch using simpler approach
        var batch = llama_batch_get_one(&tokens, tokenCount)
        
        // Ensure logits are enabled for the last token only
        if let logits = batch.logits {
            for i in 0..<Int(tokenCount) {
                logits[i] = (i == Int(tokenCount) - 1) ? 1 : 0
            }
        }
        
        // Clear previous state
        llama_memory_clear(llama_get_memory(context), false)
        
        // Encode the batch
        let result = llama_encode(context, batch)
        guard result == 0 else {
            throw LlamaEmbedError.encodingFailed
        }
        
        // For embedding models, prefer sequence-level embeddings with pooling
        if let embeddingsPtr = llama_get_embeddings_seq(context, 0) {
            return Array(UnsafeBufferPointer(start: embeddingsPtr, count: Int(embeddingDimension)))
        } else if let fallbackPtr = llama_get_embeddings_ith(context, Int32(tokenCount) - 1) {
            let embeddingSize = Int(embeddingDimension)
            return Array(UnsafeBufferPointer(start: fallbackPtr, count: embeddingSize))
        } else {
            throw LlamaEmbedError.encodingFailed
        }
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