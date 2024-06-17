import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:route4me/assistants/request_assistant.dart';
import 'package:route4me/global/directions.dart';
import 'package:route4me/global/global.dart';
import 'package:route4me/global/map_key.dart';
import 'package:route4me/info%20handler/app_info.dart';
import 'package:route4me/models/direction_infos.dart';
import 'package:route4me/models/fare_chart.dart';
import 'package:route4me/models/user_model.dart';

double computeFare(String type, String category, double distance) {
  List<double>? fares = fareCharts[type]![category];
  int distIndex = (distance.ceil() > fares!.length)
      ? fares.length - 1
      : distance.ceil() - 1;
  return fares[distIndex];
}

class assistantMethods {
  static Future<UserModel> readCurrentOnlineUserInfo() async {
    try {
      final currentUser = firebaseAuth.currentUser;
      if (currentUser != null) {
        final userRef = FirebaseDatabase.instance
            .reference()
            .child('Users')
            .child(currentUser.uid);

        DatabaseEvent event = await userRef.once();
        DataSnapshot snapshot = event.snapshot;

        if (snapshot.value != null) {
          Map<String, dynamic> data =
              Map<String, dynamic>.from(snapshot.value as Map);
          UserModel userModel = UserModel(
            firstName: data['First Name'] ?? '',
            lastName: data['Last Name'] ?? '',
            age: data['Age'] ?? 0,
            email: data['Email'] ?? '',
            uid: currentUser.uid,
          );
          print('User info retrieved: $userModel');
          return userModel;
        } else {
          throw Exception('User document does not exist');
        }
      } else {
        throw Exception('Current user is null');
      }
    } catch (error) {
      print("Failed to get user info: $error");
      rethrow; // Propagate the error for handling by the caller
    }
  }

  static Future<void> updateUserInfo(UserModel updatedUserModel) async {
    try {
      final currentUser = firebaseAuth.currentUser;
      if (currentUser != null) {
        final userRef = FirebaseDatabase.instance
            .ref()
            .child('Users')
            .child(currentUser.uid);

        await userRef.update({
          'First Name': updatedUserModel.firstName,
          'Last Name': updatedUserModel.lastName,
          'Age': updatedUserModel.age,
          'Email': updatedUserModel.email,
        });

        print('User information updated successfully');
      } else {
        throw Exception('Current user is null');
      }
    } catch (error) {
      print("Failed to update user information: $error");
      rethrow; // Propagate the error for handling by the caller
    }
  }

  static Future<String> searchAddressForGeographicCoordinates(
      Position position, context) async {
    String apiURL =
        "https://maps.googleapis.com/maps/api/geocode/json?latlng=${position.latitude},${position.longitude}&key=$mapKey";
    String humanReadableAddress = "";

    var requestResponse = await RequestAssistant.receiveRequest(apiURL);

    if (requestResponse != "Error Occurred. Failed. No Response.") {
      humanReadableAddress = requestResponse["results"][0]["formatted_address"];

      Directions userPickUpAddress = Directions();
      userPickUpAddress.locationLatitude = position.latitude;
      userPickUpAddress.locationLongitude = position.longitude;
      userPickUpAddress.locationName = humanReadableAddress;

      Provider.of<appInfo>(context, listen: false)
          .updatePickUpAddress(userPickUpAddress);
    }
    return humanReadableAddress;
  }

