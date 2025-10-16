import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_expandable_fab/flutter_expandable_fab.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:lmk/components/buildCard.dart';
import 'package:lmk/components/floatActionButton.dart';
import 'package:lmk/data/repository/post_repo.dart';
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
        elevation: 10,
        type: ExpandableFabType.fan,
        initialOpen: false,
        pos: ExpandableFabPos.right,
        fanAngle: 85,
        distance: 80,
        margin: const EdgeInsets.only(right: 16, bottom: 16),
        openButtonBuilder: RotateFloatingActionButtonBuilder(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.background,
          child: const Icon(Icons.add),
        ),
        closeButtonBuilder: RotateFloatingActionButtonBuilder(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.background,
          child: const Icon(Icons.close),
        ),
        children: [
          FloatingActionButton.small(
            backgroundColor: AppColors.secondary,
            foregroundColor: AppColors.background,
            disabledElevation: 0,
            hoverColor: AppColors.surface,
            heroTag: "fab_photo",
            onPressed: () async {
              // Open gallery to pick image
              await picker("gallery");
            },
            child: const Icon(Icons.photo),
          ),
          FloatingActionButton.small(
            backgroundColor: AppColors.secondary,
            foregroundColor: AppColors.background,
            heroTag: "fab_camera",
            onPressed: () async {
              // Open camera to capture image
              await picker("camera");
            },
            child: const Icon(Icons.camera_alt_outlined),
          ),
        ],
      ),
    );
  }

  Future<void> picker(String source) async {
    try {
      final ImagePicker picker = ImagePicker();
      // Pick an image.
      final XFile? image = await picker.pickImage(
        source: source == "camera" ? ImageSource.camera : ImageSource.gallery,
      );

      if (image == null) {
        buildErrorToast(context);
        return;
      }
      ;
      final img = image.path;
      PostRepository postrepo = PostRepository();
      await postrepo.fetchDocData(img);
    } catch (e) {
      print("Error picking image: $e");
      buildErrorToast(context, source);
    }
  }

  void buildErrorToast(BuildContext context, [String which = '']) {
    final theme = ShadTheme.of(context);
    ShadToaster.of(context).show(
      ShadToast.destructive(
        title: Text(
          which.isNotEmpty
              ? 'Failed to pick from $which'
              : 'Uh oh! Something went wrong',
        ),
        description: Text(
          which.isNotEmpty
              ? 'There was a problem accessing your $which'
              : 'No image was selected',
        ),
        action: ShadButton.destructive(
          decoration: ShadDecoration(
            border: ShadBorder.all(
              color: theme.colorScheme.destructiveForeground,
              width: 1,
            ),
          ),
          onPressed: which.isNotEmpty
              ? () async {
                  ShadToaster.of(context).hide();
                  await picker(which);
                }
              : () {
                  ShadToaster.of(context).hide();
                },
          child: Text(which.isNotEmpty ? 'Try again' : 'Dismiss'),
        ),
      ),
    );
  }
}
