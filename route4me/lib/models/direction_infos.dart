import 'package:google_maps_flutter/google_maps_flutter.dart';

class DirectionDetailsInfo {
  String? e_points;
  String? distance_text;
  double distance_value;
  String? duration_text;
  int? duration_value;
  String? duration_in_traffic_text;
  int? duration_in_traffic_value;
  List<dynamic>? steps;
  List<TransitInfo>? transitSteps;
  String? fare;
  double? destinationLatitude; // Added for destination latitude
  double? destinationLongitude; // Added for destination longitude

  DirectionDetailsInfo({
    this.e_points,
    this.distance_text,
    required this.distance_value,
    this.duration_text,
    this.duration_value,
    this.duration_in_traffic_text,
    this.duration_in_traffic_value,
    this.steps,
    this.transitSteps,
    this.fare,
    this.destinationLatitude, // Initialize in constructor
    this.destinationLongitude,
  });
}

class TransitInfo {
  final String? vehicleType;
  final String? lineName;
  final String? agencyName;
  final String? departureStop;
  final String? arrivalStop;
  final String? departureTime;
  final String? arrivalTime;
  final LatLng departureLocation;
  final LatLng? arrivalLocation;
  final int? numberOfStops;

  TransitInfo({
    this.vehicleType,
    this.lineName,
    this.agencyName,
    this.departureStop,
    this.arrivalStop,
    this.departureTime,
    this.arrivalTime,
    required this.departureLocation,
    this.arrivalLocation,
    this.numberOfStops,
  });
}
