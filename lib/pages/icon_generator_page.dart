import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path/path.dart' as path;

class IconGeneratorPage extends StatefulWidget {
  const IconGeneratorPage({super.key});

  @override
  _IconGeneratorPageState createState() => _IconGeneratorPageState();
}

class _IconGeneratorPageState extends State<IconGeneratorPage> {
  final GlobalKey _globalKey = GlobalKey();
  bool _isSaving = false;
  String _status = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('图标生成器'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 预览图标
            RepaintBoundary(
              key: _globalKey,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  shape: BoxShape.circle,
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // 数字框
                    Container(
                      width: 180,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        "123",
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontSize: 70,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    // 加号按钮
                    Positioned(
                      bottom: 60,
                      left: 95,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.add,
                          size: 30,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                    // 减号按钮
                    Positioned(
                      bottom: 60,
                      right: 95,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.remove,
                          size: 30,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
            // 保存按钮
            ElevatedButton(
              onPressed: _isSaving ? null : _saveIcon,
              child: _isSaving
                  ? const CircularProgressIndicator()
                  : const Text('保存图标'),
            ),
            const SizedBox(height: 10),
            Text(_status),
          ],
        ),
      ),
    );
  }

  Future<void> _saveIcon() async {
    try {
      setState(() {
        _isSaving = true;
        _status = "正在生成图标...";
      });

      // 获取RepaintBoundary的渲染对象
      final RenderRepaintBoundary boundary = _globalKey.currentContext!
          .findRenderObject() as RenderRepaintBoundary;

      // 生成高质量图像 (3.0 pixelRatio确保足够清晰)
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData != null) {
        final Uint8List pngBytes = byteData.buffer.asUint8List();

        // 保存iOS图标文件
        final String iosIconPath = path.join('ios', 'Runner', 'Assets.xcassets',
            'AppIcon.appiconset', 'Icon-App-1024x1024@1x.png');
        await File(iosIconPath).writeAsBytes(pngBytes);

        // 运行图标生成工具来更新所有平台的图标
        await _runIconGenerator();

        setState(() {
          _status = "图标已成功生成并保存到所有平台";
        });
      }
    } catch (e) {
      setState(() {
        _status = "保存失败: $e";
      });
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  Future<void> _runIconGenerator() async {
    try {
      // 运行Flutter启动图标生成工具
      final ProcessResult result = await Process.run(
          'flutter', ['pub', 'run', 'flutter_launcher_icons'],
          runInShell: true);

      if (result.exitCode != 0) {
        setState(() {
          _status += "\n图标生成器错误: ${result.stderr}";
        });
      }

      // 运行启动屏幕生成工具
      final ProcessResult splashResult = await Process.run(
          'flutter', ['pub', 'run', 'flutter_native_splash:create'],
          runInShell: true);

      if (splashResult.exitCode != 0) {
        setState(() {
          _status += "\n启动屏幕生成器错误: ${splashResult.stderr}";
        });
      }
    } catch (e) {
      setState(() {
        _status += "\n运行生成器失败: $e";
      });
    }
  }
}
