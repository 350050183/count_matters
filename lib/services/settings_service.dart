import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService extends ChangeNotifier {
  // 键名
  static const String _darkModeKey = 'dark_mode';
  static const String _languageKey = 'language';
  static const String _statsEntryLimitKey = 'stats_entry_limit';

  // 设置值
  bool _isDarkMode = false;
  String _language = 'system';
  int _statsEntryLimit = 6;

  // 获取器
  bool get isDarkMode => _isDarkMode;
  String get language => _language;
  int get statsEntryLimit => _statsEntryLimit;

  // 单例实例
  static final SettingsService _instance = SettingsService._internal();

  // 工厂构造函数
  factory SettingsService() => _instance;

  // 内部构造函数
  SettingsService._internal();

  // 初始化设置
  Future<void> init() async {
    await loadSettings();
  }

  // 从SharedPreferences加载设置
  Future<void> loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isDarkMode = prefs.getBool(_darkModeKey) ?? false;
      _language = prefs.getString(_languageKey) ?? 'system';
      _statsEntryLimit = prefs.getInt(_statsEntryLimitKey) ?? 6;
      debugPrint(
          '设置已加载: 深色模式=$_isDarkMode, 语言=$_language, 统计记录限制=$_statsEntryLimit');
      notifyListeners();
    } catch (e) {
      debugPrint('加载设置时出错: $e');
    }
  }

  // 设置深色模式
  Future<void> setDarkMode(bool value) async {
    if (_isDarkMode == value) return;

    _isDarkMode = value;
    debugPrint('更新深色模式: $_isDarkMode');
    await _saveSettings();
    notifyListeners();
  }

  // 设置语言
  Future<void> setLanguage(String value) async {
    if (_language == value) return;

    _language = value;
    debugPrint('更新语言: $_language');
    await _saveSettings();
    notifyListeners();
  }

  // 设置统计记录限制
  Future<void> setStatsEntryLimit(int value) async {
    if (_statsEntryLimit == value) return;

    _statsEntryLimit = value;
    debugPrint('更新统计记录限制: $_statsEntryLimit');
    await _saveSettings();
    notifyListeners();
  }

  // 保存设置到SharedPreferences
  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_darkModeKey, _isDarkMode);
      await prefs.setString(_languageKey, _language);
      await prefs.setInt(_statsEntryLimitKey, _statsEntryLimit);
      debugPrint(
          '设置已保存: 深色模式=$_isDarkMode, 语言=$_language, 统计记录限制=$_statsEntryLimit');
    } catch (e) {
      debugPrint('保存设置时出错: $e');
    }
  }

  // 获取ThemeMode
  ThemeMode getThemeMode() {
    return _isDarkMode ? ThemeMode.dark : ThemeMode.light;
  }

  // 获取Locale
  Locale? getLocale() {
    debugPrint('获取语言区域设置，当前语言: $_language');
    // 只有在明确选择使用系统设置时才返回null
    if (_language == 'system') {
      debugPrint('返回null，使用系统语言');
      return null;
    }

    // 为明确选择的语言创建Locale
    final locale = Locale(_language);
    debugPrint('返回用户设置的语言区域: ${locale.languageCode}');
    return locale;
  }
}
