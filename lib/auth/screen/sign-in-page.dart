import 'package:flutter/material.dart';
import 'package:lmk/auth/services/google_auth.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            AuthMethods().signInWithGoogle(context);
            // Implement sign-in logic here
          },
          child: const Text('Sign in with Google'),
        ),
      ),
    );
  }
}
