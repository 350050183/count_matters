import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../generated/app_localizations.dart';
import '../models/category.dart';
import '../models/event.dart';
import '../services/event_service.dart';
import 'about_page.dart';
import 'category_list_page.dart';
import 'event_list_page.dart';
import 'settings_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  final bool _showingCategories = true;
  Event? _selectedEvent;
  late final EventService _eventService;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _eventService = Provider.of<EventService>(context, listen: false);
    _initializeApp();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 减少不必要的刷新，只在依赖变化时进行轻量级检查
  }

  @override
  Future<bool> didPopRoute() async {
    // 当用户从其他页面返回时刷新数据
    if (_isInitialized) {
      _refreshEvents();
    }
    return false; // 返回false表示我们没有处理返回事件
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // 处理应用程序生命周期状态变化
    if (state == AppLifecycleState.resumed && _isInitialized) {
      // 当应用从后台恢复时刷新数据
      _refreshEvents();
    }
    super.didChangeAppLifecycleState(state);
  }

  Future<void> _initializeApp() async {
    if (!mounted) return;

    try {
      await _eventService.initialize();

      // 检查是否存在类别，如果不存在则创建默认类别
      final categories = await _eventService.getCategories();
      if (categories.isEmpty) {
        await _eventService.addCategory(
          'default',
          description: '默认类别',
        );
        debugPrint('已创建默认类别');
      }

      // 首先尝试加载默认事件
      final defaultEvent = await _eventService.getDefaultEvent();

      if (defaultEvent != null) {
        debugPrint('找到默认事件: ${defaultEvent.name}');
        if (mounted) {
          setState(() {
            _selectedEvent = defaultEvent;
            _isInitialized = true;
          });
        }
        return;
      }

      // 如果没有默认事件，则获取第一个事件作为默认选中事件
      final events = await _eventService.getEvents();

      if (mounted) {
        setState(() {
          if (events.isNotEmpty) {
            debugPrint('找到 ${events.length} 个事件，选择第一个');
            _selectedEvent = events.first;
          } else {
            debugPrint('没有找到事件');
            _selectedEvent = null;
          }
          _isInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('初始化时发生错误: $e');
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    }
  }

  // 添加刷新事件数据的方法
  Future<void> _refreshEvents() async {
    debugPrint('开始刷新事件数据...');

    try {
      // 首先尝试加载默认事件
      final defaultEvent = await _eventService.getDefaultEvent();

      if (defaultEvent != null) {
        debugPrint('刷新：找到默认事件: ${defaultEvent.name}');
        if (mounted) {
          setState(() {
            _selectedEvent = defaultEvent;
          });
        }
        return;
      }

      // 如果没有默认事件，则获取事件列表并选择第一个
      final events = await _eventService.getEvents();
      debugPrint('获取到 ${events.length} 个事件');

      if (mounted) {
        setState(() {
          if (events.isNotEmpty) {
            _selectedEvent = events.first;
            debugPrint('已选择事件: ${_selectedEvent!.name}');
          } else {
            _selectedEvent = null;
            debugPrint('没有可用事件');
          }
        });
      }
    } catch (e) {
      debugPrint('刷新事件数据失败: $e');
      // 发生错误时不更新状态，保持当前显示
    }
  }

  void _showAddCategoryDialog() {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context).addCategory),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context).categoryName,
              ),
            ),
            TextField(
              controller: descriptionController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context).categoryDescription,
              ),
            ),
            TextField(
              controller: passwordController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context).categoryPassword,
              ),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context).cancel),
          ),
          TextButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                await _eventService.addCategory(
                  nameController.text,
                  description: descriptionController.text.isEmpty
                      ? null
                      : descriptionController.text,
                  password: passwordController.text.isEmpty
                      ? null
                      : passwordController.text,
                );
                setState(() {});
                Navigator.pop(context);
              }
            },
            child: Text(AppLocalizations.of(context).add),
          ),
        ],
      ),
    );
  }

  void _showEditCategoryDialog(Category category) {
    final nameController = TextEditingController(text: category.name);
    final descriptionController =
        TextEditingController(text: category.description ?? '');
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context).editCategory),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context).categoryName,
              ),
            ),
            TextField(
              controller: descriptionController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context).categoryDescription,
              ),
            ),
            TextField(
              controller: passwordController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context).categoryPassword,
              ),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context).cancel),
          ),
          TextButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                category.name = nameController.text;
                category.description = descriptionController.text.isEmpty
                    ? null
                    : descriptionController.text;
                if (passwordController.text.isNotEmpty) {
                  category.setPassword(passwordController.text);
                }
                await _eventService.updateCategory(category);
                setState(() {});
                Navigator.pop(context);
              }
            },
            child: Text(AppLocalizations.of(context).save),
          ),
        ],
      ),
    );
  }

  Future<bool> _checkCategoryPassword(Category category) async {
    if (!category.isPasswordProtected) return true;

    final completer = Completer<bool>();
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context).enterPassword),
        content: TextField(
          controller: passwordController,
          decoration: const InputDecoration(
            labelText: '密码',
          ),
          obscureText: true,
        ),
        actions: [
          TextButton(
            onPressed: () {
              completer.complete(false);
              Navigator.pop(context);
            },
            child: Text(AppLocalizations.of(context).cancel),
          ),
          TextButton(
            onPressed: () {
              final isCorrect = category.checkPassword(passwordController.text);
              if (isCorrect) {
                completer.complete(true);
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(AppLocalizations.of(context).wrongPassword),
                  ),
                );
              }
            },
            child: Text(AppLocalizations.of(context).confirm),
          ),
        ],
      ),
    );

    return completer.future;
  }

  void _showNoEventDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context).hint),
        content: Text(AppLocalizations.of(context).pleaseAddEvent),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text(AppLocalizations.of(context).cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _navigateToEventList();
            },
            child: Text(AppLocalizations.of(context).confirm),
          ),
        ],
      ),
    );
  }

  void _showSelectEventDialog() async {
    final events = await _eventService.getEvents();
    if (!mounted) return;

    if (events.isEmpty) {
      _showNoEventDialog();
      return;
    }

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context).selectEvent),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              return ListTile(
                title: Text(event.name),
                subtitle: Text(
                    '${AppLocalizations.of(context).clickCount}: ${event.clickCount}'),
                onTap: () {
                  setState(() {
                    _selectedEvent = event;
                  });
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  // 修改跳转到EventListPage的方法，使用Navigator.push并在返回时刷新数据
  void _navigateToEventList() async {
    debugPrint('准备跳转到EventListPage...');

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EventListPage(eventService: _eventService),
      ),
    );

    debugPrint('从EventListPage返回...');

    // 从EventListPage返回后，刷新事件数据
    await _refreshEvents();

    debugPrint('事件数据已刷新，选中事件: ${_selectedEvent?.name ?? "无"}');
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).appTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.category),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CategoryListPage(
                    eventService: _eventService,
                  ),
                ),
              );

              // 从类别页面返回后，刷新事件数据
              await _refreshEvents();
            },
            tooltip: AppLocalizations.of(context).categoryManagement,
          ),
          IconButton(
            icon: const Icon(Icons.event),
            onPressed: _navigateToEventList,
            tooltip: AppLocalizations.of(context).eventManagement,
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsPage(),
                ),
              );
            },
            tooltip: AppLocalizations.of(context).settings,
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AboutPage(),
                ),
              );
            },
            tooltip: AppLocalizations.of(context).about,
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_selectedEvent != null) ...[
              Text(
                _selectedEvent!.name,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 20),
              Text(
                '${AppLocalizations.of(context).clickCount}: ${_selectedEvent!.clickCount}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 40),
            ],
            GestureDetector(
              onTap: () async {
                debugPrint('按钮被点击');
                if (_selectedEvent == null) {
                  debugPrint('没有选中的事件，显示提示对话框');
                  _showNoEventDialog();
                  return;
                }
                debugPrint('准备记录事件点击: ${_selectedEvent!.id}');
                try {
                  // 记录点击
                  await _eventService.logEventClick(_selectedEvent!.id);
                  debugPrint('点击记录成功');

                  // 重新获取更新后的事件数据
                  final updatedEvent =
                      await _eventService.getEvent(_selectedEvent!.id);
                  if (updatedEvent != null && mounted) {
                    debugPrint(
                        '获取到更新后的事件: ${updatedEvent.name}, 点击数: ${updatedEvent.clickCount}');
                    setState(() {
                      _selectedEvent = updatedEvent;
                    });
                  } else {
                    debugPrint('未能获取更新后的事件，可能已被删除');
                  }
                } catch (e) {
                  debugPrint('记录点击发生错误: $e');
                }
              },
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).colorScheme.primary,
                  border: Theme.of(context).brightness == Brightness.dark
                      ? Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 2.0,
                        )
                      : null,
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white.withOpacity(0.2)
                          : Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                    if (Theme.of(context).brightness == Brightness.dark)
                      BoxShadow(
                        color: Colors.white.withOpacity(0.05),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    Icons.add,
                    size: 64,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
