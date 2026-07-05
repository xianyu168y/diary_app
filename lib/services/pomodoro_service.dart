import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import 'package:vibration/vibration.dart';
import '../models/pomodoro_record.dart';
import '../models/todo_task.dart';
import '../repositories/pomodoro/pomodoro_repository.dart';
import '../repositories/pomodoro/hive_pomodoro_repository.dart';
import 'todo_service.dart';

class PomodoroService extends ChangeNotifier {
  /// 全局单例（注入默认 Hive 仓库）
  static final PomodoroService instance = PomodoroService._internal(
    HivePomodoroRepository(),
  );

  factory PomodoroService() => instance;

  final PomodoroRepository _repository;

  PomodoroService._internal(this._repository);

  static const String _statsBox = 'pomodoro_stats';
  static const String _customKey = 'custom_minutes';
  static const String _durationsKey = 'custom_durations';
  static const String _timerSecondsKey = 'timer_remaining';
  static const String _timerRunningKey = 'timer_running';
  static const String _timerPausedKey = 'timer_paused';
  static const String _timerTotalKey = 'timer_total';

  Timer? _timer;
  int _remainingSeconds = 25 * 60;
  int _totalSeconds = 25 * 60;
  bool _isRunning = false;
  bool _isPaused = false;
  bool _isInitialized = false;
  int _todayCount = 0;
  int _customMinutes = 25;
  List<PomodoroRecord> _records = [];
  DateTime? _startTime;
  List<int> _customDurations = [];

  String? _boundTodoId;
  String? _boundTodoName;
  final TodoService _todoService = TodoService();

  List<int> get allDurations {
    final seen = <int>{};
    final result = <int>[];
    for (final d in [..._customDurations]) {
      if (seen.add(d)) result.add(d);
    }
    result.sort();
    return result;
  }

  int get remainingSeconds => _remainingSeconds;
  int get totalSeconds => _totalSeconds;
  bool get isRunning => _isRunning;
  bool get isPaused => _isPaused;
  double get progress => 1.0 - (_remainingSeconds / _totalSeconds);
  int get todayCount => _todayCount;
  int get customMinutes => _customMinutes;
  List<PomodoroRecord> get records => List.unmodifiable(_records);
  bool get isCustomMode => !allDurations.contains(_totalSeconds ~/ 60);
  String? get boundTodoId => _boundTodoId;
  String? get boundTodoName => _boundTodoName;
  bool get hasBoundTodo => _boundTodoId != null;

