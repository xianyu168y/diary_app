import '../../../lib/repositories/pomodoro/pomodoro_repository.dart';
import '../../../lib/models/pomodoro_record.dart';

class FakePomodoroRepository implements PomodoroRepository {
  final List<PomodoroRecord> _storage = [];

  @override
  Future<void> init() async {}

  @override
  Future<List<PomodoroRecord>> getAll() async => List.of(_storage);

  @override
  Future<void> save(PomodoroRecord record) async {
    _storage.removeWhere((r) => r.id == record.id);
    _storage.add(record);
  }

  @override
  Future<void> delete(String id) async {
    _storage.removeWhere((r) => r.id == id);
  }
}