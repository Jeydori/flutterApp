import 'dart:async';
import 'dart:math';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_geofire/flutter_geofire.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:route4me/models/direction_infos.dart';
import 'package:route4me/models/driver_details.dart';

class NavigationPage extends StatefulWidget {
  final DirectionDetailsInfo directionDetailsInfo;

  const NavigationPage({super.key, required this.directionDetailsInfo});

  @override
  _NavigationPageState createState() => _NavigationPageState();
}

class _NavigationPageState extends State<NavigationPage> {
  GoogleMapController? _mapController;
  StreamSubscription<Position>? _positionStreamSubscription;

  Position? _currentPosition;
  List<LatLng> polylineCoordinates = [];
  final Set<Polyline> _polylines = <Polyline>{};
  final Set<Marker> _markers = <Marker>{};
  final Set<Circle> _circles = <Circle>{};
  final Set<Marker> _driverMarkers = <Marker>{};
  Map<String, LatLng> activeDrivers = {};
  String _distanceText = "";
  String _etaText = "";

  @override
  void initState() {
    super.initState();
    _initLocationService();
    _drawRoute();
    _locateInitialPosition();
    checkIfLocationPermissionAllowed();
  }

  void _locateInitialPosition() async {
    try {
      Position initialPosition = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      print("Initial position found: $initialPosition"); // Debug output
      _updateMapLocation(initialPosition);
    } catch (e) {
      print("Error getting initial position: $e");
    }
  }

