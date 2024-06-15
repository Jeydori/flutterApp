import 'package:google_maps_flutter/google_maps_flutter.dart';

class DirectionDetailsInfo {
  String? e_points;
  String? distance_text;
  double distance_value;
  String duration_text;
  int? duration_value;
  String? duration_in_traffic_text;
  int? duration_in_traffic_value;
  List<dynamic>? steps;
  List<TransitInfo>? transitSteps;
  double? destinationLatitude;
  double? destinationLongitude;

  DirectionDetailsInfo({
    this.e_points,
    this.distance_text,
    required this.distance_value,
    required this.duration_text,
    this.duration_value,
    this.duration_in_traffic_text,
    this.duration_in_traffic_value,
    this.steps,
    this.transitSteps,
    this.destinationLatitude,
    this.destinationLongitude,
  });

  Map<String, dynamic> toJson() {
    return {
      'e_points': e_points,
      'distance_text': distance_text,
      'distance_value': distance_value,
      'duration_text': duration_text,
      'duration_value': duration_value,
      'duration_in_traffic_text': duration_in_traffic_text,
      'duration_in_traffic_value': duration_in_traffic_value,
      'steps': steps,
      'transitSteps': transitSteps?.map((t) => t.toJson()).toList(),
      'destinationLatitude': destinationLatitude,
      'destinationLongitude': destinationLongitude,
    };
  }
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
  final double? fare;
  final String? distanceText;

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
    this.fare,
    this.distanceText,
  });

  Map<String, dynamic> toJson() {
    return {
      'vehicleType': vehicleType,
      'lineName': lineName,
      'agencyName': agencyName,
      'departureStop': departureStop,
      'arrivalStop': arrivalStop,
      'departureTime': departureTime,
      'arrivalTime': arrivalTime,
      'departureLocation': {
        'lat': departureLocation.latitude,
        'lng': departureLocation.longitude,
      },
      'arrivalLocation': {
        'lat': arrivalLocation?.latitude,
        'lng': arrivalLocation?.longitude,
      },
      'numberOfStops': numberOfStops,
      'fare': fare,
      'distanceText': distanceText,
    };
  }
}
