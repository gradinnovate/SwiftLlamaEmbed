import Foundation
import llama
import SwiftLlamaEmbed

/// Simple demo program to test SwiftLlamaEmbed
@main
struct Demo {
    static func main() {
        print("=== SwiftLlamaEmbed Demo ===")
        
        // Parse command line arguments
        let arguments = CommandLine.arguments
        let modelPath: String
        
        if arguments.count > 1 {
            // Use provided model path
            modelPath = arguments[1]
        } else {
            // Use default model path
            modelPath = "~/Documents/SnapGoModels/mxbai-embed-large-v1-q4_k_m.gguf"
            print("📝 No model path provided. Using default: \(modelPath)")
            print("💡 Usage: swift run Demo <model_path>")
        }
        
        let expandedPath = NSString(string: modelPath).expandingTildeInPath
        
        print("🔍 Looking for model at: \(expandedPath)")
        
        // Check if model exists
        if !FileManager.default.fileExists(atPath: expandedPath) {
            print("❌ Model not found at: \(expandedPath)")
            print("💡 Usage: swift run Demo <model_path>")
            print("📥 Example: swift run Demo ~/Downloads/mxbai-embed-large-v1-q4_k_m.gguf")
            return
        }
        
        do {
            print("🔄 Loading model...")
            let model = try EmbeddingModel(modelPath: expandedPath)
            print("✅ Model loaded successfully!")
            print("📏 Embedding dimension: \(model.embeddingDimension)")
            
            // Test embedding generation
            let texts = [
                "Hello world",
                "Swift programming language",
                "Machine learning with embeddings"
            ]
            
            print("\n🧮 Generating embeddings...")
            for (i, text) in texts.enumerated() {
                let embedding = try model.embed(text: text)
                print("Text \(i+1): '\(text)'")
                print("  Embedding size: \(embedding.count)")
                print("  First 5 values: \(Array(embedding.prefix(5)))")
                print("")
            }
            
            // Test similarity
            print("🔍 Testing similarity...")
            let text1 = "cat sleeping"
            let text2 = "cat resting"
            let text3 = "weather sunny"
            
            let emb1 = try model.embed(text: text1)
            let emb2 = try model.embed(text: text2)
            let emb3 = try model.embed(text: text3)
            
            let sim12 = EmbeddingModel.cosineSimilarity(emb1, emb2)
            let sim13 = EmbeddingModel.cosineSimilarity(emb1, emb3)
            
            print("Similarity between '\(text1)' and '\(text2)': \(sim12)")
            print("Similarity between '\(text1)' and '\(text3)': \(sim13)")
            
            print("✅ Demo completed successfully!")
            
        } catch {
            print("❌ Error: \(error)")
        }
    }
} 