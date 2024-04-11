import 'package:flutter/cupertino.dart';
import 'package:route4me/global/directions.dart';

class appInfo extends ChangeNotifier{
  Directions? userPickUpLocation, userDestinationLocation;
  int countTotalTrips = 0;
  //List<String> historyTripsKeysList = [];
  //List<TripsHistoryModel> allTripHistoryInformationList = [];

  void updatePickUpAddress(Directions userPickUpAddress){
    userPickUpLocation = userPickUpAddress;
    notifyListeners();
  }
  void updateDestinationAddress(Directions userDestinationAddress){
    userDestinationLocation = userDestinationAddress;
    notifyListeners();
  }
}