import 'dart:convert';
import 'package:http/http.dart' as http;

class OpenAIService {
  final String _apiKey =
      "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";

  final String _apiUrl = "https://api.openai.com/v1/images/generations";

  Future<String> generateImage(String prompt) async {
    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'dall-e-3',
          'prompt': prompt,
          'n': 1,
          'size': '1024x1024',
          'response_format': 'url',
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'][0]['url'];
      } else {
        throw Exception(
            'Failed to generate image: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to connect to the internet:');
    }
  }
}
