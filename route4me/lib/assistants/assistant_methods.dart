import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:route4me/assistants/request_assistant.dart';
import 'package:route4me/global/directions.dart';
import 'package:route4me/global/global.dart';
import 'package:route4me/global/map_key.dart';
import 'package:route4me/info%20handler/app_info.dart';
import 'package:route4me/models/user_model.dart';

class assistantMethods {
  static void readCurrentOnlineUserInfo() async {
    final currentUser = firebaseAuth.currentUser;
    if (currentUser != null) {
      final userRef =
          FirebaseFirestore.instance.collection('Users').doc(currentUser.uid);

      userRef.get().then((doc) {
        if (doc.exists) {
          userModelCurrentInfo = UserModel.fromSnapshot(doc);
        }
      }).catchError((error) {
        print("Failed to get user info: $error");
      });
    }
  }

  static Future<String> searchAddressForGeographicCoordinates(
      Position position, context) async {
    String apiURL =
        "https://maps.googleapis.com/maps/api/geocode/json/latlng=${position.latitude},${position.longitude}&key=$mapKey";
    String humanReadableAddress = "";

    var requestResponse = await RequestAssistant.receiveRequest(apiURL);

    if (requestResponse != "Error Occured. Failed. No Response.") {
      humanReadableAddress = requestResponse["results"][0]["formatted_address"];

      Directions userPickUpAddress = Directions();
      userPickUpAddress.locationLatitude = position.latitude;
      userPickUpAddress.locationLongitude = position.longitude;
      userPickUpAddress.locationName = humanReadableAddress;

      Provider.of<appInfo>(context, listen: false)
          .updatePickUpAddress(userPickUpAddress);
    }
    return humanReadableAddress;
  }
}
