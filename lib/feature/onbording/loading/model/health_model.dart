// lib/models/health_model.dart
class HealthModel {
  final String status;
  final bool isHealthy;

  HealthModel({
    required this.status,
    required this.isHealthy,
  });

  factory HealthModel.fromJson(Map<String, dynamic> json) {
    return HealthModel(
      status: json['status'] ?? 'unknown',
      isHealthy: json['status'] == 'ok',
    );
  }
}