import XCTest
import llama
@testable import SwiftLlamaEmbed

extension EmbeddingModel {
    var internalVocab: OpaquePointer? { self.vocab }
}

final class SwiftLlamaEmbedTests: XCTestCase {
    
    let modelPath = "~/Documents/Models/mxbai-embed-large-v1-q4_k_m.gguf"
    
    func testEmbeddingModelInitialization() {
        let expandedPath = NSString(string: modelPath).expandingTildeInPath
        
        do {
            let model = try EmbeddingModel(modelPath: expandedPath, silent: true)
            XCTAssertGreaterThan(model.embeddingDimension, 0, "Embedding dimension should be greater than 0")
            print("Model loaded successfully with embedding dimension: \(model.embeddingDimension)")
        } catch {
            XCTFail("Failed to initialize embedding model: \(error)")
        }
    }
    
    func testTextEmbedding() {
        let expandedPath = NSString(string: modelPath).expandingTildeInPath
        
        do {
            let model = try EmbeddingModel(modelPath: expandedPath, silent: true)
            
            // Test with normal text (should use auto strategy)
            let normalText = """
            This is a comprehensive test of the SwiftLlamaEmbed library's embedding generation capabilities. 
            The library provides a robust Swift interface to llama.cpp's powerful embedding functionality, 
            enabling developers to seamlessly integrate advanced text embedding features into their iOS and macOS applications.
            """
            
            let embedding = try model.embed(text: normalText)
            
            XCTAssertGreaterThan(embedding.count, 0, "Embedding should not be empty")
            XCTAssertEqual(embedding.count, Int(model.embeddingDimension), "Embedding size should match model dimension")
            
            print("Generated embedding for normal text")
            print("Embedding dimension: \(embedding.count)")
            print("First 10 values: \(Array(embedding.prefix(10)))")
            
        } catch {
            XCTFail("Failed to generate embedding: \(error)")
        }
    }
    
    func testCosineSimilarity() {
        let expandedPath = NSString(string: modelPath).expandingTildeInPath
        
        do {
            let model = try EmbeddingModel(modelPath: expandedPath, silent: true)
            
            let text1 = "The cat is sleeping on the mat."
            let text2 = "A cat is resting on a mat."
            let text3 = "The weather is nice today."
            
            let embedding1 = try model.embed(text: text1)
            let embedding2 = try model.embed(text: text2)
            let embedding3 = try model.embed(text: text3)
            
            let similarity12 = EmbeddingModel.cosineSimilarity(embedding1, embedding2)
            let similarity13 = EmbeddingModel.cosineSimilarity(embedding1, embedding3)
            
            print("Similarity between '\(text1)' and '\(text2)': \(similarity12)")
            print("Similarity between '\(text1)' and '\(text3)': \(similarity13)")
            
            // Similar sentences should have higher similarity than dissimilar ones
            XCTAssertGreaterThan(similarity12, similarity13, "Similar sentences should have higher cosine similarity")
            
        } catch {
            XCTFail("Failed to test cosine similarity: \(error)")
        }
    }
    
    func testEmbeddingNormalization() {
        let embedding = [1.0, 2.0, 3.0, 4.0, 5.0] as [Float]
        let normalized = EmbeddingModel.normalize(embedding)
        
        // Check that the normalized vector has unit length
        let norm = sqrt(normalized.map { $0 * $0 }.reduce(0, +))
        XCTAssertEqual(norm, 1.0, accuracy: 1e-6, "Normalized vector should have unit length")
        
        print("Original embedding: \(embedding)")
        print("Normalized embedding: \(normalized)")
        print("Normalized vector norm: \(norm)")
    }
    
