import Foundation

#if canImport(FoundationModels)
import FoundationModels

@available(iOS 26.0, *)
@MainActor
public enum OnDeviceAIService {
    public static var isAvailable: Bool {
        switch SystemLanguageModel.default.availability {
        case .available:
            return true
        default:
            return false
        }
    }

    public static func answer(query: String, contextSummary: String) async throws -> String {
        let instructions = """
        You are Common Ground, a private co-parenting assistant built into a family app.
        Answer ONLY using the family data provided below. Be concise, warm, and factual.
        If the data does not contain enough information, say what is missing.
        Never invent medical, legal, or financial details.

        Family data:
        \(contextSummary)
        """

        let session = LanguageModelSession(instructions: instructions)
        let response = try await session.respond(to: query)
        return response.content
    }
}
#endif
