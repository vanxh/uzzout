import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthController extends GetxController {
  final Rx<User?> user = Rx<User?>(null);
  final RxBool isLoading = false.obs;
  final Rx<String?> errorMessage = Rx<String?>(null);

  final _supabase = Supabase.instance.client;

  @override
  void onInit() {
    super.onInit();
    _supabase.auth.onAuthStateChange.listen((data) {
      user.value = data.session?.user;
      update();
    });

    user.value = _supabase.auth.currentUser;
  }

  bool get isAuthenticated => user.value != null;

  Future<AuthResponse?> signInWithGoogle() async {
    try {
      isLoading.value = true;
      errorMessage.value = null;

      final String androidGoogleClientId =
          '1005277075218-dpt6cs3ljjpluuv3rbljd653217vdm15.apps.googleusercontent.com';
      final String iosGoogleClientId =
          '1005277075218-gj933ge0r9r1kof3e8qm3neatevrabah.apps.googleusercontent.com';
      final String webGoogleClientId =
          '1005277075218-mv84uljs7b5cqar8f6muqnqcn6hnjfkn.apps.googleusercontent.com';

      final GoogleSignIn googleSignIn = GoogleSignIn(
        clientId: Platform.isIOS ? iosGoogleClientId : androidGoogleClientId,
        serverClientId: webGoogleClientId,
        scopes: ['email', 'profile'],
      );

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        isLoading.value = false;
        return null;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;

      if (accessToken == null) {
        throw 'No Access Token found.';
      }
      if (idToken == null) {
        throw 'No ID Token found.';
      }

      debugPrint('Signed in: ${googleUser.displayName}');
      debugPrint('Email: ${googleUser.email}');
      debugPrint('ID: ${googleUser.id}');

      final response = await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      return response;
    } catch (error) {
      errorMessage.value = 'Failed to sign in with Google: ${error.toString()}';
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> signOut() async {
    try {
      isLoading.value = true;
      await _supabase.auth.signOut();
    } catch (error) {
      errorMessage.value = 'Failed to sign out: ${error.toString()}';
    } finally {
      isLoading.value = false;
    }
  }
}
