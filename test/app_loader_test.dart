import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lmk/components/app_loader.dart';
import 'package:lmk/components/colours/colours.dart';

void main() {
  testWidgets('AppLoader renders SpinKitFadingCube with primary color by default',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AppLoader(),
        ),
      ),
    );

    expect(find.byType(AppLoader), findsOneWidget);
    expect(find.byType(SpinKitFadingCube), findsOneWidget);

    final cube = tester.widget<SpinKitFadingCube>(find.byType(SpinKitFadingCube));
    expect(cube.color, AppColors.primary);
    expect(cube.size, 25.0);
  });

  testWidgets('AppLoader supports custom size and color', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AppLoader(
            size: 16.0,
            color: Colors.white,
          ),
        ),
      ),
    );

    final cube = tester.widget<SpinKitFadingCube>(find.byType(SpinKitFadingCube));
    expect(cube.color, Colors.white);
    expect(cube.size, 16.0);
  });
}
