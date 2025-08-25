import Foundation

class OpenAIManager {
    static let shared = OpenAIManager()
    
    private init() {}
    
    // MARK: - Configuration
    
    private let apiKey: String = {
        // Try environment variable first (for CI/CD)
        if let envKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] {
            return envKey
        }
        
        // Use local config file (safer for personal use)
        return Config.openAIAPIKey
    }()
    private let baseURL = "https://api.openai.com/v1"
    
    // MARK: - API Models
    
    struct TranscriptionRequest {
        let audioData: Data
        let fileName: String
        let model: String = "whisper-1"
        let responseFormat: String = "json"
        let language: String? = nil // Auto-detect if nil
    }
    
    struct TranscriptionResponse: Codable {
        let text: String
    }
    
    struct ChatCompletionRequest: Codable {
        let model: String
        let messages: [ChatMessage]
        let maxTokens: Int?
        let temperature: Double?
        
        enum CodingKeys: String, CodingKey {
            case model, messages, temperature
            case maxTokens = "max_tokens"
        }
    }
    
    struct ChatMessage: Codable {
        let role: String
        let content: String
    }
    
    struct ChatCompletionResponse: Codable {
        let choices: [ChatChoice]
        let usage: Usage?
    }
    
    struct ChatChoice: Codable {
        let message: ChatMessage
    }
    
    struct Usage: Codable {
        let promptTokens: Int
        let completionTokens: Int
        let totalTokens: Int
        
        enum CodingKeys: String, CodingKey {
            case promptTokens = "prompt_tokens"
            case completionTokens = "completion_tokens"
            case totalTokens = "total_tokens"
        }
    }
    
    // MARK: - API Key Management
    
    func isAPIKeyConfigured() -> Bool {
        return !apiKey.isEmpty && apiKey != "YOUR_OPENAI_API_KEY_HERE"
    }
    
    func validateAPIKey() async throws -> Bool {
        // Test API key with a simple request
        let messages = [ChatMessage(role: "user", content: "Hello")]
        let request = ChatCompletionRequest(
            model: "gpt-3.5-turbo",
            messages: messages,
            maxTokens: 5,
            temperature: 0.1
        )
        
        do {
            _ = try await generateChatCompletion(request: request)
            return true
        } catch {
            throw OpenAIError.invalidAPIKey
        }
    }
    
    // MARK: - Speech-to-Text (Whisper)
    
    func transcribeAudio(audioData: Data, fileName: String) async throws -> String {
        guard isAPIKeyConfigured() else {
            throw OpenAIError.noAPIKey
        }
        
        let url = URL(string: "\(baseURL)/audio/transcriptions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        // Create multipart form data
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // Add model parameter
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"model\"\r\n\r\n".data(using: .utf8)!)
        body.append("whisper-1\r\n".data(using: .utf8)!)
        
        // Add response_format parameter
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"response_format\"\r\n\r\n".data(using: .utf8)!)
        body.append("json\r\n".data(using: .utf8)!)
        
        // Add audio file
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: audio/m4a\r\n\r\n".data(using: .utf8)!)
        body.append(audioData)
        body.append("\r\n".data(using: .utf8)!)
        
        // Close boundary
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw OpenAIError.networkError
            }
            
            if httpResponse.statusCode == 401 {
                throw OpenAIError.invalidAPIKey
            }
            
            guard httpResponse.statusCode == 200 else {
                throw OpenAIError.apiError("HTTP \(httpResponse.statusCode)")
            }
            
            let transcriptionResponse = try JSONDecoder().decode(TranscriptionResponse.self, from: data)
            return transcriptionResponse.text
            
        } catch let error as OpenAIError {
            throw error
        } catch {
            throw OpenAIError.networkError
        }
    }
    
    // MARK: - AI Summarization
    
    func generateSummary(from transcript: String) async throws -> String {
        guard isAPIKeyConfigured() else {
            throw OpenAIError.noAPIKey
        }
        
        let prompt = """
        Please provide a concise summary of the following voice journal entry. Focus on the main topics, key insights, and important details. Keep it brief but comprehensive:
        
        \(transcript)
        """
        
        let messages = [ChatMessage(role: "user", content: prompt)]
        let request = ChatCompletionRequest(
            model: "gpt-3.5-turbo",
            messages: messages,
            maxTokens: 150,
            temperature: 0.3
        )
        
        let response = try await generateChatCompletion(request: request)
        
        guard let firstChoice = response.choices.first else {
            throw OpenAIError.noResponse
        }
        
        return firstChoice.message.content.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    func generateInsights(from transcript: String) async throws -> String {
        guard isAPIKeyConfigured() else {
            throw OpenAIError.noAPIKey
        }
        
        let prompt = """
        Analyze this voice journal entry and provide 2-3 key insights or themes. Focus on emotions, patterns, or important realizations:
        
        \(transcript)
        """
        
        let messages = [ChatMessage(role: "user", content: prompt)]
        let request = ChatCompletionRequest(
            model: "gpt-3.5-turbo",
            messages: messages,
            maxTokens: 100,
            temperature: 0.4
        )
        
        let response = try await generateChatCompletion(request: request)
        
        guard let firstChoice = response.choices.first else {
            throw OpenAIError.noResponse
        }
        
        return firstChoice.message.content.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    // MARK: - Private Methods
    
    private func generateChatCompletion(request: ChatCompletionRequest) async throws -> ChatCompletionResponse {
        let url = URL(string: "\(baseURL)/chat/completions")!
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            urlRequest.httpBody = try JSONEncoder().encode(request)
            let (data, response) = try await URLSession.shared.data(for: urlRequest)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw OpenAIError.networkError
            }
            
            if httpResponse.statusCode == 401 {
                throw OpenAIError.invalidAPIKey
            }
            
            guard httpResponse.statusCode == 200 else {
                // Try to parse error response
                if let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let error = errorData["error"] as? [String: Any],
                   let message = error["message"] as? String {
                    throw OpenAIError.apiError(message)
                }
                throw OpenAIError.apiError("HTTP \(httpResponse.statusCode)")
            }
            
            return try JSONDecoder().decode(ChatCompletionResponse.self, from: data)
            
        } catch let error as OpenAIError {
            throw error
        } catch {
            throw OpenAIError.networkError
        }
    }
}

// MARK: - Error Types

enum OpenAIError: Error, LocalizedError {
    case noAPIKey
    case invalidAPIKey
    case networkError
    case apiError(String)
    case noResponse
    case audioFileError
    
    var errorDescription: String? {
        switch self {
        case .noAPIKey:
            return "OpenAI API key not configured. Please add your API key to use AI features."
        case .invalidAPIKey:
            return "Invalid OpenAI API key. Please check your API key and try again."
        case .networkError:
            return "Network error occurred. Please check your internet connection."
        case .apiError(let message):
            return "OpenAI API error: \(message)"
        case .noResponse:
            return "No response received from OpenAI API."
        case .audioFileError:
            return "Error processing audio file for transcription."
        }
    }
}
