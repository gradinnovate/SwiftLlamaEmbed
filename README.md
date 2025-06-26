# SwiftLlamaEmbed

A Swift wrapper for llama.cpp that provides easy-to-use text embedding functionality for iOS, macOS, tvOS, and visionOS applications.

## Features

- 🚀 **High Performance**: Built on top of llama.cpp for optimal performance
- 📱 **Multi-Platform**: Supports iOS, macOS, tvOS, and visionOS
- 🎯 **Simple API**: Clean Swift interface for text embedding generation
- 🔧 **Configurable**: Customizable model parameters and pooling strategies
- 📊 **Utility Functions**: Built-in cosine similarity and normalization functions

## Installation

### Swift Package Manager

Add SwiftLlamaEmbed as a dependency in your `Package.swift` file:

```swift
dependencies: [
    .package(path: "path/to/SwiftLlamaEmbed")
]
```

Or add it through Xcode:
1. Go to File → Add Package Dependencies
2. Enter the repository URL
3. Select the version/branch you want to use

## Quick Start

### Step 1: Download a Model

First, download a compatible GGUF embedding model:

```bash
# Create model directory
mkdir -p ~/Documents/SnapGoModels

# Download mxbai-embed-large-v1-q4_k_m model
curl -L -o ~/Documents/SnapGoModels/mxbai-embed-large-v1-q4_k_m.gguf \
  "https://huggingface.co/mixedbread-ai/mxbai-embed-large-v1/resolve/main/gguf/mxbai-embed-large-v1-q4_k_m.gguf"
```

### Step 2: Try the Demo

```bash
# Clone and navigate to the repository
git clone <repository-url>
cd SwiftLlamaEmbed

# Run the demo with your model
swift run Demo ~/Documents/SnapGoModels/mxbai-embed-large-v1-q4_k_m.gguf
```

### Step 3: Use in Your Project

### Basic Usage

```swift
import SwiftLlamaEmbed

// Initialize the embedding model
let modelPath = "~/Documents/SnapGoModels/mxbai-embed-large-v1-q4_k_m.gguf"
let expandedPath = NSString(string: modelPath).expandingTildeInPath

do {
    let model = try EmbeddingModel(modelPath: expandedPath)
    
    // Generate embeddings for text
    let text = "Hello world, this is a test sentence."
    let embedding = try model.embed(text: text)
    
    print("Embedding dimension: \(model.embeddingDimension)")
    print("Generated embedding: \(embedding.count) values")
    
} catch {
    print("Error: \(error)")
}
```

### Semantic Similarity

```swift
import SwiftLlamaEmbed

let model = try EmbeddingModel(modelPath: modelPath)

let text1 = "The cat is sleeping on the mat."
let text2 = "A cat is resting on a mat."
let text3 = "The weather is nice today."

let embedding1 = try model.embed(text: text1)
let embedding2 = try model.embed(text: text2)
let embedding3 = try model.embed(text: text3)

let similarity12 = EmbeddingModel.cosineSimilarity(embedding1, embedding2)
let similarity13 = EmbeddingModel.cosineSimilarity(embedding1, embedding3)

print("Similarity between similar texts: \(similarity12)")
print("Similarity between different texts: \(similarity13)")
```

### Custom Configuration

```swift
import SwiftLlamaEmbed

let config = EmbeddingConfig(
    contextSize: 1024,
    threads: 4,
    embeddings: true,
    poolingType: LLAMA_POOLING_TYPE_MEAN
)

let model = try EmbeddingModel(modelPath: modelPath, config: config)
```

## API Reference

### EmbeddingModel

The main class for generating text embeddings.

#### Initialization

```swift
init(modelPath: String, config: EmbeddingConfig = EmbeddingConfig()) throws
```

- `modelPath`: Path to the GGUF model file
- `config`: Configuration options for the model

#### Properties

```swift
var embeddingDimension: Int32 { get }
```

Returns the dimension of embeddings produced by the model.

#### Methods

```swift
func embed(text: String) throws -> [Float]
```

Generates embeddings for the given text.

```swift
static func cosineSimilarity(_ embedding1: [Float], _ embedding2: [Float]) -> Float
```

Computes cosine similarity between two embedding vectors.

```swift
static func normalize(_ embedding: [Float]) -> [Float]
```

Normalizes an embedding vector to unit length.

### EmbeddingConfig

Configuration structure for customizing model behavior.

```swift
struct EmbeddingConfig {
    let contextSize: Int32      // Context size (default: 512)
    let threads: Int32          // Number of threads (default: 0 = auto)
    let embeddings: Bool        // Enable embeddings (default: true)
    let poolingType: llama_pooling_type  // Pooling strategy (default: MEAN)
}
```

### LlamaEmbedError

Error types that can be thrown by the library:

