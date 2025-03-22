// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => '要事计数';

  @override
  String get categoryManagement => '事件类别管理';

  @override
  String get eventManagement => '事件管理';

  @override
  String get addCategory => '添加类别';

  @override
  String get editCategory => '编辑类别';

  @override
  String get deleteCategory => '删除类别';

  @override
  String get categoryName => '类别名称';

  @override
  String get categoryPassword => '类别密码';

  @override
  String get categoryDescription => '类别描述';

  @override
  String get addEvent => '添加事件';

  @override
  String get editEvent => '编辑事件';

  @override
  String get deleteEvent => '删除事件';

  @override
  String get eventName => '事件名称';

  @override
  String get eventDescription => '描述（可选）';

  @override
  String clickCount(int count) {
    return '点击次数：$count';
  }

  @override
  String get loadMore => '加载更多';

  @override
  String get cancel => '取消';

  @override
  String get save => '保存';

  @override
  String get add => '添加';

  @override
  String get enterPassword => '请输入密码';

  @override
  String get wrongPassword => '密码错误';

  @override
  String get confirm => '确定';

  @override
  String eventLogs(String eventName) {
    return '$eventName - 点击记录';
  }

  @override
  String get hint => '提示';

  @override
  String get pleaseAddEvent => '请先添加事件';

  @override
  String get pleaseSelectEvent => '请先选择要计数的事件';

  @override
  String get selectEvent => '选择事件';

  @override
  String get increaseCount => '增加次数';

  @override
  String get switchEvent => '切换事件';

  @override
  String get eventTitle => '事件管理';

  @override
  String get searchEvent => '搜索事件';

  @override
  String get unknownCategory => '未知类别';

  @override
  String get selectCategory => '选择类别';

  @override
  String get setAsDefault => '设为默认';

  @override
  String get isDefault => '已是默认';

  @override
  String defaultSetSuccess(String eventName) {
    return '$eventName 已设为默认事件';
  }

  @override
  String defaultSetFailed(String error) {
    return '设置默认事件失败: $error';
  }

  @override
  String get edit => '编辑';

  @override
  String get delete => '删除';

  @override
  String get settings => '设置';

  @override
  String get darkMode => '深色模式';

  @override
  String get language => '语言';

  @override
  String get defaultLanguage => '系统默认';

  @override
  String get about => '关于';

  @override
  String get version => '版本';

  @override
  String get developer => '开发者';

  @override
  String get appDescription => '要事计数 是一个简单的应用，用于跟踪各种事件的点击次数。';

  @override
  String get statsReport => '统计报告';

  @override
  String get dailyStats => '每日统计';

  @override
  String get weeklyStats => '每周统计';

  @override
  String get monthlyStats => '每月统计';

  @override
  String get totalClicks => '总点击次数';

  @override
  String get noData => '暂无数据';

  @override
  String get week => '第周';

  @override
  String get dateRange => '日期范围';

  @override
  String get apply => '应用';

  @override
  String get optional => '可选';

  @override
  String get defaultCategory => '默认分类';

  @override
  String get defaultCategoryDescription => '默认分类';

  @override
  String get eventNameRequired => '事件名称不能为空';

  @override
  String get categoryRequired => '请选择一个类别';

  @override
  String get copyright => '© 2023-2024 要事计数';
}
