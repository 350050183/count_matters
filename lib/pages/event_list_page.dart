import 'package:flutter/material.dart';

import '../generated/app_localizations.dart';
import '../models/category.dart';
import '../models/event.dart';
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

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    // 根据categoryId参数过滤事件
    final events = widget.categoryId != null
        ? await widget.eventService.getEvents(widget.categoryId)
        : await widget.eventService.getEvents();

    final categories = await widget.eventService.getCategories();
    final defaultEventId = await widget.eventService.getDefaultEventId();

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
      });
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

    return Scaffold(
      appBar: AppBar(
        title: widget.categoryId != null
            ? Text(
                '${AppLocalizations.of(context)?.eventTitle} - $categoryName')
            : Text(AppLocalizations.of(context).eventTitle),
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
                                              onPressed: () =>
                                                  Navigator.pop(context, false),
                                              child: Text(
                                                  AppLocalizations.of(context)
                                                      .cancel),
                                            ),
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, true),
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
                                } else if (value == 'stats') {
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
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      Icon(Icons.edit, size: 18),
                                      SizedBox(width: 8),
                                      Text('编辑'),
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
                                        color: isDefault ? Colors.amber : null,
                                      ),
                                      SizedBox(width: 8),
                                      Text(isDefault ? '已是默认' : '设为默认'),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(Icons.delete,
                                          size: 18, color: Colors.red),
                                      SizedBox(width: 8),
                                      Text('删除',
                                          style: TextStyle(color: Colors.red)),
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
    );
  }
}
