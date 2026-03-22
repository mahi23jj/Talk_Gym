import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/exercise_repository.dart';
import '../model/journey_models.dart';

enum ChallengeMode { speed, concise }

class ExerciseViewModel extends ChangeNotifier {
  ExerciseViewModel({required ExerciseRepository repository})
    : _repository = repository;

  final ExerciseRepository _repository;

  JourneyData? _journey;
  bool _isLoading = false;
  String? _error;
  JourneyNode? _selectedNode;
  bool _isRecording = false;
  int _recordingSeconds = 0;
  bool _isChallengeModeSelectionVisible = false;
  ChallengeMode? _activeChallengeMode;
  bool _isCoachConversationVisible = false;
  bool _isResultVisible = false;
  bool _isCoachRecording = false;
  int _coachRecordingSeconds = 0;
  Timer? _timer;
  Timer? _coachTimer;

  JourneyData? get journey => _journey;
  bool get isLoading => _isLoading;
  String? get error => _error;
  JourneyNode? get selectedNode => _selectedNode;
  bool get isRecording => _isRecording;
  int get recordingSeconds => _recordingSeconds;
  bool get isChallengeModeSelectionVisible => _isChallengeModeSelectionVisible;
  ChallengeMode? get activeChallengeMode => _activeChallengeMode;
  bool get isCoachConversationVisible => _isCoachConversationVisible;
  bool get isResultVisible => _isResultVisible;
  bool get isCoachRecording => _isCoachRecording;
  int get coachRecordingSeconds => _coachRecordingSeconds;
  bool get canSubmitAnswer => _recordingSeconds > 0;

  Future<void> loadJourney() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _journey = await _repository.fetchJourney();
    } catch (_) {
      _error = 'Could not load journey.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void selectNode(JourneyNode node) {
    if (node.state == JourneyNodeState.locked) {
      return;
    }

    _selectedNode = node;
    _isChallengeModeSelectionVisible = false;
    _activeChallengeMode = null;
    _isCoachConversationVisible = false;
    _isResultVisible = false;
    _resetRecording();
    _resetCoachRecording();
    notifyListeners();
  }

  void backToJourney() {
    _selectedNode = null;
    _isChallengeModeSelectionVisible = false;
    _activeChallengeMode = null;
    _isCoachConversationVisible = false;
    _isResultVisible = false;
    _resetRecording();
    _resetCoachRecording();
    notifyListeners();
  }

  void openChallengeModeSelection() {
    if (_selectedNode == null || !canSubmitAnswer) {
      return;
    }

    _timer?.cancel();
    _isRecording = false;
    _isChallengeModeSelectionVisible = true;
    _activeChallengeMode = null;
    _isCoachConversationVisible = false;
    _isResultVisible = false;
    notifyListeners();
  }

  void backToLevelDetail() {
    if (!_isChallengeModeSelectionVisible) {
      return;
    }

    _isChallengeModeSelectionVisible = false;
    _activeChallengeMode = null;
    _isCoachConversationVisible = false;
    _isResultVisible = false;
    notifyListeners();
  }

  void selectSpeedChallenge() {
    if (!_isChallengeModeSelectionVisible) {
      return;
    }

    _activeChallengeMode = ChallengeMode.speed;
    _isChallengeModeSelectionVisible = false;
    _isCoachConversationVisible = false;
    _isResultVisible = false;
    notifyListeners();
  }

  void selectConciseChallenge() {
    if (!_isChallengeModeSelectionVisible) {
      return;
    }

    _activeChallengeMode = ChallengeMode.concise;
    _isChallengeModeSelectionVisible = false;
    _isCoachConversationVisible = false;
    _isResultVisible = false;
    notifyListeners();
  }

  void backToChallengeSelection() {
    if (_activeChallengeMode == null) {
      return;
    }

    _activeChallengeMode = null;
    _isChallengeModeSelectionVisible = true;
    _isCoachConversationVisible = false;
    _isResultVisible = false;
    notifyListeners();
  }

  void openCoachConversation() {
    if (_activeChallengeMode == null) {
      return;
    }

    _timer?.cancel();
    _isRecording = false;
    _isCoachConversationVisible = true;
    _isResultVisible = false;
    _resetCoachRecording();
    notifyListeners();
  }

  void backToChallengeActive() {
    if (!_isCoachConversationVisible) {
      return;
    }

    _isCoachConversationVisible = false;
    _isResultVisible = false;
    _resetCoachRecording();
    notifyListeners();
  }

  void openResultsPage() {
    if (!_isCoachConversationVisible) {
      return;
    }

    _coachTimer?.cancel();
    _isCoachRecording = false;
    _isCoachConversationVisible = false;
    _isResultVisible = true;
    notifyListeners();
  }

  void retryQuestionFromResults() {
    if (!_isResultVisible) {
      return;
    }

    _isResultVisible = false;
    _isCoachConversationVisible = false;
    _resetCoachRecording();
    _resetRecording();
    notifyListeners();
  }

  void toggleCoachRecording() {
    if (_isCoachRecording) {
      _coachTimer?.cancel();
      _isCoachRecording = false;
      notifyListeners();
      return;
    }

    _isCoachRecording = true;
    _coachTimer?.cancel();
    _coachTimer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      _coachRecordingSeconds += 1;
      notifyListeners();
    });
    notifyListeners();
  }

  void toggleRecording() {
    if (_isRecording) {
      _timer?.cancel();
      _isRecording = false;
      notifyListeners();
      return;
    }

    _isRecording = true;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      _recordingSeconds += 1;
      notifyListeners();
    });
    notifyListeners();
  }

  void _resetRecording() {
    _timer?.cancel();
    _timer = null;
    _isRecording = false;
    _recordingSeconds = 0;
  }

  void _resetCoachRecording() {
    _coachTimer?.cancel();
    _coachTimer = null;
    _isCoachRecording = false;
    _coachRecordingSeconds = 0;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _coachTimer?.cancel();
    super.dispose();
  }
}
