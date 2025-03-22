// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Counter';

  @override
  String get categoryManagement => 'Category Management';

  @override
  String get eventManagement => 'Event Management';

  @override
  String get addCategory => 'Add Category';

  @override
  String get editCategory => 'Edit Category';

  @override
  String get deleteCategory => 'Delete Category';

  @override
  String get categoryName => 'Category Name';

  @override
  String get categoryPassword => 'Category Password';

  @override
  String get categoryDescription => 'Category Description';

  @override
  String get addEvent => 'Add Event';

  @override
  String get editEvent => 'Edit Event';

  @override
  String get deleteEvent => 'Delete Event';

  @override
  String get eventName => 'Event Name';

  @override
  String get eventDescription => 'Description (Optional)';

  @override
  String clickCount(int count) {
    return 'Click Count: $count';
  }

  @override
  String get loadMore => 'Load More';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get add => 'Add';

  @override
  String get enterPassword => 'Please Enter Password';

  @override
  String get wrongPassword => 'Wrong Password';

  @override
  String get confirm => 'Confirm';

  @override
  String eventLogs(String eventName) {
    return '$eventName - Click Records';
  }

  @override
  String get hint => 'Hint';

  @override
  String get pleaseAddEvent => 'Please add an event first';

  @override
  String get pleaseSelectEvent => 'Please select an event to count';

  @override
  String get selectEvent => 'Select Event';

  @override
  String get increaseCount => 'Increase Count';

  @override
  String get switchEvent => 'Switch Event';

  @override
  String get eventTitle => 'Event Management';

  @override
  String get searchEvent => 'Search Event';

  @override
  String get unknownCategory => 'Unknown Category';

  @override
  String get selectCategory => 'Select Category';

  @override
  String get setAsDefault => 'Set as Default';

  @override
  String get isDefault => 'Default';

  @override
  String defaultSetSuccess(String eventName) {
    return '$eventName has been set as default';
  }

  @override
  String defaultSetFailed(String error) {
    return 'Failed to set default event: $error';
  }

  @override
  String get edit => 'Edit';

  @override
  String get delete => 'Delete';

  @override
  String get settings => 'Settings';

  @override
  String get darkMode => 'Dark Mode';

  @override
  String get language => 'Language';

  @override
  String get defaultLanguage => 'System Default';

  @override
  String get about => 'About';

  @override
  String get version => 'Version';

  @override
  String get developer => 'Developer';

  @override
  String get appDescription => 'Count Matters is a simple app to track click counts for various events.';

  @override
  String get statsReport => 'Stats Report';

  @override
  String get dailyStats => 'Daily Stats';

  @override
  String get weeklyStats => 'Weekly Stats';

  @override
  String get monthlyStats => 'Monthly Stats';

  @override
  String get totalClicks => 'Total Clicks';

  @override
  String get noData => 'No Data';

  @override
  String get week => 'Week';

  @override
  String get dateRange => 'Date Range';

  @override
  String get apply => 'Apply';

  @override
  String get optional => 'Optional';

  @override
  String get defaultCategory => 'Default';

  @override
  String get defaultCategoryDescription => 'Default category';

  @override
  String get eventNameRequired => 'Event name is required';

  @override
  String get categoryRequired => 'Please select a category';
}
