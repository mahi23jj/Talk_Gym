// lib/repositories/health_repository.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:talk_gym/core/constants/api_constants.dart';
import 'package:talk_gym/feature/onbording/loading/model/health_model.dart';


class HealthRepository {
  static const int maxRetries = 30;
  static const Duration retryDelay = Duration(seconds: 1);

  Future<HealthModel> checkHealth() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/api/v1/health'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return HealthModel.fromJson(data);
      } else {
        throw Exception('Health check failed with status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to connect to backend: $e');
    }
  }

  Future<HealthModel> waitForHealthyBackend({
    Function(int attempt, Duration delay)? onRetry,
  }) async {
    int attempt = 0;
    
    while (attempt < maxRetries) {
      try {
        final health = await checkHealth();
        if (health.isHealthy) {
          return health;
        }
      } catch (e) {
        debugPrint('Health check attempt ${attempt + 1} failed: $e');
      }
      
      attempt++;
      
      if (attempt < maxRetries) {
        if (onRetry != null) {
          onRetry(attempt, retryDelay);
        }
        await Future.delayed(retryDelay);
      }
    }
    
    throw Exception('Backend not healthy after $maxRetries attempts');
  }
}