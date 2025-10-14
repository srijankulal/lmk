import 'package:flutter/material.dart';
import 'package:flutter_expandable_fab/flutter_expandable_fab.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:lmk/components/buildCard.dart';
import 'package:lmk/components/floatActionButton.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:lmk/components/avatar_card.dart';
import 'package:lmk/components/colours/colours.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

final List<Reminder> reminders = [
  // Reminder(
  //   title: "Car Insurance",
  //   subtitle: "Renew before policy expires",
  //   time: "10 Nov",
  //   color: AppColors.secondary,
  // ),
  // Reminder(
  //   title: "Emission Test",
  //   subtitle: "Expires in 5 days",
  //   time: "18 Oct",
  //   color: AppColors.accent,
  // ),
  // Reminder(
  //   title: "Health Insurance",
  //   subtitle: "Next renewal due",
  //   time: "01 Jan",
  //   color: AppColors.surface,
  // ),
  // Reminder(
  //   title: "Car Insurance",
  //   subtitle: "Renew before policy expires",
  //   time: "10 Nov",
  //   color: AppColors.secondary,
  // ),
  // Reminder(
  //   title: "Emission Test",
  //   subtitle: "Expires in 5 days",
  //   time: "18 Oct",
  //   color: AppColors.accent,
  // ),
  // Reminder(
  //   title: "Health Insurance",
  //   subtitle: "Next renewal due",
  //   time: "01 Jan",
  //   color: AppColors.surface,
  // ),
  // Reminder(
  //   title: "Health Insurance",
  //   subtitle: "Next renewal due",
  //   time: "01 Jan",
  //   color: AppColors.surface,
  // ),
  // Reminder(
  //   title: "Emission Test",
  //   subtitle: "Expires in 5 days",
  //   time: "18 Oct",
  //   color: AppColors.accent,
  // ),
  // Reminder(
  //   title: "Health Insurance",
  //   subtitle: "Next renewal due",
  //   time: "01 Jan",
  //   color: AppColors.surface,
  // ),
  // Reminder(
  //   title: "Health Insurance",
  //   subtitle: "Next renewal due",
  //   time: "01 Jan",
  //   color: AppColors.surface,
  // ),
  // Reminder(
  //   title: "Emission Test",
  //   subtitle: "Expires in 5 days",
  //   time: "18 Oct",
  //   color: AppColors.accent,
  // ),
  // Reminder(
  //   title: "Health Insurance",
  //   subtitle: "Next renewal due",
  //   time: "01 Jan",
  //   color: AppColors.surface,
  // ),
  // Reminder(
  //   title: "Health Insurance",
  //   subtitle: "Next renewal due",
  //   time: "01 Jan",
  //   color: AppColors.surface,
  // ),
  // Reminder(
  //   title: "Emission Test",
  //   subtitle: "Expires in 5 days",
  //   time: "18 Oct",
  //   color: AppColors.accent,
  // ),
  // Reminder(
  //   title: "Health Insurance",
  //   subtitle: "Next renewal due",
  //   time: "01 Jan",
  //   color: AppColors.surface,
  // ),
  // Reminder(
  //   title: "Health Insurance",
  //   subtitle: "Next renewal due",
  //   time: "01 Jan",
  //   color: AppColors.surface,
  // ),
];

class _HomeState extends State<Home> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top Section (remains the same)
            ScaleTransition(
              scale: _animation,
              child: Container(
                color: AppColors.surfaceDark,
                padding: const EdgeInsets.only(bottom: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 22),
                    AvatarCard(
                      name: "John Doe",
                      imageUrl: "https://avatar.iran.liara.run/public/41",
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 20.0, top: 16.0),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Your stuffs.",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Transform.translate(
                // Move the card list up to overlap the dark header slightly
                offset: const Offset(0, -24),
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),

                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        offset: Offset(0, -5),
                      ),
                    ],
                  ),
                  child: BuildCard(reminders: reminders),
                ),
              ),
            ),
            // ------------------------------------------------------------------
          ],
        ),
      ),

      floatingActionButtonLocation: ExpandableFab.location,

      floatingActionButton: ExpandableFab(
        type: ExpandableFabType.fan,
        initialOpen: false,
        pos: ExpandableFabPos.right,
        distance: 80,
        openButtonBuilder: RotateFloatingActionButtonBuilder(
          child: const Icon(Icons.add),
        ),
        closeButtonBuilder: RotateFloatingActionButtonBuilder(
          child: const Icon(Icons.close),
        ),
        children: [
          FloatingActionButton.small(
            heroTag: "fab_camera",
            onPressed: () {},
            child: const Icon(Icons.camera_alt_outlined),
          ),
          FloatingActionButton.small(
            heroTag: "fab_photo",
            onPressed: () {},
            child: const Icon(Icons.photo),
          ),
        ],
      ),
    );
  }
}
