import 'package:flutter/material.dart';
import 'package:lmk/data/models/post/post.dart';
import 'package:lmk/main/home.dart';
import 'package:lmk/presentation/dataFrom.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'launch/launch.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ShadApp(
      darkTheme: ShadThemeData(
        brightness: Brightness.dark,
        colorScheme: const ShadSlateColorScheme.dark(),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const Launch(),
        '/home': (context) => const Home(),
        '/docForm': (context) => DocForm(),
       
      },
    );
  }
}
