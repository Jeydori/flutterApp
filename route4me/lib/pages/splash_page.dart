import 'package:flutter/material.dart';
import 'dart:async';

import 'package:route4me/pages/auth_page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  startTimer() {
    Timer(const Duration(seconds: 3), () async {
      Navigator.push(
          context, MaterialPageRoute(builder: (c) => const AuthPage()));
    });
  }

  @override
  void initState() {
    super.initState();
    startTimer();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'lib/images/route4me logo.png',
              height: 260,
              width: 300,
            ),
          ],
        ),
      ),
    );
  }
}
