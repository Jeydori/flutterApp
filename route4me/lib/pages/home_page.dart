import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geocoder2/geocoder2.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart'hide LocationAccuracy;
import 'package:provider/provider.dart';
import 'package:route4me/assistants/assistant_methods.dart';
import 'package:route4me/components/drawer.dart';
import 'package:route4me/global/directions.dart';
import 'package:route4me/global/map_key.dart';

import '../info handler/app_info.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final user = FirebaseAuth.instance.currentUser!;
  final Completer<GoogleMapController> _controllerGoogleMap = Completer();
  GoogleMapController? newGoogleMapController;

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

    final GlobalKey<ScaffoldState> _scaffoldState = GlobalKey<ScaffoldState>();

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
    BitmapDescriptor? activeNearbyIcon;

    locateUserPosition() async {
      Position cPosition = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      userCurrentPosition = cPosition;

      LatLng latLngPosition = LatLng(userCurrentPosition!.latitude, userCurrentPosition!.longitude);
      CameraPosition cameraPosition = CameraPosition(target: latLngPosition, zoom: 15);

      newGoogleMapController!.animateCamera(CameraUpdate.newCameraPosition(cameraPosition));

      String humanReadableAddress = await assistantMethods.searchAddressForGeographicCoordinates(userCurrentPosition!, context);
      print('This is our address = ' + humanReadableAddress);

     // userName = userModelCurrentInfo!.name!;
     // userEmail = userModelCurrentInfo!.email!;

     // initializeGeofireListener();

      //assistantMethods.readTripsKeysForOnlineUser(context);


    }
    
    getAddressFromLatLng() async {
      try {
        GeoData data = await Geocoder2.getDataFromCoordinates(
          latitude: pickLocation!.latitude, 
          longitude: pickLocation!.longitude, 
          googleMapApiKey: mapKey,
          );
          setState(() {
            Directions userPickUpAddress = Directions();
            userPickUpAddress.locationLatitude = pickLocation!.latitude;
            userPickUpAddress.locationLongitude = pickLocation!.longitude;
            userPickUpAddress.locationName = data.address;
            //address = data.address;
            Provider.of<appInfo>(context, listen: false).updatePickUpAddress(userPickUpAddress);

          });
      } catch (e) {
        print(e);
      }
    }

 checkIfLocationPermissionAllowed() async{
  locationPermission = await Geolocator.requestPermission();

  if(locationPermission == LocationPermission.denied){
    locationPermission = await Geolocator.requestPermission();
  } 
 }
    @override
  void initState() {
    // TODO: implement initState
    super.initState();
    checkIfLocationPermissionAllowed();
  }

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
      body: Stack(
          children: [
            GoogleMap(
              mapType: MapType.normal,
              myLocationEnabled: true,
              zoomGesturesEnabled: true,
              zoomControlsEnabled: true,
              initialCameraPosition: _kGooglePlex,
              polylines: polylineSet,
              markers: markerSet,
              circles: circleSet,
              onMapCreated: (GoogleMapController controller) {
                _controllerGoogleMap.complete(controller);
                newGoogleMapController = controller;

                setState(() {
                
                });
                locateUserPosition();
              },
              onCameraMove: (CameraPosition? position){
                if(pickLocation != position!.target){
                  setState(() {
                    pickLocation = position.target;
                  });
                }
              },
              onCameraIdle: (){
                getAddressFromLatLng();
              },
            ),
            Align(
              alignment: Alignment.center,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 35.0),
                child: Icon(Icons.location_on, color: Colors.orange[600],size: 50,)),
            ), 
            Positioned(
              top: 40,
              right: 20,
              left: 20,
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.orange),
                  color: Colors.white,
                ),
                padding: const EdgeInsets.all(20),
                child: Text(
                  Provider.of<appInfo>(context).userPickUpLocation != null? 
                  (Provider.of<appInfo>(context).userPickUpLocation!.locationName!).substring(0, 24) +
                   "..." : "Not Getting Address",
                  overflow: TextOverflow.visible, softWrap: true,
                ),
              ),
              )
          ],
        ),
      ),
    );
  }
}