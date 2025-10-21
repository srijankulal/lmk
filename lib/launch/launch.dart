import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../main/home.dart';

class Launch extends StatelessWidget {
  const Launch({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Launch Screen',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          IconButton(
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.all(Colors.blue),
              foregroundColor: WidgetStateProperty.all(Colors.white),
              padding: WidgetStateProperty.all(
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              textStyle: WidgetStateProperty.all(
                const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            icon: Icon(Icons.arrow_circle_right_rounded),

            onPressed: () {
              FirebaseAuth.instance.currentUser;
              if (FirebaseAuth.instance.currentUser == null) {
                Navigator.pushReplacementNamed(context, '/signIn');
                return;
              }
              Navigator.pushReplacementNamed(context, '/home');
            },
          ),
        ],
      ),
    );
  }
}
