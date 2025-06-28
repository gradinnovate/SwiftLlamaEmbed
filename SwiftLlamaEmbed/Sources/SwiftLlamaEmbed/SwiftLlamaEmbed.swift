import Foundation
import llama

/// Strategy for handling text longer than context size
public enum LongTextStrategy {
    /// Simply truncate the text to fit context size
    case truncate
    /// Split text into chunks and average their embeddings
    case chunk(maxChunkSize: Int32, overlap: Int32 = 0)
    /// Use sliding window approach (take first and last portions)
    case slidingWindow(windowSize: Int32)
    /// Automatically choose the best strategy based on text characteristics
    case auto
}

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
        return try embed(text: text, strategy: .auto)
    }
    
    /// Generate embeddings for the given text with different strategies for long text
    /// - Parameters:
    ///   - text: Input text to generate embeddings for
    ///   - strategy: Strategy to handle text longer than context size
    /// - Returns: Array of Float values representing the embedding
    public func embed(text: String, strategy: LongTextStrategy) throws -> [Float] {
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
        
        // 根據策略處理長文本
        if tokenCount > config.contextSize {
            let actualStrategy: LongTextStrategy
            if case .auto = strategy {
                actualStrategy = chooseOptimalStrategy(text: text, tokenCount: Int(tokenCount))
            } else {
                actualStrategy = strategy
            }
            
            switch actualStrategy {
            case .truncate:
                print("Warning: Input text has \(tokenCount) tokens, exceeding context size \(config.contextSize). Truncating.")
                let nTokens = min(Int(tokenCount), Int(config.contextSize))
                let finalTokens = Array(tokens.prefix(nTokens))
                return try embedSingleChunk(finalTokens)
                
            case .chunk(let maxChunkSize, let overlap):
                print("Auto-selected chunking strategy for long text (\(tokenCount) tokens)")
                return try embedWithChunking(tokens: tokens, tokenCount: Int(tokenCount), maxChunkSize: Int(maxChunkSize), overlap: Int(overlap))
                
            case .slidingWindow(let windowSize):
                print("Auto-selected sliding window strategy for long text (\(tokenCount) tokens)")
                return try embedWithSlidingWindow(tokens: tokens, tokenCount: Int(tokenCount), windowSize: Int(windowSize))
                
            case .auto:
                // This should not happen due to the actualStrategy assignment above
                fatalError("Auto strategy should have been resolved")
            }
        } else {
            // 文本長度在限制內，直接處理
            let finalTokens = Array(tokens.prefix(Int(tokenCount)))
            return try embedSingleChunk(finalTokens)
        }
    }
    
    /// 處理單個文本塊的 embedding
    private func embedSingleChunk(_ tokens: [llama_token]) throws -> [Float] {
        guard let context = context else {
            throw LlamaEmbedError.contextCreationFailed
        }
        
        let nTokens = tokens.count

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
            batch.token[batchIndex] = tokens[i]
            batch.pos[batchIndex] = Int32(i)
            batch.n_seq_id[batchIndex] = 1
            batch.seq_id[batchIndex]![0] = 0  // seq_id = 0
            batch.logits[batchIndex] = 1      // 對於 embedding，所有 token 都需要 logits = true
            batch.n_tokens += 1
        }

        // 設置 embeddings 模式並清理記憶體
        llama_set_embeddings(context, true)
        llama_memory_clear(llama_get_memory(context), true)
        
        // 對於 embedding 模式，直接使用 llama_encode 避免警告訊息
        let result = llama_encode(context, batch)
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
    
    /// 使用分塊策略處理長文本
    private func embedWithChunking(tokens: [llama_token], tokenCount: Int, maxChunkSize: Int, overlap: Int) throws -> [Float] {
        let chunkSize = min(maxChunkSize, Int(config.contextSize))
        let stride = chunkSize - overlap
        
        var allEmbeddings: [[Float]] = []
        var start = 0
        
        while start < tokenCount {
            let end = min(start + chunkSize, tokenCount)
            let chunk = Array(tokens[start..<end])
            
            let embedding = try embedSingleChunk(chunk)
            allEmbeddings.append(embedding)
            
            start += stride
            
            // 如果剩餘的 tokens 數量小於 stride，則處理最後一塊
            if start < tokenCount && start + stride >= tokenCount {
                let lastChunk = Array(tokens[start..<tokenCount])
                if lastChunk.count > overlap { // 避免重複處理太小的塊
                    let lastEmbedding = try embedSingleChunk(lastChunk)
                    allEmbeddings.append(lastEmbedding)
                }
                break
            }
        }
        
        // 平均所有塊的 embeddings
        return averageEmbeddings(allEmbeddings)
    }
    
    /// 使用滑動窗口策略處理長文本
    private func embedWithSlidingWindow(tokens: [llama_token], tokenCount: Int, windowSize: Int) throws -> [Float] {
        let windowSize = min(windowSize, Int(config.contextSize))
        let halfWindow = windowSize / 2
        
        // 取前半部分和後半部分
        let frontTokens = Array(tokens.prefix(halfWindow))
        let backTokens = Array(tokens.suffix(halfWindow))
        
        let frontEmbedding = try embedSingleChunk(frontTokens)
        let backEmbedding = try embedSingleChunk(backTokens)
        
        // 平均前後兩部分的 embeddings
        return averageEmbeddings([frontEmbedding, backEmbedding])
    }
    
    /// 計算多個 embeddings 的平均值
    private func averageEmbeddings(_ embeddings: [[Float]]) -> [Float] {
        guard !embeddings.isEmpty else { return [] }
        guard embeddings.count > 1 else { return embeddings[0] }
        
        let embeddingSize = embeddings[0].count
        var averaged = Array(repeating: Float(0.0), count: embeddingSize)
        
        for embedding in embeddings {
            for i in 0..<embeddingSize {
                averaged[i] += embedding[i]
            }
        }
        
        let count = Float(embeddings.count)
        for i in 0..<embeddingSize {
            averaged[i] /= count
        }
        
        return averaged
    }
    
    /// 智能選擇最佳策略處理長文本
    private func chooseOptimalStrategy(text: String, tokenCount: Int) -> LongTextStrategy {
        let contextSize = Int(config.contextSize)
        let overflowRatio = Double(tokenCount) / Double(contextSize)
        
        // 分析文本特徵
        let lines = text.components(separatedBy: .newlines)
        let sentences = text.components(separatedBy: CharacterSet(charactersIn: ".!?。！？"))
        
        // 決策邏輯
        switch overflowRatio {
        case 1.0..<1.5:
            // 輕微超出，使用滑動窗口保留首尾重要資訊
            return .slidingWindow(windowSize: Int32(contextSize * 4 / 5))
            
        case 1.5..<3.0:
            // 中等長度，根據結構選擇
            if lines.count > 10 || sentences.count > 20 {
                // 結構化文本，使用分塊
                return .chunk(maxChunkSize: Int32(contextSize * 3 / 4), overlap: Int32(contextSize / 8))
            } else {
                // 連續文本，使用滑動窗口
                return .slidingWindow(windowSize: Int32(contextSize * 4 / 5))
            }
            
        default:
            // 很長的文本，使用分塊策略
            let chunkSize = Int32(contextSize * 2 / 3)
            let overlap = Int32(contextSize / 6)
            return .chunk(maxChunkSize: chunkSize, overlap: overlap)
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