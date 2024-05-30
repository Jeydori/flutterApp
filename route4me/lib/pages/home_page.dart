import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_geofire/flutter_geofire.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:route4me/assistants/assistant_methods.dart';
import 'package:route4me/global/global.dart';
import 'package:route4me/assistants/geofire_assistant.dart';
import 'package:route4me/models/active_available_drivers.dart';
import 'package:provider/provider.dart';
import 'package:route4me/info handler/app_info.dart';
import 'package:route4me/components/progress_dialog.dart';
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

  static const CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(37.42796133580664, -122.085749655962),
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
  BitmapDescriptor? activeNearbyIcon;

  @override
  void initState() {
    super.initState();
    checkIfLocationPermissionAllowed();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    createActiveNearByDriverIconMarker();
  }

  void checkIfLocationPermissionAllowed() async {
    locationPermission = await Geolocator.requestPermission();

    if (locationPermission == LocationPermission.denied) {
      locationPermission = await Geolocator.requestPermission();
    }
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

        String humanReadableAddress =
            await assistantMethods.searchAddressForGeographicCoordinates(
                userCurrentPosition!, context);
        print('This is our address = $humanReadableAddress');

        userName = userModelCurrentInfo?.firstName ?? "Unknown";
        userEmail = userModelCurrentInfo?.email ?? "Unknown";

        initializeGeofireListener();
      } else {
        print("User current position is null.");
      }
    } catch (e) {
      print("Error locating user position: $e");
    }
  }

  void initializeGeofireListener() {
    Geofire.initialize("activeDrivers");

    if (userCurrentPosition != null) {
      Geofire.queryAtLocation(
        userCurrentPosition!.latitude,
        userCurrentPosition!.longitude,
        10,
      )?.listen((dynamic data) {
        if (data is Map<String, dynamic>) {
          var map = data as Map<String, dynamic>;
          var callBack = map['callBack'] as String?;
          switch (callBack) {
            case Geofire.onKeyEntered:
              handleDriverEntered(map);
              break;
            case Geofire.onKeyExited:
              handleDriverExited(map);
              break;
            case Geofire.onKeyMoved:
              handleDriverMoved(map);
              break;
            case Geofire.onGeoQueryReady:
              print("GeoQuery is ready.");
              activeNearbyDriverKeysLoaded = true;
              displayActiveDriversOnUsersMap();
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

  void handleDriverEntered(Map<String, dynamic> map) {
    var key = map["key"] as String?;
    var location = map["l"] as List<dynamic>?;
    if (key != null && location != null && location.length >= 2) {
      ActiveAvailableDrivers activeNearByAvailableDrivers =
          ActiveAvailableDrivers(
        driverId: key,
        locationLatitude: location[0] as double,
        locationLongitude: location[1] as double,
      );
      GeofireAssistant.activeAvailableDriversList
          .add(activeNearByAvailableDrivers);
      if (activeNearbyDriverKeysLoaded) {
        displayActiveDriversOnUsersMap();
      }
    } else {
      print("Error: Missing data in map['key'] or map['l']");
    }
  }

  void handleDriverExited(Map<String, dynamic> map) {
    var key = map["key"] as String?;
    if (key != null) {
      GeofireAssistant.deleteOfflineDriverfromList(key);
      displayActiveDriversOnUsersMap();
    } else {
      print("Error: Missing data in map['key']");
    }
  }

  void handleDriverMoved(Map<String, dynamic> map) {
    var key = map["key"] as String?;
    var location = map["l"] as List<dynamic>?;
    if (key != null && location != null && location.length >= 2) {
      ActiveAvailableDrivers activeNearByAvailableDrivers =
          ActiveAvailableDrivers(
        driverId: key,
        locationLatitude: location[0] as double,
        locationLongitude: location[1] as double,
      );
      GeofireAssistant.updateAvailableDriversLocation(
          activeNearByAvailableDrivers);
      displayActiveDriversOnUsersMap();
    } else {
      print("Error: Missing data in map['key'] or map['l']");
    }
  }

  void createActiveNearByDriverIconMarker() {
    if (activeNearbyIcon == null) {
      BitmapDescriptor.fromAssetImage(
        ImageConfiguration(
            devicePixelRatio:
                2.5), // You can adjust the devicePixelRatio if needed
        'assets/images/jeep.png',
      ).then((icon) {
        setState(() {
          activeNearbyIcon = icon;
        });
      }).catchError((e) {
        print("Error loading jeep.png: $e");
      });
    }
  }

  void displayActiveDriversOnUsersMap() {
    setState(() {
      markerSet.clear(); // Clear existing markers

      for (var driver in GeofireAssistant.activeAvailableDriversList) {
        LatLng driverPosition =
            LatLng(driver.locationLatitude, driver.locationLongitude);
        Marker marker = Marker(
          markerId: MarkerId(driver.driverId),
          position: driverPosition,
          icon: activeNearbyIcon ??
              BitmapDescriptor.defaultMarker, // Use the custom icon
        );
        markerSet.add(marker); // Add marker to the set
      }
    });
  }

  Future<void> drawPolylineFromOriginToDestination() async {
    var originPosition =
        Provider.of<appInfo>(context, listen: false).userPickUpLocation;
    var destinationPosition =
        Provider.of<appInfo>(context, listen: false).userDestinationLocation;

    var originLatLng = LatLng(
        originPosition!.locationLatitude!, originPosition.locationLongitude!);
    var destinationLatLng = LatLng(destinationPosition!.locationLatitude!,
        destinationPosition.locationLongitude!);

    showDialog(
      context: context,
      builder: (BuildContext context) =>
          ProgressDialog(message: "Please wait..."),
    );

    var directionDetailsInfo =
        await assistantMethods.obtainOriginToDestinationDirectionDetails(
            originLatLng, destinationLatLng);

    setState(() {
      tripDirectionDetailsInfo = directionDetailsInfo;
    });

    Navigator.pop(context);

    PolylinePoints pPoints = PolylinePoints();
    List<PointLatLng> decodePolylinePointsResultList =
        pPoints.decodePolyline(directionDetailsInfo.e_points!);

    pLineCoordinatedList.clear();

    if (decodePolylinePointsResultList.isNotEmpty) {
      for (var pointLatLng in decodePolylinePointsResultList) {
        pLineCoordinatedList
            .add(LatLng(pointLatLng.latitude, pointLatLng.longitude));
      }
    }

    polylineSet.clear();

    setState(() {
      Polyline polyline = Polyline(
        color: Colors.blue,
        polylineId: const PolylineId('PolylineID'),
        jointType: JointType.round,
        points: pLineCoordinatedList,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        geodesic: true,
        width: 5,
      );
      polylineSet.add(polyline);
    });

    LatLngBounds boundsLatLng;
    if (originLatLng.latitude > destinationLatLng.latitude &&
        originLatLng.longitude > destinationLatLng.longitude) {
      boundsLatLng =
          LatLngBounds(southwest: destinationLatLng, northeast: originLatLng);
    } else if (originLatLng.longitude > destinationLatLng.longitude) {
      boundsLatLng = LatLngBounds(
        southwest: LatLng(originLatLng.latitude, destinationLatLng.longitude),
        northeast: LatLng(destinationLatLng.latitude, originLatLng.longitude),
      );
    } else if (originLatLng.latitude > destinationLatLng.latitude) {
      boundsLatLng = LatLngBounds(
        southwest: LatLng(destinationLatLng.latitude, originLatLng.longitude),
        northeast: LatLng(originLatLng.latitude, destinationLatLng.longitude),
      );
    } else {
      boundsLatLng =
          LatLngBounds(southwest: originLatLng, northeast: destinationLatLng);
    }

    newGoogleMapController!
        .animateCamera(CameraUpdate.newLatLngBounds(boundsLatLng, 65));

    Marker originMaker = Marker(
      markerId: const MarkerId("originID"),
      infoWindow:
          InfoWindow(title: originPosition.locationName, snippet: "Origin"),
      position: originLatLng,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
    );

    Marker destinationMaker = Marker(
      markerId: const MarkerId("destinationID"),
      infoWindow: InfoWindow(
          title: destinationPosition.locationName, snippet: "Destination"),
      position: destinationLatLng,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
    );

    setState(() {
      markerSet.add(originMaker);
      markerSet.add(destinationMaker);
    });

    Circle originCircle = Circle(
      circleId: const CircleId("originID"),
      fillColor: Colors.green,
      radius: 12,
      strokeWidth: 3,
      strokeColor: Colors.white,
      center: originLatLng,
    );

    Circle destinationCircle = Circle(
      circleId: const CircleId("destinationID"),
      fillColor: Colors.red,
      radius: 12,
      strokeWidth: 3,
      strokeColor: Colors.white,
      center: destinationLatLng,
    );

    setState(() {
      circleSet.add(originCircle);
      circleSet.add(destinationCircle);
    });
  }

  @override
  Widget build(BuildContext context) {
    createActiveNearByDriverIconMarker();
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
        body: Stack(
          children: [
            GoogleMap(
              mapType: MapType.normal,
              myLocationEnabled: true,
              zoomGesturesEnabled: true,
              zoomControlsEnabled: false,
              initialCameraPosition: _kGooglePlex,
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
                                        Column(
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
                                    'Change Pickup',
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
                                  onPressed: () {},
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
                                    'Show PUVs',
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
          ],
        ),
      ),
    );
  }
}
