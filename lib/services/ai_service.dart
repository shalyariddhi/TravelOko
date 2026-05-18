import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class AIService {
  static String get apiKey => dotenv.env['OPENAI_API_KEY'] ?? '';

  static Future<Map<String, dynamic>> getTripSuggestion({
    required String location,
    required int budget,
    required int days,
    required List<String> nearbyContext,
    String? preferences,
  }) async {
    final url = Uri.parse("https://api.openai.com/v1/chat/completions");

    final contextString = nearbyContext.isNotEmpty 
        ? "Available places nearby to prioritize: ${nearbyContext.join(', ')}." 
        : "";

    final preferenceString = preferences != null && preferences.isNotEmpty
        ? "User Preferences: $preferences."
        : "";

    final response = await http.post(
      url,
      headers: {
        "Authorization": "Bearer $apiKey",
        "Content-Type": "application/json",
      },
      body: json.encode({
        "model": "gpt-4o-mini",
        "messages": [
          {
            "role": "system",
            "content": "You are a personalized travel planner. Return ONLY raw JSON (no markdown formatting, no backticks). Required Structure: {\"title\": \"string\", \"description\": \"string\", \"places\": [{\"name\": \"string\", \"cost\": number, \"type\": \"string\"}], \"budget\": number, \"duration\": number}. For 'type', use 'hotel', 'food', or 'activity'. Provide realistic estimated 'cost' per person in local currency. $contextString $preferenceString"
          },
          {
            "role": "user",
            "content": "Plan a safe, realistic trip in or around $location for $days days with a budget of ₹$budget. Suggest places from the provided nearby list when applicable."
          }
        ]
      }),
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to fetch AI suggestions. Code: ${response.statusCode}");
    }

    final data = json.decode(response.body);
    var content = data["choices"][0]["message"]["content"];

    // Clean up potential markdown formatting issues
    content = content.replaceAll("```json", "").replaceAll("```", "").trim();

    return json.decode(content);
  }

  static Future<List<double>> getEmbedding(String text) async {
    final res = await http.post(
      Uri.parse("https://api.openai.com/v1/embeddings"),
      headers: {
        "Authorization": "Bearer $apiKey",
        "Content-Type": "application/json",
      },
      body: json.encode({
        "model": "text-embedding-3-small",
        "input": text,
      }),
    );

    if (res.statusCode != 200) {
      debugPrint("Failed to fetch embedding: ${res.body}");
      return [];
    }

    final data = json.decode(res.body);
    return List<double>.from(data["data"][0]["embedding"]);
  }
}