    func testLongTextStrategies() {
        let expandedPath = NSString(string: modelPath).expandingTildeInPath
        
        do {
            let model = try EmbeddingModel(modelPath: expandedPath, silent: true)
            
            // Create a long text that will exceed context size
            let baseText = """
            This is a comprehensive test of the SwiftLlamaEmbed library's embedding generation capabilities. 
            The library provides a robust Swift interface to llama.cpp's powerful embedding functionality, 
            enabling developers to seamlessly integrate advanced text embedding features into their iOS and macOS applications. 
            With support for various pooling strategies and context management, this library offers flexible solutions 
            for natural language processing tasks. The implementation follows best practices for memory management 
            and error handling, ensuring reliable performance in production environments.
            """
            
            let longText = String(repeating: baseText + "\n\n", count: 40)
            
            // Test auto strategy (default)
            let autoEmbedding = try model.embed(text: longText)
            XCTAssertGreaterThan(autoEmbedding.count, 0, "Auto strategy should generate embedding")
            print("Auto strategy embedding dimension: \(autoEmbedding.count)")
            
            // Test truncate strategy
            let truncateEmbedding = try model.embed(text: longText, strategy: .truncate)
            XCTAssertGreaterThan(truncateEmbedding.count, 0, "Truncate strategy should generate embedding")
            print("Truncate strategy embedding dimension: \(truncateEmbedding.count)")
            
            // Test chunking strategy
            let chunkEmbedding = try model.embed(text: longText, strategy: .chunk(maxChunkSize: 300, overlap: 50))
            XCTAssertGreaterThan(chunkEmbedding.count, 0, "Chunk strategy should generate embedding")
            print("Chunk strategy embedding dimension: \(chunkEmbedding.count)")
            
            // Test sliding window strategy
            let slidingEmbedding = try model.embed(text: longText, strategy: .slidingWindow(windowSize: 400))
            XCTAssertGreaterThan(slidingEmbedding.count, 0, "Sliding window strategy should generate embedding")
            print("Sliding window strategy embedding dimension: \(slidingEmbedding.count)")
            
            // All embeddings should have the same dimension
            XCTAssertEqual(autoEmbedding.count, Int(model.embeddingDimension))
            XCTAssertEqual(truncateEmbedding.count, Int(model.embeddingDimension))
            XCTAssertEqual(chunkEmbedding.count, Int(model.embeddingDimension))
            XCTAssertEqual(slidingEmbedding.count, Int(model.embeddingDimension))
            
        } catch {
            XCTFail("Failed to test long text strategies: \(error)")
        }
    }
    
    func testCustomConfiguration() {
        let expandedPath = NSString(string: modelPath).expandingTildeInPath
        
        let config = EmbeddingConfig(
            contextSize: 512,
            threads: 4,
            poolingType: LLAMA_POOLING_TYPE_MEAN
        )
        
        do {
            let model = try EmbeddingModel(modelPath: expandedPath, config: config, silent: true)
            let text = String(repeating: "Testing custom configuration. ", count: 100)
            
            // Let the model handle long text automatically
            let embedding = try model.embed(text: text)
            
            XCTAssertGreaterThan(embedding.count, 0, "Embedding should be generated with custom config")
            XCTAssertEqual(embedding.count, Int(model.embeddingDimension), "Embedding size should match model dimension")
            print("Custom config test passed. Embedding dimension: \(embedding.count)")
            
        } catch {
            XCTFail("Failed to test custom configuration: \(error)")
        }
    }
    
    func testInvalidModelPath() {
        let invalidPath = "/invalid/path/to/model.gguf"
        
        XCTAssertThrowsError(try EmbeddingModel(modelPath: invalidPath, silent: true)) { error in
            if case LlamaEmbedError.invalidModelPath = error {
                // Expected error
                print("Correctly threw invalidModelPath error")
            } else {
                XCTFail("Expected invalidModelPath error, got: \(error)")
            }
        }
    }
    
    func testEmptyTextEmbedding() {
        let expandedPath = NSString(string: modelPath).expandingTildeInPath
        
        do {
            let model = try EmbeddingModel(modelPath: expandedPath, silent: true)
            
            // Test with empty string
            XCTAssertThrowsError(try model.embed(text: "")) { error in
                print("Empty text correctly threw error: \(error)")
            }
            
            // Test with whitespace only
            XCTAssertThrowsError(try model.embed(text: " ")) { error in
                print("Whitespace-only text correctly threw error: \(error)")
            }
            
        } catch {
            XCTFail("Failed during empty text test: \(error)")
        }
    }
} 
