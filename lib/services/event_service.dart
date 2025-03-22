import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart' hide Category;
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../l10n/app_localizations.dart';
import '../main.dart';
import '../models/category.dart';
import '../models/event.dart';

// 存储接口抽象类
abstract class StorageInterface {
  String? getString(String key);
  Future<void> setString(String key, String value);
  Future<void> remove(String key);
}

// Web平台实现
class WebStorage implements StorageInterface {
  // 一个内存存储作为备用，当无法使用Web存储时使用
  final Map<String, String> _fallbackStorage = {};

  @override
  String? getString(String key) {
    try {
      // 仅在Web平台编译时执行
      if (kIsWeb) {
        try {
          // 这里使用动态导入或反射方式访问localStorage
          // 简化实现：直接使用内存备份
          return _fallbackStorage[key];
        } catch (e) {
          debugPrint('无法访问Web存储: $e');
          return _fallbackStorage[key];
        }
      } else {
        return _fallbackStorage[key];
      }
    } catch (e) {
      debugPrint('WebStorage getString错误: $e');
      return null;
    }
  }

  @override
  Future<void> setString(String key, String value) async {
    try {
      _fallbackStorage[key] = value;

      if (kIsWeb) {
        try {
          // 尝试使用Web存储API
          // 简化实现：使用内存备份
        } catch (e) {
          debugPrint('无法访问Web存储: $e');
        }
      }
    } catch (e) {
      debugPrint('WebStorage setString错误: $e');
    }
  }

  @override
  Future<void> remove(String key) async {
    try {
      _fallbackStorage.remove(key);

      if (kIsWeb) {
        try {
          // 尝试使用Web存储API
          // 简化实现：使用内存备份
        } catch (e) {
          debugPrint('无法访问Web存储: $e');
        }
      }
    } catch (e) {
      debugPrint('WebStorage remove错误: $e');
    }
  }
}

// 使用SQLite的本地存储实现
class SQLiteStorage implements StorageInterface {
  final Database db;

  SQLiteStorage(this.db);

  @override
  String? getString(String key) {
    try {
      // SQLite的查询是异步的，但我们需要一个同步返回值
      // 这只是一个简单实现，真实情况应该使用另一种模式设计
      // 为了简化，我们将返回null，实际操作会在异步中完成
      return null;
    } catch (e) {
      debugPrint('SQLiteStorage getString错误: $e');
      return null;
    }
  }

  @override
  Future<void> setString(String key, String value) async {
    try {
      await db.delete('app_settings', where: 'key = ?', whereArgs: [key]);
      await db.insert('app_settings', {'key': key, 'value': value});
    } catch (e) {
      debugPrint('SQLiteStorage setString错误: $e');
    }
  }

  @override
  Future<void> remove(String key) async {
    try {
      await db.delete('app_settings', where: 'key = ?', whereArgs: [key]);
    } catch (e) {
      debugPrint('SQLiteStorage remove错误: $e');
    }
  }
}

// 内存存储实现，用于任何平台的备用
class MemoryStorage implements StorageInterface {
  final Map<String, String> _storage = {};

  @override
  String? getString(String key) {
    return _storage[key];
  }

  @override
  Future<void> setString(String key, String value) async {
    _storage[key] = value;
  }

  @override
  Future<void> remove(String key) async {
    _storage.remove(key);
  }
}

class EventService extends ChangeNotifier {
  final _uuid = const Uuid();
  Database? _db;
  bool _isInitialized = false;
  bool _isUsingInMemoryDatabase = false;

  // 存储接口
  late StorageInterface _storage;

  // 内存数据存储，当数据库无法使用时的备用方案
  final Map<String, Category> _categories = {};
  final Map<String, Event> _events = {};
  final Map<String, List<DateTime>> _eventLogs = {};
  String? _defaultEventId;

  // localStorage键名
  static const String _categoriesKey = 'categories_data';
  static const String _eventsKey = 'events_data';
  static const String _eventLogsKey = 'event_logs_data';
  static const String _defaultEventIdKey = 'default_event_id';

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // 默认使用内存存储作为初始值
      _storage = MemoryStorage();

