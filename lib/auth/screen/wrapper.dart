import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lmk/auth/screen/sign-in-page.dart';
import 'package:lmk/data/local/user_local.dart';
import 'package:lmk/data/models/local/local_user.dart';
import 'package:lmk/main/home.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserLocal?>(
      future: UserLocalDataSource().getUser(),
      builder: (context, localSnapshot) {
        if (localSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        final localUser = localSnapshot.data;
        if (localUser != null && localUser.uid.isNotEmpty) {
          return const Home();
        }
        return StreamBuilder(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return const Home();
            } else {
              return const SignInPage();
            }
          },
        );
      },
    );
  }
}
