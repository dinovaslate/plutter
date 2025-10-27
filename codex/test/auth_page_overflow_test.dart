import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:codex/main.dart';

void main() {
  testWidgets('AuthPage register form stays within bounds on wide layouts',
      (tester) async {
    final binding = tester.binding;
    binding.window.physicalSizeTestValue = const Size(1200, 720);
    binding.window.devicePixelRatioTestValue = 1.0;

    addTearDown(() {
      binding.window.clearPhysicalSizeTestValue();
      binding.window.clearDevicePixelRatioTestValue();
    });

    await tester.pumpWidget(const MaterialApp(home: AuthPage()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('New here? Create an account'));
    await tester.pumpAndSettle(const Duration(milliseconds: 500));

    expect(tester.takeException(), isNull);
  });
}