- `.modelLoadFailed(String)`: Failed to load the model file
- `.contextCreationFailed`: Failed to create llama context
- `.tokenizationFailed`: Failed to tokenize input text
- `.encodingFailed`: Failed to encode tokens to embeddings
- `.invalidModelPath`: Invalid model file path
- `.backendInitializationFailed`: Failed to initialize llama backend

## Model Requirements

This library works with GGUF format embedding models. Make sure your model:

1. Is in GGUF format
2. Supports embedding generation
3. Is compatible with llama.cpp

### Recommended Models

- `mxbai-embed-large-v1` (quantized versions available)
- `nomic-embed-text-v1`
- `all-MiniLM-L6-v2`

### Model Download

You can download compatible models from:

1. **Hugging Face** - Search for models with "gguf" in the name
2. **Hugging Face Collections** - Look for llama.cpp compatible embedding models

#### Example: Download mxbai-embed-large-v1-q4_k_m

```bash
# Create model directory
mkdir -p ~/Documents/SnapGoModels

# Download using wget (if available)
wget -O ~/Documents/SnapGoModels/mxbai-embed-large-v1-q4_k_m.gguf \
  "https://huggingface.co/mixedbread-ai/mxbai-embed-large-v1/resolve/main/gguf/mxbai-embed-large-v1-q4_k_m.gguf"

# Or download using curl
curl -L -o ~/Documents/SnapGoModels/mxbai-embed-large-v1-q4_k_m.gguf \
  "https://huggingface.co/mixedbread-ai/mxbai-embed-large-v1/resolve/main/gguf/mxbai-embed-large-v1-q4_k_m.gguf"
```

#### Model Size Guidelines

- **Q4_K_M**: Good balance of quality and size (~700MB for large models)
- **Q8_0**: Higher quality, larger size (~1.3GB for large models)
- **F16**: Highest quality, largest size (~2.6GB for large models)

## Performance Tips

1. **Choose appropriate context size**: Larger context sizes use more memory
2. **Use quantized models**: Q4_K_M or Q8_0 for balance of size and quality
3. **Adjust thread count**: Set to match your device's CPU cores
4. **Reuse model instances**: Avoid creating multiple instances for the same model

## Demo Application

The package includes a demo application that showcases the library's functionality.

### Running the Demo

#### With Custom Model Path:
```bash
swift run Demo /path/to/your/model.gguf
```

#### With Default Model Path:
```bash
swift run Demo
```
Uses default path: `~/Documents/SnapGoModels/mxbai-embed-large-v1-q4_k_m.gguf`

#### Examples:
```bash
# Using a downloaded model
swift run Demo ~/Downloads/mxbai-embed-large-v1-q4_k_m.gguf

# Using a relative path
swift run Demo ./models/embedding-model.gguf

# Using an absolute path
swift run Demo /Users/username/Models/mxbai-embed-large-v1-q4_k_m.gguf
```

### Demo Features

The demo application demonstrates:

1. **Model Loading**: Loading and initializing embedding models
2. **Text Embedding**: Generating embeddings for multiple text samples
3. **Similarity Calculation**: Computing cosine similarity between texts
4. **Error Handling**: Proper error handling and user feedback

### Demo Output Example

```
=== SwiftLlamaEmbed Demo ===
🔍 Looking for model at: /Users/username/Downloads/mxbai-embed-large-v1-q4_k_m.gguf
🔄 Loading model...
✅ Model loaded successfully!
📏 Embedding dimension: 1024

🧮 Generating embeddings...
Text 1: 'Hello world'
  Embedding size: 1024
  First 5 values: [0.45076138, -0.10205228, 0.34666988, 0.1038327, -0.92713916]

Text 2: 'Swift programming language'
  Embedding size: 1024
  First 5 values: [0.12345678, -0.87654321, 0.11111111, 0.22222222, -0.33333333]

Text 3: 'Machine learning with embeddings'
  Embedding size: 1024
  First 5 values: [0.98765432, -0.11111111, 0.44444444, 0.55555555, -0.66666666]

🔍 Testing similarity...
Similarity between 'cat sleeping' and 'cat resting': 0.8523456
Similarity between 'cat sleeping' and 'weather sunny': 0.1234567
✅ Demo completed successfully!
```

## Examples

The library includes several example functions in `ExampleUsage`:

```swift
// Basic usage
ExampleUsage.basicExample()

// Semantic similarity search
ExampleUsage.semanticSimilarityExample()

// Custom configuration
ExampleUsage.customConfigExample()

// Batch processing
ExampleUsage.batchProcessingExample()
```

## Testing

Run the test suite to verify the installation:

```bash
swift test
```

Make sure you have a valid GGUF model file at the specified path in the tests.

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- Built on top of [llama.cpp](https://github.com/ggerganov/llama.cpp)
- Inspired by the need for local text embeddings in Swift applications 