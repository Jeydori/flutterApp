import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:route4me/components/drawer_tile.dart';
import 'package:route4me/pages/login_register_page.dart';
import 'package:route4me/pages/settings_page.dart';

class MyDrawer extends StatelessWidget {
  const MyDrawer({super.key});

  void _confirmSignOut(BuildContext context) async {
    final bool confirm = await showDialog(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            title: const Text('Confirm Logout'),
            content: const Text('Are you sure you want to log out?'),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: const BorderSide(color: Colors.orange, width: 2),
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.orange, // Background color
                ),
                child: const Text('Logout'),
              ),
            ],
          ),
        ) ??
        false; // Using ?? false to handle null (when dialog is dismissed)

    if (confirm) {
      FirebaseAuth.instance.signOut();
      GoogleSignIn().signOut();
      GoogleSignIn().disconnect();

      Navigator.of(context).pop(); // Close the success dialog
      Navigator.of(context).popUntil((route) => route.isFirst);
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (context) => const LoginOrRegisterPage()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          // App logo
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 50.0),
              child: Image.asset(
                'lib/images/route4me logo.png',
                height: 260,
                width: 300,
              ),
            ),
          ),
          // Divider
          Padding(
            padding: const EdgeInsets.all(25.0),
            child: Divider(
              color: Colors.orange[600],
            ),
          ),
          // Home list tile
          DrawerTile(
            text: 'H O M E',
            icon: Icons.home,
            onTap: () {
              Navigator.pop(context);
            },
          ),
          // Settings list tile
          DrawerTile(
            text: 'S E T T I N G S',
            icon: Icons.settings,
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsPage(),
                ),
              );
            },
          ),
          // Logout list tile
          DrawerTile(
            text: 'L O G O U T',
            icon: Icons.logout,
            onTap: () => _confirmSignOut(context),
          ),
        ],
      ),
    );
  }
}
