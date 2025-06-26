import Foundation
import llama

/// Example usage of SwiftLlamaEmbed
public struct ExampleUsage {
    
    /// Basic example of loading a model and generating embeddings
    public static func basicExample() {
        let modelPath = "~/Documents/SnapGoModels/mxbai-embed-large-v1-q4_k_m.gguf"
        let expandedPath = NSString(string: modelPath).expandingTildeInPath
        
        do {
            // Initialize the embedding model
            let model = try EmbeddingModel(modelPath: expandedPath)
            
            print("Model loaded successfully!")
            print("Embedding dimension: \(model.embeddingDimension)")
            
            // Generate embeddings for some text
            let text = "This is a sample text for embedding generation."
            let embedding = try model.embed(text: text)
            
            print("Generated embedding for: '\(text)'")
            print("Embedding length: \(embedding.count)")
            print("First 5 values: \(Array(embedding.prefix(5)))")
            
        } catch {
            print("Error: \(error)")
        }
    }
    
    /// Example of semantic similarity search
    public static func semanticSimilarityExample() {
        let modelPath = "~/Documents/SnapGoModels/mxbai-embed-large-v1-q4_k_m.gguf"
        let expandedPath = NSString(string: modelPath).expandingTildeInPath
        
        do {
            let model = try EmbeddingModel(modelPath: expandedPath)
            
            // Documents to search
            let documents = [
                "The cat is sleeping peacefully on the warm sunny windowsill.",
                "Apple announced new iPhone models with advanced camera features.",
                "Machine learning algorithms are transforming modern technology.",
                "A dog is playing fetch in the park with its owner.",
                "The latest smartphone has impressive computational photography capabilities."
            ]
            
            // Query
            let query = "smartphone with advanced camera"
            
            print("Searching for: '\(query)'")
            print("In documents:")
            for (i, doc) in documents.enumerated() {
                print("\(i + 1). \(doc)")
            }
            print()
            
            // Generate embeddings
            let queryEmbedding = try model.embed(text: query)
            var similarities: [(Int, Float)] = []
            
            for (index, document) in documents.enumerated() {
                let docEmbedding = try model.embed(text: document)
                let similarity = EmbeddingModel.cosineSimilarity(queryEmbedding, docEmbedding)
                similarities.append((index, similarity))
            }
            
            // Sort by similarity (highest first)
            similarities.sort { $0.1 > $1.1 }
            
            print("Results (sorted by relevance):")
            for (rank, (docIndex, similarity)) in similarities.enumerated() {
                print("\(rank + 1). [Score: \(String(format: "%.3f", similarity))] \(documents[docIndex])")
            }
            
        } catch {
            print("Error: \(error)")
        }
    }
    
    /// Example with custom configuration
    public static func customConfigExample() {
        let modelPath = "~/Documents/SnapGoModels/mxbai-embed-large-v1-q4_k_m.gguf"
        let expandedPath = NSString(string: modelPath).expandingTildeInPath
        
        // Custom configuration
        let config = EmbeddingConfig(
            contextSize: 1024,      // Larger context size
            threads: 4,             // Use 4 threads
            embeddings: true,       // Enable embeddings
            poolingType: LLAMA_POOLING_TYPE_MEAN  // Mean pooling
        )
        
        do {
            let model = try EmbeddingModel(modelPath: expandedPath, config: config)
            
            print("Model loaded with custom configuration:")
            print("- Context size: \(config.contextSize)")
            print("- Threads: \(config.threads)")
            print("- Pooling type: Mean")
            
            let longText = """
            This is a longer text that demonstrates the embedding generation capability 
            of the SwiftLlamaEmbed library. The library provides a clean Swift interface 
            to the llama.cpp embedding functionality, allowing developers to easily 
            integrate text embedding generation into their iOS and macOS applications.
            """
            
            let embedding = try model.embed(text: longText)
            let normalized = EmbeddingModel.normalize(embedding)
            
            print("Generated embedding for long text (\(longText.count) characters)")
            print("Embedding dimension: \(embedding.count)")
            print("Normalized embedding (first 5 values): \(Array(normalized.prefix(5)))")
            
        } catch {
            print("Error: \(error)")
        }
    }
    
    /// Example of batch processing multiple texts
    public static func batchProcessingExample() {
        let modelPath = "~/Documents/SnapGoModels/mxbai-embed-large-v1-q4_k_m.gguf"
        let expandedPath = NSString(string: modelPath).expandingTildeInPath
        
        let texts = [
            "Swift is a powerful programming language.",
            "Python is popular for machine learning.",
            "JavaScript runs in web browsers.",
            "The weather is beautiful today.",
            "Coffee tastes great in the morning."
        ]
        
        do {
            let model = try EmbeddingModel(modelPath: expandedPath)
            
            print("Processing \(texts.count) texts...")
            var embeddings: [[Float]] = []
            
            for (index, text) in texts.enumerated() {
                let embedding = try model.embed(text: text)
                embeddings.append(embedding)
                print("Processed (\(index + 1)/\(texts.count)): \(text)")
            }
            
            print("\nComputing similarities between all pairs:")
            for i in 0..<texts.count {
                for j in (i+1)..<texts.count {
                    let similarity = EmbeddingModel.cosineSimilarity(embeddings[i], embeddings[j])
                    print("'\(texts[i])' vs '\(texts[j])': \(String(format: "%.3f", similarity))")
                }
            }
            
        } catch {
            print("Error: \(error)")
        }
    }
} 