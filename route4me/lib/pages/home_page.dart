import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_geofire/flutter_geofire.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:route4me/assistants/assistant_methods.dart';
import 'package:route4me/global/global.dart';
import 'package:provider/provider.dart';
import 'package:route4me/info handler/app_info.dart';
import 'package:route4me/components/progress_dialog.dart';
import 'package:route4me/models/direction_infos.dart';
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
  // BitmapDescriptor? activeNearbyIcon;

  @override
  void initState() {
    super.initState();
    checkIfLocationPermissionAllowed();
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

  void handleDriverEntered(Map<dynamic, dynamic> map) {
    var key = map["key"];
    var latitude = map["latitude"];
    var longitude = map["longitude"];
    print("Driver entered: key=$key, latitude=$latitude, longitude=$longitude");

    if (key != null && latitude != null && longitude != null) {
      LatLng driverPosition = LatLng(latitude, longitude);
      Marker marker = Marker(
          markerId: MarkerId(key),
          position: driverPosition,
          icon: BitmapDescriptor.defaultMarker,
          onTap: () {
            showBottomSheet();
          });
      setState(() {
        markerSet.add(marker);
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
      });
    } else {
      print("Error: Missing data in map['key']");
    }
  }

  void handleDriverMoved(Map<dynamic, dynamic> map) {
    var key = map["key"];
    var latitude = map["latitude"];
    var longitude = map["longitude"];
    print("Driver moved: key=$key, latitude=$latitude, longitude=$longitude");

    if (key != null && latitude != null && longitude != null) {
      LatLng driverPosition = LatLng(latitude, longitude);
      Marker marker = Marker(
        markerId: MarkerId(key),
        position: driverPosition,
        icon: BitmapDescriptor.defaultMarker,
        onTap: () {
          showBottomSheet();
        },
      );
      setState(() {
        markerSet.removeWhere((m) => m.markerId.value == key);
        markerSet.add(marker);
      });
    } else {
      print(
          "Error: Missing data in map['key'], map['latitude'], or map['longitude']");
    }
  }

  // Function to show bottom sheet
  void showBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          height: 300,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Center(
            child: Text('Driver Information'),
          ),
        );
      },
    );
  }

  void showRouteSelectionSheet(
      BuildContext context, List<DirectionDetailsInfo> directionsList) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          height: 300,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.all(8.0),
                child: Center(
                  child: Text('Choose a Route',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: directionsList.length,
                  itemBuilder: (context, index) {
                    var directionDetailsInfo = directionsList[index];
                    return ListTile(
                      title: Text('Route ${index + 1}'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              'Distance: ${directionDetailsInfo.distance_text}'),
                          Text(
                              'Duration: ${directionDetailsInfo.duration_text}'),
                          if (directionDetailsInfo.fare != null)
                            Text(
                                'Estimated Fare: ${directionDetailsInfo.fare}'),
                        ],
                      ),
                      onTap: () {
                        Navigator.pop(
                            context); // Close this sheet and open the detailed route sheet
                        _drawSelectedRoute(
                            context, directionDetailsInfo, directionsList);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _drawSelectedRoute(
      BuildContext context,
      DirectionDetailsInfo directionDetailsInfo,
      List<DirectionDetailsInfo> directionsList) async {
    setState(() {
      tripDirectionDetailsInfo = directionDetailsInfo;
    });

    polylineSet.clear();
    circleSet.clear();

    PolylinePoints polylinePoints = PolylinePoints();
    List<PointLatLng> decodedPolylinePoints =
        polylinePoints.decodePolyline(directionDetailsInfo.e_points!);
    List<LatLng> polylineCoordinates = decodedPolylinePoints
        .map((point) => LatLng(point.latitude, point.longitude))
        .toList();

    LatLngBounds boundsLatLng = _calculateLatLngBounds(polylineCoordinates);
    newGoogleMapController!
        .animateCamera(CameraUpdate.newLatLngBounds(boundsLatLng, 70));

    for (var step in directionDetailsInfo.steps!) {
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

    // Define custom Circle indicators for departure and arrival
    for (var transitStep in directionDetailsInfo.transitSteps!) {
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

    // Optional: Mark the starting and ending locations more prominently
    if (polylineCoordinates.isNotEmpty) {
      circleSet.add(Circle(
        circleId: CircleId('end'),
        center: polylineCoordinates.last,
        radius: 80,
        fillColor: Colors.red,
        strokeWidth: 1,
        strokeColor: Colors.white,
      ));
    }

    setState(() {}); // Trigger a UI update if needed.

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          height: 300,
          child: Column(
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: IconButton(
                  icon: Icon(Icons.arrow_back),
                  onPressed: () {
                    Navigator.pop(context); // Close this details sheet
                    showRouteSelectionSheet(
                        context, directionsList); // Reopen the selection sheet
                  },
                ),
              ),
              Center(
                child: Text('Route Information'),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Distance: ${directionDetailsInfo.distance_text}'),
                    Text('Duration: ${directionDetailsInfo.duration_text}'),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: directionDetailsInfo.transitSteps!.length,
                  itemBuilder: (context, index) {
                    var transitStep = directionDetailsInfo.transitSteps![index];
                    return ListTile(
                      title: Text(
                          '${transitStep.vehicleType} - ${transitStep.lineName}'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Agency: ${transitStep.agencyName}'),
                          Text(
                              'From: ${transitStep.departureStop} at ${transitStep.departureTime}'),
                          Text(
                              'To: ${transitStep.arrivalStop} at ${transitStep.arrivalTime}'),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
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

    var directionsList =
        await assistantMethods.obtainOriginToDestinationDirectionDetails(
            originLatLng, destinationLatLng);

    Navigator.pop(context);

    if (directionsList.isEmpty) {
      print("No routes found");
      return;
    }

    showRouteSelectionSheet(context, directionsList);
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
    // createActiveNearByDriverIconMarker();
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
          ],
        ),
      ),
    );
  }
}
