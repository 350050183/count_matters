import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

import 'generated/app_localizations.dart';
import 'pages/home_page.dart';
import 'pages/icon_generator_page.dart';
import 'services/auth_service.dart';
import 'services/event_service.dart';
import 'services/settings_service.dart';

// 全局实例，方便访问
late EventService eventService;
late SettingsService settingsService;
late AuthService authService;
// 全局key，用于重建整个应用
final GlobalKey<AppStateContainerState> appStateKey =
    GlobalKey<AppStateContainerState>();
// 全局导航键，用于在没有上下文时获取全局上下文
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// 用于标记应用是否需要重启的通知器
class RestartNotifier extends ChangeNotifier {
  bool _needsRestart = false;

  bool get needsRestart => _needsRestart;

  set needsRestart(bool value) {
    if (_needsRestart != value) {
      _needsRestart = value;
      notifyListeners();
    }
  }
}

// 全局方法，用于重建应用
void rebuildApp() {
  appStateKey.currentState?.rebuildApp();
}

Future<void> initializeDatabase() async {
  if (kIsWeb) {
    // Web平台初始化
    try {
      debugPrint('正在初始化Web平台数据库...');

      // 直接设置databaseFactory而不进行测试
      // Web环境下的测试可能会因为浏览器安全策略或WASM加载问题而阻塞
      databaseFactory = databaseFactoryFfiWeb;
      debugPrint('Web平台数据库工厂初始化成功（未进行测试）');

      // 注意：真正的数据库测试将在EventService.initialize中进行
      // 如果那里失败，将自动切换到内存数据模式
    } catch (e, stackTrace) {
      debugPrint('初始化Web数据库工厂时出错: $e');
      debugPrint('堆栈跟踪: $stackTrace');
      debugPrint('尝试使用备用方案...');

      // 尝试再次设置，不过这次不处理异常
      databaseFactory = databaseFactoryFfiWeb;
      debugPrint('数据库工厂已设置（可能不可用）');
    }
  } else {
    // 其他平台初始化
    try {
      debugPrint('正在初始化本地平台数据库...');
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      debugPrint('本地平台数据库工厂初始化成功');
    } catch (e, stackTrace) {
      debugPrint('初始化本地数据库工厂时出错: $e');
      debugPrint('堆栈跟踪: $stackTrace');
      rethrow;
    }
  }
}

Future<void> main() async {
  debugPrint('应用程序启动...');

  try {
    debugPrint('确保Flutter绑定初始化...');
    WidgetsFlutterBinding.ensureInitialized();
    debugPrint('Flutter绑定初始化成功');

    debugPrint('开始初始化数据库...');
    await initializeDatabase();
    debugPrint('数据库初始化成功');

    debugPrint('创建EventService实例...');
    eventService = EventService();

    debugPrint('初始化SettingsService...');
    settingsService = SettingsService();
    await settingsService.init();
    debugPrint('SettingsService初始化成功');

    debugPrint('初始化AuthService...');
    authService = AuthService();
    debugPrint('AuthService初始化成功');

    // Web环境下的特殊处理
    if (kIsWeb) {
      debugPrint('Web环境: 使用并行初始化...');

      // 同时启动UI和数据库初始化，但不等待数据库初始化完成
      eventService.initialize().then((_) {
        debugPrint('EventService初始化成功（后台）');
      }).catchError((e) {
        debugPrint('EventService初始化出错（后台）: $e');
      });

      // 直接启动UI，不等待数据库初始化
      debugPrint('Web环境: 启动UI而不等待数据库初始化...');
    } else {
      // 非Web环境：等待数据库初始化完成
      debugPrint('开始初始化EventService...');
      await eventService.initialize();
      debugPrint('EventService初始化成功');
    }

    debugPrint('启动应用程序UI...');
    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => eventService),
          ChangeNotifierProvider(create: (_) => settingsService),
          ChangeNotifierProvider(create: (_) => authService),
          ChangeNotifierProvider(create: (_) => RestartNotifier()),
        ],
        child: const MyApp(),
      ),
    );
    debugPrint('应用程序UI启动成功');
  } catch (e, stackTrace) {
    debugPrint('初始化过程中出错: $e');
    debugPrint('堆栈跟踪: $stackTrace');
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('初始化错误: $e'),
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AppStateContainer(
      key: appStateKey,
      child: const AppWithLocale(),
    );
  }
}

