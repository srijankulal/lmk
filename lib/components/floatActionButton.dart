import 'package:flutter/material.dart';

/// A reusable floating pill-shaped action panel with optional buttons and a FAB.
///
/// Example usage:
/// ```dart
/// FloatingActionPanel(
///   onAddPressed: () => print("Add pressed"),
///   onMedPressed: () => print("Medicine pressed"),
///   onStatsPressed: () => print("Stats pressed"),
///   onSettingsPressed: () => print("Settings pressed"),
/// )
/// ```
class FloatingActionPanel extends StatelessWidget {
  final VoidCallback? onAddPressed;
  final VoidCallback? onMedPressed;
  final VoidCallback? onStatsPressed;
  final VoidCallback? onSettingsPressed;

  final Color panelColor;
  final Color fabColor;
  final Color iconColor;

  const FloatingActionPanel({
    super.key,
    this.onAddPressed,
    this.onMedPressed,
    this.onStatsPressed,
    this.onSettingsPressed,
    this.panelColor = const Color(0xFF596356), // soft gray-green
    this.fabColor = const Color(0xFFFF4D00), // bright orange
    this.iconColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomCenter,
      clipBehavior: Clip.none,
      children: [
        // Pill bar
        Container(
          margin: const EdgeInsets.only(bottom: 24),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: panelColor,
            borderRadius: BorderRadius.circular(40),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(15),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.medication_outlined),
                color: iconColor,
                onPressed: onMedPressed,
              ),
              IconButton(
                icon: const Icon(Icons.bar_chart_rounded),
                color: iconColor,
                onPressed: onStatsPressed,
              ),
              IconButton(
                icon: const Icon(Icons.tune_rounded),
                color: iconColor,
                onPressed: onSettingsPressed,
              ),
            ],
          ),
        ),

        // Floating Add button
        Positioned(
          bottom: 10,
          right: -20,
          child: FloatingActionButton(
            onPressed: onAddPressed,
            backgroundColor: fabColor,
            shape: const CircleBorder(),
            elevation: 4,
            child: const Icon(Icons.add, color: Colors.black),
          ),
        ),
      ],
    );
  }
}
