import 'package:flutter/material.dart';

import 'icon_generator.dart';

void main() async {
  // 初始化Flutter绑定
  WidgetsFlutterBinding.ensureInitialized();

  // 生成图标
  await IconGenerator.captureAndSaveIcon();

  // 完成后退出
  print('完成图标生成');
}
