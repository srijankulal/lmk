import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:lmk/launch/launch.dart';

class AuthMethods {
  final FirebaseAuth auth = FirebaseAuth.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  static bool isInitialize = false;
  static Future<void> initSignIn() async {
    if (!isInitialize) {
      await _googleSignIn.initialize(
        serverClientId:
            '640860070869-2mfc4kpoebpstf39834f4s7qr4ltgmd1.apps.googleusercontent.com',
      );
    }
    isInitialize = true;
  }

  Future<UserCredential?> signInWithGoogle(BuildContext context) async {
    try {
      final googleSignIn = GoogleSignIn.instance;

      // Must initialize (v7.x)
      await googleSignIn.initialize();

      // Authenticate / sign in
      final GoogleSignInAccount? googleUser = await googleSignIn.authenticate();
      if (googleUser == null) {
        // user cancelled sign in
        return null;
      }

      // Get idToken
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final String? idToken = googleAuth.idToken;
      if (idToken == null) {
        throw FirebaseAuthException(
          code: "ERROR_MISSING_ID_TOKEN",
          message: "Missing Google ID Token",
        );
      }

      // Get accessToken via authorizationClient for scopes
      const List<String> scopes = ['email', 'profile', 'openid'];
      GoogleSignInClientAuthorization? authorization = await googleUser
          .authorizationClient
          .authorizationForScopes(scopes);

      // If not yet granted, request scopes (UI)
      if (authorization?.accessToken == null) {
        authorization = await googleUser.authorizationClient.authorizeScopes(
          scopes,
        );
        if (authorization.accessToken == null) {
          throw FirebaseAuthException(
            code: "ERROR_MISSING_ACCESS_TOKEN",
            message: "User did not grant required permissions",
          );
        }
      }

      final String accessToken = authorization!.accessToken;
      final String name = googleUser.displayName ?? "No Name";
      print("Google Sign-In successful: $name");
      final String email = googleUser.email;
      print("Google Sign-In email: $email");
      final String photoUrl = googleUser.photoUrl ?? "";
      print("Google Sign-In photoUrl: $photoUrl");

      // Create credential for Firebase
      final credential = GoogleAuthProvider.credential(
        idToken: idToken,
        accessToken: accessToken,
      );

      final UserCredential userCredential = await FirebaseAuth.instance
          .signInWithCredential(credential);

      final User? user = userCredential.user;

      if (user != null) {
        final userDetails = {
          "Name": user.displayName,
          "Email": user.email,
          "Id": user.uid,
          "Image": user.photoURL ?? "<some default url>",
        };
        print("User details: $userDetails");
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => Launch()),
        );
      }

      return userCredential;
    } on GoogleSignInException catch (e) {
      print("GoogleSignInException: ${e.code} — ${e.description}");
      rethrow;
    } catch (e) {
      print("Error during Google Sign-In: $e");
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await auth.signOut();
    
  }
}
