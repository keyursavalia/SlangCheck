// Data/Services/GeminiAPIClient.swift
// SlangCheck
//
// Lightweight HTTP client for Google's Gemini REST API.
// Used as the fallback AI backend when Apple Intelligence is unavailable.
// The API key is read from `Secrets.plist` (not committed to source control).

import Foundation
import OSLog

// MARK: - GeminiAPIClient

/// Sends structured-output requests to the Gemini REST API.
///
/// All calls use JSON mode (`responseMimeType: "application/json"`) so
/// responses can be decoded directly into typed Swift structs.
struct GeminiAPIClient: Sendable {

    // MARK: - Configuration

    /// The Gemini model ID. `gemini-2.0-flash` balances speed with quality.
    private static let modelID = "gemini-2.0-flash"

    /// Base URL for the Gemini v1beta generative language API.
    private static let baseURL = "https://generativelanguage.googleapis.com/v1beta/models"

    // MARK: - API Key

    /// Reads the Gemini API key from `Secrets.plist` in the main bundle.
    ///
    /// `Secrets.plist` is listed in `.gitignore` — never committed.
    /// Format: `<dict><key>GeminiAPIKey</key><string>YOUR_KEY</string></dict>`
    static var apiKey: String? {
        guard let path = Bundle.main.path(forResource: "Secrets", ofType: "plist"),
              let dict = NSDictionary(contentsOfFile: path),
              let key  = dict["GeminiAPIKey"] as? String,
              !key.isEmpty
        else { return nil }
        return key
    }

    // MARK: - Request

    /// Sends a prompt to Gemini and decodes the JSON response into `T`.
    ///
    /// - Parameters:
    ///   - systemInstruction: Optional system prompt for the model.
    ///   - prompt: The user-facing prompt text.
    ///   - schema: A JSON Schema dictionary describing the expected output shape.
    /// - Returns: The decoded response, or `nil` on any failure.
    func generate<T: Decodable>(
        systemInstruction: String? = nil,
        prompt: String,
        schema: [String: Any],
        as type: T.Type
    ) async -> T? {
        guard let apiKey = Self.apiKey else {
            Logger.app.warning("Gemini API key not configured. Add it to Secrets.plist.")
            return nil
        }

        let endpoint = "\(Self.baseURL)/\(Self.modelID):generateContent?key=\(apiKey)"
        // SAFE: endpoint is built from compile-time constants + a validated plist string.
        guard let url = URL(string: endpoint) else { return nil }

        var body: [String: Any] = [
            "contents": [
                ["parts": [["text": prompt]]]
            ],
            "generationConfig": [
                "responseMimeType": "application/json",
                "responseSchema": schema
            ]
        ]

        if let systemInstruction {
            body["systemInstruction"] = [
                "parts": [["text": systemInstruction]]
            ]
        }

        guard let httpBody = try? JSONSerialization.data(withJSONObject: body) else { return nil }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = httpBody

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                Logger.app.error("Gemini API returned non-2xx status.")
                return nil
            }
            return parseGeminiResponse(data: data, as: type)
        } catch {
            Logger.app.error("Gemini API request failed: \(error.localizedDescription)")
            return nil
        }
    }

    // MARK: - Response Parsing

    /// Extracts the text content from Gemini's response envelope and decodes it.
    ///
    /// Gemini wraps its output in: `{ "candidates": [{ "content": { "parts": [{ "text": "..." }] } }] }`.
    /// The `text` field contains the JSON string we need to decode.
    private func parseGeminiResponse<T: Decodable>(data: Data, as type: T.Type) -> T? {
        guard let envelope = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let candidates = envelope["candidates"] as? [[String: Any]],
              let content = candidates.first?["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]],
              let text = parts.first?["text"] as? String,
              let jsonData = text.data(using: .utf8)
        else { return nil }

        return try? JSONDecoder().decode(type, from: jsonData)
    }
}
