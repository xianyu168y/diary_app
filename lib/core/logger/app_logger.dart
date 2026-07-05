/// 统一日志工具。
///
/// 替代 `print()`，便于后续接入日志平台或切换日志级别。
/// 用法：
///   AppLogger.info('数据加载完成');
///   AppLogger.error('保存失败', e);
class AppLogger {
  static void info(String message) {
    // ignore: avoid_print
    print('[INFO] $message');
  }

  static void warn(String message) {
    // ignore: avoid_print
    print('[WARN] $message');
  }

  static void error(String message, [Object? exception]) {
    // ignore: avoid_print
    print('[ERROR] $message${exception != null ? ' | $exception' : ''}');
  }

  static void debug(String message) {
    // ignore: avoid_print
    print('[DEBUG] $message');
  }
}