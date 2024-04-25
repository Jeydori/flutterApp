import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:route4me/components/button.dart';
import 'package:route4me/components/text_field.dart';
import 'package:route4me/global/global.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final emailController = TextEditingController();

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  Future passwordReset() async {
    // show loading circle
    showDialog(
      context: context,
      builder: (context) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );

    try {
      await firebaseAuth.sendPasswordResetEmail(
          email: emailController.text.trim());
      Navigator.pop(context);
      // If no exception is thrown, show a success message
      showDialog(
          context: context,
          builder: (context) {
            return const AlertDialog(
              content: Text(
                  textAlign: TextAlign.center,
                  'Password reset link was sent successfully, you can now set a new password and go back to the login page'),
            );
          });
    } on FirebaseAuthException catch (e) {
      Navigator.pop(context);

      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            content: Text(e.message.toString()),
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.orange[600],
        elevation: 0,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'lib/images/route4me icon lang.jpg',
            height: 100,
            width: 100,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 25.0),
            child: Text(
              'Enter your email and wait for the password reset link!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20),
            ),
          ),
          //emailfield
          const SizedBox(height: 10),
          textfield(
            controller: emailController,
            hintText: '   Email',
            obscureText: false,
          ),
          //reset pass button
          const SizedBox(height: 10),
          button(
            text: "Reset Password",
            onTap: passwordReset,
          ),
        ],
      ),
    );
  }
}
