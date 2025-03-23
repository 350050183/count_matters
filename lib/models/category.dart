import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

class Category {
  final String id;
  String name;
  String? description;
  final DateTime createdAt;
  String? _passwordHash;
  String? _salt;

  static final _random = Random.secure();

  Category({
    required this.id,
    required this.name,
    this.description,
    String? password,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now() {
    if (password != null) {
      setPassword(password);
    }
  }

  bool get isPasswordProtected => _passwordHash != null;

  String _generateSalt() {
    var values = List<int>.generate(32, (i) => _random.nextInt(256));
    return base64Url.encode(values);
  }

  bool _isPasswordStrong(String password) {
    if (password.isEmpty) {
      return true;
    }
    return password.length >= 3;
  }

  void setPassword(String password) {
    if (password.isEmpty) {
      _passwordHash = null;
      _salt = null;
      return;
    }

    if (!_isPasswordStrong(password)) {
      throw ArgumentError('密码必须至少包含3个字符');
    }

    _salt = _generateSalt();
    final bytes = utf8.encode(password + _salt!);
    _passwordHash = sha256.convert(bytes).toString();
  }

  bool checkPassword(String password) {
    if (!isPasswordProtected) return true;
    if (_salt == null) return false;

    final bytes = utf8.encode(password + _salt!);
    final hash = sha256.convert(bytes).toString();
    return hash == _passwordHash;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'passwordHash': _passwordHash,
      'salt': _salt,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    debugPrint('开始解析Category数据: $map');

    final String id = map['id'] as String;
    final String name = map['name'] as String;

    // 处理 createdAt 字段
    DateTime createdAt;
    try {
      if (map['createdAt'] is String) {
        createdAt = DateTime.parse(map['createdAt'] as String);
      } else if (map['created_at'] is int) {
        createdAt =
            DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int);
      } else {
        createdAt = DateTime.now();
      }
    } catch (e) {
      debugPrint('解析时间错误: $e，使用当前时间代替');
      createdAt = DateTime.now();
    }

    final category = Category(
      id: id,
      name: name,
      description: map['description'] as String?,
      createdAt: createdAt,
    );

    debugPrint('已创建Category对象: id=$id, name=$name');

    // 处理密码相关字段
    try {
      if (map['passwordHash'] is String || map['password_hash'] is String) {
        category._passwordHash =
            map['passwordHash'] as String? ?? map['password_hash'] as String?;
        debugPrint('设置了密码哈希');
      }

      if (map['salt'] is String) {
        category._salt = map['salt'] as String?;
        debugPrint('设置了盐值');
      }
    } catch (e) {
      debugPrint('处理密码字段时出错: $e');
    }

    return category;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Category && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
