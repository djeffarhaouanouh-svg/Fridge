import 'dart:convert';
import 'dart:typed_data';
import 'package:google_generative_ai/google_generative_ai.dart';

class GoogleVisionService {
  static const _apiKey = 'AIzaSyBxx8QJSlnTZB6J8kV-rZ14wuvB_RQZikg';

  final _model = GenerativeModel(
    model: 'gemini-2.0-flash',
    apiKey: _apiKey,
  );

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
