import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class SettingsProvider extends ChangeNotifier {
  final Box _box = Hive.box('settings');

  bool get soundEnabled => _box.get('sound', defaultValue: true);
  bool get vibrationEnabled => _box.get('vibration', defaultValue: true);
  bool get darkMode => _box.get('darkMode', defaultValue: false);

  void toggleSound(bool value) {
    _box.put('sound', value);
    notifyListeners();
  }

  void toggleVibration(bool value) {
    _box.put('vibration', value);
    notifyListeners();
  }

  void toggleDarkMode(bool value) {
    _box.put('darkMode', value);
    notifyListeners();
  }
}