// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:exercise6/main.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // 模拟相机列表
    final cameras = await availableCameras();
    final firstCamera = cameras.isNotEmpty ? cameras.first : null;

    // 确保相机可用
    if (firstCamera != null) {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: TakePictureScreen(camera: firstCamera),
        ),
      );
    }

    // 验证 UI 元素
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);
  });
}
