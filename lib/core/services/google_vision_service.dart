import 'dart:convert';
import 'dart:typed_data';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../config/app_secrets.dart';

class GoogleVisionService {
  static const _visionApiKey = String.fromEnvironment('GOOGLE_VISION_API_KEY');
  static const _geminiApiKey = String.fromEnvironment('GEMINI_API_KEY');

  late final GenerativeModel _model;

  GoogleVisionService() {
    final apiKey = _visionApiKey.isNotEmpty
        ? _visionApiKey
        : (_geminiApiKey.isNotEmpty
            ? _geminiApiKey
            : AppSecrets.googleVisionApiKey);
    _model = GenerativeModel(
      model: 'gemini-2.0-flash',
      apiKey: apiKey,
    );
  }

  Future<List<String>> detectIngredients(Uint8List imageBytes) async {
    final response = await _model.generateContent([
      Content.multi([
        TextPart(
          'List all food ingredients visible in this image. '
          'Return ONLY a JSON array of strings in English, '
          'example: ["chicken","rice","tomatoes"]. Nothing else.',
        ),
        DataPart('image/jpeg', imageBytes),
      ]),
    ]);

    try {
      final text = (response.text ?? '[]')
          .replaceAll(RegExp(r'```json|```'), '')
          .trim();
      return (jsonDecode(text) as List).cast<String>();
    } catch (_) {
      return [];
    }
  }
}
