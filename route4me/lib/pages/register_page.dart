import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:route4me/components/button.dart';
import 'package:route4me/components/text_field.dart';
import 'package:route4me/components/circle_tile.dart';
import 'package:route4me/pages/home_page.dart';
import 'package:route4me/services/auth_service.dart';

class RegisterPage extends StatefulWidget {
  final Function()? onTap;
  const RegisterPage({super.key, required this.onTap});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  //text editing controllers
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final ageController = TextEditingController();

  Timer? _timer;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    firstNameController.dispose();
    lastNameController.dispose();
    ageController.dispose();
    super.dispose();
  }

  //sign user up method
  void signUp() {
    if (passwordController.text == confirmPasswordController.text) {
      // Use AuthService to register the user
      var authService = AuthService();
      authService
          .registerWithEmailPassword(
        emailController.text.trim(),
        passwordController.text.trim(),
      )
          .then((user) {
        if (user != null) {
          // User has been created and verification email sent
          addUserDetails(
            firstNameController.text.trim(),
            lastNameController.text.trim(),
            int.parse(ageController.text.trim()),
            emailController.text.trim(),
            user.uid,
          ).then((_) {
            // Show a dialog asking the user to verify their email
            showDialog(
              context: context,
              barrierDismissible: false, // Prevent dialog from being dismissed
              builder: (context) {
                _startEmailVerificationCheck();
                return AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: const BorderSide(color: Colors.orange, width: 2),
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Registration successful! Please verify your email and wait a moment.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.black),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          user.sendEmailVerification().then((_) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text("Verification email sent")),
                            );
                          }).catchError((error) {
                            print("Failed to send verification email: $error");
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.black,
                          backgroundColor: Colors.white,
                          side:
                              const BorderSide(color: Colors.orange, width: 2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text("Resend Verification Email"),
                      ),
                    ],
                  ),
                );
              },
            );
          }).catchError((error) {
            print("Failed to add user details: $error");
          });
        } else {
          // Show an error message if registration failed
          showDialog(
            context: context,
            builder: (context) {
              return const AlertDialog(
                content: Text(
                  textAlign: TextAlign.center,
                  'Failed to register. Please try again.',
                ),
              );
            },
          );
        }
      }).catchError((error) {
        print("Registration failed: $error");
        // Handle registration error
      });
    } else {
      // Show error if passwords do not match
      showDialog(
        context: context,
        builder: (context) {
          return const AlertDialog(
            content: Text(
              textAlign: TextAlign.center,
              'Passwords do not match!',
            ),
          );
        },
      );
    }
  }

  Future<void> addUserDetails(String firstName, String lastName, int age,
      String email, String uid) async {
    DatabaseReference userRef =
        FirebaseDatabase.instance.ref().child("Users").child(uid);
    await userRef.set({
      'First Name': firstName,
      'Last Name': lastName,
      'Age': age,
      'Email': email,
      'Uid': uid,
    }).then((_) {
      print("User added with ID: $uid");
    }).catchError((error) {
      print("Failed to add user: $error");
    });
  }

  void _startEmailVerificationCheck() {
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      FirebaseAuth.instance.currentUser?.reload().then((_) {
        User? user = FirebaseAuth.instance.currentUser;
        if (user != null && user.emailVerified) {
          _timer?.cancel();
          Navigator.of(context).pop(); // Close the dialog
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomePage()),
          );
        }
      }).catchError((error) {
        print("Error reloading user: $error");
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
          child: Center(
        child: SingleChildScrollView(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const SizedBox(height: 10),
            Image.asset(
              'lib/images/route4me logo.png',
              height: 100,
              width: 100,
            ),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Register below with your details!',
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.black,
                    fontStyle: FontStyle.normal,
                  ),
                ),
              ],
            ),
            //first name textfield
            const SizedBox(height: 1),
            textfield(
              controller: firstNameController,
              hintText: '   First Name',
              obscureText: false,
            ),
            //last name textfield
            const SizedBox(height: 1),
            textfield(
              controller: lastNameController,
              hintText: '   Last Name',
              obscureText: false,
            ),
            //age textfield
            const SizedBox(height: 1),
            textfield(
              controller: ageController,
              hintText: '   Age',
              obscureText: false,
            ),
            //email textfield
            const SizedBox(height: 1),
            textfield(
              controller: emailController,
              hintText: '   Email',
              obscureText: false,
            ),
            //passwordfield
            const SizedBox(height: 1),
            textfield(
              controller: passwordController,
              hintText: '   Password',
              obscureText: true,
            ),
            //confirmpasswordfield
            const SizedBox(height: 1),
            textfield(
              controller: confirmPasswordController,
              hintText: '   Confirm Password',
              obscureText: true,
            ),

            //signUp button
            const SizedBox(height: 15),
            button(
              text: "Sign Up",
              onTap: signUp,
            ),
            //divider
            const SizedBox(height: 20),

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
                  'Already have an account?',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: widget.onTap,
                  child: const Text(
                    'Login now',
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
