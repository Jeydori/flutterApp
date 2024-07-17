import 'package:firebase_database/firebase_database.dart';

class UserModel {
  String firstName;
  String lastName;
  int age;
  String email;
  String uid;
  String? profileImageUrl;

  UserModel({
    required this.firstName,
    required this.lastName,
    required this.age,
    required this.email,
    required this.uid,
    this.profileImageUrl,
  });

  factory UserModel.fromSnapshot(DataSnapshot snapshot) {
    Map<String, dynamic> data = snapshot.value as Map<String, dynamic>;
    return UserModel(
      firstName: data['First Name'] ?? '',
      lastName: data['Last Name'] ?? '',
      age: data['Age'] ?? 0,
      email: data['Email'] ?? '',
      uid: data['Uid'] ?? '',
      profileImageUrl: data['Profile Image URL'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'First Name': firstName,
      'Last Name': lastName,
      'Age': age,
      'Email': email,
      'Uid': uid,
      'Profile Image URL': profileImageUrl,
    };
  }
}