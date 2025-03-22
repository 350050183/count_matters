import 'package:flutter/material.dart';

import '../generated/app_localizations.dart';
import '../models/category.dart';
import '../services/event_service.dart';
import 'event_list_page.dart';

class CategoryListPage extends StatefulWidget {
  final EventService eventService;

  const CategoryListPage({super.key, required this.eventService});

  @override
  State<CategoryListPage> createState() => _CategoryListPageState();
}

class _CategoryListPageState extends State<CategoryListPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<Category> _categories = [];
  Map<String, int> _categoryEventCounts = {}; // 存储类别事件数量

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    debugPrint('正在加载类别列表...');
    final categories = await widget.eventService.getCategories();
    debugPrint('获取到${categories.length}个类别');

    // 获取每个类别的事件数量
    Map<String, int> counts = {};
    for (var category in categories) {
      counts[category.id] =
          await widget.eventService.getCategoryEventCount(category.id);
    }

    if (mounted) {
      setState(() {
        _categories = categories;
        _categoryEventCounts = counts;
        debugPrint('类别列表已更新，UI将重新构建');
      });
    }
  }

  List<Category> get _filteredCategories => _categories
      .where((category) =>
          category.name.toLowerCase().contains(_searchQuery.toLowerCase()))
      .toList();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _navigateToEventList() async {
    debugPrint('准备跳转到EventListPage...');

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EventListPage(eventService: widget.eventService),
      ),
    );

    debugPrint('从EventListPage返回...');
    // 从事件列表页面返回后重新加载类别数据，确保事件计数是最新的
    _loadCategories();
  }

  void _showAddCategoryDialog() {
    final nameController = TextEditingController();
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
              controller: passwordController,
              decoration: InputDecoration(
                labelText:
                    '${AppLocalizations.of(context).categoryPassword} (${AppLocalizations.of(context).optional})',
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
                try {
                  await widget.eventService.addCategory(
                    nameController.text,
                    password: passwordController.text.isEmpty
                        ? null
                        : passwordController.text,
                  );
                  await _loadCategories();
                  Navigator.pop(context);
                } catch (e) {
                  // 显示错误提示
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${AppLocalizations.of(context).hint}: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
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
              controller: passwordController,
              decoration: InputDecoration(
                labelText:
                    '${AppLocalizations.of(context).categoryPassword} (${AppLocalizations.of(context).optional})',
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
                if (passwordController.text.isNotEmpty) {
                  category.setPassword(passwordController.text);
                }
                await widget.eventService.updateCategory(category);
                await _loadCategories();
                Navigator.pop(context);
              }
            },
            child: Text(AppLocalizations.of(context).save),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).categoryTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.event),
            onPressed: _navigateToEventList,
            tooltip: AppLocalizations.of(context).eventManagement,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context).searchCategory,
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
              itemCount: _filteredCategories.length,
              itemBuilder: (context, index) {
                final category = _filteredCategories[index];
                final eventCount = _categoryEventCounts[category.id] ?? 0;

                return ListTile(
                  title: Text(category.name),
                  subtitle: Text(
                    '${AppLocalizations.of(context).eventCount}: $eventCount',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                  leading: category.isPasswordProtected
                      ? const Icon(Icons.lock)
                      : const Icon(Icons.folder),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _showEditCategoryDialog(category),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () async {
                          // 先检查是否有关联的事件
                          bool hasEvents = await widget.eventService
                              .categoryHasEvents(category.id);

                          if (hasEvents) {
                            // 如果有关联事件，提示用户先删除事件
                            if (mounted) {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title:
                                      Text(AppLocalizations.of(context).hint),
                                  content: Text(AppLocalizations.of(context)
                                      .categoryHasEventsWarning),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: Text(
                                          AppLocalizations.of(context).confirm),
                                    ),
                                  ],
                                ),
                              );
                            }
                            return;
                          }

                          // 没有关联事件，显示确认对话框
                          bool confirm = await showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title:
                                      Text(AppLocalizations.of(context).hint),
                                  content: Text(
                                      '${AppLocalizations.of(context).deleteCategory}?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: Text(
                                          AppLocalizations.of(context).cancel),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      child: Text(
                                        AppLocalizations.of(context).confirm,
                                        style:
                                            const TextStyle(color: Colors.red),
                                      ),
                                    ),
                                  ],
                                ),
                              ) ??
                              false;

                          // 用户确认后删除
                          if (confirm) {
                            await widget.eventService
                                .deleteCategory(category.id);
                            await _loadCategories();
                          }
                        },
                      ),
                    ],
                  ),
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EventListPage(
                          eventService: widget.eventService,
                          categoryId: category.id,
                        ),
                      ),
                    );
                    // 从事件列表页面返回后重新加载类别数据，更新事件计数
                    _loadCategories();
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddCategoryDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
