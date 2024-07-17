import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_geofire/flutter_geofire.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:route4me/models/direction_infos.dart';
import 'package:route4me/models/driver_details.dart';
import 'package:firebase_database/firebase_database.dart';

class NavigationPage extends StatefulWidget {
  final DirectionDetailsInfo directionDetailsInfo;
  final LatLng destinationPosition; // Add this line

  const NavigationPage(
      {super.key,
      required this.directionDetailsInfo,
      required this.destinationPosition}); // Update constructor

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

  bool hasNavigated = false;

  @override
  void initState() {
    super.initState();
    _initLocationService();
    _drawRoute();
    checkIfLocationPermissionAllowed();
    print(
        "Destination set to: ${widget.directionDetailsInfo.destinationLatitude}, ${widget.directionDetailsInfo.destinationLongitude}"); // Debug destination
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  void _initLocationService() {
    LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 2, // More frequent updates
    );

    _positionStreamSubscription =
        Geolocator.getPositionStream(locationSettings: locationSettings).listen(
            (Position position) {
      _currentPosition = position;
      if (!hasNavigated) {
        _updateNavigation();
      }
      _slantCamera();
    }, onError: (e) {
      print("Error getting location stream: $e");
    });
  }

  void _updateNavigation() {
    double distance = Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      widget
          .destinationPosition.latitude, // Use the passed destination latitude
      widget.destinationPosition
          .longitude, // Use the passed destination longitude
    );

    if (distance <= 50 && !hasNavigated) {
      print("Near destination, stopping navigation.");
      hasNavigated = true;
      _stopNavigation();
    }
  }

  void _stopNavigation() {
    if (_positionStreamSubscription != null) {
      _positionStreamSubscription!.cancel();
      _positionStreamSubscription = null;
      _showArrivalDialog();
      print("Navigation stopped.");
    }
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

  void _slantCamera() {
    if (_currentPosition != null) {
      LatLng currentLatLng =
          LatLng(_currentPosition!.latitude, _currentPosition!.longitude);
      _mapController
          ?.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(
        target: currentLatLng,
        zoom: 18,
        tilt: 70,
        bearing: _currentPosition!.heading,
      )));
    }
  }

  void _drawRoute() {
    List<PointLatLng> decodedPolylinePoints =
        PolylinePoints().decodePolyline(widget.directionDetailsInfo.e_points!);
    polylineCoordinates = decodedPolylinePoints
        .map((point) => LatLng(point.latitude, point.longitude))
        .toList();

    setState(() {
      _polylines.clear();
      _markers.clear();
      _circles.clear();

      final Color walkingColor = Colors.orange;
      final Color transitColor = Colors.orange;
      final int defaultWidth = 7; // Increased width for all polylines
      final int walkingWidth = 9; // Even thicker width for walking segments

      for (var step in widget.directionDetailsInfo.steps ?? []) {
        List<PointLatLng> stepPoints =
            PolylinePoints().decodePolyline(step['polyline']['points']);
        List<LatLng> stepCoordinates = stepPoints
            .map((point) => LatLng(point.latitude, point.longitude))
            .toList();

        Polyline polyline = Polyline(
            polylineId: PolylineId('step_${stepCoordinates.hashCode}'),
            points: stepCoordinates,
            color:
                step['travel_mode'] == 'WALKING' ? walkingColor : transitColor,
            width:
                step['travel_mode'] == 'WALKING' ? walkingWidth : defaultWidth,
            patterns: step['travel_mode'] == 'WALKING'
                ? [PatternItem.dot, PatternItem.gap(10)]
                : []);

        _polylines.add(polyline);
      }
      if (widget.directionDetailsInfo.transitSteps != null) {
        for (var transitStep in widget.directionDetailsInfo.transitSteps!) {
          Circle departureCircle = Circle(
            circleId: CircleId('departure_${transitStep.departureStop}'),
            center: transitStep.departureLocation,
            radius: 20,
            fillColor: Colors.white.withOpacity(0.5),
            strokeColor: Colors.black,
            strokeWidth: 2,
          );

          Circle arrivalCircle = Circle(
            circleId: CircleId('arrival_${transitStep.arrivalStop}'),
            center: transitStep.arrivalLocation!,
            radius: 20,
            fillColor: Colors.white.withOpacity(0.5),
            strokeColor: Colors.black,
            strokeWidth: 2,
          );

          _circles.add(departureCircle);
          _circles.add(arrivalCircle);
        }
      }
    });
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
            onPressed: () {
              _stopNavigation();
            },
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
                });
              },
              polylines: _polylines,
              markers: _markers.union(_driverMarkers),
              circles: _circles,
              myLocationEnabled: true,
            ),
          ),
        ],
      ),
    );
  }

  Future<BitmapDescriptor> getVehicleIcon(String vehicleType) async {
    print('Vehicle type: $vehicleType'); // Debugging line
    String iconName;
    switch (vehicleType) {
      case 'Bus Ordinary (O-PUB)':
      case 'Bus Aircon (A-PUB)':
        iconName = 'lib/images/bus.png';
        break;
      case 'E-Jeepney Aircon (A-MPUJ)':
      case 'E-Jeepney Non-Aircon (Na-MPUJ)':
        iconName = 'lib/images/e-jeep.png';
        break;
      case 'Jeepney (TPUJ)':
      default:
        iconName = 'lib/images/jeep.png'; // Default to jeep icon
    }

    print('Icon name: $iconName'); // Debugging line

    return BitmapDescriptor.fromAssetImage(
        ImageConfiguration(size: Size(1, 1)), iconName);
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
    var key = map["key"] as String;
    var latitude = map["latitude"] as double;
    var longitude = map["longitude"] as double;
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
    var key = map["key"] as String;
    var latitude = map["latitude"] as double;
    var longitude = map["longitude"] as double;
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
    var key = map["key"] as String;
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
