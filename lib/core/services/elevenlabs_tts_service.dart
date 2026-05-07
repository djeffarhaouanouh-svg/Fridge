import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class ElevenLabsTtsService {
  static const _apiKey = String.fromEnvironment('ELEVENLABS_API_KEY');
  static const _configuredVoiceId = String.fromEnvironment(
    'ELEVENLABS_VOICE_ID',
    defaultValue: '21m00Tcm4TlvDq8ikWAM',
  );
  static const _fallbackVoiceIds = <String>[
    '21m00Tcm4TlvDq8ikWAM',
    'EXAVITQu4vr4xnSDxMaL',
  ];

  Future<Uint8List> synthesize(String text) async {
    if (_apiKey.isEmpty) {
      throw Exception('ELEVENLABS_API_KEY is missing.');
    }

    final voicesToTry = <String>[
      _configuredVoiceId.trim(),
      ..._fallbackVoiceIds,
    ].where((id) => id.isNotEmpty).toSet();

    String? lastError;
    for (final voiceId in voicesToTry) {
      final response = await http
          .post(
            Uri.parse('https://api.elevenlabs.io/v1/text-to-speech/$voiceId'),
            headers: {
              'xi-api-key': _apiKey,
              'content-type': 'application/json',
              'accept': 'audio/mpeg',
            },
            body: jsonEncode({
              'text': text,
              'model_id': 'eleven_multilingual_v2',
              'voice_settings': {
                'stability': 0.45,
                'similarity_boost': 0.75,
              },
            }),
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        return response.bodyBytes;
      }

      lastError = 'voice=$voiceId status=${response.statusCode} body=${response.body}';
    }

    throw Exception('ElevenLabs failed: $lastError');
  }
}
