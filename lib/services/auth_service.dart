import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 1. Sign Up (Updated to send Verification Email)
  Future<String?> signUp({required String email, required String password, required String fullName}) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = result.user;

      // Update the name
      await user?.updateDisplayName(fullName);

      // NEW: Send Verification Email immediately
      await user?.sendEmailVerification();

      return null; // Success
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return "An unknown error occurred";
    }
  }

  // 2. Sign In
  Future<String?> signIn({required String email, required String password}) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(email: email, password: password);

      // Optional: Check if they verified their email before letting them in
      if (!result.user!.emailVerified) {
        // You can choose to block them, or just let them in.
        // For now, let's just return null (Success).
      }

      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return "An unknown error occurred";
    }
  }

  // 3. Sign Out
  Future<void> signOut() async {
    await _auth.signOut();
  }
}