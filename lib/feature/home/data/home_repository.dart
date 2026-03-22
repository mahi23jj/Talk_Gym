import '../model/home_models.dart';

abstract class HomeRepository {
  Future<HomeDashboardData> fetchDashboard();
}
