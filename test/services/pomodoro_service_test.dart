import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../../lib/models/pomodoro_record.dart';
import '../../lib/services/pomodoro_service.dart';

void main() {
  late Directory tmpDir;

  setUpAll(() {
    tmpDir = Directory.systemTemp.createTempSync('hive_pomodoro_test_');
    Hive.init(tmpDir.path);
  });

  setUp(() async {
    final box = await Hive.openBox('pomodoro_stats');
    await box.clear();
    final s = PomodoroService();
    // 不 dispose 单例，只清空状态和定时器
    s.reset();
    await s.init();
  });

  tearDown(() {
    // 只取消定时器，不 dispose ChangeNotifier
    PomodoroService().reset();
  });

  tearDownAll(() async {
    await Hive.close();
    try { tmpDir.deleteSync(recursive: true); } catch (_) {}
  });

  group('PomodoroService', () {
    test('init 后记录为空、今日计数为 0', () {
      final s = PomodoroService();
      expect(s.records, isEmpty);
      expect(s.todayCount, 0);
    });

    test('start 后 isRunning 为 true', () {
      final s = PomodoroService();
      s.start();
      expect(s.isRunning, true);
      expect(s.isPaused, false);
    });

    test('pause 后 isPaused 为 true', () {
      final s = PomodoroService();
      s.start();
      s.pause();
      expect(s.isPaused, true);
      expect(s.isRunning, true);
    });

    test('reset 后 isRunning 为 false，剩余时间恢复', () {
      final s = PomodoroService();
      s.start();
      s.reset();
      expect(s.isRunning, false);
      expect(s.remainingSeconds, s.totalSeconds);
    });

    test('setDuration 修改计时时长', () {
      final s = PomodoroService();
      s.setDuration(30);
      expect(s.totalSeconds, 30 * 60);
      expect(s.remainingSeconds, 30 * 60);
    });

    test('setDuration 运行时无效', () {
      final s = PomodoroService();
      s.setDuration(15);
      s.start();
      s.setDuration(30);
      expect(s.totalSeconds, 15 * 60);
      s.pause();
    });

    test('addCustomDuration / removeCustomDuration', () async {
      final s = PomodoroService();
      await s.addCustomDuration(40);
      expect(s.allDurations, contains(40));

      await s.removeCustomDuration(40);
      expect(s.allDurations, isNot(contains(40)));
    });

    test('bindToTodo / unbindTodo', () async {
      final s = PomodoroService();
      await s.bindToTodo('todo-1', '学习 Flutter');
      expect(s.boundTodoId, 'todo-1');
      expect(s.boundTodoName, '学习 Flutter');
      expect(s.hasBoundTodo, true);

      s.unbindTodo();
      expect(s.hasBoundTodo, false);
      expect(s.boundTodoId, isNull);
    });

    test('formattedTime 格式正确', () {
      final s = PomodoroService();
      s.setDuration(25);
      expect(s.formattedTime, matches(RegExp(r'^\d{2}:\d{2}$')));
    });

    test('progress 在 0~1 之间', () {
      final s = PomodoroService();
      expect(s.progress, greaterThanOrEqualTo(0.0));
      expect(s.progress, lessThanOrEqualTo(1.0));
    });

    test('init 从 Hive 加载已有记录', () async {
      // 直接写一条记录到 Hive
      final box = Hive.box('pomodoro_stats');
      final record = PomodoroRecord(
        id: const Uuid().v4(), date: DateTime.now(),
        startTime: DateTime.now(), endTime: DateTime.now(), minutes: 25,
      );
      final existing = (box.get('records') as List?) ?? [];
      existing.add(record.toMap());
      await box.put('records', existing);

      // 重新 init 加载
      final s = PomodoroService();
      await s.init();
      expect(s.records.any((r) => r.id == record.id), true);
    });

    test('今天计数归零后再 init 仍然为 0（无新记录）', () async {
      final s = PomodoroService();
      await s.init();
      expect(s.todayCount, 0);
    });
  });
}