/// Configuration for AI APIs.
///
/// If Vertex AI is not enabled or not found in your Firebase Console,
/// you can get a completely free Gemini API key (no credit card needed)
/// from: https://aistudio.google.com/app/apikey
///
/// Paste your API key below or pass it via:
/// flutter run --dart-define=GEMINI_API_KEY=your_key_here
class ApiConfig {
  // Google AI Studio Gemini API key:
  static const String geminiApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: '', // Kept empty in repository for security. Add locally or via --dart-define
  );

  /// Returns true if a Google AI Studio API key is provided.
  static bool get hasGeminiApiKey => geminiApiKey.trim().isNotEmpty;
}
