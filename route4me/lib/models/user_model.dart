import 'package:firebase_database/firebase_database.dart';

class UserModel {
  String? firstName;
  String? lastName;
  int? age;
  String? email;

  UserModel({
    this.firstName,
    this.lastName,
    this.age,
    this.email,
  });
  UserModel.forSnapshot(DataSnapshot snap) {
    firstName = (snap.value as dynamic)['First Name'];
    lastName = (snap.value as dynamic)['Last Name'];
    age = (snap.value as dynamic)['Age'];
    email = (snap.value as dynamic)['Email'];
  }
}
