import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../generated/app_localizations.dart';
import '../models/category.dart';
import '../services/auth_service.dart';
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
    final currentPasswordController = TextEditingController();
    bool isChangingPassword = false;
    bool isDeletingPassword = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(builder: (context, setState) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context).editCategory),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context).categoryName,
                  ),
                ),
                const SizedBox(height: 16),
                if (category.isPasswordProtected) ...[
                  Row(
                    children: [
                      Icon(Icons.lock, color: Colors.orange),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '该类别已启用密码保护',
                          style: TextStyle(color: Colors.orange),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () {
                          setState(() {
                            isChangingPassword = !isChangingPassword;
                            isDeletingPassword = false;
                          });
                        },
                        child: Text(isChangingPassword ? '取消修改密码' : '修改密码'),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            isDeletingPassword = !isDeletingPassword;
                            isChangingPassword = false;
                          });
                        },
                        child: Text(
                          isDeletingPassword ? '取消删除密码' : '删除密码',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  const SizedBox(height: 8),
                  TextField(
                    controller: passwordController,
                    decoration: InputDecoration(
                      labelText:
                          '${AppLocalizations.of(context).categoryPassword} (${AppLocalizations.of(context).optional})',
                      helperText: '设置密码将启用类别保护功能',
                    ),
                    obscureText: true,
                  ),
                ],
                if (isChangingPassword && category.isPasswordProtected) ...[
                  const SizedBox(height: 16),
                  TextField(
                    controller: currentPasswordController,
                    decoration: InputDecoration(
                      labelText: '当前密码',
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: passwordController,
                    decoration: InputDecoration(
                      labelText: '新密码',
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                  ),
                ],
                if (isDeletingPassword && category.isPasswordProtected) ...[
                  const SizedBox(height: 16),
                  TextField(
                    controller: currentPasswordController,
                    decoration: InputDecoration(
                      labelText: '当前密码',
                      border: OutlineInputBorder(),
                      helperText: '请输入当前密码以确认删除',
                    ),
                    obscureText: true,
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppLocalizations.of(context).cancel),
            ),
            TextButton(
              onPressed: () async {
                if (nameController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('类别名称不能为空'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                // 更新类别名称
                category.name = nameController.text;

                // 处理密码相关操作
                if (category.isPasswordProtected) {
                  if (isChangingPassword) {
                    // 验证当前密码
                    if (!category
                        .checkPassword(currentPasswordController.text)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('当前密码错误'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    // 设置新密码
                    if (passwordController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('新密码不能为空'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    try {
                      category.setPassword(passwordController.text);
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('设置密码失败: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                  } else if (isDeletingPassword) {
                    // 验证当前密码
                    if (!category
                        .checkPassword(currentPasswordController.text)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('密码错误，无法删除密码'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    // 删除密码
                    category.setPassword("");
                  }
                } else if (passwordController.text.isNotEmpty) {
                  // 添加新密码
                  try {
                    category.setPassword(passwordController.text);
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('设置密码失败: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }
                }

                await widget.eventService.updateCategory(category);
                await _loadCategories();
                Navigator.pop(context);

                // 显示操作成功提示
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('类别已更新'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: Text(AppLocalizations.of(context).save),
            ),
          ],
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // 点击空白处时，取消输入框的焦点，收起键盘
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
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
                                        child: Text(AppLocalizations.of(context)
                                            .confirm),
                                      ),
                                    ],
                                  ),
                                );
                              }
                              return;
                            }

                            // 如果类别有密码保护，先进行密码验证
                            if (category.isPasswordProtected) {
                              // 获取AuthService实例
                              final authService = Provider.of<AuthService>(
                                  context,
                                  listen: false);

                              // 检查是否已经验证过（当天）
                              if (!authService
                                  .isCategoryVerified(category.id)) {
                                bool? passwordVerified =
                                    await _showPasswordVerificationDialog(
                                        category);
                                if (passwordVerified != true) {
                                  // 密码验证失败，不进行删除操作
                                  return;
                                }
                                // 验证成功，标记已验证
                                authService.markCategoryAsVerified(category.id);
                              }
                            }

                            // 显示确认对话框
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
                                        child: Text(AppLocalizations.of(context)
                                            .cancel),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, true),
                                        child: Text(
                                          AppLocalizations.of(context).confirm,
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
                                  .deleteCategory(category.id);
                              await _loadCategories();
                            }
                          },
                        ),
                      ],
                    ),
                    onTap: () async {
                      // 检查类别是否需要密码验证
                      if (category.isPasswordProtected) {
                        // 获取AuthService实例
                        final authService =
                            Provider.of<AuthService>(context, listen: false);

                        // 检查是否已经验证过（当天）
                        if (!authService.isCategoryVerified(category.id)) {
                          // 显示密码验证对话框
                          bool? passwordVerified =
                              await _showPasswordVerificationDialog(category);
                          if (passwordVerified != true) {
                            // 密码验证失败，不进行跳转
                            return;
                          }
                          // 验证成功，标记已验证
                          authService.markCategoryAsVerified(category.id);
                        }
                      }

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
      ),
    );
  }

  // 显示密码验证对话框
  Future<bool?> _showPasswordVerificationDialog(Category category) async {
    final TextEditingController passwordController = TextEditingController();

    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('验证密码'),
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
}
