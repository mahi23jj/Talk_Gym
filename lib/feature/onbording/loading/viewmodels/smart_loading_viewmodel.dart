// lib/viewmodels/smart_loading_viewmodel.dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../repositories/health_repository.dart';

enum LoadingState {
  initializing,
  calibrating,
  personalizing,
  ready,
  completed,
  error,
}

class SmartLoadingViewModel extends ChangeNotifier {
  final HealthRepository _healthRepository;
  
  LoadingState _currentState = LoadingState.initializing;
  LoadingState get currentState => _currentState;
  
  String _errorMessage = '';
  String get errorMessage => _errorMessage;
  
  bool _isBackendHealthy = false;
  bool get isBackendHealthy => _isBackendHealthy;
  
  int _healthCheckAttempts = 0;
  int get healthCheckAttempts => _healthCheckAttempts;
  
  Timer? _stateTimer;
  Timer? _healthCheckTimer;
  
  SmartLoadingViewModel({HealthRepository? healthRepository})
      : _healthRepository = healthRepository ?? HealthRepository();
  
  void startLoadingSequence() {
    _startHealthCheck();
    _startStateProgression();
  }
  
  void _startHealthCheck() {
    _healthCheckTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      if (!_isBackendHealthy) {
        await _checkBackendHealth();
      } else {
        timer.cancel();
      }
    });
  }
  
  Future<void> _checkBackendHealth() async {
    _healthCheckAttempts++;
    notifyListeners();
    
    try {
      final health = await _healthRepository.checkHealth();
      if (health.isHealthy) {
        _isBackendHealthy = true;
        notifyListeners();
        debugPrint('✅ Backend is healthy after $_healthCheckAttempts attempts');
      }
    } catch (e) {
      debugPrint('⚠️ Health check attempt $_healthCheckAttempts failed: $e');
    }
  }
  
  void _startStateProgression() {
    const stateDurations = {
      LoadingState.initializing: Duration(seconds: 3),
      LoadingState.calibrating: Duration(seconds: 3),
      LoadingState.personalizing: Duration(seconds: 3),
      LoadingState.ready: Duration(seconds: 2),
    };
    
    _stateTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_currentState == LoadingState.ready) {
        timer.cancel();
        _completeLoading();
      } else {
        _advanceToNextState();
      }
    });
  }
  
  void _advanceToNextState() {
    switch (_currentState) {
      case LoadingState.initializing:
        _currentState = LoadingState.calibrating;
        break;
      case LoadingState.calibrating:
        _currentState = LoadingState.personalizing;
        break;
      case LoadingState.personalizing:
        _currentState = LoadingState.ready;
        break;
      default:
        break;
    }
    notifyListeners();
  }
  
  Future<void> _completeLoading() async {
    _stateTimer?.cancel();
    
    // Wait for backend to be healthy if not already
    if (!_isBackendHealthy) {
      _currentState = LoadingState.initializing;
      notifyListeners();
      
      try {
        await _healthRepository.waitForHealthyBackend(
          onRetry: (attempt, delay) {
            _healthCheckAttempts = attempt;
            notifyListeners();
          },
        );
        _isBackendHealthy = true;
        notifyListeners();
      } catch (e) {
        _errorMessage = 'Unable to connect to coaching service. Please check your connection.';
        _currentState = LoadingState.error;
        notifyListeners();
        return;
      }
    }
    
    _currentState = LoadingState.completed;
    notifyListeners();
  }
  
  String getStateTitle() {
    switch (_currentState) {
      case LoadingState.initializing:
        return 'Initializing Intelligence';
      case LoadingState.calibrating:
        return 'Calibrating Voice Analysis';
      case LoadingState.personalizing:
        return 'Personalizing Coaching';
      case LoadingState.ready:
        return 'Ready';
      case LoadingState.completed:
        return 'Complete';
      case LoadingState.error:
        return 'Connection Error';
    }
  }
  
  String getStateSubtitle() {
    switch (_currentState) {
      case LoadingState.initializing:
        return 'Preparing your training environment';
      case LoadingState.calibrating:
        return 'Calibrating communication signals';
      case LoadingState.personalizing:
        return 'Adapting to your practice style';
      case LoadingState.ready:
        return 'Your coach is ready';
      case LoadingState.completed:
        return 'Welcome to TalkGym';
      case LoadingState.error:
        return 'Unable to connect';
    }
  }
  
  String getStateDescription() {
    switch (_currentState) {
      case LoadingState.initializing:
        return 'Setting the foundation for focused interview practice.';
      case LoadingState.calibrating:
        return 'Aligning for precision feedback.';
      case LoadingState.personalizing:
        return 'Creating your personalized coaching flow.';
      case LoadingState.ready:
        return 'Let\'s train your next breakthrough.';
      case LoadingState.completed:
        return 'Your personalized coaching journey begins now.';
      case LoadingState.error:
        return _errorMessage;
    }
  }
  
  @override
  void dispose() {
    _stateTimer?.cancel();
    _healthCheckTimer?.cancel();
    super.dispose();
  }
}