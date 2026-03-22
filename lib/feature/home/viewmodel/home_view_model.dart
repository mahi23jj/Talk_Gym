import 'package:flutter/foundation.dart';

import '../data/home_repository.dart';
import '../model/home_models.dart';

class HomeViewModel extends ChangeNotifier {
  HomeViewModel({required HomeRepository repository})
    : _repository = repository;

  final HomeRepository _repository;

  HomeDashboardData? _dashboard;
  bool _isLoading = false;
  String? _error;
  int _currentNavIndex = 0;

  HomeDashboardData? get dashboard => _dashboard;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get currentNavIndex => _currentNavIndex;

  Future<void> loadDashboard() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _dashboard = await _repository.fetchDashboard();
    } catch (_) {
      _error = 'Could not load dashboard data.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setNavIndex(int index) {
    if (_currentNavIndex == index) {
      return;
    }

    _currentNavIndex = index;
    notifyListeners();
  }
}