  void _updateMapLocation(Position position) {
    LatLng currentLatLng = LatLng(position.latitude, position.longitude);
    _mapController?.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(
      target: currentLatLng,
      zoom: 18,
      tilt: 70,
      bearing: _currentPosition != null
          ? _getBearing(
              LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
              currentLatLng)
          : 0,
    )));
    _updateUserLocationMarker(currentLatLng);
    _updateDistanceAndEta(currentLatLng);
  }

  void _updateUserLocationMarker(LatLng currentLatLng) {
    Marker currentLocationMarker = Marker(
      markerId: const MarkerId('currentLocation'),
      position: currentLatLng,
      anchor: const Offset(0.5, 1),
    );

    setState(() {
      _markers.removeWhere((m) => m.markerId.value == 'currentLocation');
      _markers.add(currentLocationMarker);
    });
  }

  void _initLocationService() {
    LocationSettings locationSettings = const LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 10,
    );

    _positionStreamSubscription =
        Geolocator.getPositionStream(locationSettings: locationSettings).listen(
            (Position position) {
      _currentPosition = position;
      _updateMapLocation(position);
    }, onError: (e) {
      print("Error getting location stream: $e");
    });
  }

  void _updateDistanceAndEta(LatLng currentLatLng) {
    LatLng destinationLatLng = LatLng(
        widget.directionDetailsInfo.destinationLatitude!,
        widget.directionDetailsInfo.destinationLongitude!);

    double distance = Geolocator.distanceBetween(
        currentLatLng.latitude,
        currentLatLng.longitude,
        destinationLatLng.latitude,
        destinationLatLng.longitude);

    double speed = _currentPosition?.speed ?? 0; // Speed in m/s

    setState(() {
      _distanceText = "${(distance / 1000).toStringAsFixed(2)} km";
      double time = (speed > 0) ? distance / speed : 0;
      _etaText = (time > 0)
          ? "${(time / 3600).floor()} hr ${(time % 3600 / 60).floor()} min"
          : "Calculating ETA...";
    });

    // Check if the user has arrived at the destination
    if (distance < 50) {
      // Threshold in meters
      _stopNavigation();
      _showArrivalDialog();
    }
  }

  void _drawRoute() {
    // Decode overall route polyline
    List<PointLatLng> decodedPolylinePoints =
        PolylinePoints().decodePolyline(widget.directionDetailsInfo.e_points!);
    polylineCoordinates = decodedPolylinePoints
        .map((point) => LatLng(point.latitude, point.longitude))
        .toList();

    // Clear previous routes, markers, and circles
    _polylines.clear();
    _markers.clear();

    // Define the colors for walking and transit
    final Color walkingColor = Colors.orange; // Color for walking
    final Color transitColor = Colors.orange; // Color for transit

    // Draw each step in the route
    for (var step in widget.directionDetailsInfo.steps ?? []) {
      List<PointLatLng> stepPoints =
          PolylinePoints().decodePolyline(step['polyline']['points']);
      List<LatLng> stepCoordinates = stepPoints
          .map((point) => LatLng(point.latitude, point.longitude))
          .toList();

      Polyline polyline = Polyline(
          polylineId: PolylineId('step_${stepCoordinates.hashCode}'),
          points: stepCoordinates,
          color: step['travel_mode'] == 'WALKING' ? walkingColor : transitColor,
          width: 5,
          patterns: step['travel_mode'] == 'WALKING'
              ? [PatternItem.dot, PatternItem.gap(10)]
              : []);

      setState(() {
        _polylines.add(polyline);
      });
    }

    // Handle transit details if available
    if (widget.directionDetailsInfo.transitSteps != null) {
      _circles.clear(); // Clear previous circles
      for (var transitStep in widget.directionDetailsInfo.transitSteps!) {
        Circle departureCircle = Circle(
          circleId: CircleId('departure_${transitStep.departureStop}'),
          center: transitStep.departureLocation,
          radius: 50,
          fillColor: Colors.white,
          strokeColor: Colors.black,
          strokeWidth: 2,
        );

        Circle arrivalCircle = Circle(
          circleId: CircleId('arrival_${transitStep.arrivalStop}'),
          center: transitStep.arrivalLocation!,
          radius: 50,
          fillColor: Colors.white,
          strokeColor: Colors.black,
          strokeWidth: 2,
        );

        setState(() {
          _circles.add(departureCircle);
          _circles.add(arrivalCircle);
        });
      }
    }

    // Adjust camera to show the entire route
    _adjustCameraToRoute(polylineCoordinates);
  }

  void _adjustCameraToRoute(List<LatLng> polylineCoordinates) {
    if (polylineCoordinates.isNotEmpty) {
      LatLngBounds bounds = _calculateLatLngBounds(polylineCoordinates);
      _mapController
          ?.animateCamera(CameraUpdate.newLatLngBounds(bounds, 100))
          .then((_) {
        _mapController?.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target:
                  polylineCoordinates.first, // Focus on the start of the route
              zoom: 18,
              tilt: 70,
              bearing: _getBearing(
                  polylineCoordinates.first, polylineCoordinates.last),
            ),
          ),
        );
      });
    }
  }

  double _getBearing(LatLng start, LatLng end) {
    double deltaLongitude = end.longitude - start.longitude;
    double deltaLatitude = log(tan(end.latitude / 2.0 + pi / 4.0) /
        tan(start.latitude / 2.0 + pi / 4.0));
    double angle = atan2(deltaLongitude, deltaLatitude);

    return (angle * 180.0 / pi + 360.0) % 360.0;
  }

  LatLngBounds _calculateLatLngBounds(List<LatLng> polylineCoordinates) {
    double southwestLat = polylineCoordinates.first.latitude;
    double southwestLng = polylineCoordinates.first.longitude;
    double northeastLat = polylineCoordinates.first.latitude;
    double northeastLng = polylineCoordinates.first.longitude;

    for (LatLng latLng in polylineCoordinates) {
      if (latLng.latitude < southwestLat) southwestLat = latLng.latitude;
      if (latLng.latitude > northeastLat) northeastLat = latLng.latitude;
      if (latLng.longitude < southwestLng) southwestLng = latLng.longitude;
      if (latLng.longitude > northeastLng) northeastLng = latLng.longitude;
    }

    return LatLngBounds(
      southwest: LatLng(southwestLat, southwestLng),
      northeast: LatLng(northeastLat, northeastLng),
    );
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Navigation',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: _stopNavigation,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: GoogleMap(
              mapType: MapType.normal,
              initialCameraPosition: const CameraPosition(
                target: LatLng(14.599512, 120.984222),
                zoom: 14.4746,
              ),
              onMapCreated: (controller) {
                setState(() {
                  _mapController = controller;
                  _slantCamera();
                });
              },
              polylines: _polylines,
              markers: _markers.union(_driverMarkers),
              circles: _circles,
              myLocationEnabled: true,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text('Distance: $_distanceText, ETA: $_etaText'),
          ),
        ],
      ),
    );
  }

  void _slantCamera() {
    if (_currentPosition != null) {
      LatLng currentLatLng =
          LatLng(_currentPosition!.latitude, _currentPosition!.longitude);
      _mapController
          ?.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(
        target: currentLatLng,
        zoom: 18,
        tilt: 70,
        bearing: _getBearing(currentLatLng, currentLatLng),
      )));
    }
  }

  void _stopNavigation() {
    setState(() {
      _positionStreamSubscription?.cancel();
    });
    Navigator.pop(context, "Trip Completed");
  }

  void _showArrivalDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // User must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Arrived"),
          content: const Text("You have arrived at your destination."),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                Navigator.of(context)
                    .pop("Trip Completed"); // Close NavigationPage
              },
            ),
          ],
        );
      },
    );
  }

  // The following methods are integrated from `homePage`

  Future<BitmapDescriptor> getVehicleIcon(String vehicleType) async {
    print('Vehicle type: $vehicleType'); // Debugging line
    String iconName;
    switch (vehicleType) {
      case 'Bus Ordinary (O-PUB)':
        iconName = 'lib/images/bus.png';
        break;
      case 'Bus Aircon (A-PUB)':
        iconName = 'lib/images/bus.png';
        break;
      case 'E-Jeepney Aircon (A-MPUJ)':
        iconName = 'lib/images/e-jeep.png';
        break;
      case 'E-Jeepney Non-Aircon (Na-MPUJ)':
        iconName = 'lib/images/e-jeep.png';
        break;
      case 'Jeepney (TPUJ)':
        iconName = 'lib/images/jeep.png';
        break;
      default:
        iconName = 'lib/images/jeep.png'; // Default to jeep icon
    }

    print('Icon name: $iconName'); // Debugging line

    return BitmapDescriptor.fromAssetImage(
        ImageConfiguration(size: Size(1, 1)), iconName);
  }

  void checkIfLocationPermissionAllowed() async {
    LocationPermission locationPermission =
        await Geolocator.requestPermission();

    if (locationPermission == LocationPermission.denied) {
      locationPermission = await Geolocator.requestPermission();
    }

    locateUserPosition();
  }

  void locateUserPosition() async {
    try {
      Position cPosition = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      _currentPosition = cPosition;

      if (_currentPosition != null) {
        LatLng latLngPosition =
            LatLng(_currentPosition!.latitude, _currentPosition!.longitude);
        CameraPosition cameraPosition =
            CameraPosition(target: latLngPosition, zoom: 15);

        if (_mapController != null) {
          _mapController!
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

    if (_currentPosition != null) {
      print(
          "Querying at location: ${_currentPosition!.latitude}, ${_currentPosition!.longitude}");
      Geofire.queryAtLocation(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
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

      // Get the appropriate icon based on the vehicle type
      var vehicleIcon = await getVehicleIcon(driverDetails.carType);

      Marker marker = Marker(
        markerId: MarkerId(key),
        position: driverPosition,
        icon: vehicleIcon, // Use the icon based on vehicle type
      );

      setState(() {
        _driverMarkers.add(marker);
        activeDrivers[key] = driverPosition; // Update active drivers map
      });
    } else {
      print(
          "Error: Missing data in map['key'], map['latitude'], or map['longitude']");
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

      // Get the appropriate icon based on the vehicle type
      var vehicleIcon = await getVehicleIcon(driverDetails.carType);

      Marker marker = Marker(
        markerId: MarkerId(key),
        position: driverPosition,
        icon: vehicleIcon, // Use the icon based on vehicle type
      );

      setState(() {
        _driverMarkers.removeWhere((m) => m.markerId.value == key);
        _driverMarkers.add(marker);
        activeDrivers[key] =
            driverPosition; // Update position in activeDrivers map
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
        _driverMarkers.removeWhere((marker) => marker.markerId.value == key);
        activeDrivers.remove(key); // Remove from active drivers map
      });
    } else {
      print("Error: Missing data in map['key']");
    }
  }
}
