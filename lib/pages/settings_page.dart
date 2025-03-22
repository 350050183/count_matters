import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../generated/app_localizations.dart';
import '../main.dart';
import '../services/settings_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late SettingsService _settingsService;
  bool _isDarkMode = false;
  String _selectedLanguage = 'system';

  @override
  void initState() {
    super.initState();
    _settingsService = Provider.of<SettingsService>(context, listen: false);
    _loadSettings();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 每次依赖变更时重新获取设置
    _settingsService = Provider.of<SettingsService>(context, listen: false);
    _loadSettings();
  }

  void _loadSettings() {
    setState(() {
      _isDarkMode = _settingsService.isDarkMode;
      _selectedLanguage = _settingsService.language;
      debugPrint(
          '从SettingsService加载设置: 深色模式=$_isDarkMode, 语言=$_selectedLanguage');
    });
  }

  void _toggleDarkMode(bool value) async {
    setState(() {
      _isDarkMode = value;
    });
    await _settingsService.setDarkMode(value);
    debugPrint('深色模式已更新: $value');
  }

  void _changeLanguage(String? language) async {
    if (language != null && language != _selectedLanguage) {
      debugPrint('正在切换语言从 $_selectedLanguage 到 $language');

      // 更新界面显示
      setState(() {
        _selectedLanguage = language;
      });

      try {
        // 保存语言设置
        await _settingsService.setLanguage(language);
        debugPrint('✅ 语言设置已保存: $language');

        // 强制重建整个应用
        if (mounted) {
          // 设置UI反馈
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  '${language == 'en' ? 'Changing language...' : '正在切换语言...'}'),
              duration: const Duration(milliseconds: 500),
            ),
          );

          // 短暂延迟确保设置已保存
          await Future.delayed(const Duration(milliseconds: 200));

          // 触发应用程序重建
          debugPrint('🔄 正在重建应用程序...');
          rebuildApp();

          // 显示成功提示
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => AlertDialog(
                  title: Text(AppLocalizations.of(context).hint),
                  content: Text(
                      '${language == 'en' ? 'Language' : '语言'}${language == 'en' ? ' changed to English' : '已切换为中文'}'),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: Text(AppLocalizations.of(context).confirm),
                    ),
                  ],
                ),
              );
            }
          });
        }
      } catch (e) {
        debugPrint('❌ 语言切换失败: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('语言切换失败: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).settings),
      ),
      body: ListView(
        children: [
          ListTile(
            title: Text(AppLocalizations.of(context).darkMode),
            trailing: Switch(
              value: _isDarkMode,
              onChanged: _toggleDarkMode,
            ),
          ),
          ListTile(
            title: Text(AppLocalizations.of(context).language),
            trailing: DropdownButton<String>(
              value: _selectedLanguage,
              onChanged: _changeLanguage,
              items: [
                DropdownMenuItem(
                  value: 'system',
                  child: Text(AppLocalizations.of(context).defaultLanguage),
                ),
                const DropdownMenuItem(
                  value: 'en',
                  child: Text('English'),
                ),
                const DropdownMenuItem(
                  value: 'zh',
                  child: Text('中文'),
                ),
              ],
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              '${AppLocalizations.of(context).version}: 1.0.0',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
