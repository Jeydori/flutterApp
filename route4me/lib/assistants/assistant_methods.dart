import 'package:geolocator/geolocator.dart';
import 'package:route4me/assistants/request_assistant.dart';
import 'package:route4me/global/directions.dart';
import 'package:route4me/global/map_key.dart';

class assistantMethods{
  static Future<String> searchAddressForGeographicCoordinates(Position position, context) async{
    String apiURL = "https://maps.googleapis.com/maps/api/geocode/json/latlng=${position.latitude},${position.longitude}&key=$mapKey";
    String humanReadableAddress = "";

    var requestResponse = await RequestAssistant.receiveRequest(apiURL);

    if(requestResponse != "Error Occured. Failed. No Response."){
      humanReadableAddress = requestResponse["results"][0]["formatted_address"];

      Directions userDestinationAddress = Directions();
      userDestinationAddress.locationLatitude = position.latitude;
      userDestinationAddress.locationLongitude = position.longitude;
      userDestinationAddress.locationName = humanReadableAddress;
      
     //Provider.of<AppInfo>(context, listen: false).updateDestinationLocationAddress(userDestinationAddress);
    }
    return humanReadableAddress;
  }
}