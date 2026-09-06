import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  bool _isSimpleMode = false;

  bool get isSimpleMode => _isSimpleMode;

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _isSimpleMode = prefs.getBool('isSimpleMode') ?? false;
    notifyListeners();
  }

  Future<void> toggleSimpleMode() async {
    _isSimpleMode = !_isSimpleMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isSimpleMode', _isSimpleMode);
    notifyListeners();
  }
}
