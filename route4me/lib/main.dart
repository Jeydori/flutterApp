import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:route4me/firebase_options.dart';
import 'package:route4me/info%20handler/app_info.dart';
import 'package:route4me/pages/splash_page.dart';

// Ensure this file is properly saved and there are no typos in file names or paths
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

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
        navigatorKey: navigatorKey, // Correct usage
        home: SplashPage(),
      ),
    );
  }
}
