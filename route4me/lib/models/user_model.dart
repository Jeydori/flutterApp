import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  String firstName;
  String lastName;
  int age;
  String email;
  String uid;

  UserModel({
    required this.firstName,
    required this.lastName,
    required this.age,
    required this.email,
    required this.uid,
  });

  factory UserModel.fromSnapshot(DocumentSnapshot snapshot) {
    Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
    return UserModel(
      firstName: data['First Name'] ?? '',
      lastName: data['Last Name'] ?? '',
      age: data['Age'] ?? 0,
      email: data['Email'] ?? '',
      uid: data['Uid'] ?? '',
    );
  }
}
