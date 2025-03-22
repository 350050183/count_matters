import 'package:flutter/foundation.dart';

// 用于管理类别访问权限的服务
class AuthService extends ChangeNotifier {
  // 已验证的类别ID及其验证时间
  final Map<String, DateTime> _verifiedCategories = {};

  // 检查某个类别是否已经验证过，如果验证过且是今天验证的，则不需要再次验证
  bool isCategoryVerified(String categoryId) {
    if (!_verifiedCategories.containsKey(categoryId)) {
      return false;
    }

    final DateTime verifiedTime = _verifiedCategories[categoryId]!;
    final DateTime now = DateTime.now();

    // 检查验证时间是否是今天
    return verifiedTime.year == now.year &&
        verifiedTime.month == now.month &&
        verifiedTime.day == now.day;
  }

  // 标记某个类别已经通过验证
  void markCategoryAsVerified(String categoryId) {
    _verifiedCategories[categoryId] = DateTime.now();
    notifyListeners();
  }

  // 清除所有验证状态
  void clearAllVerifications() {
    _verifiedCategories.clear();
    notifyListeners();
  }

  // 清除特定类别的验证状态
  void clearCategoryVerification(String categoryId) {
    _verifiedCategories.remove(categoryId);
    notifyListeners();
  }
}
