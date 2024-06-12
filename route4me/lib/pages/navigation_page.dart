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
  Position? _currentPosition;
  Set<Polyline> _polylines = Set<Polyline>();
  Set<Marker> _markers = Set<Marker>();
  bool _isNavigating = true;

  @override
  void initState() {
    super.initState();
    _initLocationService();
    _drawRoute();
  }

  StreamSubscription<Position>? _positionStreamSubscription;

  void _initLocationService() {
    LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );

    _positionStreamSubscription =
        Geolocator.getPositionStream(locationSettings: locationSettings).listen(
            (Position position) {
      if (position != null) {
        setState(() {
          _currentPosition = position;
          _updateUserLocation();
        });
      }
    }, onError: (e) {
      print("Error getting location stream: $e");
    });
  }

  void _stopNavigation() {
    setState(() {
      _isNavigating = false;
    });
    _positionStreamSubscription
        ?.cancel(); // Cancel the position stream subscription
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
        color: Colors.blue,
        width: 5,
      ));
      _markers.add(Marker(
        markerId: MarkerId('start'),
        position: polylineCoordinates.first,
        infoWindow: InfoWindow(title: 'Start'),
      ));
      _markers.add(Marker(
        markerId: MarkerId('end'),
        position: polylineCoordinates.last,
        infoWindow: InfoWindow(title: 'End'),
      ));
    });
  }

  void _updateUserLocation() {
    if (_currentPosition != null && _isNavigating) {
      LatLng currentLatLng =
          LatLng(_currentPosition!.latitude, _currentPosition!.longitude);

      // Move the camera to the new location
      _mapController?.animateCamera(CameraUpdate.newLatLng(currentLatLng));

      // Update or add the marker for the current location
      Marker currentLocationMarker = Marker(
        markerId: MarkerId('currentLocation'),
        position: currentLatLng,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      );

      setState(() {
        // Check if the marker already exists
        _markers.removeWhere((m) => m.markerId.value == 'currentLocation');
        _markers.add(currentLocationMarker);
      });
    }
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
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: LatLng(14.599512, 120.984222),
          zoom: 14.4746,
        ),
        onMapCreated: (controller) {
          setState(() {
            _mapController = controller;
          });
        },
        polylines: _polylines,
        markers: _markers,
        myLocationEnabled: true,
      ),
    );
  }
}
