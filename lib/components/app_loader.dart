import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:lmk/components/colours/colours.dart';

/// The official signature loading animation for LMK app.
/// Uses SpinKitFadingCube with tailored app primary colors.
class AppLoader extends StatelessWidget {
  final double size;
  final Color? color;

  const AppLoader({
    super.key,
    this.size = 25.0,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SpinKitFadingCube(
        color: color ?? AppColors.primary,
        size: size,
      ),
    );
  }
}
