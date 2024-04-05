//import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:route4me/components/drawer.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final user = FirebaseAuth.instance.currentUser!;
  //final Completer<GoogleMapController> _controllerGoogleMap = Completer();

  LatLng? pickLocation;
  Location location = Location();
  String? address;

  static const CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(37.42796133580664, -122.085749655962),
    zoom: 14.4746,
  );

 /* static const CameraPosition _kLake = CameraPosition(
      bearing: 192.8334901395799,
      target: LatLng(37.43296265331129, -122.08832357078792),
      tilt: 59.440717697143555,
      zoom: 19.151926040649414);*/

    //final GlobalKey<ScaffoldState> _scaffoldState = GlobalKey<ScaffoldState>();

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

    bool openNavigatorDrawer = true;

    bool activeNearbyDriverKeysLoaded = false;
    BitmapDescriptor? activeNearbyIcon;


  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: (){
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        appBar: AppBar(
        title: const Text("Home"),
      ),
      drawer: const MyDrawer(),
      body: const Stack(
          children: [
            GoogleMap(
              initialCameraPosition: _kGooglePlex,
              ),
          ],
        ),
      ),
    );
  }
}