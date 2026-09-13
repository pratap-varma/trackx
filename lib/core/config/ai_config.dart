import 'dart:convert';
import 'package:http/http.dart' as http;

class AiConfig {
  static const String geminiModel = 'gemini-3.6-flash';
}

class AiModelManager {
  static String? _cachedGeminiModel;
  static String? _cachedGroqModel;

  static Future<String> getActiveGeminiModel(String apiKey) async {
    if (_cachedGeminiModel != null && _cachedGeminiModel != 'gemini-2.5-flash') {
      return _cachedGeminiModel!;
    }

    try {
      final uri = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models?key=$apiKey');
      final res = await http.get(uri).timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final models = data['models'] as List?;
        if (models != null) {
          final contentModels = models.where((m) {
            final methods = (m['supportedGenerationMethods'] as List?)?.map((e) => e.toString()).toList();
            return methods == null || methods.contains('generateContent');
          }).map((m) => m['name'].toString().replaceAll('models/', '')).toList();

          for (final candidate in [
            'gemini-3.6-flash',
            'gemini-2.0-flash',
            'gemini-1.5-flash',
            'gemini-1.5-flash-002',
            'gemini-1.5-flash-001',
            'gemini-1.5-pro',
            'gemini-pro',
          ]) {
            if (contentModels.contains(candidate)) {
              _cachedGeminiModel = candidate;
              return candidate;
            }
          }
          // Fallback to any gemini flash model in the list that supports generateContent,
          // strictly excluding deprecated/unavailable models like gemini-2.5-flash
          for (final name in contentModels) {
            if (name.contains('gemini') &&
                name.contains('flash') &&
                !name.contains('2.5')) {
              _cachedGeminiModel = name;
              return name;
            }
          }
        }
      }
    } catch (e) {
      print('[DEBUG LOG] Dynamic Model Listing: Gemini list failed: $e');
    }

    return 'gemini-3.6-flash'; // Stable official GA fallback
  }

  static Future<String?> getActiveGroqModel(String apiKey) async {
    if (_cachedGroqModel != null) return _cachedGroqModel;

    try {
      final uri = Uri.parse('https://api.groq.com/openai/v1/models');
      final res = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $apiKey'},
      ).timeout(const Duration(seconds: 5));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final dataList = data['data'] as List?;
        if (dataList != null) {
          final names = dataList.map((m) => m['id'].toString()).toList();
          // Look for stable llama vision models first
          for (final candidate in ['llama-3.2-11b-vision', 'llama-3.2-90b-vision']) {
            if (names.contains(candidate)) {
              _cachedGroqModel = candidate;
              print('[DEBUG LOG] Dynamic Model Listing: Found verified Groq candidate $candidate');
              return candidate;
            }
          }
          // Fallback to any vision model in the list
          for (final name in names) {
            if (name.contains('vision')) {
              _cachedGroqModel = name;
              print('[DEBUG LOG] Dynamic Model Listing: Fallback to Groq $name');
              return name;
            }
          }
        }
      }
    } catch (e) {
      print('[DEBUG LOG] Dynamic Model Listing: Groq list failed: $e');
    }

    return null; // Return null if no supported vision model found
  }
}
