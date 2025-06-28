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
            let model = try EmbeddingModel(modelPath: expandedPath)
            XCTAssertGreaterThan(model.embeddingDimension, 0, "Embedding dimension should be greater than 0")
            print("Model loaded successfully with embedding dimension: \(model.embeddingDimension)")
        } catch {
            XCTFail("Failed to initialize embedding model: \(error)")
        }
    }
    
    func testTextEmbedding() {
        let expandedPath = NSString(string: modelPath).expandingTildeInPath
        
        do {
            let model = try EmbeddingModel(modelPath: expandedPath)
            let text = """
            This is a comprehensive test of the SwiftLlamaEmbed library's embedding generation capabilities. 
            The library provides a robust Swift interface to llama.cpp's powerful embedding functionality, 
            enabling developers to seamlessly integrate advanced text embedding features into their iOS and macOS applications. 
            This is a comprehensive test of the SwiftLlamaEmbed library's embedding generation capabilities. 
            This is a comprehensive test of the SwiftLlamaEmbed library's embedding generation capabilities. 
            This is a comprehensive test of the SwiftLlamaEmbed library's embedding generation capabilities. 
            This is a comprehensive test of the SwiftLlamaEmbed library's embedding generation capabilities. 
            This is a comprehensive test of the SwiftLlamaEmbed library's embedding generation capabilities. 
            This is a comprehensive test of the SwiftLlamaEmbed library's embedding generation capabilities. 
            The library provides a robust Swift interface to llama.cpp's powerful embedding functionality, 
            enabling developers to seamlessly integrate advanced text embedding features into their iOS and macOS applications. 
            This is a comprehensive test of the SwiftLlamaEmbed library's embedding generation capabilities. 
            This is a comprehensive test of the SwiftLlamaEmbed library's embedding generation capabilities. 
            This is a comprehensive test of the SwiftLlamaEmbed library's embedding generation capabilities. 
            This is a comprehensive test of the SwiftLlamaEmbed library's embedding generation capabilities. 
            This is a comprehensive test of the SwiftLlamaEmbed library's embedding generation capabilities. 
            This is a comprehensive test of the SwiftLlamaEmbed library's embedding generation capabilities. 
            This is a comprehensive test of the SwiftLlamaEmbed library's embedding generation capabilities. 
            This is a comprehensive test of the SwiftLlamaEmbed library's embedding generation capabilities. 
            This is a comprehensive test of the SwiftLlamaEmbed library's embedding generation capabilities. 
            This is a comprehensive test of the SwiftLlamaEmbed library's embedding generation capabilities. 
            The library provides a robust Swift interface to llama.cpp's powerful embedding functionality, 
            enabling developers to seamlessly integrate advanced text embedding features into their iOS and macOS applications. 
            This is a comprehensive test of the SwiftLlamaEmbed library's embedding generation capabilities. 
            This is a comprehensive test of the SwiftLlamaEmbed library's embedding generation capabilities. 
            This is a comprehensive test of the SwiftLlamaEmbed library's embedding generation capabilities. 
            This is a comprehensive test of the SwiftLlamaEmbed library's embedding generation capabilities. 
            This is a comprehensive test of the SwiftLlamaEmbed library's embedding generation capabilities. 
            This is a comprehensive test of the SwiftLlamaEmbed library's embedding generation capabilities. 
            The library provides a robust Swift interface to llama.cpp's powerful embedding functionality, 
            enabling developers to seamlessly integrate advanced text embedding features into their iOS and macOS applications. 
            This is a comprehensive test of the SwiftLlamaEmbed library's embedding generation capabilities. 
            This is a comprehensive test of the SwiftLlamaEmbed library's embedding generation capabilities. 
            This is a comprehensive test of the SwiftLlamaEmbed library's embedding generation capabilities. 
            This is a comprehensive test of the SwiftLlamaEmbed library's embedding generation capabilities. 
            This is a comprehensive test of the SwiftLlamaEmbed library's embedding generation capabilities. 
            This is a comprehensive test of the SwiftLlamaEmbed library's embedding generation capabilities. 
            This is a comprehensive test of the SwiftLlamaEmbed library's embedding generation capabilities. 
            This is a comprehensive test of the SwiftLlamaEmbed library's embedding generation capabilities. 
            """
            // 先 tokenize，若超過 contextSize，截斷
            let contextSize = 512
            let vocab = model.internalVocab!
            let maxTokens = Int32(text.utf8.count) + 8
            var tokens = Array<llama_token>(repeating: 0, count: Int(maxTokens))
            let tokenCount = llama_tokenize(
                vocab,
                text,
                Int32(text.utf8.count),
                &tokens,
                maxTokens,
                true,
                false
            )
            let nTokens = min(Int(tokenCount), contextSize)
            let truncatedText: String
            if nTokens < Int(tokenCount) {
                // 以 token 為單位反推字元長度
                let utf8View = text.utf8
                var charCount = 0
                var tokenSoFar = 0
                for (i, c) in utf8View.enumerated() {
                    charCount = i + 1
                    var tempTokens = Array<llama_token>(repeating: 0, count: Int(maxTokens))
                    let tempCount = llama_tokenize(
                        vocab,
                        String(text.utf8.prefix(charCount)),
                        Int32(charCount),
                        &tempTokens,
                        maxTokens,
                        true,
                        false
                    )
                    if Int(tempCount) >= nTokens { break }
                }
                let idx = text.utf8.index(text.utf8.startIndex, offsetBy: charCount)
                truncatedText = String(text.utf8[text.utf8.startIndex..<idx]) ?? String(text.prefix(512))
            } else {
                truncatedText = text
            }
            let embedding = try model.embed(text: truncatedText)
            
            XCTAssertGreaterThan(embedding.count, 0, "Embedding should not be empty")
            XCTAssertEqual(embedding.count, Int(model.embeddingDimension), "Embedding size should match model dimension")
            
            print("Generated embedding for text: '\(truncatedText.prefix(80))...'")
            print("Embedding dimension: \(embedding.count)")
            print("First 10 values: \(Array(embedding.prefix(10)))")
            
        } catch {
            XCTFail("Failed to generate embedding: \(error)")
        }
    }
    
    func testCosineSimilarity() {
        let expandedPath = NSString(string: modelPath).expandingTildeInPath
        
        do {
            let model = try EmbeddingModel(modelPath: expandedPath)
            
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
    
    func testCustomConfiguration() {
        let expandedPath = NSString(string: modelPath).expandingTildeInPath
        
        let config = EmbeddingConfig(
            contextSize: 512,
            threads: 4,
            poolingType: LLAMA_POOLING_TYPE_MEAN,
        )
        
        do {
            let model = try EmbeddingModel(modelPath: expandedPath, config: config)
            let text = String(repeating: "Testing custom configuration.", count: 1000)
            // 先 tokenize，若超過 contextSize，截斷
            let contextSize = 512
            let vocab = model.internalVocab!
            let maxTokens = Int32(text.utf8.count) + 8
            var tokens = Array<llama_token>(repeating: 0, count: Int(maxTokens))
            let tokenCount = llama_tokenize(
                vocab,
                text,
                Int32(text.utf8.count),
                &tokens,
                maxTokens,
                true,
                false
            )
            let nTokens = min(Int(tokenCount), contextSize)
            let truncatedText: String
            if nTokens < Int(tokenCount) {
                let utf8View = text.utf8
                var charCount = 0
                var tokenSoFar = 0
                for (i, c) in utf8View.enumerated() {
                    charCount = i + 1
                    var tempTokens = Array<llama_token>(repeating: 0, count: Int(maxTokens))
                    let tempCount = llama_tokenize(
                        vocab,
                        String(text.utf8.prefix(charCount)),
                        Int32(charCount),
                        &tempTokens,
                        maxTokens,
                        true,
                        false
                    )
                    if Int(tempCount) >= nTokens { break }
                }
                let idx = text.utf8.index(text.utf8.startIndex, offsetBy: charCount)
                truncatedText = String(text.utf8[text.utf8.startIndex..<idx]) ?? String(text.prefix(512))
            } else {
                truncatedText = text
            }
            let embedding = try model.embed(text: truncatedText)
            
            XCTAssertGreaterThan(embedding.count, 0, "Embedding should be generated with custom config")
            print("Custom config test passed. Embedding dimension: \(embedding.count)")
            
        } catch {
            XCTFail("Failed to test custom configuration: \(error)")
        }
    }
    
    func testInvalidModelPath() {
        let invalidPath = "/invalid/path/to/model.gguf"
        
        XCTAssertThrowsError(try EmbeddingModel(modelPath: invalidPath)) { error in
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
            let model = try EmbeddingModel(modelPath: expandedPath)
            
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
