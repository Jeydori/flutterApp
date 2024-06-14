import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:route4me/models/direction_infos.dart';

class NavigationPage extends StatefulWidget {
  final DirectionDetailsInfo directionDetailsInfo;

  NavigationPage({required this.directionDetailsInfo});

  @override
  _NavigationPageState createState() => _NavigationPageState();
}

class _NavigationPageState extends State<NavigationPage> {
  GoogleMapController? _mapController;
  StreamSubscription<Position>? _positionStreamSubscription;

  Position? _currentPosition;
  Set<Polyline> _polylines = Set<Polyline>();
  Set<Marker> _markers = Set<Marker>();
  bool _isNavigating = true;
  BitmapDescriptor? userLocationIcon;
  String _distanceText = "";
  String _etaText = "";

  @override
  void initState() {
    super.initState();
    _initLocationService();
    _drawRoute();
    _locateInitialPosition();
    _loadCustomIcon();
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
    _mapController
        ?.animateCamera(CameraUpdate.newLatLngZoom(currentLatLng, 15));
    _updateUserLocationMarker(currentLatLng);
    _updateDistanceAndEta(currentLatLng);
  }

  void _updateUserLocationMarker(LatLng currentLatLng) {
    Marker currentLocationMarker = Marker(
      markerId: MarkerId('currentLocation'),
      position: currentLatLng,
      icon: userLocationIcon ?? BitmapDescriptor.defaultMarker,
      anchor: Offset(0.5, 1),
    );

    setState(() {
      _markers.removeWhere((m) => m.markerId.value == 'currentLocation');
      _markers.add(currentLocationMarker);
    });
  }

  void _initLocationService() {
    LocationSettings locationSettings = LocationSettings(
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

  void _loadCustomIcon() {
    BitmapDescriptor.fromAssetImage(
            ImageConfiguration(size: Size(1, 1)), 'lib/images/JEEP.png')
        .then((icon) {
      setState(() {
        userLocationIcon = icon;
      });
    }).catchError((e) {
      print("Failed to load user location icon: $e");
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
    if (distance < 30) {
      // Threshold in meters
      _stopNavigation();
      _showArrivalDialog();
    }
  }

  void _drawRoute() {
    List<PointLatLng> decodedPolylinePoints =
        PolylinePoints().decodePolyline(widget.directionDetailsInfo.e_points!);
    List<LatLng> polylineCoordinates = decodedPolylinePoints
        .map((point) => LatLng(point.latitude, point.longitude))
        .toList();

    setState(() {
      _polylines.add(Polyline(
        polylineId: PolylineId('route'),
        points: polylineCoordinates,
        color: Colors.orange.shade900,
        width: 5,
      ));
      _markers.add(Marker(
        markerId: MarkerId('end'),
        position: polylineCoordinates.last,
        infoWindow: InfoWindow(title: 'End'),
      ));
    });
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
        title: Text('Navigation'),
        actions: [
          IconButton(
            icon: Icon(Icons.stop),
            onPressed: _stopNavigation,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: GoogleMap(
              mapType: MapType.normal,
              initialCameraPosition: CameraPosition(
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
              markers: _markers,
              myLocationEnabled: true,
            ),
          ),
          Padding(
            padding: EdgeInsets.all(8.0),
            child: Text('Distance: $_distanceText, ETA: $_etaText'),
          ),
        ],
      ),
    );
  }

  void _slantCamera() {
    _mapController?.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(
      target: LatLng(14.599512, 120.984222),
      zoom: 14.4746,
      tilt: 45.0,
    )));
  }

  void _stopNavigation() {
    setState(() {
      _isNavigating = false;
    });
    _positionStreamSubscription?.cancel();

    // Optionally pass back any required data, such as details about the trip
    Navigator.pop(context, "Trip Completed"); // You can pass back data here
  }

  void _showArrivalDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // User must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Arrived"),
          content: Text("You have arrived at your destination."),
          actions: <Widget>[
            TextButton(
              child: Text('OK'),
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
}
