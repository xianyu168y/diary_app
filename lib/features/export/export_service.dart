import 'dart:convert';
import '../../repositories/todo/todo_repository.dart';

/// 数据导出服务。
///
/// 只依赖 [TodoRepository] 抽象，完全不感知 Hive / 文件系统。
/// 如果这里写得舒服 → Repository 抽对了。
class ExportService {
  final TodoRepository todoRepository;

  ExportService({required this.todoRepository});

  /// 将所有待办导出为 JSON 字符串
  Future<String> exportTodos() async {
    final todos = await todoRepository.getAll();
    return jsonEncode(todos.map((t) => t.toMap()).toList());
  }
}