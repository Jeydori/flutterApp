import 'package:flutter/material.dart';
import 'package:route4me/models/user_model.dart';
import 'package:route4me/assistants/assistant_methods.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final ageController = TextEditingController();
  final emailController = TextEditingController();

  UserModel? currentUser;

  @override
  void initState() {
    super.initState();
    // Fetch current user's info when the profile page is initialized
    fetchCurrentUser();
  }

  Future<void> fetchCurrentUser() async {
    try {
      UserModel user = await assistantMethods.readCurrentOnlineUserInfo();
      // Set the initial values for all fields
      setState(() {
        currentUser = user;
        firstNameController.text = user.firstName;
        lastNameController.text = user.lastName;
        ageController.text = user.age.toString();
        emailController.text = user.email;
      });
    } catch (error) {
      print("Failed to fetch user info: $error");
      // Handle error
    }
  }

  Future<void> updateUserInfo() async {
    try {
      if (currentUser != null) {
        final updatedUserModel = UserModel(
          firstName: firstNameController.text,
          lastName: lastNameController.text,
          age: int.tryParse(ageController.text) ?? 0,
          email: emailController.text,
          uid: currentUser!.uid,
        );
        await assistantMethods.updateUserInfo(updatedUserModel);
        // Update local user model with the new information
        setState(() {
          currentUser = updatedUserModel;
        });
        print('User information updated successfully');
      }
    } catch (error) {
      print("Failed to update user information: $error");
      // Handle error
    }
  }

  Future<void> showUserNameDialogAlert(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Update User Information'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(
                  controller: firstNameController,
                  decoration: const InputDecoration(labelText: 'First Name'),
                ),
                TextFormField(
                  controller: lastNameController,
                  decoration: const InputDecoration(labelText: 'Last Name'),
                ),
                TextFormField(
                  controller: ageController,
                  decoration: const InputDecoration(labelText: 'Age'),
                ),
                TextFormField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.red),
              ),
            ),
            TextButton(
              onPressed: () {
                updateUserInfo();
                Navigator.pop(context);
              },
              child: const Text(
                'Ok',
                style: TextStyle(color: Colors.blue),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.orange[600],
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person_outline, size: 80),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: firstNameController,
                  decoration: const InputDecoration(labelText: 'First Name'),
                  readOnly: true,
                ),
                TextFormField(
                  controller: lastNameController,
                  decoration: const InputDecoration(labelText: 'Last Name'),
                  readOnly: true,
                ),
                TextFormField(
                  controller: ageController,
                  decoration: const InputDecoration(labelText: 'Age'),
                  readOnly: true,
                ),
                TextFormField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  readOnly: true,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    showUserNameDialogAlert(context);
                  },
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    backgroundColor: Colors.orange[600],
                  ),
                  child: const Text(
                    'Update Information',
                    style: TextStyle(color: Colors.black),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
