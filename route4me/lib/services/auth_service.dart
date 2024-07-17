import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  // Google Sign In
  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? gUser = await GoogleSignIn().signIn();
      if (gUser == null) {
        print("Google sign-in was aborted.");
        return null;
      }
      final GoogleSignInAuthentication gAuth = await gUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: gAuth.accessToken,
        idToken: gAuth.idToken,
      );
      return await _firebaseAuth.signInWithCredential(credential);
    } catch (error) {
      print("Error during Google sign-in: $error");
      throw error; // Or handle this error appropriately in your app
    }
  }

  // Register with Email and Password
  Future<User?> registerWithEmailPassword(String email, String password) async {
    try {
      UserCredential userCredential = await _firebaseAuth
          .createUserWithEmailAndPassword(email: email, password: password);
      User? user = userCredential.user;
      user?.sendEmailVerification();
      return user;
    } catch (e) {
      print("Error in registering user: $e");
      return null;
    }
  }

  // Check if email is verified
  Future<bool> isEmailVerified() async {
    User? user = _firebaseAuth.currentUser;
    return user?.emailVerified ?? false;
  }

  // Sign in with Email and Password
  Future<User?> signInWithEmailPassword(String email, String password) async {
    try {
      UserCredential userCredential = await _firebaseAuth
          .signInWithEmailAndPassword(email: email, password: password);
      User? user = userCredential.user;
      if (user != null && !user.emailVerified) {
        throw FirebaseAuthException(
            code: "email-not-verified",
            message: "Please verify your email first.");
      }
      return user;
    } catch (e) {
      print("Error during sign-in: $e");
      return null;
    }
  }
}
