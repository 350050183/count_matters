import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart'
    show getApplicationDocumentsDirectory;
import 'package:sqflite/sqflite.dart';

class SettingsService extends ChangeNotifier {
  // 键名
  static const String _darkModeKey = 'dark_mode';
  static const String _languageKey = 'language';
  static const String _statsEntryLimitKey = 'stats_entry_limit';

  // 设置值
  bool _isDarkMode = false;
  String _language = 'system';
  int _statsEntryLimit = 6;

  // 数据库
  Database? _db;
  bool _isUsingInMemoryDatabase = false;

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
    await _initDatabase();
    await loadSettings();
  }

  // 初始化数据库
  Future<void> _initDatabase() async {
    try {
      // 直接使用内存数据库
      if (Platform.isIOS) {
        _isUsingInMemoryDatabase = true;
        debugPrint('iOS平台: 使用内存数据库');
        return;
      }

      String dbPath;
      if (Platform.isAndroid) {
        // 在Android上使用应用文件目录
        final documentsDirectory = await getApplicationDocumentsDirectory();
        dbPath = join(documentsDirectory.path, 'settings.db');
      } else {
        final path = await getDatabasesPath();
        dbPath = join(path, 'settings.db');
      }

      debugPrint('打开设置数据库: $dbPath');
      _db = await openDatabase(
        dbPath,
        version: 1,
        onCreate: (db, version) async {
          debugPrint('创建设置表...');
          await db.execute('''
            CREATE TABLE settings (
              key TEXT PRIMARY KEY,
              bool_value INTEGER,
              string_value TEXT,
              int_value INTEGER
            )
          ''');
        },
      );
      debugPrint('设置数据库初始化成功');
    } catch (e, stackTrace) {
      debugPrint('初始化设置数据库出错: $e');
      debugPrint('堆栈跟踪: $stackTrace');
      _isUsingInMemoryDatabase = true;
      debugPrint('切换到内存数据库');
    }
  }

  // 从数据库加载设置
  Future<void> loadSettings() async {
    try {
      if (_isUsingInMemoryDatabase) {
        // 使用默认值
        debugPrint('使用默认设置值');
        return;
      }

      if (_db == null) {
        debugPrint('数据库未初始化，使用默认设置');
        return;
      }

      // 查询深色模式设置
      final darkModeRow = await _db!.query(
        'settings',
        where: 'key = ?',
        whereArgs: [_darkModeKey],
      );
      if (darkModeRow.isNotEmpty && darkModeRow.first['bool_value'] != null) {
        _isDarkMode = darkModeRow.first['bool_value'] == 1;
      }

      // 查询语言设置
      final languageRow = await _db!.query(
        'settings',
        where: 'key = ?',
        whereArgs: [_languageKey],
      );
      if (languageRow.isNotEmpty && languageRow.first['string_value'] != null) {
        _language = languageRow.first['string_value'] as String;
      }

      // 查询统计记录限制
      final statsLimitRow = await _db!.query(
        'settings',
        where: 'key = ?',
        whereArgs: [_statsEntryLimitKey],
      );
      if (statsLimitRow.isNotEmpty &&
          statsLimitRow.first['int_value'] != null) {
        _statsEntryLimit = statsLimitRow.first['int_value'] as int;
      }

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

  // 保存设置到数据库
  Future<void> _saveSettings() async {
    try {
      if (_isUsingInMemoryDatabase) {
        debugPrint('内存数据库模式，设置将不会持久化');
        return;
      }

      if (_db == null) {
        debugPrint('数据库未初始化，无法保存设置');
        return;
      }

      // 保存深色模式设置
      await _db!.insert(
        'settings',
        {
          'key': _darkModeKey,
          'bool_value': _isDarkMode ? 1 : 0,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // 保存语言设置
      await _db!.insert(
        'settings',
        {
          'key': _languageKey,
          'string_value': _language,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // 保存统计记录限制
      await _db!.insert(
        'settings',
        {
          'key': _statsEntryLimitKey,
          'int_value': _statsEntryLimit,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

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

  @override
  void dispose() {
    _db?.close();
    super.dispose();
  }
}
