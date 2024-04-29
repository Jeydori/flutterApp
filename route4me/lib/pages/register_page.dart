import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:route4me/components/button.dart';
import 'package:route4me/components/text_field.dart';
import 'package:route4me/components/circle_tile.dart';
import 'package:route4me/global/global.dart';
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
  void signUp() async {
    try {
      Future<void> addUserDetails(String firstName, String lastName, int age,
          String email, String uid) async {
        await FirebaseFirestore.instance.collection("Users").doc(uid).set({
          'First Name': firstName,
          'Last Name': lastName,
          'Age': age,
          'Email': email,
          'Uid': uid,
        }).then((_) {
          print("Document added with ID: $uid");
        }).catchError((error) {
          print("Failed to add user: $error");
        });
      }

      //check if password is confirmed
      if (passwordController.text == confirmPasswordController.text) {
        //create user
        UserCredential userCredential =
            await firebaseAuth.createUserWithEmailAndPassword(
                email: emailController.text, password: passwordController.text);

        // Get the UID of the newly created user
        String uid = userCredential.user!.uid;

        //add user details
        addUserDetails(
          firstNameController.text.trim(),
          lastNameController.text.trim(),
          int.parse(ageController.text.trim()),
          emailController.text.trim(),
          uid,
        );
        //if no exception were thrown
        showDialog(
            context: context,
            builder: (context) {
              return const AlertDialog(
                content: Text(
                    textAlign: TextAlign.center, 'You have been registered!'),
              );
            });
      } else {
        //show error message that passwords don't match
        showDialog(
            context: context,
            builder: (context) {
              return const AlertDialog(
                content:
                    Text(textAlign: TextAlign.center, 'Password don\'t match!'),
              );
            });
      }
    } on FirebaseAuthException catch (e) {
      // show the error code
      showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              content: Text(
                textAlign: TextAlign.center,
                e.message.toString(),
              ),
            );
          });
    }
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
              'lib/images/route4me text lang.png',
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
