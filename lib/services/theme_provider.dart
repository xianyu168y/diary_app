import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _mode = ThemeMode.light;
  String? _password; // 4位数字密码，null = 未开启
  bool _locked = true; // 当前是否锁定中

  ThemeMode get mode => _mode;
  bool get isDark => _mode == ThemeMode.dark;
  bool get hasPassword => _password != null && _password!.isNotEmpty;
  bool get isLocked => _locked;
  String? get password => _password;

  void toggle() {
    _mode = _mode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  void setMode(ThemeMode mode) {
    _mode = mode;
    notifyListeners();
  }

  Future<void> loadPassword() async {
    final box = await Hive.openBox('settings');
    _password = box.get('diary_password');
    notifyListeners();
  }

  Future<void> setPassword(String pwd) async {
    _password = pwd;
    final box = await Hive.openBox('settings');
    await box.put('diary_password', pwd);
    _locked = true;
    notifyListeners();
  }

  Future<void> clearPassword() async {
    _password = null;
    _locked = true;
    final box = await Hive.openBox('settings');
    await box.delete('diary_password');
    notifyListeners();
  }

  bool checkPassword(String input) => _password == input;

  void unlock() { _locked = false; notifyListeners(); }
  void lock() { _locked = true; notifyListeners(); }
}