  static Future<List<DirectionDetailsInfo>>
      obtainOriginToDestinationDirectionDetails(LatLng originPosition,
          LatLng destinationPosition, String carType) async {
    String urlOriginToDestinationDirectionDetails =
        "https://maps.googleapis.com/maps/api/directions/json?origin=${originPosition.latitude},${originPosition.longitude}&destination=${destinationPosition.latitude},${destinationPosition.longitude}&mode=transit&alternatives=true&key=$mapKey";
    var responseDirectionApi = await RequestAssistant.receiveRequest(
        urlOriginToDestinationDirectionDetails);

    if (responseDirectionApi == "failed") {
      return [];
    }

    List<DirectionDetailsInfo> directionsList = [];

    for (var route in responseDirectionApi["routes"]) {
      DirectionDetailsInfo directionDetailsInfo = DirectionDetailsInfo(
        e_points: route["overview_polyline"]["points"],
        distance_text: route["legs"][0]["distance"]["text"],
        distance_value: (route["legs"][0]["distance"]["value"]).toDouble(),
        duration_text: route["legs"][0]["duration"]["text"],
        duration_value: route["legs"][0]["duration"]["value"],
        steps: route["legs"][0]["steps"],
      );

      List<TransitInfo> transitSteps = [];
      for (var step in directionDetailsInfo.steps!) {
        if (step["travel_mode"] == "TRANSIT") {
          String distanceText = step["distance"]["text"];
          double distanceInKm = double.parse(distanceText.split(' ')[0]);
          double fare = computeFare(carType, "Regular", distanceInKm);

          transitSteps.add(TransitInfo(
            vehicleType: carType,
            lineName: step["transit_details"]["line"]["short_name"] ??
                step["transit_details"]["line"]["name"],
            agencyName: step["transit_details"]["line"]["agencies"][0]["name"],
            departureStop: step["transit_details"]["departure_stop"]["name"],
            arrivalStop: step["transit_details"]["arrival_stop"]["name"],
            departureTime: step["transit_details"]["departure_time"]["text"],
            arrivalTime: step["transit_details"]["arrival_time"]["text"],
            departureLocation: LatLng(
              step["transit_details"]["departure_stop"]["location"]["lat"],
              step["transit_details"]["departure_stop"]["location"]["lng"],
            ),
            arrivalLocation: LatLng(
              step["transit_details"]["arrival_stop"]["location"]["lat"],
              step["transit_details"]["arrival_stop"]["location"]["lng"],
            ),
            numberOfStops: step["transit_details"]["num_stops"],
            fare: fare,
            distanceText: step["distance"]["text"],
          ));
        }
      }
      directionDetailsInfo.transitSteps = transitSteps;
      directionsList.add(directionDetailsInfo);
    }

    return directionsList;
  }

  static Future<DirectionDetailsInfo> fetchDriverToDepartureDetails(
      LatLng driverPosition, LatLng firstDeparturePosition) async {
    String url =
        "https://maps.googleapis.com/maps/api/directions/json?origin=${driverPosition.latitude},${driverPosition.longitude}&destination=${firstDeparturePosition.latitude},${firstDeparturePosition.longitude}&departure_time=now&mode=transit&traffic_model=best_guess&key=$mapKey";

    var response = await RequestAssistant.receiveRequest(url);

    // Default DirectionDetailsInfo in case of failure or empty routes
    DirectionDetailsInfo defaultDirectionDetailsInfo = DirectionDetailsInfo(
      e_points: '',
      distance_text: 'No route found',
      distance_value: 0.0,
      duration_text: 'No duration available',
      duration_value: 0,
    );

    if (response == "failed" ||
        response["routes"] == null ||
        response["routes"].isEmpty) {
      return defaultDirectionDetailsInfo;
    }

    var route = response["routes"][0];
    if (route["legs"] == null || route["legs"].isEmpty) {
      return defaultDirectionDetailsInfo;
    }

    var leg = route["legs"][0];

    DirectionDetailsInfo directionDetailsInfo = DirectionDetailsInfo(
      e_points: route["overview_polyline"]["points"],
      distance_text: leg["distance"]["text"],
      distance_value: (leg["distance"]["value"]).toDouble(),
      duration_text: leg["duration"]["text"],
      duration_value: leg["duration"]["value"],
    );

    // Debug prints to ensure correct values
    print("Fetched trafficInfo: $directionDetailsInfo");
    return directionDetailsInfo;
  }
}
