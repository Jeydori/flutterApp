import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:route4me/firebase_options.dart';
import 'package:route4me/info%20handler/app_info.dart';
import 'package:route4me/pages/auth_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const route4me());
}

class route4me extends StatelessWidget {
  const route4me({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => appInfo(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Route4Me',
        home: AuthPage(),
      ),
    );
  }
}