import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../../lib/models/pomodoro_record.dart';
import '../../lib/services/pomodoro_service.dart';

void main() {
  late Directory tmpDir;
  late PomodoroService service;

  setUpAll(() {
    tmpDir = Directory.systemTemp.createTempSync('hive_pomodoro_test_');
    Hive.init(tmpDir.path);
  });

  setUp(() async {
    final box = await Hive.openBox('pomodoro_stats');
    await box.clear();
    service = PomodoroService();
    await service.init();
  });

  tearDown(() {
    service.dispose();
  });

  tearDownAll(() async {
    await Hive.close();
    try { tmpDir.deleteSync(recursive: true); } catch (_) {}
  });

  group('PomodoroService', () {
    test('init 后记录为空、今日计数为 0', () {
      expect(service.records, isEmpty);
      expect(service.todayCount, 0);
    });

    test('start 后 isRunning 为 true', () {
      service.start();
      expect(service.isRunning, true);
      expect(service.isPaused, false);
    });

    test('pause 后 isPaused 为 true', () {
      service.start();
      service.pause();
      expect(service.isPaused, true);
      expect(service.isRunning, true);
    });

    test('reset 后 isRunning 为 false，剩余时间恢复', () {
      service.start();
      service.reset();
      expect(service.isRunning, false);
      expect(service.remainingSeconds, service.totalSeconds);
    });

    test('setDuration 修改计时时长', () {
      service.setDuration(30);
      expect(service.totalSeconds, 30 * 60);
      expect(service.remainingSeconds, 30 * 60);
    });

    test('setDuration 运行时无效', () {
      service.setDuration(15);
      service.start();
      service.setDuration(30);
      expect(service.totalSeconds, 15 * 60);
      service.pause();
    });

    test('addCustomDuration / removeCustomDuration', () async {
      await service.addCustomDuration(40);
      expect(service.allDurations, contains(40));

      await service.removeCustomDuration(40);
      expect(service.allDurations, isNot(contains(40)));
    });

    test('bindToTodo / unbindTodo', () async {
      await service.bindToTodo('todo-1', '学习 Flutter');
      expect(service.boundTodoId, 'todo-1');
      expect(service.boundTodoName, '学习 Flutter');
      expect(service.hasBoundTodo, true);

      service.unbindTodo();
      expect(service.hasBoundTodo, false);
      expect(service.boundTodoId, isNull);
    });

    test('formattedTime 格式正确', () {
      service.setDuration(25);
      expect(service.formattedTime, matches(RegExp(r'^\d{2}:\d{2}$')));
    });

    test('progress 在 0~1 之间', () {
      expect(service.progress, greaterThanOrEqualTo(0.0));
      expect(service.progress, lessThanOrEqualTo(1.0));
    });

    test('init 从 Hive 加载已有记录', () async {
      final box = Hive.box('pomodoro_stats');
      final record = PomodoroRecord(
        id: const Uuid().v4(), date: DateTime.now(),
        startTime: DateTime.now(), endTime: DateTime.now(), minutes: 25,
      );
      final existing = (box.get('records') as List?) ?? [];
      existing.add(record.toMap());
      await box.put('records', existing);

      await service.init();
      expect(service.records.any((r) => r.id == record.id), true);
    });

    test('今天计数归零后再 init 仍然为 0（无新记录）', () async {
      await service.init();
      expect(service.todayCount, 0);
    });
  });
}