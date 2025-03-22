import 'package:flutter/material.dart';

import '../generated/app_localizations.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).about),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            // 应用图标
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                'lib/assets/images/app_icon.png',
                width: 100,
                height: 100,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 20),
            // 应用名称
            Text(
              AppLocalizations.of(context).appTitle,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 10),
            // 版本
            Text(
              '${AppLocalizations.of(context).version}: 1.0.0',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 20),
            // 应用描述
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  AppLocalizations.of(context).appDescription,
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(height: 30),
            // 开发者信息
            ListTile(
              title: Text(AppLocalizations.of(context).developer),
              subtitle: const Text('Swingcoder'),
              leading: const Icon(Icons.code),
            ),
            const Divider(),
            // 联系方式
            const ListTile(
              title: Text('Email'),
              subtitle: Text('swingcoder@gmail.com'),
              leading: Icon(Icons.email),
            ),
            const ListTile(
              title: Text('Website'),
              subtitle: Text('https://www.wukun.info'),
              leading: Icon(Icons.language),
            ),
            const SizedBox(height: 20),
            // 版权信息
            Text(
              AppLocalizations.of(context).copyright,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