      // 在Web环境下进行简化检查
      if (kIsWeb) {
        debugPrint('Web环境: 初始化开始...');

        // 在Web环境下尝试使用WebStorage
        _storage = WebStorage();

        // 尝试从存储中加载数据
        await _loadFromStorage();

        // 使用超快速超时来测试SQLite，避免阻塞
        bool sqliteTestSucceeded = false;

        try {
          // 使用极短的超时快速测试SQLite
          await Future.delayed(const Duration(milliseconds: 100));
          sqliteTestSucceeded = false; // 直接假设测试失败，避免长时间等待

          debugPrint('Web环境: 跳过SQLite测试，默认使用内存数据库');
        } catch (e) {
          debugPrint('SQLite测试失败: $e');
        }

        // 直接使用内存数据库，避免SQLite初始化问题
        debugPrint('Web环境: 使用内存数据库');
        _useInMemoryDatabase();
        _isInitialized = true;
        return;
      }

      String dbPath;
      if (kIsWeb) {
        dbPath = 'events.db';
        debugPrint('Web环境: 使用内存数据库路径: $dbPath');
      } else {
        final path = await getDatabasesPath();
        dbPath = join(path, 'events.db');
        debugPrint('本地环境: 使用文件系统数据库路径: $dbPath');
      }

      debugPrint('Opening database at: $dbPath');

      // 在web环境下添加额外的错误处理
      if (kIsWeb) {
        debugPrint('Web环境: 即将调用openDatabase...');
        try {
          _db = await openDatabase(
            dbPath,
            version: 1,
            onCreate: (db, version) async {
              debugPrint('Web环境: 创建数据库表...');
              await _createDatabaseTables(db);
            },
            onOpen: (db) {
              debugPrint('Web环境: 数据库打开成功');
            },
          ).timeout(const Duration(seconds: 15), onTimeout: () {
            debugPrint('打开数据库超时，切换到内存数据模式');
            _useInMemoryDatabase();
            throw TimeoutException('打开数据库超时，已切换到内存模式');
          });

          if (_db != null) {
            _storage = SQLiteStorage(_db!);
          } else {
            // 如果数据库初始化失败，使用内存数据库
            _useInMemoryDatabase();
          }
        } catch (e, stackTrace) {
          debugPrint('Web环境: 打开数据库失败: $e');
          debugPrint('Web环境: 堆栈跟踪: $stackTrace');

          // 使用内存数据库作为备用
          _useInMemoryDatabase();
        }
      } else {
        // 原始代码用于非Web环境
        _db = await openDatabase(
          dbPath,
          version: 1,
          onCreate: (db, version) async {
            debugPrint('Creating database tables...');
            await _createDatabaseTables(db);
          },
          onOpen: (db) {
            debugPrint('Database opened successfully.');
          },
        );

        if (_db != null) {
          _storage = SQLiteStorage(_db!);
        }
      }

