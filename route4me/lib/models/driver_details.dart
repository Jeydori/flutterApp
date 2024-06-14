class DriverDetails {
  final String firstName;
  final String lastName;
  final String email;
  final String carPlate;
  final String carType;

  DriverDetails({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.carPlate,
    required this.carType,
  });

  factory DriverDetails.fromSnapshot(dynamic snapshot) {
    return DriverDetails(
      firstName: snapshot['First Name'] ?? '',
      lastName: snapshot['Last Name'] ?? '',
      email: snapshot['Email'] ?? '',
      carPlate: snapshot['carPlate'] ?? '',
      carType: snapshot['carType'] ?? '',
    );
  }
}
