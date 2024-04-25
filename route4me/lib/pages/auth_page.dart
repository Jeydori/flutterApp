import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:route4me/global/global.dart';
import 'package:route4me/pages/home_page.dart';
import 'package:route4me/pages/login_register_page.dart';

class AuthPage extends StatelessWidget {
  const AuthPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: firebaseAuth.authStateChanges(),
        builder: (context, snapshot) {
          //user is logged in
          if (snapshot.hasData) {
            return const HomePage();
          }
          //user is not logged in
          else {
            return const LoginOrRegisterPage();
          }
        },
      ),
    );
  }
}
