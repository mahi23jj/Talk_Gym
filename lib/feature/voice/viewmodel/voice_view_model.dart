import 'package:flutter/foundation.dart';

import '../data/voice_repository.dart';
import '../model/voice_models.dart';

class VoiceViewModel extends ChangeNotifier {
  VoiceViewModel({required VoiceRepository repository})
    : _repository = repository;

  final VoiceRepository _repository;

  List<VoiceScenario> _scenarios = <VoiceScenario>[];
  bool _isLoading = false;
  String? _error;
  VoiceScenario? _selectedScenario;
  String _responseDraft = '';
  bool _isPlayingAudio = false;

  List<VoiceScenario> get scenarios => _scenarios;
  bool get isLoading => _isLoading;
  String? get error => _error;
  VoiceScenario? get selectedScenario => _selectedScenario;
  String get responseDraft => _responseDraft;
  bool get isPlayingAudio => _isPlayingAudio;
  bool get canSubmitResponse => _responseDraft.trim().isNotEmpty;

  Future<void> loadScenarios() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _scenarios = await _repository.fetchScenarios();
    } catch (_) {
      _error = 'Could not load voice scenarios.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void selectScenario(VoiceScenario scenario) {
    _selectedScenario = scenario;
    _responseDraft = '';
    _isPlayingAudio = false;
    notifyListeners();
  }

  void backToList() {
    _selectedScenario = null;
    _responseDraft = '';
    _isPlayingAudio = false;
    notifyListeners();
  }

  void updateResponseDraft(String value) {
    _responseDraft = value;
    notifyListeners();
  }

  void toggleAudioPlayback() {
    if (_selectedScenario == null) {
      return;
    }

    _isPlayingAudio = !_isPlayingAudio;
    notifyListeners();
  }
}
