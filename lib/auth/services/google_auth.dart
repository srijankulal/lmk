import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:lmk/components/colours/colours.dart';
import 'package:lmk/data/local/user_local.dart';
import 'package:lmk/data/models/local/local_user.dart';
import 'package:lmk/launch/launch.dart';
import 'package:lmk/data/repository/userRegister.dart';
import 'package:lmk/services/sync_service.dart';

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
      }

      final String accessToken = authorization!.accessToken;
      final String name = googleUser.displayName ?? "No Name";
      print("Google Sign-In successful: $name");
      final String email = googleUser.email;
      print("Google Sign-In email: $email");
      final String photoUrl = googleUser.photoUrl ?? "";
      print("Google Sign-In photoUrl: $photoUrl");
      final loading = SpinKitFadingCube(color: AppColors.primary, size: 25.0);
      // Create credential for Firebase
      final credential = GoogleAuthProvider.credential(
        idToken: idToken,
        accessToken: accessToken,
      );

      final UserCredential userCredential = await FirebaseAuth.instance
          .signInWithCredential(credential);

      final User? user = userCredential.user;

      if (user != null) {
        // This is a new user registration flow.
        // For existing users, this might be redundant.
        // You might want to check if the user is new.
        // final bool isNewUser = userCredential.additionalUserInfo?.isNewUser ?? false;
        // if (isNewUser) {
        final userDetails = {
          "name": user.displayName ?? "No Name",
          "email": user.email,
          "uid": user.uid,
          "profileUrl": user.photoURL ?? "",
        };
        print("User details for registration: $userDetails");

        final String? idTokenFirebase = await user.getIdToken();
        if (idTokenFirebase != null) {
          // Show loading while registering/saving
          if (context.mounted) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (_) => Center(child: loading),
            );
          }
          try {
            await UserRegister().registerUser(idTokenFirebase, userDetails);
            print("User registered on backend successfully.");
            final details = UserLocal()
              ..uid = user.uid
              ..name = user.displayName ?? "No Name"
              ..photoUrl = user.photoURL ?? "";
            UserLocalDataSource().saveUser(details);
            print("User details saved locally: $details");

            // ✅ SYNC DOWN: Fetch reminders from cloud and populate local DB
            print("Starting initial sync...");
            await SyncService().syncDown();
            print("Initial sync completed.");
          } catch (e) {
            print("Error registering user on backend: $e");
          } finally {
            if (context.mounted && Navigator.canPop(context)) {
              Navigator.pop(context); // dismiss loading
            }
          }
        }
        if (!context.mounted) {
          print("Context is not mounted, cannot navigate.");
          return userCredential;
        }
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => Launch()),
        );
        return userCredential;
      }
      return null;
    } on GoogleSignInException catch (e) {
      print("GoogleSignInException: ${e.code} — ${e.description}");
      rethrow;
    } catch (e) {
      print("Error during Google Sign-In: $e");
      rethrow;
    }
  }

  Future<void> signInAsGuest(BuildContext context, {required String name}) async {
    try {
      String guestUid = "guest_${DateTime.now().millisecondsSinceEpoch}";
      try {
        final anonCred = await auth.signInAnonymously();
        if (anonCred.user != null) {
          guestUid = anonCred.user!.uid;
        }
      } catch (e) {
        print('Firebase anonymous auth not configured or offline: $e');
      }

      final details = UserLocal()
        ..uid = guestUid
        ..name = name.trim().isNotEmpty ? name.trim() : "Guest"
        ..guest = true;
      await UserLocalDataSource().saveUser(details);

      if (!context.mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
    } catch (e) {
      print('Guest sign-in error: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    try {
      await auth.signOut();
    } catch (_) {}
    await UserLocalDataSource().clearUser();
  }
}