// 状态容器，用于重建整个应用
class AppStateContainer extends StatefulWidget {
  final Widget child;

  const AppStateContainer({super.key, required this.child});

  @override
  State<AppStateContainer> createState() => AppStateContainerState();

  // 提供静态方法访问State
  static AppStateContainerState of(BuildContext context) {
    return context.findAncestorStateOfType<AppStateContainerState>()!;
  }
}

class AppStateContainerState extends State<AppStateContainer> {
  // 用于触发重建的键
  Key _key = UniqueKey();

  // 重建整个应用
  void rebuildApp() {
    setState(() {
      _key = UniqueKey();
    });
  }

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: _key,
      child: widget.child,
    );
  }
}

// 实际的应用程序构建
class AppWithLocale extends StatelessWidget {
  const AppWithLocale({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsService>(
      builder: (context, settingsService, _) {
        // 获取语言设置
        final language = settingsService.language;
        final isSystemLanguage = language == 'system';
        final userLocale = isSystemLanguage ? null : Locale(language);

        // 打印详细日志
        debugPrint('⚙️ 应用程序正在构建...');
        debugPrint('🔹 当前主题: ${settingsService.isDarkMode ? "深色" : "浅色"}');
        debugPrint('🔹 语言设置: ${isSystemLanguage ? "系统默认" : language}');
        debugPrint('🔹 将使用Locale: ${userLocale?.languageCode ?? "系统默认"}');

        return MaterialApp(
          debugShowCheckedModeBanner: false,
          navigatorKey: navigatorKey,
          title: 'Count Matters',
          // 浅色主题
          theme: ThemeData(
            primarySwatch: Colors.blue,
            visualDensity: VisualDensity.adaptivePlatformDensity,
            useMaterial3: true,
          ),
          // 深色主题
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            primarySwatch: Colors.blue,
            visualDensity: VisualDensity.adaptivePlatformDensity,
            useMaterial3: true,
          ),
          // 主题模式
          themeMode: settingsService.getThemeMode(),
          // 使用明确的locale设置
          locale: isSystemLanguage ? null : Locale(language),
          // 国际化配置
          localizationsDelegates: const [
            ...AppLocalizations.localizationsDelegates,
          ],
          supportedLocales: const [
            Locale('en'), // 英语
            Locale('zh'), // 中文
          ],
          // 本地化回调，确保选择正确的语言
          localeResolutionCallback: (deviceLocale, supportedLocales) {
            debugPrint('🔍 正在解析Locale...');
            debugPrint('🔍 设备语言: ${deviceLocale?.languageCode}');
            debugPrint(
                '🔍 支持的语言: ${supportedLocales.map((l) => l.languageCode).join(', ')}');

            // 用户明确设置了语言，优先使用用户设置
            if (!isSystemLanguage) {
              final userLocale = Locale(language);
              debugPrint('🌐 使用用户指定的语言: ${userLocale.languageCode}');
              return userLocale;
            }

            // 否则使用设备语言
            if (deviceLocale != null) {
              for (var locale in supportedLocales) {
                if (locale.languageCode == deviceLocale.languageCode) {
                  debugPrint('🌐 使用设备语言: ${deviceLocale.languageCode}');
                  return deviceLocale;
                }
              }
            }

            // 默认使用英语
            debugPrint('🌐 没有匹配的语言，使用默认英语');
            return const Locale('en');
          },
          home: const HomePage(),
          routes: {
            '/icon_generator': (context) => const IconGeneratorPage(),
          },
        );
      },
    );
  }
}