  String get formattedTime {
    final m = (_remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (_remainingSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Future<void> init() async {
    await _repository.init();
    _records = await _repository.getAll();
    final box = Hive.box(_statsBox);
    _todayCount = box.get(_todayKey, defaultValue: 0);
    _customMinutes = box.get(_customKey, defaultValue: 25);
    final raw = box.get(_durationsKey);
    if (raw is List && raw.isNotEmpty) {
      _customDurations = raw.cast<int>();
    } else {
      _customDurations = [15, 25, 30, 45, 60];
      await box.put(_durationsKey, _customDurations);
    }
    if (!_isInitialized) {
      final restored = _restoreTimerState(box);
      if (!restored) {
        if (allDurations.contains(_customMinutes)) {
          _totalSeconds = _customMinutes * 60;
          _remainingSeconds = _customMinutes * 60;
        } else if (allDurations.isNotEmpty) {
          _totalSeconds = allDurations.first * 60;
          _remainingSeconds = allDurations.first * 60;
        }
      }
      _isInitialized = true;
    }
    await _todoService.init();
    notifyListeners();
  }

  bool _restoreTimerState(Box box) {
    final savedRemaining = box.get(_timerSecondsKey);
    if (savedRemaining == null) return false;
    _remainingSeconds = savedRemaining as int;
    _totalSeconds = box.get(_timerTotalKey, defaultValue: _totalSeconds) as int;
    _isRunning = box.get(_timerRunningKey, defaultValue: false) as bool;
    _isPaused = box.get(_timerPausedKey, defaultValue: false) as bool;
    if (_isRunning && !_isPaused && _remainingSeconds > 0) {
      _startTimer();
    }
    return true;
  }

  void _persistTimerState() {
    final box = Hive.box(_statsBox);
    box.put(_timerSecondsKey, _remainingSeconds);
    box.put(_timerTotalKey, _totalSeconds);
    box.put(_timerRunningKey, _isRunning);
    box.put(_timerPausedKey, _isPaused);
  }

  String get _todayKey {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  void setDuration(int minutes) {
    if (!_isRunning) {
      _totalSeconds = minutes * 60;
      _remainingSeconds = minutes * 60;
      notifyListeners();
    }
  }

  Future<void> setCustomDuration(int minutes) async {
    if (!_isRunning) {
      _customMinutes = minutes;
      _totalSeconds = minutes * 60;
      _remainingSeconds = minutes * 60;
      final box = Hive.box(_statsBox);
      await box.put(_customKey, _customMinutes);
      notifyListeners();
    }
  }

  Future<void> addCustomDuration(int minutes) async {
    if (_customDurations.contains(minutes)) return;
    _customDurations.add(minutes);
    _customDurations.sort();
    final box = Hive.box(_statsBox);
    await box.put(_durationsKey, _customDurations);
    notifyListeners();
  }

  Future<bool> removeCustomDuration(int minutes) async {
    if (_customDurations.length <= 1) return false;
    _customDurations.remove(minutes);
    if (_totalSeconds == minutes * 60 && _customDurations.isNotEmpty) {
      _totalSeconds = _customDurations.first * 60;
      _remainingSeconds = _customDurations.first * 60;
      _customMinutes = _customDurations.first;
      final box = Hive.box(_statsBox);
      await box.put(_customKey, _customMinutes);
      await box.put(_durationsKey, _customDurations);
    } else {
      final box = Hive.box(_statsBox);
      await box.put(_durationsKey, _customDurations);
    }
    notifyListeners();
    return true;
  }

  Future<void> bindToTodo(String todoId, String todoName) async {
    _boundTodoId = todoId;
    _boundTodoName = todoName;
    notifyListeners();
  }

  void unbindTodo() {
    _boundTodoId = null;
    _boundTodoName = null;
    notifyListeners();
  }

  void start() {
    if (_isRunning && !_isPaused) return;
    if (_isPaused) { _isPaused = false; _startTimer(); _persistTimerState(); notifyListeners(); return; }
    _remainingSeconds = _totalSeconds;
    _isRunning = true;
    _isPaused = false;
    _startTime = DateTime.now();
    _startTimer();
    _persistTimerState();
    notifyListeners();
  }

  void pause() {
    if (!_isRunning || _isPaused) return;
    _isPaused = true;
    _timer?.cancel();
    _persistTimerState();
    notifyListeners();
  }

  void reset() {
    _timer?.cancel();
    _isRunning = false;
    _isPaused = false;
    _remainingSeconds = _totalSeconds;
    _persistTimerState();
    notifyListeners();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_remainingSeconds > 0) {
        _remainingSeconds--;
        _persistTimerState();
        notifyListeners();
      } else {
        _onComplete();
      }
    });
  }

  Future<void> _onComplete() async {
    _timer?.cancel();
    try {
      if (await Vibration.hasVibrator() == true) {
        Vibration.vibrate(duration: 500);
        await Future.delayed(const Duration(milliseconds: 300));
        Vibration.vibrate(duration: 500);
        await Future.delayed(const Duration(milliseconds: 300));
        Vibration.vibrate(duration: 500);
      }
    } catch (_) {}
    _isRunning = false;
    _isPaused = false;
    _startTime = null;
    final box = Hive.box(_statsBox);
    box.delete(_timerSecondsKey);
    box.delete(_timerRunningKey);
    box.delete(_timerPausedKey);
    box.delete(_timerTotalKey);
    final minutes = _totalSeconds ~/ 60;
    final now = DateTime.now();
    final record = PomodoroRecord(
      id: const Uuid().v4(), date: now,
      startTime: _startTime ?? now, endTime: now, minutes: minutes,
      categoryId: _boundTodoId,
    );
    _records.add(record);
    _startTime = null;

    await _repository.save(record);
    _todayCount++;
    await box.put(_todayKey, _todayCount);

    if (_boundTodoId != null) {
      final tasks = _todoService.getAll();
      final task = tasks.cast<TodoTask?>().firstWhere((t) => t?.id == _boundTodoId, orElse: () => null);
      if (task != null) {
        task.addFocusMinutes(minutes);
        await _todoService.save(task);
      }
    }
    notifyListeners();
  }

  @override
  void dispose() { _timer?.cancel(); super.dispose(); }
}