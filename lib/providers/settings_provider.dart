import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class SettingsProvider extends ChangeNotifier {
  static const _boxName = 'settings';

  late Box _box;

  bool get soundEnabled => _box.get('soundEnabled', defaultValue: true) as bool;
  bool get vibrationEnabled => _box.get('vibrationEnabled', defaultValue: true) as bool;
  bool get keepAwake => _box.get('keepAwake', defaultValue: true) as bool;
  bool get darkMode => _box.get('darkMode', defaultValue: true) as bool;
  int get warningSeconds => _box.get('warningSeconds', defaultValue: 60) as int;

  Future<void> init() async {
    _box = await Hive.openBox(_boxName);
  }

  Future<void> setSoundEnabled(bool value) async {
    await _box.put('soundEnabled', value);
    notifyListeners();
  }

  Future<void> setVibrationEnabled(bool value) async {
    await _box.put('vibrationEnabled', value);
    notifyListeners();
  }

  Future<void> setKeepAwake(bool value) async {
    await _box.put('keepAwake', value);
    notifyListeners();
  }

  Future<void> setDarkMode(bool value) async {
    await _box.put('darkMode', value);
    notifyListeners();
  }

  Future<void> setWarningSeconds(int value) async {
    await _box.put('warningSeconds', value);
    notifyListeners();
  }
}
