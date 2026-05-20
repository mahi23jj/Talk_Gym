import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/constants/api_constants.dart';
import '../models/profile_model.dart';
import 'package:talk_gym/core/auth_token_storage.dart';

class ProfileRepository {
  final http.Client client;

  ProfileRepository({required this.client});

  Future<ProfileModel> getProfile() async {
    final String bearerToken = await _resolveBearerToken();
    final response = await client.get(
      Uri.parse('${ApiConstants.baseUrl}/api/v1/profile'),
      headers: {
        'Authorization': 'Bearer $bearerToken',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      return ProfileModel.fromJson(data);
    } else if (response.statusCode == 401) {
      throw Exception('Authentication failed. Please login again.');
    } else {
      throw Exception('Failed to load profile. Status: ${response.statusCode}');
    }
  }

  // Mock data for development/testing
  Future<ProfileModel> getMockProfile() async {
    await Future.delayed(const Duration(milliseconds: 500)); // Simulate network delay
    return ProfileModel(
      username: 'Mahlet',
      email: 'solomonmahi782@gmail.com',
      trialStatus: const TrialStatus(
        interviewsUsed: 24,
        interviewsLimit: 5,
        remaining: 0,
      ),
      progress: const Progress(
        totalQuestionsAttempted: 24,
        completedSessions: 2,
        avgImprovement: 0,
      ),
    );
  }

  Future<String> _resolveBearerToken() async {
    final String token = (await AuthTokenStorage.getToken() ?? '').trim();
    if (token.isEmpty) {
      throw StateError(
        'Missing authentication token. Please login/signin first.',
      );
    }
    return token;
  }
}