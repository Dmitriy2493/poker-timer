import 'dart:async';
import 'package:flutter/material.dart';
import '../models/blind_level.dart';
import '../models/structure.dart';
import '../models/tournament_state.dart';
import '../services/audio_service.dart';
import '../services/storage_service.dart';

class TournamentProvider extends ChangeNotifier {
  final AudioService _audioService;
  final StorageService _storageService;

  TournamentProvider(this._audioService, this._storageService);

  List<Structure> _structures = [];
  Structure? _activeStructure;
  TournamentState _state = const TournamentState();
  Timer? _timer;
  int _warningSeconds = 60;
  bool _warningFired = false;

  List<Structure> get structures => _structures;
  Structure? get activeStructure => _activeStructure;
  TournamentState get state => _state;

  BlindLevel? get currentLevel {
    if (_activeStructure == null) return null;
    final levels = _activeStructure!.levels;
    if (_state.currentLevelIndex >= levels.length) return null;
    return levels[_state.currentLevelIndex];
  }

  BlindLevel? get peekNextLevel {
    if (_activeStructure == null) return null;
    final levels = _activeStructure!.levels;
    final nextIndex = _state.currentLevelIndex + 1;
    if (nextIndex >= levels.length) return null;
    return levels[nextIndex];
  }

  bool get isLastLevel {
    if (_activeStructure == null) return true;
    return _state.currentLevelIndex >= _activeStructure!.levels.length - 1;
  }

  String get formattedTime {
    final s = _state.remainingSeconds;
    final m = s ~/ 60;
    final sec = s % 60;
    return '${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  double get levelProgress {
    if (currentLevel == null) return 0.0;
    final total = currentLevel!.durationMinutes * 60;
    if (total == 0) return 0.0;
    return 1.0 - (_state.remainingSeconds / total);
  }

  Future<void> init(int warningSeconds) async {
    _warningSeconds = warningSeconds;
    _structures = await _storageService.loadStructures();
    if (_structures.isEmpty) {
      final defaultStructure = Structure.defaultStructure();
      await _storageService.saveStructure(defaultStructure);
      _structures = [defaultStructure];
    }
    if (_structures.isNotEmpty) {
      _activeStructure = _structures.first;
      _resetToCurrentLevel();
    }
    notifyListeners();
  }

  void selectStructure(Structure structure) {
    stop();
    _activeStructure = structure;
    _state = const TournamentState();
    _resetToCurrentLevel();
    notifyListeners();
  }

  void start() {
    if (_activeStructure == null) return;
    if (_state.status == TimerStatus.running) return;

    _state = _state.copyWith(status: TimerStatus.running);
    _timer = Timer.periodic(const Duration(seconds: 1), _onTick);
    notifyListeners();
  }

  void pause() {
    _timer?.cancel();
    _state = _state.copyWith(status: TimerStatus.paused);
    notifyListeners();
  }

  void stop() {
    _timer?.cancel();
    _state = const TournamentState();
    if (_activeStructure != null && _activeStructure!.levels.isNotEmpty) {
      _resetToCurrentLevel();
    }
    notifyListeners();
  }

  void nextLevel() {
    if (isLastLevel) return;
    _state = _state.copyWith(
      currentLevelIndex: _state.currentLevelIndex + 1,
      status: _state.status == TimerStatus.running ? TimerStatus.running : TimerStatus.paused,
    );
    _resetToCurrentLevel(keepStatus: true);
    notifyListeners();
  }

  void previousLevel() {
    if (_state.currentLevelIndex == 0) return;
    _state = _state.copyWith(
      currentLevelIndex: _state.currentLevelIndex - 1,
    );
    _resetToCurrentLevel(keepStatus: true);
    notifyListeners();
  }

  void _onTick(Timer timer) {
    if (_state.remainingSeconds <= 0) {
      _levelComplete();
      return;
    }

    final newRemaining = _state.remainingSeconds - 1;
    _state = _state.copyWith(remainingSeconds: newRemaining);

    // Warning alert
    if (!_warningFired && newRemaining == _warningSeconds) {
      _warningFired = true;
      _audioService.playWarning();
    }

    notifyListeners();
  }

  void _levelComplete() {
    _timer?.cancel();
    _audioService.playLevelEnd();

    if (isLastLevel) {
      _state = _state.copyWith(status: TimerStatus.stopped, remainingSeconds: 0);
      notifyListeners();
      return;
    }

    _state = _state.copyWith(
      currentLevelIndex: _state.currentLevelIndex + 1,
      status: TimerStatus.running,
    );
    _resetToCurrentLevel(keepStatus: true);
    _timer = Timer.periodic(const Duration(seconds: 1), _onTick);
    notifyListeners();
  }

  void _resetToCurrentLevel({bool keepStatus = false}) {
    if (_activeStructure == null) return;
    final level = _activeStructure!.levels[_state.currentLevelIndex];
    _warningFired = false;
    _state = _state.copyWith(
      remainingSeconds: level.durationMinutes * 60,
      status: keepStatus ? _state.status : TimerStatus.stopped,
    );
  }

  // Structure CRUD
  Future<void> addStructure(Structure structure) async {
    await _storageService.saveStructure(structure);
    _structures = await _storageService.loadStructures();
    notifyListeners();
  }

  Future<void> updateStructure(Structure structure) async {
    await _storageService.saveStructure(structure);
    _structures = await _storageService.loadStructures();
    if (_activeStructure?.id == structure.id) {
      _activeStructure = structure;
      _resetToCurrentLevel();
    }
    notifyListeners();
  }

  Future<void> deleteStructure(String id) async {
    await _storageService.deleteStructure(id);
    _structures = await _storageService.loadStructures();
    if (_activeStructure?.id == id) {
      _activeStructure = _structures.isNotEmpty ? _structures.first : null;
      _state = const TournamentState();
      if (_activeStructure != null) _resetToCurrentLevel();
    }
    notifyListeners();
  }

  void updateWarningSeconds(int seconds) {
    _warningSeconds = seconds;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
