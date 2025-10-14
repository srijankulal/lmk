import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:flutter/material.dart';
import 'package:lmk/components/colours/colours.dart';

class AvatarCard extends StatelessWidget {
  const AvatarCard({super.key, required this.name, required this.imageUrl});

  final String name;
  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          ShadAvatar(
            imageUrl,
            placeholder: const Icon(Icons.person_2),
            size: Size(60, 60),
          ),
          const SizedBox(width: 26),
          Text(
            "Hello, ",
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            name,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textOnPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
