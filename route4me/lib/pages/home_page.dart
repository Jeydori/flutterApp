import 'dart:async';
import 'dart:math';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_geofire/flutter_geofire.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:route4me/assistants/assistant_methods.dart';
import 'package:route4me/components/sorting_toggle.dart';
import 'package:route4me/global/global.dart';
import 'package:provider/provider.dart';
import 'package:route4me/info handler/app_info.dart';
import 'package:route4me/components/progress_dialog.dart';
import 'package:route4me/main.dart';
import 'package:route4me/models/direction_infos.dart';
import 'package:route4me/models/driver_details.dart';
import 'package:route4me/pages/navigation_page.dart';
import 'package:route4me/pages/search_page.dart';
import 'package:route4me/services/precise_pickup_location.dart';
import 'package:route4me/components/drawer.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final Completer<GoogleMapController> _controllerGoogleMap = Completer();
  GoogleMapController? newGoogleMapController;

  static const CameraPosition Manila = CameraPosition(
    target: LatLng(14.599512, 120.984222),
    zoom: 14.4746,
  );

  double searchLocationContainerHeight = 220;
  double waitingResponsefromDriverContainerHeight = 0;
  double assignedDriverInfoContainerHeight = 0;

  Position? userCurrentPosition;
  var geoLocation = Geolocator();
  LocationPermission? locationPermission;
  double bottomPaddingofMap = 0;

  List<LatLng> pLineCoordinatedList = [];
  Set<Polyline> polylineSet = {};

  Set<Marker> markerSet = {};
  Set<Circle> circleSet = {};

  String? userName = "";
  String? userEmail = "";

  bool openNavigationDrawer = true;

  bool activeNearbyDriverKeysLoaded = false;
  Map<String, LatLng> activeDrivers = {};

  BitmapDescriptor activeNearbyIcon = BitmapDescriptor.defaultMarker;

  @override
  void initState() {
    super.initState();
    checkIfLocationPermissionAllowed();
    addCustomIcon();
  }

  void addCustomIcon() {
    BitmapDescriptor.fromAssetImage(
            ImageConfiguration(size: Size(1, 1)), 'lib/images/jeep.png')
        .then((icon) {
      setState(() {
        activeNearbyIcon = icon;
      });
    }).catchError((e) {
      print("Failed to load icon: $e");
    });
  }

  void checkIfLocationPermissionAllowed() async {
    locationPermission = await Geolocator.requestPermission();

    if (locationPermission == LocationPermission.denied) {
      locationPermission = await Geolocator.requestPermission();
    }

    locateUserPosition();
  }

  void locateUserPosition() async {
    try {
      Position cPosition = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      userCurrentPosition = cPosition;

      if (userCurrentPosition != null) {
        LatLng latLngPosition = LatLng(
            userCurrentPosition!.latitude, userCurrentPosition!.longitude);
        CameraPosition cameraPosition =
            CameraPosition(target: latLngPosition, zoom: 15);

        if (newGoogleMapController != null) {
          newGoogleMapController!
              .animateCamera(CameraUpdate.newCameraPosition(cameraPosition));
        }

        print('This is our address = $latLngPosition');

        // Initialize GeoFire listener
        initializeGeofireListener();
      } else {
        print("User current position is null.");
      }
    } catch (e) {
      print("Error locating user position: $e");
    }
  }

  void initializeGeofireListener() {
    print("Initializing Geofire...");
    Geofire.initialize("activeDrivers");

    if (userCurrentPosition != null) {
      print(
          "Querying at location: ${userCurrentPosition!.latitude}, ${userCurrentPosition!.longitude}");
      Geofire.queryAtLocation(
        userCurrentPosition!.latitude,
        userCurrentPosition!.longitude,
        100, // You can increase this value to test with a larger radius
      )?.listen((dynamic data) {
        print(
            "Geofire data received: $data"); // Print raw data received from Geofire

        if (data is Map<dynamic, dynamic>) {
          var callBack = data['callBack'] as String?;
          print("Geofire callback: $callBack");
          switch (callBack) {
            case Geofire.onKeyEntered:
              handleDriverEntered(data);
              break;
            case Geofire.onKeyExited:
              handleDriverExited(data);
              break;
            case Geofire.onKeyMoved:
              handleDriverMoved(data);
              break;
            case Geofire.onGeoQueryReady:
              print("GeoQuery is ready.");
              break;
            default:
              print("Unknown callback: $callBack");
          }
        } else {
          print("Geofire data is not a valid map: $data");
        }
      }).onError((error) {
        print('Geofire error: $error');
      });
    } else {
      print('Current position is null');
    }
  }

  Future<DriverDetails> getDriverDetails(String key) async {
    var snapshot =
        await FirebaseDatabase.instance.ref().child('Drivers').child(key).get();
    if (snapshot.exists && snapshot.value != null) {
      return DriverDetails.fromSnapshot(snapshot.value);
    } else {
      print('No driver details found for key: $key');
      return Future.error('Driver details not found');
    }
  }

  void handleDriverEntered(Map<dynamic, dynamic> map) async {
    var key = map["key"];
    var latitude = map["latitude"];
    var longitude = map["longitude"];
    print("Driver entered: key=$key, latitude=$latitude, longitude=$longitude");

    if (key != null && latitude != null && longitude != null) {
      LatLng driverPosition = LatLng(latitude, longitude);

      // Fetch driver details from Firebase
      var driverDetails = await getDriverDetails(key);

      Marker marker = Marker(
        markerId: MarkerId(key),
        position: driverPosition,
        icon: activeNearbyIcon,
        onTap: () {
          showCustomBottomSheet(
            barrierColor: Colors.transparent,
            context: context,
            title: "Driver Information",
            content: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                      "Name: ${driverDetails.firstName} ${driverDetails.lastName}"),
                  Text("Contact email: ${driverDetails.email}"),
                  Text('PUV: ${driverDetails.carType}'),
                  Text('Plate Number: ${driverDetails.carPlate}'),
                  Text("Latitude: $latitude"),
                  Text("Longitude: $longitude"),
                ],
              ),
            ),
          );
        },
      );
      setState(() {
        markerSet.add(marker);
        activeDrivers[key] = driverPosition; // Update active drivers map
      });
    } else {
      print(
          "Error: Missing data in map['key'], map['latitude'], or map['longitude']");
    }
  }

  void handleDriverExited(Map<dynamic, dynamic> map) {
    var key = map["key"];
    print("Driver exited: key=$key");

    if (key != null) {
      setState(() {
        markerSet.removeWhere((marker) => marker.markerId.value == key);
        activeDrivers.remove(key); // Remove from active drivers map
      });
    } else {
      print("Error: Missing data in map['key']");
    }
  }

  void handleDriverMoved(Map<dynamic, dynamic> map) async {
    var key = map["key"];
    var latitude = map["latitude"];
    var longitude = map["longitude"];
    print("Driver moved: key=$key, latitude=$latitude, longitude=$longitude");

    if (key != null && latitude != null && longitude != null) {
      LatLng driverPosition = LatLng(latitude, longitude);

      // Fetch driver details from Firebase
      var driverDetails = await getDriverDetails(key);

      Marker marker = Marker(
        markerId: MarkerId(key),
        position: driverPosition,
        icon: activeNearbyIcon,
        onTap: () {
          showCustomBottomSheet(
            barrierColor: Colors.transparent,
            context: context,
            title: "Driver Moved",
            content: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                      "Name: ${driverDetails.firstName} ${driverDetails.lastName}"),
                  Text("Contact email: ${driverDetails.email}"),
                  Text('PUV: ${driverDetails.carType}'),
                  Text('Plate Number: ${driverDetails.carPlate}'),
                  Text("Latitude: $latitude"),
                  Text("Longitude: $longitude"),
                ],
              ),
            ),
          );
        },
      );
      setState(() {
        markerSet.removeWhere((m) => m.markerId.value == key);
        markerSet.add(marker);
        activeDrivers[key] =
            driverPosition; // Update position in activeDrivers map
      });
    } else {
      print(
          "Error: Missing data in map['key'], map['latitude'], or map['longitude']");
    }
  }

  void showCustomBottomSheet({
    required BuildContext context,
    required String title,
    required Widget content,
    required Color barrierColor,
  }) {
    showModalBottomSheet(
      isScrollControlled: true,
      barrierColor: barrierColor, // You can adjust the transparency as needed
      context: context,
      builder: (BuildContext ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.4, // Adjusted for better initial appearance
          minChildSize: 0.2, // Minimal size when collapsed
          maxChildSize: 0.9, // Maximal size when expanded
          expand: false,
          builder: (BuildContext context, ScrollController scrollController) {
            return Container(
              padding: EdgeInsets.symmetric(horizontal: 0, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white, // White background for the main container
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(10),
                  topRight: Radius.circular(10),
                ),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 5,
                    color: Colors.black26,
                    spreadRadius: 3,
                  ),
                ],
              ),
              child: ListView(
                controller: scrollController,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: Colors.grey[300], // Grey handle indicator
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  Container(
                    color: Colors.orange, // Orange background for the title
                    padding: EdgeInsets.only(
                        top: 8, bottom: 8), // Remove left and right padding
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black, // Black text for contrast
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(height: 20),
                  Center(child: content),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void showRouteSelectionSheet(
      BuildContext context,
      List<DirectionDetailsInfo> directionsList,
      Function(List<TransitInfo>?) calculateTotalFare,
      Function(BuildContext, DirectionDetailsInfo, List<DirectionDetailsInfo>)
          drawSelectedRoute,
      Function(BuildContext, DirectionDetailsInfo, List<DirectionDetailsInfo>,
              DirectionDetailsInfo?, String)
          showRouteInfoBottomSheet,
      String carType) {
    showModalBottomSheet(
      barrierColor: Colors.transparent,
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
      ),
      builder: (BuildContext ctx) {
        return RouteSelectionSheet(
          directionsList: directionsList,
          calculateTotalFare: calculateTotalFare,
          drawSelectedRoute: drawSelectedRoute,
          showRouteInfoBottomSheet: showRouteInfoBottomSheet,
          carType: carType, // Pass carType to the RouteSelectionSheet
        );
      },
    );
  }

  MapEntry<String, LatLng>? getNearestDriverEntry() {
    if (userCurrentPosition == null) {
      return null; // Early return if position is null
    }

    double minDistance = double.maxFinite;
    MapEntry<String, LatLng>? nearestDriverEntry;

    for (var entry in activeDrivers.entries) {
      double distance = calculateDistance(
        userCurrentPosition!.latitude,
        userCurrentPosition!.longitude,
        entry.value.latitude,
        entry.value.longitude,
      );
      if (distance < minDistance) {
        minDistance = distance;
        nearestDriverEntry = entry;
      }
    }

    return nearestDriverEntry;
  }

  void _drawSelectedRoute(
      BuildContext context,
      DirectionDetailsInfo directionDetailsInfo,
      List<DirectionDetailsInfo> directionsList) async {
    setState(() {
      tripDirectionDetailsInfo = directionDetailsInfo;
      polylineSet.clear(); // Clear any existing polylines
      circleSet.clear(); // Clear any existing circles
    });

    MapEntry<String, LatLng>? nearestDriverEntry = getNearestDriverEntry();
    if (nearestDriverEntry != null) {
      String nearestDriverKey = nearestDriverEntry.key;
      DriverDetails driverDetails = await getDriverDetails(nearestDriverKey);

      // Decode and draw the route polyline
      PolylinePoints polylinePoints = PolylinePoints();
      List<PointLatLng> decodedPolylinePoints =
          polylinePoints.decodePolyline(directionDetailsInfo.e_points!);
      List<LatLng> polylineCoordinates = decodedPolylinePoints
          .map((point) => LatLng(point.latitude, point.longitude))
          .toList();

      // Set map bounds around the new polyline
      LatLngBounds boundsLatLng = _calculateLatLngBounds(polylineCoordinates);
      await newGoogleMapController!
          .animateCamera(CameraUpdate.newLatLngBounds(boundsLatLng, 70));

      // Adding start and end circles for the route
      _addStartAndEndCircles(polylineCoordinates);

      // Add steps to the map (this draws the detailed route polyline)
      _addStepsToMap(directionDetailsInfo.steps!);

      // Add transit steps circles to the map (visualizing stops)
      _addTransitStepsCircles(directionDetailsInfo.transitSteps!);

      LatLng? nearestDriverPosition = getNearestDriverPosition();
      DirectionDetailsInfo? trafficInfo;
      if (nearestDriverPosition != null) {
        LatLng firstDeparturePosition =
            directionDetailsInfo.transitSteps!.first.departureLocation;

        // Fetch traffic info from the nearest driver to the first departure position
        trafficInfo = await assistantMethods.fetchDriverToDepartureDetails(
            nearestDriverPosition, firstDeparturePosition);

        // Debug print to check trafficInfo
        print("Traffic Info Duration Text: ${trafficInfo?.duration_text}");
        if (trafficInfo != null) {
          drawDriverToDeparturePolyline(
              nearestDriverPosition, firstDeparturePosition, trafficInfo);
          // Show the popup dialog with the arrival time
          showPUVArrivalDialog(trafficInfo.duration_text);
        }
      }

      // Use mounted check before updating UI
      if (mounted) {
        setState(() {
          // Call to show the route info bottom sheet is still here, ensuring that the sheet is updated as originally designed
          _showRouteInfoBottomSheet(context, directionDetailsInfo,
              directionsList, driverDetails.carType);
        });
      } else {
        print("Widget is not mounted, skip updating the state.");
      }
    }
  }

  void showPUVArrivalDialog(String duration) {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: Colors.orange.shade600, width: 2),
          ),
          child: Stack(
            children: [
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Center(
                      child: RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: TextStyle(fontSize: 16, color: Colors.black),
                          children: <TextSpan>[
                            TextSpan(
                                text:
                                    'The nearest PUV will arrive to your first departure in '),
                            TextSpan(
                              text: duration,
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            TextSpan(text: '.'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                right: 0,
                child: IconButton(
                  padding: EdgeInsets.all(5), // Minimal padding around the icon
                  icon: Icon(Icons.close),
                  onPressed: () {
                    Navigator.of(context).pop(); // Close the dialog
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _addStartAndEndCircles(List<LatLng> polylineCoordinates) {
    if (polylineCoordinates.isNotEmpty) {
      // Start Circle
      Circle startCircle = Circle(
        circleId: CircleId('start_circle'),
        center: polylineCoordinates.first,
        radius: 20,
        fillColor: Colors.green,
        strokeWidth: 1,
        strokeColor: Colors.white,
      );

      // End Circle
      Circle endCircle = Circle(
        circleId: CircleId('end_circle'),
        center: polylineCoordinates.last,
        radius: 100,
        fillColor: Colors.red,
        strokeWidth: 1,
        strokeColor: Colors.white,
      );

      setState(() {
        circleSet.add(startCircle);
        circleSet.add(endCircle);
      });
    }
  }

  void _addStepsToMap(List<dynamic> steps) {
    for (var step in steps) {
      List<PointLatLng> stepPolylinePoints =
          PolylinePoints().decodePolyline(step["polyline"]["points"]);
      List<LatLng> stepCoordinates = stepPolylinePoints
          .map((point) => LatLng(point.latitude, point.longitude))
          .toList();
      bool isWalking = step["travel_mode"] == "WALKING";
      polylineSet.add(Polyline(
        polylineId: PolylineId('${step["start_location"].toString()}'),
        points: stepCoordinates,
        color: isWalking ? Colors.orange : Colors.orange,
        width: 4,
        patterns: isWalking ? [PatternItem.dot] : [],
      ));
    }
  }

  void _addTransitStepsCircles(List<dynamic> transitSteps) {
    for (var transitStep in transitSteps) {
      Circle departureCircle = Circle(
        circleId: CircleId('departure_${transitStep.departureStop}'),
        center: transitStep.departureLocation!,
        radius: 60,
        fillColor: Colors.white,
        strokeWidth: 1,
        strokeColor: Colors.black,
      );

      Circle arrivalCircle = Circle(
        circleId: CircleId('arrival_${transitStep.arrivalStop}'),
        center: transitStep.arrivalLocation!,
        radius: 60,
        fillColor: Colors.white,
        strokeWidth: 1,
        strokeColor: Colors.black,
      );

      setState(() {
        circleSet.add(departureCircle);
        circleSet.add(arrivalCircle);
      });
    }
  }

  void _showRouteInfoBottomSheet(
      BuildContext context,
      DirectionDetailsInfo directionDetailsInfo,
      List<DirectionDetailsInfo> directionsList,
      String carType) {
    // Calculate the total fare for all transit steps
    double totalTransitFare =
        calculateTotalFare(directionDetailsInfo.transitSteps);

    // Debug print to check direction details info
    print('Showing route info for: ${directionDetailsInfo.distance_text}');

    showCustomBottomSheet(
      barrierColor: Colors.transparent,
      context: context,
      title: "Route Information",
      content: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 10),
              Text('Total Distance: ${directionDetailsInfo.distance_text}',
                  style: TextStyle(fontSize: 16)),
              Text('Duration: ${directionDetailsInfo.duration_text}',
                  style: TextStyle(fontSize: 16)),
              Text('Vehicle Type: $carType',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Text('Total Fare: ₱${totalTransitFare.toStringAsFixed(2)}',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              SizedBox(height: 10),
              Text('Detailed Steps:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.orange.shade600, width: 2.0),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: directionDetailsInfo.steps?.length ?? 0,
                  itemBuilder: (context, index) {
                    var step = directionDetailsInfo.steps![index];
                    String stepTitle =
                        step["travel_mode"] == "WALKING" ? "Walk" : "Transit";
                    String fareDetails = "";
                    if (stepTitle == "Transit") {
                      TransitInfo? transitStep =
                          directionDetailsInfo.transitSteps?.firstWhere(
                              (t) =>
                                  t.departureLocation ==
                                  LatLng(
                                      step["transit_details"]["departure_stop"]
                                          ["location"]["lat"],
                                      step["transit_details"]["departure_stop"]
                                          ["location"]["lng"]),
                              orElse: () => TransitInfo(
                                  vehicleType: '',
                                  lineName: '',
                                  agencyName: '',
                                  departureStop: '',
                                  arrivalStop: '',
                                  departureTime: '',
                                  arrivalTime: '',
                                  departureLocation: LatLng(0, 0),
                                  arrivalLocation: LatLng(0, 0),
                                  numberOfStops: 0,
                                  fare: 0.0,
                                  distanceText: ''));
                      fareDetails =
                          '₱${transitStep?.fare?.toStringAsFixed(2) ?? "0.00"}';
                    }
                    String stepDetails = stepTitle == "Walk"
                        ? 'Walk ${step["distance"]["text"]} - ${step["duration"]["text"]}'
                        : '${step["transit_details"]["line"]["vehicle"]["name"]} ${step["distance"]["text"]} from ${step["transit_details"]["departure_stop"]["name"]} to ${step["transit_details"]["arrival_stop"]["name"]}';

                    return ListTile(
                      leading: Icon(
                        stepTitle == "Walk"
                            ? Icons.directions_walk
                            : Icons.directions_bus,
                        color: Colors.orange.shade600,
                      ),
                      title: RichText(
                        text: TextSpan(
                          style: TextStyle(fontSize: 16, color: Colors.black),
                          children: [
                            TextSpan(
                                text: stepTitle,
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            TextSpan(text: " - "),
                            TextSpan(text: stepDetails),
                            if (stepTitle == "Transit")
                              TextSpan(
                                  text: " - Fare: ",
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                            if (stepTitle == "Transit")
                              TextSpan(text: fareDetails),
                          ],
                        ),
                      ),
                      subtitle: Text(step["duration"]["text"],
                          style: TextStyle(color: Colors.grey)),
                    );
                  },
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    Navigator.pop(context); // Dismiss the bottom sheet first
                    Future.delayed(Duration(milliseconds: 100), () {
                      // Wait a bit before navigating
                      showRouteSelectionSheet(
                        context,
                        directionsList,
                        calculateTotalFare,
                        drawSelectedRoute,
                        showRouteInfoBottomSheet,
                        carType,
                      );
                    });
                  },
                  child: Text("Choose another route",
                      style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.bold)),
                ),
              ),
              Align(
                alignment: Alignment.center,
                child: ElevatedButton(
                  onPressed: () {
                    print(
                        "Starting navigation for: ${directionDetailsInfo.distance_text}");
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      startNavigation(context, directionDetailsInfo);
                    });
                  },
                  child: Text("Start Navigation",
                      style: TextStyle(color: Colors.black)),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10))),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  double calculateTotalFare(List<TransitInfo>? transitSteps) {
    double totalFare = 0.0;
    if (transitSteps != null) {
      for (var step in transitSteps) {
        if (step.fare != null) {
          totalFare += step.fare!;
          // Debug print to verify fare values
          print('Step fare: ${step.fare}');
        }
      }
    }
    // Debug print to verify total fare
    print('Total fare: $totalFare');
    return totalFare;
  }

  Future<void> startNavigation(
      BuildContext context, DirectionDetailsInfo directionDetails) async {
    final result = await navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (context) =>
            NavigationPage(directionDetailsInfo: directionDetails),
      ),
    );

    if (result != null && result == "Trip Completed") {
      showRatingDialog(context);
    }
  }

  void showRatingDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Rate the Trip"),
          content: Text("Please rate your trip experience."),
          actions: <Widget>[
            TextButton(
              child: Text("Cancel"),
              onPressed: () {
                Navigator.of(context).pop(); // Closes the dialog
              },
            ),
            TextButton(
              child: Text("Submit"),
              onPressed: () {
                // Handle the submission of the rating here
                Navigator.of(context).pop(); // Closes the dialog
              },
            ),
          ],
        );
      },
    );
  }

  void drawDriverToDeparturePolyline(
      LatLng start, LatLng end, DirectionDetailsInfo trafficInfo) {
    // Decode polyline from the traffic info and add it to the map
    List<PointLatLng> polylinePoints =
        PolylinePoints().decodePolyline(trafficInfo.e_points!);
    List<LatLng> polylineCoordinates = polylinePoints
        .map((point) => LatLng(point.latitude, point.longitude))
        .toList();

    Polyline driverRoute = Polyline(
      polylineId: PolylineId("driverRoute"),
      points: polylineCoordinates,
      color: Colors.yellow.shade600, // Color for driver route
      width: 5,
    );

    setState(() {
      polylineSet.add(driverRoute);
    });
  }

  LatLng? getNearestDriverPosition() {
    if (userCurrentPosition == null)
      return null; // Early return if position is null

    double minDistance = double.maxFinite;
    LatLng? nearestDriver;

    for (var entry in activeDrivers.entries) {
      double distance = calculateDistance(
        userCurrentPosition!.latitude,
        userCurrentPosition!.longitude,
        entry.value.latitude,
        entry.value.longitude,
      );
      if (distance < minDistance) {
        minDistance = distance;
        nearestDriver = entry.value;
      }
    }

    return nearestDriver;
  }

  double calculateDistance(lat1, lon1, lat2, lon2) {
    var p = 0.017453292519943295; // Math.PI / 180
    var c = cos;
    var a = 0.5 -
        c((lat2 - lat1) * p) / 2 +
        c(lat1 * p) * c(lat2 * p) * (1 - c((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a)); // 2 * R; R = 6371 km
  }

  Future<void> drawPolylineFromOriginToDestination() async {
    var originPosition =
        Provider.of<appInfo>(context, listen: false).userPickUpLocation;
    var destinationPosition =
        Provider.of<appInfo>(context, listen: false).userDestinationLocation;

    MapEntry<String, LatLng>? nearestDriverEntry = getNearestDriverEntry();
    if (nearestDriverEntry == null) {
      print("No nearest driver found");
      return;
    }

    String nearestDriverKey = nearestDriverEntry.key;
    DriverDetails driverDetails = await getDriverDetails(nearestDriverKey);
    String carType =
        driverDetails.carType; // Fetching carType from driver details

    var originLatLng = LatLng(
        originPosition!.locationLatitude!, originPosition.locationLongitude!);
    var destinationLatLng = LatLng(destinationPosition!.locationLatitude!,
        destinationPosition.locationLongitude!);

    showDialog(
      context: context,
      builder: (BuildContext context) =>
          ProgressDialog(message: "Please wait..."),
    );

    var directionsList =
        await assistantMethods.obtainOriginToDestinationDirectionDetails(
            originLatLng, destinationLatLng, carType); // Now passing carType

    Navigator.pop(context);

    if (directionsList.isEmpty) {
      print("No routes found");
      return;
    }

    // Assuming showRouteSelectionSheet is ready to handle carType if needed
    showRouteSelectionSheet(
      context,
      directionsList,
      calculateTotalFare,
      (context, info, directionsList) =>
          _drawSelectedRoute(context, info, directionsList),
      (context, info, directionsList, trafficInfo, carType) =>
          _showRouteInfoBottomSheet(context, info, directionsList, carType),
      carType, // Pass carType to showRouteSelectionSheet
    );
  }

  LatLngBounds _calculateLatLngBounds(List<LatLng> polylineCoordinates) {
    double minLat = polylineCoordinates.first.latitude;
    double maxLat = polylineCoordinates.first.latitude;
    double minLng = polylineCoordinates.first.longitude;
    double maxLng = polylineCoordinates.first.longitude;

    for (var coordinate in polylineCoordinates) {
      if (coordinate.latitude < minLat) minLat = coordinate.latitude;
      if (coordinate.latitude > maxLat) maxLat = coordinate.latitude;
      if (coordinate.longitude < minLng) minLng = coordinate.longitude;
      if (coordinate.longitude > maxLng) maxLng = coordinate.longitude;
    }

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        return GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus();
          },
          child: Scaffold(
            appBar: AppBar(
              title: const Text(
                "Home",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            drawer: const MyDrawer(),
            body: Stack(children: [
              GoogleMap(
                mapType: MapType.normal,
                myLocationEnabled: true,
                zoomGesturesEnabled: true,
                zoomControlsEnabled: false,
                initialCameraPosition: Manila,
                polylines: polylineSet,
                markers: markerSet,
                circles: circleSet,
                onMapCreated: (GoogleMapController controller) {
                  _controllerGoogleMap.complete(controller);
                  newGoogleMapController = controller;

                  setState(() {});
                  locateUserPosition();
                },
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.black38,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.orange[600],
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Column(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(5),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.location_on_outlined,
                                          color: Colors.black,
                                        ),
                                        const SizedBox(width: 10),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              "From",
                                              style: TextStyle(
                                                color: Colors.black,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              Provider.of<appInfo>(context)
                                                          .userPickUpLocation !=
                                                      null
                                                  ? "${(Provider.of<appInfo>(context).userPickUpLocation!.locationName!).substring(0, 24)}..."
                                                  : "...",
                                            )
                                          ],
                                        )
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  const Divider(
                                    height: 1,
                                    thickness: 2,
                                    color: Colors.black,
                                  ),
                                  const SizedBox(height: 5),
                                  Padding(
                                    padding: const EdgeInsets.all(5),
                                    child: GestureDetector(
                                      onTap: () async {
                                        // Go to search page
                                        var responseFromSearchPage =
                                            await Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                    builder: (c) =>
                                                        const SearchPage()));

                                        if (responseFromSearchPage ==
                                            "obtainedDestination") {
                                          setState(() {
                                            openNavigationDrawer = false;
                                          });
                                        }
                                        await drawPolylineFromOriginToDestination();
                                      },
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.location_on_outlined,
                                            color: Colors.black,
                                          ),
                                          const SizedBox(width: 10),
                                          Flexible(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                const Text(
                                                  "Where to",
                                                  style: TextStyle(
                                                    color: Colors.black,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                Text(
                                                  Provider.of<appInfo>(context)
                                                              .userDestinationLocation !=
                                                          null
                                                      ? Provider.of<appInfo>(
                                                              context)
                                                          .userDestinationLocation!
                                                          .locationName!
                                                      : "...",
                                                )
                                              ],
                                            ),
                                          )
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(
                              height: 5,
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Flexible(
                                  child: ElevatedButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (c) =>
                                              const PrecisePickUpLocation(),
                                        ),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.amber[400],
                                      textStyle: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    child: const Text(
                                      'Set Pickup',
                                      style: TextStyle(
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(
                                  width: 10,
                                ),
                                Flexible(
                                  child: ElevatedButton(
                                    onPressed: () async {
                                      // Go to search page
                                      var responseFromSearchPage =
                                          await Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (c) =>
                                                      const SearchPage()));

                                      if (responseFromSearchPage ==
                                          "obtainedDestination") {
                                        setState(() {
                                          openNavigationDrawer = false;
                                        });
                                      }
                                      await drawPolylineFromOriginToDestination();
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.amber[400],
                                      textStyle: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    child: const Text(
                                      'Set Destination',
                                      style: TextStyle(
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ]),
          ),
        );
      },
    );
  }
}
