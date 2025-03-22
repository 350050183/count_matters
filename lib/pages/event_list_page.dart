import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../generated/app_localizations.dart';
import '../models/category.dart';
import '../models/event.dart';
import '../services/auth_service.dart';
import '../services/event_service.dart';
import 'event_logs_page.dart';
import 'event_stats_page.dart';

class EventListPage extends StatefulWidget {
  final EventService eventService;
  final String? categoryId;

  const EventListPage({
    super.key,
    required this.eventService,
    this.categoryId,
  });

  @override
  State<EventListPage> createState() => _EventListPageState();
}

class _EventListPageState extends State<EventListPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Category? _selectedCategory;
  List<Event> _events = [];
  List<Category> _categories = [];
  String? _defaultEventId;
  bool _isLoading = true;

  // 添加排序相关状态变量
  String _sortBy = 'name'; // 可选值: 'name', 'createdAt', 'clickCount'
  bool _sortAscending = true;

  // 本地化文本辅助方法
  String _getLocalText(String key) {
    final locale = Localizations.localeOf(context).languageCode;
    final isZh = locale == 'zh';

    // 添加缺少的本地化字符串
    switch (key) {
      case 'isDefault':
        return isZh ? '已是默认' : 'Default';
      case 'setAsDefault':
        return isZh ? '设为默认' : 'Set as Default';
      case 'edit':
        return isZh ? '编辑' : 'Edit';
      case 'delete':
        return isZh ? '删除' : 'Delete';
      default:
        return key;
    }
  }

  @override
  void initState() {
    super.initState();
    _loadData();
    // 在异步之后检查类别密码保护
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkCategoryPassword();
    });
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    // 获取类别列表
    final categories = await widget.eventService.getCategories();
    final defaultEventId = await widget.eventService.getDefaultEventId();
    final authService = Provider.of<AuthService>(context, listen: false);

    List<Event> events;

    // 根据categoryId参数过滤事件
    if (widget.categoryId != null) {
      // 如果是特定类别视图，则只加载该类别的事件
      events = await widget.eventService.getEvents(widget.categoryId);
    } else {
      // 如果是全部事件视图，需要过滤掉受密码保护且未验证的类别
      final allEvents = await widget.eventService.getEvents();

      // 过滤事件列表
      events = allEvents.where((event) {
        // 查找事件所属的类别
        final category = categories.firstWhere(
          (c) => c.id == event.categoryId,
          orElse: () => Category(id: '', name: '未知类别'),
        );

        // 如果类别受密码保护但未验证，过滤掉该事件
        if (category.isPasswordProtected &&
            !authService.isCategoryVerified(category.id)) {
          return false;
        }

        // 其他事件正常显示
        return true;
      }).toList();
    }

    if (mounted) {
      setState(() {
        _events = events;
        _categories = categories;
        _defaultEventId = defaultEventId;

        // 如果有categoryId，设置初始选择的类别
        if (widget.categoryId != null) {
          for (var category in categories) {
            if (category.id == widget.categoryId) {
              _selectedCategory = category;
              break;
            }
          }
        }

        _isLoading = false;

        // 加载数据后应用排序
        _sortEvents();
      });
    }
  }

  // 添加排序事件的方法
  void _sortEvents() {
    setState(() {
      _filteredEvents.sort((a, b) {
        int comparison;

        switch (_sortBy) {
          case 'name':
            comparison = a.name.compareTo(b.name);
            break;
          case 'createdAt':
            comparison = a.createdAt.compareTo(b.createdAt);
            break;
          case 'clickCount':
            comparison = a.clickCount.compareTo(b.clickCount);
            break;
          case 'lastClickTime':
            final lastClickTimeA = a.lastClickTime ?? DateTime(1970);
            final lastClickTimeB = b.lastClickTime ?? DateTime(1970);
            comparison = lastClickTimeA.compareTo(lastClickTimeB);
            break;
          default:
            comparison = 0;
        }

        return _sortAscending ? comparison : -comparison;
      });
    });
  }

  // 切换排序方式
  void _toggleSort(String sortBy) {
    setState(() {
      if (_sortBy == sortBy) {
        // 如果已经按此字段排序，则切换升序/降序
        _sortAscending = !_sortAscending;
      } else {
        // 如果是新的排序字段，设为升序
        _sortBy = sortBy;
        _sortAscending = true;
      }
      _sortEvents();
    });
  }

  // 检查类别是否需要密码验证
  Future<void> _checkCategoryPassword() async {
    if (widget.categoryId != null) {
      final categoryId = widget.categoryId!; // 使用非空断言确保类型正确
      final category = await widget.eventService.getCategory(categoryId);
      if (category != null && category.isPasswordProtected) {
        // 检查是否需要验证密码
        final authService = Provider.of<AuthService>(context, listen: false);
        if (!authService.isCategoryVerified(category.id)) {
          // 显示密码输入对话框
          final bool? authenticated =
              await _showCategoryPasswordDialog(category);
          if (authenticated != true) {
            // 密码验证失败，返回上一页
            if (mounted) {
              Navigator.pop(context);
            }
            return;
          }
          // 验证成功，标记已验证
          authService.markCategoryAsVerified(category.id);
        }
      }
    }
  }

  List<Event> get _filteredEvents => _events
      .where((event) =>
          event.name.toLowerCase().contains(_searchQuery.toLowerCase()))
      .toList();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddEventDialog() {
    final nameController = TextEditingController();

    // 如果是从类别页面进入，则预先选择该类别
    if (widget.categoryId != null && _selectedCategory == null) {
      for (var category in _categories) {
        if (category.id == widget.categoryId) {
          _selectedCategory = category;
          break;
        }
      }
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context).addEvent),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context).eventName,
              ),
            ),
            const SizedBox(height: 16),
            widget.categoryId != null
                ? Text(
                    '${AppLocalizations.of(context).categoryName}: ${_selectedCategory?.name ?? ""}')
                : DropdownButtonFormField<Category>(
                    value: _selectedCategory,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context).selectCategory,
                    ),
                    items: _categories.map((category) {
                      return DropdownMenuItem(
                        value: category,
                        child: Text(category.name),
                      );
                    }).toList(),
                    onChanged: (Category? value) {
                      setState(() {
                        _selectedCategory = value;
                      });
                    },
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
              if (nameController.text.isEmpty) {
                // 显示错误消息：事件名称不能为空
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content:
                        Text(AppLocalizations.of(context).eventNameRequired),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              if (_selectedCategory == null) {
                // 显示错误消息：必须选择类别
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content:
                        Text(AppLocalizations.of(context).categoryRequired),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              try {
                debugPrint('添加事件: ${nameController.text}');
                final newEvent = await widget.eventService.addEvent(
                  nameController.text,
                  _selectedCategory!.id,
                );
                debugPrint('事件添加成功: ${newEvent.id}');
                await _loadData();
                debugPrint('数据已刷新');
                Navigator.pop(context);

                // 显示成功消息
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('添加成功: ${nameController.text}'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              } catch (e) {
                debugPrint('添加事件失败: $e');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('添加失败: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: Text(AppLocalizations.of(context).add),
          ),
        ],
      ),
    );
  }

  void _showEditEventDialog(Event event) {
    final nameController = TextEditingController(text: event.name);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context).editEvent),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context).eventName,
              ),
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
                event.name = nameController.text;
                await widget.eventService.updateEvent(event);
                _loadData();
                Navigator.pop(context);
              }
            },
            child: Text(AppLocalizations.of(context).save),
          ),
        ],
      ),
    );
  }

  // 设置默认事件
  Future<void> _setAsDefaultEvent(Event event) async {
    try {
      await widget.eventService.setDefaultEvent(event.id);
      await _loadData();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${event.name} 已设为默认事件'),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('设置默认事件失败: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // 获取类别名称，用于显示在标题中
    String categoryName = '';
    if (widget.categoryId != null && _selectedCategory != null) {
      categoryName = _selectedCategory!.name;
    }

    return GestureDetector(
      // 点击空白处时，取消输入框的焦点，收起键盘
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title: widget.categoryId != null
              ? Text(
                  '${AppLocalizations.of(context)?.eventTitle} - $categoryName')
              : Text(AppLocalizations.of(context).eventTitle),
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: _showAddEventDialog,
              tooltip: AppLocalizations.of(context).addEvent,
            ),
            // 添加排序按钮
            PopupMenuButton<String>(
              icon: const Icon(Icons.sort),
              tooltip: '排序方式',
              onSelected: _toggleSort,
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'name',
                  child: Row(
                    children: [
                      Text(_isZh ? '按名称排序' : 'Sort by name'),
                      if (_sortBy == 'name')
                        Icon(
                          _sortAscending
                              ? Icons.arrow_upward
                              : Icons.arrow_downward,
                          size: 16,
                        ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'createdAt',
                  child: Row(
                    children: [
                      Text(_isZh ? '按创建时间排序' : 'Sort by creation time'),
                      if (_sortBy == 'createdAt')
                        Icon(
                          _sortAscending
                              ? Icons.arrow_upward
                              : Icons.arrow_downward,
                          size: 16,
                        ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'clickCount',
                  child: Row(
                    children: [
                      Text(_isZh ? '按点击次数排序' : 'Sort by click count'),
                      if (_sortBy == 'clickCount')
                        Icon(
                          _sortAscending
                              ? Icons.arrow_upward
                              : Icons.arrow_downward,
                          size: 16,
                        ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'lastClickTime',
                  child: Row(
                    children: [
                      Text(_isZh ? '按最后点击时间排序' : 'Sort by last click time'),
                      if (_sortBy == 'lastClickTime')
                        Icon(
                          _sortAscending
                              ? Icons.arrow_upward
                              : Icons.arrow_downward,
                          size: 16,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  if (widget.categoryId != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: Row(
                        children: [
                          Icon(Icons.folder,
                              color: Theme.of(context).primaryColor),
                          const SizedBox(width: 8),
                          Text(
                            categoryName,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context).searchEvent,
                        prefixIcon: const Icon(Icons.search),
                        border: const OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _filteredEvents.length,
                      itemBuilder: (context, index) {
                        final event = _filteredEvents[index];
                        final category = _categories.firstWhere(
                          (c) => c.id == event.categoryId,
                          orElse: () => Category(
                            id: '',
                            name: AppLocalizations.of(context).unknownCategory,
                          ),
                        );
                        final isDefault = event.id == _defaultEventId;

                        return ListTile(
                          title: Row(
                            children: [
                              Text(event.name),
                              if (isDefault)
                                Padding(
                                  padding: const EdgeInsets.only(left: 8.0),
                                  child: Icon(
                                    Icons.star,
                                    color: Colors.amber,
                                    size: 16,
                                  ),
                                ),
                            ],
                          ),
                          subtitle: Text(category.name),
                          onTap: () async {
                            // 获取事件所属类别
                            final category = await widget.eventService
                                .getCategory(event.categoryId);

                            if (category != null &&
                                category.isPasswordProtected) {
                              // 检查是否需要验证密码
                              final authService = Provider.of<AuthService>(
                                  context,
                                  listen: false);
                              if (!authService
                                  .isCategoryVerified(category.id)) {
                                // 显示密码输入对话框
                                final bool? authenticated =
                                    await _showCategoryPasswordDialog(category);
                                if (authenticated != true) {
                                  // 密码验证失败，不进行跳转
                                  return;
                                }
                                // 验证成功，标记已验证
                                authService.markCategoryAsVerified(category.id);
                              }
                            }

                            // 跳转到统计页面
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EventStatsPage(
                                  event: event,
                                  eventService: widget.eventService,
                                ),
                              ),
                            );
                          },
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextButton(
                                onPressed: () async {
                                  await widget.eventService
                                      .logEventClick(event.id);
                                  _loadData();
                                },
                                child: Text(
                                  '${AppLocalizations.of(context).clickCount}: ${event.clickCount}',
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.history),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => EventLogsPage(
                                        event: event,
                                        eventService: widget.eventService,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              PopupMenuButton<String>(
                                onSelected: (value) async {
                                  if (value == 'edit') {
                                    _showEditEventDialog(event);
                                  } else if (value == 'delete') {
                                    // 显示确认对话框
                                    bool confirm = await showDialog(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: Text(
                                                AppLocalizations.of(context)
                                                    .hint),
                                            content: Text(
                                                '${AppLocalizations.of(context).deleteEvent}?'),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(
                                                    context, false),
                                                child: Text(
                                                    AppLocalizations.of(context)
                                                        .cancel),
                                              ),
                                              TextButton(
                                                onPressed: () => Navigator.pop(
                                                    context, true),
                                                child: Text(
                                                  AppLocalizations.of(context)
                                                      .confirm,
                                                  style: const TextStyle(
                                                      color: Colors.red),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ) ??
                                        false;

                                    // 用户确认后删除
                                    if (confirm) {
                                      await widget.eventService
                                          .deleteEvent(event.id);
                                      _loadData();
                                    }
                                  } else if (value == 'setDefault') {
                                    await _setAsDefaultEvent(event);
                                  } else if (value == 'moveCategory') {
                                    _showMoveToCategoryDialog(event);
                                  } else if (value == 'stats') {
                                    // 获取事件所属类别
                                    final category = await widget.eventService
                                        .getCategory(event.categoryId);

                                    if (category != null &&
                                        category.isPasswordProtected) {
                                      // 检查是否需要验证密码
                                      final authService =
                                          Provider.of<AuthService>(context,
                                              listen: false);
                                      if (!authService
                                          .isCategoryVerified(category.id)) {
                                        // 显示密码输入对话框
                                        final bool? authenticated =
                                            await _showCategoryPasswordDialog(
                                                category);
                                        if (authenticated != true) {
                                          // 密码验证失败，不进行跳转
                                          return;
                                        }
                                        // 验证成功，标记已验证
                                        authService.markCategoryAsVerified(
                                            category.id);
                                      }
                                    }

                                    // 跳转到统计页面
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => EventStatsPage(
                                          event: event,
                                          eventService: widget.eventService,
                                        ),
                                      ),
                                    );
                                  }
                                },
                                itemBuilder: (context) => [
                                  PopupMenuItem(
                                    value: 'edit',
                                    child: Row(
                                      children: [
                                        Icon(Icons.edit, size: 18),
                                        SizedBox(width: 8),
                                        Text(_getLocalText('edit')),
                                      ],
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: 'stats',
                                    child: Row(
                                      children: [
                                        Icon(Icons.bar_chart, size: 18),
                                        SizedBox(width: 8),
                                        Text(AppLocalizations.of(context)
                                            .statistics),
                                      ],
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: 'setDefault',
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.star,
                                          size: 18,
                                          color:
                                              isDefault ? Colors.amber : null,
                                        ),
                                        SizedBox(width: 8),
                                        Text(isDefault
                                            ? _getLocalText('isDefault')
                                            : _getLocalText('setAsDefault')),
                                      ],
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: 'moveCategory',
                                    child: Row(
                                      children: [
                                        Icon(Icons.drive_file_move, size: 18),
                                        SizedBox(width: 8),
                                        Text(_isZh
                                            ? '移动到其他类别'
                                            : 'Move to Category'),
                                      ],
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(Icons.delete,
                                            size: 18, color: Colors.red),
                                        SizedBox(width: 8),
                                        Text(_getLocalText('delete'),
                                            style:
                                                TextStyle(color: Colors.red)),
                                      ],
                                    ),
                                  ),
                                ],
                                icon: const Icon(Icons.more_vert),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
        floatingActionButton: FloatingActionButton(
          onPressed: _showAddEventDialog,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  // 判断是否为中文环境
  bool get _isZh => Localizations.localeOf(context).languageCode == 'zh';

  // 显示类别密码输入对话框
  Future<bool?> _showCategoryPasswordDialog(Category category) async {
    final TextEditingController passwordController = TextEditingController();

    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('请输入密码'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('该类别"${category.name}"受密码保护'),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(
                labelText: '密码',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context).cancel),
          ),
          TextButton(
            onPressed: () {
              final enteredPassword = passwordController.text;
              final isCorrect = category.checkPassword(enteredPassword);

              if (isCorrect) {
                Navigator.pop(context, true);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('密码错误，请重试'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: Text(AppLocalizations.of(context).confirm),
          ),
        ],
      ),
    );
  }

  // 显示移动到其他类别的对话框
  void _showMoveToCategoryDialog(Event event) async {
    // 先检查源类别是否需要密码验证
    final sourceCategory =
        await widget.eventService.getCategory(event.categoryId);

    if (sourceCategory != null && sourceCategory.isPasswordProtected) {
      // 检查是否需要验证密码
      final authService = Provider.of<AuthService>(context, listen: false);
      if (!authService.isCategoryVerified(sourceCategory.id)) {
        // 显示密码输入对话框
        final bool? authenticated =
            await _showCategoryPasswordDialog(sourceCategory);
        if (authenticated != true) {
          // 密码验证失败，不允许移动
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_isZh
                  ? '密码验证失败，无法移动事件'
                  : 'Password verification failed, cannot move event'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
        // 验证成功，标记已验证
        authService.markCategoryAsVerified(sourceCategory.id);
      }
    }

    Category? selectedCategory;

    // 过滤掉当前类别，只显示其他类别
    final otherCategories =
        _categories.where((c) => c.id != event.categoryId).toList();

    if (otherCategories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isZh
              ? '没有其他可用类别，请先创建新类别'
              : 'No other categories available. Please create a new category first.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_isZh ? '移动到其他类别' : 'Move to Category'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${event.name}'),
            const SizedBox(height: 16),
            DropdownButtonFormField<Category>(
              decoration: InputDecoration(
                labelText: _isZh ? '选择目标类别' : 'Select Target Category',
                border: const OutlineInputBorder(),
              ),
              items: otherCategories.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category.name),
                );
              }).toList(),
              onChanged: (Category? value) {
                selectedCategory = value;
              },
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
              if (selectedCategory != null) {
                try {
                  // 创建一个新的事件对象，复制原始事件但更改类别ID
                  final updatedEvent = Event(
                    id: event.id,
                    categoryId: selectedCategory!.id, // 使用新的类别ID
                    name: event.name,
                    description: event.description,
                    clickCount: event.clickCount,
                    createdAt: event.createdAt,
                    logs: event.logs,
                    lastClickTime: event.lastClickTime,
                  );

                  await widget.eventService.updateEvent(updatedEvent);
                  _loadData();
                  Navigator.pop(context);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(_isZh
                          ? '已移动到：${selectedCategory!.name}'
                          : 'Moved to: ${selectedCategory!.name}'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(_isZh ? '移动失败: $e' : 'Move failed: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        _isZh ? '请选择目标类别' : 'Please select a target category'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: Text(AppLocalizations.of(context).confirm),
          ),
        ],
      ),
    );
  }
}
