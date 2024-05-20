import 'package:route4me/models/active_available_drivers.dart';

class GeofireAssistant {
  static List<ActiveAvailableDrivers> activeAvailableDriversList = [];

  static void deleteOfflineDriverfromList(String driverId) {
    int indexNumber = activeAvailableDriversList
        .indexWhere((element) => element.driverId == driverId);

    activeAvailableDriversList.removeAt(indexNumber);
  }

  static void updateAvailableDriversLocation(
      ActiveAvailableDrivers driverWhoMove) {
    int indexNumber = activeAvailableDriversList
        .indexWhere((element) => element.driverId == driverWhoMove.driverId);

    activeAvailableDriversList[indexNumber].locationLatitude =
        driverWhoMove.locationLatitude;
    activeAvailableDriversList[indexNumber].locationLongitude =
        driverWhoMove.locationLongitude;
  }
}
