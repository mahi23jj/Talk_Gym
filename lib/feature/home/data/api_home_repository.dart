import '../model/home_models.dart';
import 'home_repository.dart';

class ApiHomeRepository implements HomeRepository {
  const ApiHomeRepository();

  @override
  Future<HomeDashboardData> fetchDashboard() {
    // TODO: Replace with real API call and JSON mapping.
    throw UnimplementedError('API repository is not implemented yet.');
  }
}
