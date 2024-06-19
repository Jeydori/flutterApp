import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:route4me/components/button.dart';
import 'package:route4me/components/text_field.dart';
import 'package:route4me/components/circle_tile.dart';
import 'package:route4me/pages/forgot_page.dart';
import 'package:route4me/pages/home_page.dart';
import 'package:route4me/services/auth_service.dart';
import 'package:route4me/global/global.dart';

class LoginPage extends StatefulWidget {
  final Function()? onTap;
  const LoginPage({super.key, required this.onTap});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool _isLoading = false;

  void _showLoading(bool value) {
    if (mounted) {
      setState(() => _isLoading = value);
    }
    if (_isLoading) {
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );
    } else {
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop(); // This should dismiss the loading dialog
      }
    }
  }

  void logIn() async {
    _showLoading(true); // Show loading dialog
    try {
      final userCredential = await firebaseAuth.signInWithEmailAndPassword(
        email: emailController.text,
        password: passwordController.text,
      );

      DatabaseReference userRef = FirebaseDatabase.instance
          .ref()
          .child('Users')
          .child(userCredential.user!.uid);
      DatabaseEvent event = await userRef.once();

      if (event.snapshot.value == null) {
        throw Exception('User document does not exist');
      }

      if (mounted) {
        Navigator.of(context).pushReplacement(MaterialPageRoute(
            builder: (context) => HomePage())); // Navigate to HomePage
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Login Error"),
            content: Text(e.message ?? "Unknown error occurred during login."),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Error"),
            content: Text('An unexpected error occurred: ${e.toString()}'),
          ),
        );
      }
    } finally {
      _showLoading(false); // Always stop the loading when process is complete
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
          child: Center(
        child: SingleChildScrollView(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const SizedBox(height: 50),
            Image.asset(
              'lib/images/route4me logo.png',
              height: 260,
              width: 300,
            ),
            const SizedBox(height: 1),
            textfield(
              controller: emailController,
              hintText: '   Email',
              obscureText: false,
            ),
            const SizedBox(height: 1),
            textfield(
              controller: passwordController,
              hintText: '   Password',
              obscureText: true,
            ),
            const SizedBox(height: 5),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ForgotPasswordPage(),
                        ),
                      );
                    },
                    child: const Text(
                      'Forgot Password?',
                      style: TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 15),
            button(
              text: "Log In",
              onTap: logIn,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Continue with',
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(width: 20),
                CircleTile(
                    onTap: () => AuthService().signInWithGoogle(),
                    imagePath: 'lib/images/Google.png'),
              ],
            ),
            const Divider(thickness: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'No account?',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: widget.onTap,
                  child: const Text(
                    'Register now',
                    style: TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ]),
        ),
      )),
    );
  }
}
