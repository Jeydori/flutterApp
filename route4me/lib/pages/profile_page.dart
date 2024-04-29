import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:route4me/global/global.dart';
import 'package:route4me/models/user_model.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final ageController = TextEditingController();
  final emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Fetch current user's info when the profile page is initialized
    readCurrentOnlineUserInfo();
  }

  Future<void> readCurrentOnlineUserInfo() async {
    try {
      final currentUser = firebaseAuth.currentUser;
      if (currentUser != null) {
        final userRef =
            FirebaseFirestore.instance.collection('Users').doc(currentUser.uid);

        DocumentSnapshot doc = await userRef.get();

        if (doc.exists) {
          // Update user model with fetched data
          setState(() {
            userModelCurrentInfo = UserModel.fromSnapshot(doc);
            // Set the initial values for all fields
            firstNameController.text = userModelCurrentInfo!.firstName;
            lastNameController.text = userModelCurrentInfo!.lastName;
            ageController.text = userModelCurrentInfo!.age.toString();
            emailController.text = userModelCurrentInfo!.email;
          });
          print('User info retrieved: $userModelCurrentInfo');
        } else {
          throw Exception('User document does not exist');
        }
      } else {
        throw Exception('Current user is null');
      }
    } catch (error) {
      print("Failed to get user info: $error");
      // Handle error
    }
  }

  Future<void> showUserNameDialogAlert(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Update User Information'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(
                  controller: firstNameController,
                  decoration: InputDecoration(labelText: 'First Name'),
                ),
                TextFormField(
                  controller: lastNameController,
                  decoration: InputDecoration(labelText: 'Last Name'),
                ),
                TextFormField(
                  controller: ageController,
                  decoration: InputDecoration(labelText: 'Age'),
                ),
                TextFormField(
                  controller: emailController,
                  decoration: InputDecoration(labelText: 'Email'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.red),
              ),
            ),
            TextButton(
              onPressed: () {
                // Implement the logic to update user information in Firestore
                updateUserInfo();
                Navigator.pop(context);
              },
              child: Text(
                'Ok',
                style: TextStyle(color: Colors.blue),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> updateUserInfo() async {
    try {
      final currentUser = firebaseAuth.currentUser;
      if (currentUser != null) {
        final userRef =
            FirebaseFirestore.instance.collection('Users').doc(currentUser.uid);

        await userRef.update({
          'First Name': firstNameController.text,
          'Last Name': lastNameController.text,
          'Age': int.tryParse(ageController.text) ?? 0,
          'Email': emailController.text,
        });

        // Update local user model with the new information
        setState(() {
          userModelCurrentInfo!.firstName = firstNameController.text;
          userModelCurrentInfo!.lastName = lastNameController.text;
          userModelCurrentInfo!.age = int.tryParse(ageController.text) ?? 0;
          userModelCurrentInfo!.email = emailController.text;
        });

        print('User information updated successfully');
      } else {
        throw Exception('Current user is null');
      }
    } catch (error) {
      print("Failed to update user information: $error");
      // Handle error
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          leading: IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: Icon(
              Icons.arrow_back_ios_new,
              color: Colors.black,
            ),
          ),
          title: Text(
            'Profile',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        body: Center(
          child: Padding(
            padding: EdgeInsets.fromLTRB(30, 30, 30, 50),
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.all(50),
                  decoration: BoxDecoration(
                    color: Colors.orange[600],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.person_outline, size: 80),
                ),
                SizedBox(height: 30),
                // Text form fields for user information
                TextFormField(
                  controller: firstNameController,
                  style: TextStyle(color: Colors.black),
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'First Name',
                    labelStyle: TextStyle(color: Colors.black),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.black),
                    ),
                  ),
                ),
                TextFormField(
                  controller: lastNameController,
                  style: TextStyle(color: Colors.black),
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'Last Name',
                    labelStyle: TextStyle(color: Colors.black),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.black),
                    ),
                  ),
                ),
                TextFormField(
                  controller: ageController,
                  style: TextStyle(color: Colors.black),
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'Age',
                    labelStyle: TextStyle(color: Colors.black),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.black),
                    ),
                  ),
                ),
                TextFormField(
                  controller: emailController,
                  style: TextStyle(color: Colors.black),
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    labelStyle: TextStyle(color: Colors.black),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.black),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    showUserNameDialogAlert(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange[600],
                  ),
                  child: Text(
                    'Edit Information',
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
