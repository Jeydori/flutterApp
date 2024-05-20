import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:route4me/components/button.dart';
import 'package:route4me/components/text_field.dart';
import 'package:route4me/components/circle_tile.dart';
import 'package:route4me/pages/forgot_page.dart';
import 'package:route4me/services/auth_service.dart';
import 'package:route4me/global/global.dart';

class LoginPage extends StatefulWidget {
  final Function()? onTap;
  const LoginPage({super.key, required this.onTap});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  //text editing controllers
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  //sign user in method
  void logIn() async {
    // show loading circle
    showDialog(
      context: context,
      builder: (context) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );

    // try signing in
    try {
      final userCredential = await firebaseAuth.signInWithEmailAndPassword(
        email: emailController.text,
        password: passwordController.text,
      );

      // fetch user data from "Drivers" collection in Realtime Database
      DatabaseReference userRef = FirebaseDatabase.instance
          .ref()
          .child('Users')
          .child(userCredential.user!.uid);
      DatabaseEvent event = await userRef.once();

      if (event.snapshot.value != null) {
        // User data exists in the database, you can handle it here
        print('User data retrieved: ${event.snapshot.value}');
        // Store user data in global variable or use as needed
      } else {
        throw Exception('User document does not exist');
      }

      //pop the loading circle
      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      //pop the loading circle
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

            //emailfield
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
            //forgotpassword
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
                          builder: (context) {
                            return const ForgotPasswordPage();
                          },
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
            //signIn button
            const SizedBox(height: 15),
            button(
              text: "Log In",
              onTap: logIn,
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
                /*SizedBox(width: 0),
                CircleTile(onTap: () {}, imagePath: 'lib/images/Facebook.png'),*/
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
