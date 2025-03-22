import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path/path.dart' as path;

class IconGenerator {
  static Future<void> captureAndSaveIcon() async {
    // 创建一个1024x1024的图标
    final RenderRepaintBoundary boundary = RenderRepaintBoundary();
    final BuildContext? context = WidgetsBinding.instance.rootElement;
    if (context == null) return;

    // 计数器图标小部件
    final Widget iconWidget = Container(
      width: 1024,
      height: 1024,
      color: Theme.of(context).primaryColor,
      child: Center(
        child: ClipOval(
          child: Container(
            width: 1024,
            height: 1024,
            color: Theme.of(context).primaryColor,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // 数字框
                Container(
                  width: 600,
                  height: 360,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    "123",
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontSize: 240,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // 加号按钮
                Positioned(
                  bottom: 200,
                  left: 324,
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.add,
                      size: 100,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
                // 减号按钮
                Positioned(
                  bottom: 200,
                  right: 324,
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.remove,
                      size: 100,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    // 渲染图标
    final Size size = const Size(1024, 1024);
    final RenderView renderView = WidgetsBinding.instance.renderView;
    final PipelineOwner pipelineOwner = PipelineOwner();
    final RenderObject rootNode = RenderPositionedBox(
      alignment: Alignment.center,
      child: RenderConstrainedBox(
        additionalConstraints: BoxConstraints.tight(size),
        child: boundary,
      ),
    );

    pipelineOwner.rootNode = rootNode;
    rootNode.attach(pipelineOwner);

    final buildOwner = BuildOwner(focusManager: FocusManager());
    final Element rootElement = RenderObjectToWidgetAdapter<RenderBox>(
      container: boundary,
      child: iconWidget,
    ).attachToRenderTree(buildOwner);

    buildOwner.buildScope(rootElement);
    buildOwner.finalizeTree();

    pipelineOwner.flushLayout();
    pipelineOwner.flushCompositingBits();
    pipelineOwner.flushPaint();

    final ui.Image image = await boundary.toImage(pixelRatio: 1.0);
    final ByteData? byteData =
        await image.toByteData(format: ui.ImageByteFormat.png);

    if (byteData != null) {
      final Uint8List pngBytes = byteData.buffer.asUint8List();

      // 保存图标文件
      final String iconPath = path.join('ios', 'Runner', 'Assets.xcassets',
          'AppIcon.appiconset', 'Icon-App-1024x1024@1x.png');
      await File(iconPath).writeAsBytes(pngBytes);

      print('Icon generated and saved to: $iconPath');
    }
  }
}
