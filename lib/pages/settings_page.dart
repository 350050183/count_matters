import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../generated/app_localizations.dart';
import '../main.dart';
import '../services/settings_service.dart';
import 'about_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late SettingsService _settingsService;
  bool _isDarkMode = false;
  String _selectedLanguage = 'system';
  int _statsEntryLimit = 6;

  @override
  void initState() {
    super.initState();
    _settingsService = Provider.of<SettingsService>(context, listen: false);
    _loadSettings();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _settingsService = Provider.of<SettingsService>(context, listen: false);
    _loadSettings();
  }

  void _loadSettings() {
    setState(() {
      _isDarkMode = _settingsService.isDarkMode;
      _selectedLanguage = _settingsService.language;
      _statsEntryLimit = _settingsService.statsEntryLimit;
      debugPrint(
          '从SettingsService加载设置: 深色模式=$_isDarkMode, 语言=$_selectedLanguage, 统计记录限制=$_statsEntryLimit');
    });
  }

  void _toggleDarkMode(bool value) async {
    setState(() {
      _isDarkMode = value;
    });
    await _settingsService.setDarkMode(value);
    debugPrint('深色模式已更新: $value');
  }

  void _selectLanguage(String? value) async {
    if (value == null || value == _selectedLanguage) return;

    setState(() {
      _selectedLanguage = value;
    });
    await _settingsService.setLanguage(value);
    debugPrint('语言已更新: $value');

    rebuildApp();
  }

  void _updateStatsEntryLimit(int value) async {
    setState(() {
      _statsEntryLimit = value;
    });
    await _settingsService.setStatsEntryLimit(value);
    debugPrint('统计记录限制已更新: $value');
  }

  String _getLocalText(String key) {
    final locale = AppLocalizations.of(context);

    switch (key) {
      case 'settings':
        return locale.settings;
      case 'darkMode':
        return locale.darkMode;
      case 'language':
        return locale.language;
      case 'system':
        return locale.defaultLanguage;
      case 'english':
        return 'English';
      case 'chinese':
        return '中文';
      case 'about':
        return locale.about;
      case 'feedback':
        return locale.feedback;
      default:
        return key;
    }
  }

  String _getStatsLimitLabel() {
    return AppLocalizations.of(context).statsDisplayLimit;
  }

  // 发送意见反馈邮件
  void _sendFeedbackEmail() async {
    final locale = AppLocalizations.of(context);
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'swingcoder@gmail.com',
      query: _encodeQueryParameters({
        'subject': '${locale.appTitle} - ${locale.feedback}',
        'body': '',
      }),
    );

    try {
      if (await canLaunchUrl(emailLaunchUri)) {
        await launchUrl(emailLaunchUri);
      } else {
        // 无法启动邮件应用时显示提示
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('无法打开邮件应用'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('启动邮件应用失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('发送邮件失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // 辅助方法：编码URL查询参数
  String? _encodeQueryParameters(Map<String, String> params) {
    return params.entries
        .map((e) =>
            '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getLocalText('settings')),
      ),
      body: ListView(
        children: [
          SwitchListTile(
            title: Text(_getLocalText('darkMode')),
            value: _isDarkMode,
            onChanged: _toggleDarkMode,
          ),
          ListTile(
            title: Text(_getLocalText('language')),
            trailing: DropdownButton<String>(
              value: _selectedLanguage,
              onChanged: _selectLanguage,
              items: [
                DropdownMenuItem(
                  value: 'system',
                  child: Text(_getLocalText('system')),
                ),
                DropdownMenuItem(
                  value: 'en',
                  child: Text(_getLocalText('english')),
                ),
                DropdownMenuItem(
                  value: 'zh',
                  child: Text(_getLocalText('chinese')),
                ),
              ],
            ),
          ),
          ListTile(
            title: Text(_getStatsLimitLabel()),
            subtitle: Slider(
              value: _statsEntryLimit.toDouble(),
              min: 3,
              max: 20,
              divisions: 17,
              label: _statsEntryLimit.toString(),
              onChanged: (value) {
                _updateStatsEntryLimit(value.toInt());
              },
            ),
            trailing: Text(
              _statsEntryLimit.toString(),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          ListTile(
            title: Text(_getLocalText('about')),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AboutPage(),
                ),
              );
            },
          ),
          // 添加意见反馈选项
          ListTile(
            title: Text(_getLocalText('feedback')),
            subtitle: Text(AppLocalizations.of(context).feedbackDescription),
            trailing: const Icon(Icons.email, size: 20),
            onTap: _sendFeedbackEmail,
          ),
        ],
      ),
    );
  }
}
