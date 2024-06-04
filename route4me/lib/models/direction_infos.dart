import 'package:google_maps_flutter/google_maps_flutter.dart';

class DirectionDetailsInfo {
  String? e_points;
  String? distance_text;
  int? distance_value;
  String? duration_text;
  int? duration_value;
  String? duration_in_traffic_text;
  int? duration_in_traffic_value;
  List<dynamic>? steps;
  List<TransitInfo>? transitSteps;
  String? fare;

  DirectionDetailsInfo({
    this.e_points,
    this.distance_text,
    this.distance_value,
    this.duration_text,
    this.duration_value,
    this.duration_in_traffic_text,
    this.duration_in_traffic_value,
    this.steps,
    this.transitSteps,
    this.fare,
  });
}

class TransitInfo {
  String? vehicleType;
  String? lineName;
  String? agencyName;
  String? departureStop;
  String? arrivalStop;
  String? departureTime;
  String? arrivalTime;
  LatLng? departureLocation;
  LatLng? arrivalLocation;
  int? numberOfStops;

  TransitInfo({
    this.vehicleType,
    this.lineName,
    this.agencyName,
    this.departureStop,
    this.arrivalStop,
    this.departureTime,
    this.arrivalTime,
    this.departureLocation,
    this.arrivalLocation,
    this.numberOfStops,
  });
}
