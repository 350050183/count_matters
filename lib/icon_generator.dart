import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

// 一个简单的应用，用于生成应用图标
Future<void> main() async {
  // 确保Flutter初始化
  WidgetsFlutterBinding.ensureInitialized();

  // 创建一个RepaintBoundary
  final RenderRepaintBoundary boundary = RenderRepaintBoundary();

  // 创建一个500x500的图标渲染
  const size = Size(1024, 1024);

  // 创建渲染树
  final RenderView renderView = RenderView(
    window: WidgetsBinding.instance.window,
    child: RenderPositionedBox(
      alignment: Alignment.center,
      child: boundary,
    ),
    configuration: const ViewConfiguration(
      size: size,
      devicePixelRatio: 1.0,
    ),
  );

  // 设置渲染树的布局约束
  final PipelineOwner pipelineOwner = PipelineOwner();
  final BuildOwner buildOwner = BuildOwner();

  pipelineOwner.rootNode = renderView;
  renderView.prepareInitialFrame();

  // 创建一个图标小部件
  final RenderBox icon = RenderConstrainedBox(
    additionalConstraints: BoxConstraints.tight(size),
    child: RenderDecoratedBox(
      decoration: const BoxDecoration(
        color: Colors.blue,
        shape: BoxShape.circle,
      ),
      child: RenderPositionedBox(
        alignment: Alignment.center,
        child: RenderConstrainedBox(
          additionalConstraints:
              BoxConstraints.tight(Size(size.width * 0.5, size.height * 0.5)),
          child: RenderCustomPaint(
            painter: TouchAppIconPainter(Colors.white),
            size: Size(size.width * 0.5, size.height * 0.5),
          ),
        ),
      ),
    ),
  );

  // 将图标添加到边界
  boundary.child = icon;

  // 布局和绘制图标
  pipelineOwner.flushLayout();
  pipelineOwner.flushCompositingBits();
  pipelineOwner.flushPaint();

  // 将渲染树转换为图像
  final ui.Image image = await boundary.toImage(pixelRatio: 1.0);
  final ByteData? byteData =
      await image.toByteData(format: ui.ImageByteFormat.png);

  // 保存图像到文件
  if (byteData != null) {
    final Uint8List pngBytes = byteData.buffer.asUint8List();
    const String path = 'assets/icon/icon.png';
    await File(path).writeAsBytes(pngBytes);
    print('成功生成图标：$path');
  } else {
    print('生成图标失败');
  }

  // 退出应用
  exit(0);
}

// 自定义绘制器，绘制触摸手指图标
class TouchAppIconPainter extends CustomPainter {
  final Color color;

  TouchAppIconPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // 绘制一个手指图标的简化版本
    final path = Path();

    // 绘制手指的轮廓
    path.moveTo(size.width * 0.5, size.height * 0.2);
    path.lineTo(size.width * 0.7, size.height * 0.4);
    path.lineTo(size.width * 0.8, size.height * 0.6);
    path.lineTo(size.width * 0.7, size.height * 0.8);
    path.lineTo(size.width * 0.5, size.height * 0.9);
    path.lineTo(size.width * 0.3, size.height * 0.8);
    path.lineTo(size.width * 0.2, size.height * 0.6);
    path.lineTo(size.width * 0.3, size.height * 0.4);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
