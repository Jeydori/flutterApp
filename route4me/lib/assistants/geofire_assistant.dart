import 'package:route4me/models/active_available_drivers.dart';

class GeofireAssistant {
  static List<ActiveAvailableDrivers> activeAvailableDriversList = [];

  static void updateAvailableDriversLocation(ActiveAvailableDrivers driver) {
    // Update the driver location in the list
    for (int i = 0; i < activeAvailableDriversList.length; i++) {
      if (activeAvailableDriversList[i].driverId == driver.driverId) {
        activeAvailableDriversList[i] = driver;
        break;
      }
    }
  }

  static void deleteOfflineDriverfromList(String driverId) {
    activeAvailableDriversList
        .removeWhere((driver) => driver.driverId == driverId);
  }
}
