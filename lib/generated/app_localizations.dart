import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];

  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
  ];

  String get appTitle => _isZh ? '要事计数' : 'Count Matters';
  String get categoryTitle => _isZh ? '类别管理' : 'Categories';
  String get eventTitle => _isZh ? '事件' : 'Events';
  String get addCategory => _isZh ? '添加类别' : 'Add Category';
  String get editCategory => _isZh ? '编辑类别' : 'Edit Category';
  String get categoryName => _isZh ? '类别名称' : 'Category Name';
  String get categoryDescription => _isZh ? '类别描述' : 'Description';
  String get categoryPassword => _isZh ? '类别密码' : 'Password';
  String get cancel => _isZh ? '取消' : 'Cancel';
  String get add => _isZh ? '添加' : 'Add';
  String get save => _isZh ? '保存' : 'Save';
  String get enterPassword => _isZh ? '请输入密码' : 'Enter Password';
  String get wrongPassword => _isZh ? '密码错误' : 'Wrong Password';
  String get confirm => _isZh ? '确定' : 'Confirm';
  String get hint => _isZh ? '提示' : 'Hint';
  String get pleaseAddEvent => _isZh ? '请先添加事件' : 'Please add an event first';
  String get selectEvent => _isZh ? '选择事件' : 'Select Event';
  String get clickCount => _isZh ? '点击次数' : 'Click Count';
  String get categoryManagement => _isZh ? '事件类别管理' : 'Category Management';
  String get eventManagement => _isZh ? '事件管理' : 'Event Management';
  String get increaseCount => _isZh ? '增加次数' : 'Increase Count';
  String get pleaseSelectEvent =>
      _isZh ? '请先选择要计数的事件' : 'Please select an event';
  String get switchEvent => _isZh ? '切换事件' : 'Switch Event';
  String get searchCategory => _isZh ? '搜索类别' : 'Search Category';
  String get searchEvent => _isZh ? '搜索事件' : 'Search Event';
  String get addEvent => _isZh ? '添加事件' : 'Add Event';
  String get editEvent => _isZh ? '编辑事件' : 'Edit Event';
  String get deleteEvent => _isZh ? '删除事件' : 'Delete Event';
  String get deleteCategory => _isZh ? '删除类别' : 'Delete Category';
  String get delete => _isZh ? '删除' : 'Delete';
  String get categoryHasEventsWarning => _isZh
      ? '该类别下有事件，请先删除所有关联事件后再删除此类别。'
      : 'This category has associated events. Please delete all events in this category first.';
  String get eventName => _isZh ? '事件名称' : 'Event Name';
  String get selectCategory => _isZh ? '选择类别' : 'Select Category';
  String get unknownCategory => _isZh ? '未知类别' : 'Unknown Category';
  String get eventLogs => _isZh ? '事件日志' : 'Event Logs';
  String get eventDescription => _isZh ? '事件描述' : 'Event Description';
  String get loadMore => _isZh ? '加载更多' : 'Load More';

  // 报表相关
  String get statistics => _isZh ? '统计报表' : 'Statistics';
  String get dailyStats => _isZh ? '日统计' : 'Daily Stats';
  String get weeklyStats => _isZh ? '周统计' : 'Weekly Stats';
  String get monthlyStats => _isZh ? '月统计' : 'Monthly Stats';
  String get totalClicks => _isZh ? '总点击次数' : 'Total Clicks';
  String get dateRange => _isZh ? '日期范围' : 'Date Range';
  String get from => _isZh ? '从' : 'From';
  String get to => _isZh ? '至' : 'To';
  String get applyFilter => _isZh ? '应用筛选' : 'Apply Filter';
  String get resetFilter => _isZh ? '重置筛选' : 'Reset Filter';
  String get noData => _isZh ? '暂无数据' : 'No Data Available';
  String get exportData => _isZh ? '导出数据' : 'Export Data';
  String get week => _isZh ? '第%d周' : 'Week %d';
  String get clicksOnDate => _isZh ? '%s的点击次数: %d' : 'Clicks on %s: %d';
  String get eventCount => _isZh ? '事件数量' : 'Event Count';
  String get lastClick => _isZh ? '最后点击' : 'Last Click';

  // 设置相关
  String get settings => _isZh ? '设置' : 'Settings';
  String get darkMode => _isZh ? '深色模式' : 'Dark Mode';
  String get language => _isZh ? '语言' : 'Language';
  String get defaultLanguage => _isZh ? '系统默认' : 'System Default';

  // 关于页面
  String get about => _isZh ? '关于' : 'About';
  String get version => _isZh ? '版本' : 'Version';
  String get developer => _isZh ? '开发者' : 'Developer';
  String get appDescription => _isZh
      ? '要事计数 是一个简单的应用，用于跟踪各种事件的点击次数。'
      : 'Count Matters is a simple app to track click counts for various events.';

  // 辅助判断语言
  bool get _isZh => locale.languageCode == 'zh';

  String get optional => _isZh ? '可选' : 'Optional';

  // 添加事件时的错误提示
  String get eventNameRequired => _isZh ? '事件名称不能为空' : 'Event name is required';
  String get categoryRequired => _isZh ? '请选择一个类别' : 'Please select a category';

  // 版权信息
  String get copyright =>
      _isZh ? '© 2023-2024 要事计数' : '© 2023-2024 Count Matters';

  // 统计设置相关
  String get statsDisplayLimit => _isZh ? '统计记录显示数量' : 'Stats Display Limit';

  // 意见反馈相关
  String get feedback => _isZh ? '意见反馈' : 'Feedback';
  String get sendFeedback => _isZh ? '发送意见反馈' : 'Send Feedback';
  String get feedbackDescription => _isZh
      ? '您可以发送电子邮件给我们提供建议或报告问题'
      : 'You can send us an email with suggestions or to report issues';
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'zh'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) {
    debugPrint('🌍 Loading localization for ${locale.languageCode}');
    return SynchronousFuture<AppLocalizations>(AppLocalizations(locale));
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