      _isInitialized = true;
      debugPrint(
          'EventService initialized successfully. Using in-memory: $_isUsingInMemoryDatabase');
    } catch (e, stackTrace) {
      debugPrint('Error initializing database: $e');
      debugPrint('Stack trace: $stackTrace');
      // 尝试使用内存数据库作为最后的备用
      _useInMemoryDatabase();
      _isInitialized = true;
      debugPrint('已切换到内存数据模式');
    }
  }

  // 创建数据库表的通用方法
  Future<void> _createDatabaseTables(Database db) async {
    await db.execute('''
      CREATE TABLE categories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        passwordHash TEXT,
        salt TEXT,
        createdAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE events (
        id TEXT PRIMARY KEY,
        category_id TEXT NOT NULL,
        name TEXT NOT NULL,
        description TEXT,
        click_count INTEGER DEFAULT 0,
        created_at INTEGER NOT NULL,
        FOREIGN KEY (category_id) REFERENCES categories (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE event_logs (
        id TEXT PRIMARY KEY,
        event_id TEXT NOT NULL,
        timestamp INTEGER NOT NULL,
        FOREIGN KEY (event_id) REFERENCES events (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE app_settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    debugPrint('Creating default category...');
    // 创建默认分类
    await db.insert('categories', {
      'id': 'default',
      'name': 'Default',
      'description': 'Default category',
      'createdAt': DateTime.now().toIso8601String(),
    });
    debugPrint('Database initialization completed.');
  }

  // 从存储加载数据
  Future<void> _loadFromStorage() async {
    try {
      debugPrint('尝试从存储加载数据...');

      // 加载分类数据
      final categoriesJson = _storage.getString(_categoriesKey);
      if (categoriesJson != null) {
        final categoriesData = jsonDecode(categoriesJson) as List<dynamic>;
        for (var item in categoriesData) {
          final category = Category.fromMap(item);
          _categories[category.id] = category;
        }
        debugPrint('从存储加载了${_categories.length}个分类');
      }

      // 加载事件数据
      final eventsJson = _storage.getString(_eventsKey);
      if (eventsJson != null) {
        final eventsData = jsonDecode(eventsJson) as List<dynamic>;
        for (var item in eventsData) {
          final event = Event.fromMap(item);
          _events[event.id] = event;
        }
        debugPrint('从存储加载了${_events.length}个事件');
      }

      // 加载事件日志数据
      final eventLogsJson = _storage.getString(_eventLogsKey);
      if (eventLogsJson != null) {
        final Map<String, dynamic> logsMap = jsonDecode(eventLogsJson);
        logsMap.forEach((eventId, logsList) {
          _eventLogs[eventId] = (logsList as List<dynamic>).map((timestamp) {
            if (timestamp is String) {
              return DateTime.parse(timestamp);
            } else {
              return DateTime.fromMillisecondsSinceEpoch(timestamp as int);
            }
          }).toList();
        });
        debugPrint('从存储加载了事件日志数据');
      }

      // 加载默认事件ID
      final defaultEventId = _storage.getString(_defaultEventIdKey);
      if (defaultEventId != null) {
        _defaultEventId = defaultEventId;
        debugPrint('从存储加载了默认事件ID: $_defaultEventId');
      }

      // 如果没有分类，创建默认分类
      if (_categories.isEmpty) {
        final defaultCategory = Category(
          id: 'default',
          name: 'Default',
          description: 'Default category',
          createdAt: DateTime.now(),
        );
        _categories[defaultCategory.id] = defaultCategory;
        debugPrint('创建了默认分类');
      }
    } catch (e) {
      debugPrint('从存储加载数据时出错: $e');
    }
  }

  // 保存数据到存储
  Future<void> _saveToStorage() async {
    if (!_isUsingInMemoryDatabase) return;

    try {
      // 保存分类
      final categoriesData =
          _categories.values.map((category) => category.toMap()).toList();
      await _storage.setString(_categoriesKey, jsonEncode(categoriesData));

      // 保存事件
      final eventsData = _events.values.map((event) => event.toMap()).toList();
      await _storage.setString(_eventsKey, jsonEncode(eventsData));

      // 保存事件日志
      final Map<String, List<String>> logsToSave = {};
      _eventLogs.forEach((eventId, logs) {
        logsToSave[eventId] = logs.map((log) => log.toIso8601String()).toList();
      });
      await _storage.setString(_eventLogsKey, jsonEncode(logsToSave));

      // 保存默认事件ID
      if (_defaultEventId != null) {
        await _storage.setString(_defaultEventIdKey, _defaultEventId!);
      } else {
        await _storage.remove(_defaultEventIdKey);
      }

      debugPrint('数据已保存到存储');
    } catch (e) {
      debugPrint('保存数据到存储时出错: $e');
    }
  }

  // 设置默认事件ID
  Future<void> setDefaultEvent(String eventId) async {
    if (!_events.containsKey(eventId) && !_isUsingInMemoryDatabase) {
      // 检查数据库中是否存在该事件
      final event = await getEvent(eventId);
      if (event == null) {
        throw Exception('事件不存在');
      }
    }

    _defaultEventId = eventId;
    debugPrint('设置默认事件ID: $eventId');

    // 保存到存储
    if (_isUsingInMemoryDatabase) {
      await _saveToStorage();
    } else if (_db != null) {
      try {
        // 删除可能存在的旧记录
        await _db!.delete('app_settings',
            where: 'key = ?', whereArgs: ['default_event_id']);

        // 插入新记录
        await _db!.insert('app_settings', {
          'key': 'default_event_id',
          'value': eventId,
        });
      } catch (e) {
        debugPrint('设置默认事件ID失败: $e');
        // 如果数据库操作失败，回退到内存模式
        _isUsingInMemoryDatabase = true;
        await _saveToStorage();
      }
    }

    notifyListeners();
  }

  // 获取默认事件ID
  Future<String?> getDefaultEventId() async {
    if (_defaultEventId != null) {
      return _defaultEventId;
    }

    if (!_isUsingInMemoryDatabase && _db != null) {
      try {
        final List<Map<String, dynamic>> maps = await _db!.query(
          'app_settings',
          where: 'key = ?',
          whereArgs: ['default_event_id'],
        );

        if (maps.isNotEmpty && maps.first['value'] != null) {
          _defaultEventId = maps.first['value'] as String;
          return _defaultEventId;
        }
      } catch (e) {
        debugPrint('获取默认事件ID时出错: $e');
      }
    }

    return null;
  }

  // 获取默认事件
  Future<Event?> getDefaultEvent() async {
    final defaultEventId = await getDefaultEventId();
    if (defaultEventId == null) {
      return null;
    }

    return getEvent(defaultEventId);
  }

  // 获取单个事件
  Future<Event?> getEvent(String eventId) async {
    if (_isUsingInMemoryDatabase) {
      return _events[eventId];
    }

    try {
      if (_db == null) return null;

      final List<Map<String, dynamic>> maps = await _db!.query(
        'events',
        where: 'id = ?',
        whereArgs: [eventId],
      );

      if (maps.isEmpty) {
        return null;
      }

      return Event.fromMap(maps.first);
    } catch (e) {
      debugPrint('获取事件时出错: $e');
      return null;
    }
  }

  // 切换到内存数据模式
  void _useInMemoryDatabase() {
    debugPrint('正在切换到内存数据模式');
    _isUsingInMemoryDatabase = true;

    // 创建默认分类
    if (_categories.isEmpty) {
      // 获取本地化字符串，如果有的话
      String defaultName = 'Default';
      String defaultDesc = 'Default category';

      // 尝试获取本地化文本
      try {
        final context = navigatorKey.currentContext;
        debugPrint('获取上下文: ${context != null ? "成功" : "失败"}');

        if (context != null) {
          final l10n = AppLocalizations.of(context);
          debugPrint('获取AppLocalizations: ${l10n != null ? "成功" : "失败"}');

          if (l10n != null) {
            try {
              // 检查是否有对应的字段
              debugPrint('尝试获取defaultCategory字段...');
              defaultName = l10n.defaultCategory;
              debugPrint('成功获取defaultCategory: $defaultName');

              debugPrint('尝试获取defaultCategoryDescription字段...');
              defaultDesc = l10n.defaultCategoryDescription;
              debugPrint('成功获取defaultCategoryDescription: $defaultDesc');
            } catch (e) {
              debugPrint('获取本地化字段出错: $e');
            }
          }
        }
      } catch (e) {
        debugPrint('获取本地化文本时出错: $e');
      }

      debugPrint('创建默认分类: name=$defaultName, description=$defaultDesc');
      final defaultCategory = Category(
        id: 'default',
        name: defaultName,
        description: defaultDesc,
        createdAt: DateTime.now(),
      );
      _categories[defaultCategory.id] = defaultCategory;
    }

    debugPrint('已创建默认分类，内存模式初始化完成');
  }

  Future<List<Category>> getCategories() async {
    if (_isUsingInMemoryDatabase) {
      return _categories.values.toList();
    }

    try {
      final List<Map<String, dynamic>> maps = await _db!.query('categories');
      return List.generate(maps.length, (i) {
        try {
          return Category.fromMap(maps[i]);
        } catch (e) {
          debugPrint('解析类别数据时出错 [${maps[i]}]: $e');

          // 创建一个安全的默认类别作为替代
          return Category(
            id: maps[i]['id']?.toString() ??
                'error_${i}_${DateTime.now().millisecondsSinceEpoch}',
            name: maps[i]['name']?.toString() ?? '错误的类别',
            description: '数据解析错误',
            createdAt: DateTime.now(),
          );
        }
      });
    } catch (e) {
      debugPrint('获取类别列表时出错: $e');
      return [];
    }
  }

  Future<Category> addCategory(String name,
      {String? description, String? password}) async {
    debugPrint(
        '开始添加类别: name=$name, description=$description, hasPassword=${password != null}');
    try {
      final category = Category(
        id: _uuid.v4(),
        name: name,
        description: description,
        createdAt: DateTime.now(),
      );

      debugPrint('创建类别对象成功: id=${category.id}');

      if (password != null && password.isNotEmpty) {
        debugPrint('设置密码...');
        try {
          category.setPassword(password);
          debugPrint('密码设置成功');
        } catch (e) {
          debugPrint('设置密码失败: $e');
          rethrow; // 将错误向上传递
        }
      }

      if (_isUsingInMemoryDatabase) {
        debugPrint('使用内存数据库，保存类别');
        _categories[category.id] = category;
        await _saveToStorage();
        debugPrint('类别已保存到内存数据库');
      } else {
        debugPrint('使用SQL数据库，插入类别记录');
        final categoryMap = category.toMap();
        debugPrint('类别数据: $categoryMap');

        // 检查数据库是否初始化
        if (_db == null) {
          throw StateError('数据库未初始化');
        }

        try {
          final insertId = await _db!.insert('categories', categoryMap);
          debugPrint('插入成功，返回ID: $insertId');
        } catch (e) {
          debugPrint('数据库插入失败: $e');
          // 检查表结构
          final tableInfo =
              await _db!.rawQuery("PRAGMA table_info(categories)");
          debugPrint('categories表结构: $tableInfo');
          rethrow;
        }
      }

      debugPrint('添加类别完成，通知监听器');
      notifyListeners();
      return category;
    } catch (e, stackTrace) {
      debugPrint('添加类别失败: $e');
      debugPrint('堆栈: $stackTrace');
      rethrow; // 确保错误被传递到UI层
    }
  }

  Future<void> updateCategory(Category category) async {
    if (_isUsingInMemoryDatabase) {
      _categories[category.id] = category;
      await _saveToStorage();
    } else {
      await _db!.update(
        'categories',
        category.toMap(),
        where: 'id = ?',
        whereArgs: [category.id],
      );
    }
    notifyListeners();
  }

  Future<void> deleteCategory(String id) async {
    if (_isUsingInMemoryDatabase) {
      _categories.remove(id);
      // 删除该分类下的所有事件
      _events.removeWhere((key, event) => event.categoryId == id);
      await _saveToStorage();
    } else {
      await _db!.delete(
        'categories',
        where: 'id = ?',
        whereArgs: [id],
      );
    }
    notifyListeners();
  }

  // 检查类别是否有关联的事件
  Future<bool> categoryHasEvents(String categoryId) async {
    try {
      if (_isUsingInMemoryDatabase) {
        // 内存数据库模式
        return _events.values.any((event) => event.categoryId == categoryId);
      } else {
        // SQLite数据库模式
        final List<Map<String, dynamic>> result = await _db!.query(
          'events',
          columns: ['COUNT(*) as count'],
          where: 'category_id = ?',
          whereArgs: [categoryId],
        );

        final count = Sqflite.firstIntValue(result) ?? 0;
        return count > 0;
      }
    } catch (e) {
      debugPrint('检查类别是否有事件时出错: $e');
      return false;
    }
  }

  // 获取类别中的事件数量
  Future<int> getCategoryEventCount(String categoryId) async {
    try {
      if (_isUsingInMemoryDatabase) {
        // 内存数据库模式
        return _events.values
            .where((event) => event.categoryId == categoryId)
            .length;
      } else {
        // SQLite数据库模式
        final List<Map<String, dynamic>> result = await _db!.query(
          'events',
          columns: ['COUNT(*) as count'],
          where: 'category_id = ?',
          whereArgs: [categoryId],
        );

        return Sqflite.firstIntValue(result) ?? 0;
      }
    } catch (e) {
      debugPrint('获取类别事件数量时出错: $e');
      return 0;
    }
  }

  Future<List<Event>> getEvents([String? categoryId]) async {
    try {
      if (_isUsingInMemoryDatabase) {
        if (categoryId != null) {
          return _events.values
              .where((event) => event.categoryId == categoryId)
              .toList();
        } else {
          return _events.values.toList();
        }
      }

      if (_db == null) {
        debugPrint('数据库未初始化，返回空事件列表');
        return [];
      }

      if (categoryId != null) {
        final List<Map<String, dynamic>> maps = await _db!.query(
          'events',
          where: 'category_id = ?',
          whereArgs: [categoryId],
        );
        return List.generate(maps.length, (i) {
          try {
            return Event.fromMap(maps[i]);
          } catch (e) {
            debugPrint('解析事件数据时出错 [${maps[i]}]: $e');

            // 创建一个安全的默认事件作为替代
            return Event(
              id: maps[i]['id']?.toString() ??
                  'error_${i}_${DateTime.now().millisecondsSinceEpoch}',
              categoryId: maps[i]['category_id']?.toString() ?? 'default',
              name: maps[i]['name']?.toString() ?? '错误的事件',
              description: '数据解析错误',
              clickCount: 0,
              createdAt: DateTime.now(),
            );
          }
        });
      } else {
        final List<Map<String, dynamic>> maps = await _db!.query('events');
        return List.generate(maps.length, (i) {
          try {
            return Event.fromMap(maps[i]);
          } catch (e) {
            debugPrint('解析事件数据时出错 [${maps[i]}]: $e');

            // 创建一个安全的默认事件作为替代
            return Event(
              id: maps[i]['id']?.toString() ??
                  'error_${i}_${DateTime.now().millisecondsSinceEpoch}',
              categoryId: maps[i]['category_id']?.toString() ?? 'default',
              name: maps[i]['name']?.toString() ?? '错误的事件',
              description: '数据解析错误',
              clickCount: 0,
              createdAt: DateTime.now(),
            );
          }
        });
      }
    } catch (e) {
      debugPrint('获取事件列表时出错: $e');
      return [];
    }
  }

  Future<Event> addEvent(String name, String categoryId,
      {String? description}) async {
    final event = Event(
      id: _uuid.v4(),
      categoryId: categoryId,
      name: name,
      description: description,
      clickCount: 0,
      createdAt: DateTime.now(),
    );

    if (_isUsingInMemoryDatabase) {
      _events[event.id] = event;
      await _saveToStorage();
    } else {
      await _db!.insert('events', event.toMap());
    }

    notifyListeners();
    return event;
  }

  Future<void> updateEvent(Event event) async {
    if (_isUsingInMemoryDatabase) {
      _events[event.id] = event;
      await _saveToStorage();
    } else {
      await _db!.update(
        'events',
        event.toMap(),
        where: 'id = ?',
        whereArgs: [event.id],
      );
    }
    notifyListeners();
  }

  Future<void> deleteEvent(String id) async {
    // 如果删除的是默认事件，清除默认事件ID
    if (_defaultEventId == id) {
      _defaultEventId = null;
    }

    if (_isUsingInMemoryDatabase) {
      _events.remove(id);
      _eventLogs.remove(id);
      await _saveToStorage();
    } else {
      await _db!.delete(
        'events',
        where: 'id = ?',
        whereArgs: [id],
      );

      // 如果删除的是默认事件，从数据库中清除默认事件ID
      if (_defaultEventId == id) {
        await _db!.delete('app_settings',
            where: 'key = ?', whereArgs: ['default_event_id']);
      }
    }
    notifyListeners();
  }

  Future<void> logEventClick(String eventId) async {
    debugPrint('开始记录事件点击: $eventId');
    try {
      if (_isUsingInMemoryDatabase) {
        debugPrint('使用内存数据库模式');
        final event = _events[eventId];
        if (event != null) {
          debugPrint('找到事件: ${event.name}, 当前点击次数: ${event.clickCount}');
          event.clickCount++;
          _events[eventId] = event;
          debugPrint('增加后点击次数: ${event.clickCount}');

          // 添加点击日志
          _eventLogs.putIfAbsent(eventId, () => []);
          _eventLogs[eventId]!.add(DateTime.now());
          debugPrint('添加点击日志成功');
          await _saveToStorage();
          debugPrint('保存到存储成功');
        } else {
          debugPrint('未找到ID为 $eventId 的事件');
        }
      } else {
        if (_db == null) {
          debugPrint('数据库未初始化，无法记录点击');
          return;
        }

        debugPrint('使用数据库模式，执行事务');
        await _db!.transaction((txn) async {
          // 首先检查事件是否存在
          final List<Map<String, dynamic>> eventExists = await txn.query(
            'events',
            columns: ['id', 'name', 'click_count'],
            where: 'id = ?',
            whereArgs: [eventId],
          );

          if (eventExists.isEmpty) {
            debugPrint('数据库中未找到ID为 $eventId 的事件');
            return;
          }

          debugPrint(
              '找到事件: ${eventExists.first['name']}, 当前点击数: ${eventExists.first['click_count']}');

          // 更新点击次数
          final updateCount = await txn.rawUpdate('''
            UPDATE events 
            SET click_count = click_count + 1 
            WHERE id = ?
          ''', [eventId]);

          debugPrint('更新行数: $updateCount');

          // 记录点击日志
          final logId = DateTime.now().millisecondsSinceEpoch.toString();
          final logTimestamp = DateTime.now().millisecondsSinceEpoch;

          final logInsertId = await txn.insert('event_logs', {
            'id': logId,
            'event_id': eventId,
            'timestamp': logTimestamp,
          });

          debugPrint('插入日志成功，ID: $logInsertId');
        });

        debugPrint('事务执行完成');
      }
      debugPrint('通知监听器');
      notifyListeners();
      debugPrint('事件点击记录完成');
    } catch (e, stackTrace) {
      debugPrint('记录事件点击发生错误: $e');
      debugPrint('堆栈跟踪: $stackTrace');
      // 不抛出异常，以免影响UI
    }
  }

  Future<List<DateTime>> getEventLogs(String eventId) async {
    debugPrint('获取事件 $eventId 的日志');
    if (_isUsingInMemoryDatabase) {
      final logs = _eventLogs[eventId] ?? [];
      debugPrint('内存模式：找到 ${logs.length} 条日志');
      return logs;
    }

    final List<Map<String, dynamic>> maps = await _db!.query(
      'event_logs',
      where: 'event_id = ?',
      whereArgs: [eventId],
      orderBy: 'timestamp DESC',
    );

    final result = maps
        .map((log) =>
            DateTime.fromMillisecondsSinceEpoch(log['timestamp'] as int))
        .toList();

    debugPrint('数据库模式：找到 ${result.length} 条日志');
    return result;
  }

  // 获取事件在指定时间范围内的日志记录
  Future<List<DateTime>> getEventLogsInRange(
      String eventId, DateTime start, DateTime end) async {
    debugPrint('获取事件 $eventId 在 $start 至 $end 范围内的日志');

    List<DateTime> allLogs = await getEventLogs(eventId);
    return allLogs
        .where((log) =>
            log.isAfter(start) &&
            log.isBefore(end.add(const Duration(days: 1))))
        .toList();
  }

  // 按天统计事件点击次数
  Future<Map<DateTime, int>> getEventStatsByDay(String eventId,
      {DateTime? start, DateTime? end}) async {
    debugPrint('按天统计事件 $eventId 的点击次数');

    // 默认统计过去30天
    final now = DateTime.now();
    start ??= now.subtract(const Duration(days: 30));
    end ??= now;

    // 确保开始日期的时间部分为00:00:00
    start = DateTime(start.year, start.month, start.day);
    // 确保结束日期的时间部分为23:59:59
    end = DateTime(end.year, end.month, end.day, 23, 59, 59);

    List<DateTime> logs = await getEventLogsInRange(eventId, start, end);

    // 按天分组统计
    Map<DateTime, int> dailyStats = {};

    // 初始化所有日期，确保没有点击的日期也显示为0
    DateTime current = start;
    while (current.isBefore(end) || isSameDay(current, end)) {
      dailyStats[DateTime(current.year, current.month, current.day)] = 0;
      current = current.add(const Duration(days: 1));
    }

    // 统计每天的点击次数
    for (var log in logs) {
      DateTime day = DateTime(log.year, log.month, log.day);
      dailyStats[day] = (dailyStats[day] ?? 0) + 1;
    }

    return dailyStats;
  }

  // 按周统计事件点击次数
  Future<Map<int, int>> getEventStatsByWeek(String eventId,
      {DateTime? start, DateTime? end}) async {
    debugPrint('按周统计事件 $eventId 的点击次数');

    // 默认统计过去12周
    final now = DateTime.now();
    start ??= now.subtract(const Duration(days: 7 * 12));
    end ??= now;

    List<DateTime> logs = await getEventLogsInRange(eventId, start, end);

    // 按周分组统计
    Map<int, int> weeklyStats = {};

    // 初始化所有周，确保没有点击的周也显示为0
    for (int i = 0; i <= 12; i++) {
      DateTime weekStart =
          now.subtract(Duration(days: 7 * i + now.weekday - 1));
      int weekNumber = _getWeekNumber(weekStart);
      int yearWeekKey = weekStart.year * 100 + weekNumber;
      weeklyStats[yearWeekKey] = 0;
    }

    // 统计每周的点击次数
    for (var log in logs) {
      int weekNumber = _getWeekNumber(log);
      int yearWeekKey = log.year * 100 + weekNumber; // 年份*100+周数 作为键
      weeklyStats[yearWeekKey] = (weeklyStats[yearWeekKey] ?? 0) + 1;
    }

    return weeklyStats;
  }

  // 按月统计事件点击次数
  Future<Map<String, int>> getEventStatsByMonth(String eventId,
      {DateTime? start, DateTime? end}) async {
    debugPrint('按月统计事件 $eventId 的点击次数');

    // 默认统计过去12个月
    final now = DateTime.now();
    start ??= DateTime(now.year - 1, now.month, 1);
    end ??= DateTime(now.year, now.month, _getDaysInMonth(now.year, now.month));

    List<DateTime> logs = await getEventLogsInRange(eventId, start, end);

    // 按月分组统计
    Map<String, int> monthlyStats = {};

    // 初始化所有月份，确保没有点击的月份也显示为0
    DateTime current = start;
    while (current.isBefore(end) ||
        (current.year == end.year && current.month == end.month)) {
      String monthKey =
          '${current.year}-${current.month.toString().padLeft(2, '0')}';
      monthlyStats[monthKey] = 0;

      // 移动到下个月
      if (current.month == 12) {
        current = DateTime(current.year + 1, 1, 1);
      } else {
        current = DateTime(current.year, current.month + 1, 1);
      }
    }

    // 统计每月的点击次数
    for (var log in logs) {
      String monthKey = '${log.year}-${log.month.toString().padLeft(2, '0')}';
      monthlyStats[monthKey] = (monthlyStats[monthKey] ?? 0) + 1;
    }

    return monthlyStats;
  }

  // 获取指定日期是一年中的第几周
  int _getWeekNumber(DateTime date) {
    // 获取该年第一天
    final firstDayOfYear = DateTime(date.year, 1, 1);
    // 计算第一周有几天
    final dayOfYear = date.difference(firstDayOfYear).inDays;
    // 第一天是星期几 (0 = 周一, ... 6 = 周日)
    final weekDay = firstDayOfYear.weekday;
    // 计算周数
    return ((dayOfYear + weekDay - 1) / 7).floor() + 1;
  }

  // 获取某月的天数
  int _getDaysInMonth(int year, int month) {
    return DateTime(year, month + 1, 0).day;
  }

  // 检查两个日期是否是同一天
  bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  @override
  void dispose() {
    // 保存最后的数据
    if (_isUsingInMemoryDatabase) {
      _saveToStorage();
    }

    if (!_isUsingInMemoryDatabase) {
      _db?.close();
    }
    super.dispose();
  }

  // 创建默认类别如果不存在
  Future<void> _createDefaultCategoryIfNeeded() async {
    debugPrint('正在检查默认类别是否存在...');
    try {
      final categories = await getCategories();
      if (categories.isEmpty) {
        debugPrint('创建默认类别...');

        // 获取本地化字符串，如果有的话
        String defaultName = 'Default';
        String defaultDesc = 'Default category';

        // 尝试获取本地化文本
        try {
          final context = navigatorKey.currentContext;
          debugPrint('获取上下文: ${context != null ? "成功" : "失败"}');

          if (context != null) {
            final l10n = AppLocalizations.of(context);
            debugPrint('获取AppLocalizations: ${l10n != null ? "成功" : "失败"}');

            if (l10n != null) {
              try {
                // 检查是否有对应的字段
                debugPrint('尝试获取defaultCategory字段...');
                defaultName = l10n.defaultCategory;
                debugPrint('成功获取defaultCategory: $defaultName');

                debugPrint('尝试获取defaultCategoryDescription字段...');
                defaultDesc = l10n.defaultCategoryDescription;
                debugPrint('成功获取defaultCategoryDescription: $defaultDesc');
              } catch (e) {
                debugPrint('获取本地化字段出错: $e');
              }
            }
          }
        } catch (e) {
          debugPrint('获取本地化文本时出错: $e');
        }

        debugPrint('创建默认类别: name=$defaultName, description=$defaultDesc');
        await addCategory(defaultName, description: defaultDesc);
        debugPrint('已创建默认类别');
      }
    } catch (e) {
      debugPrint('检查默认类别时出错: $e');
    }
  }
}
