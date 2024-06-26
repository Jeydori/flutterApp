import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:route4me/assistants/request_assistant.dart';
import 'package:route4me/components/progress_dialog.dart';
import 'package:route4me/global/directions.dart';
import 'package:route4me/global/global.dart';
import 'package:route4me/global/map_key.dart';
import 'package:route4me/info%20handler/app_info.dart';
import 'package:route4me/models/predicted_places.dart';

class PlacePredictionTile extends StatefulWidget {
  final PredictedPlaces? predictedPlaces;
  const PlacePredictionTile({super.key, this.predictedPlaces});

  @override
  State<PlacePredictionTile> createState() => _PlacePredictionTileState();
}

class _PlacePredictionTileState extends State<PlacePredictionTile> {
  getPlacePredictionDetails(String? placeId, context) async {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return ProgressDialog(message: "Setting up Destination Location...");
        });
    String placeDirectionDetailUrl =
        "https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=$mapKey";

    var responseApi =
        await RequestAssistant.receiveRequest(placeDirectionDetailUrl);

    Navigator.pop(
        context); // Ensure this is within the if check to avoid popping without a dialog

    if (responseApi == "Error Occurred. Failed. No Response.") {
      return;
    }
    if (responseApi["status"] == "OK") {
      Directions directions = Directions();
      directions.locationName = responseApi["result"]["name"];
      directions.locationId = placeId;
      directions.locationLatitude =
          responseApi["result"]["geometry"]["location"]["lat"];
      directions.locationLongitude =
          responseApi["result"]["geometry"]["location"]["lng"];

      Provider.of<appInfo>(context, listen: false)
          .updateDestinationAddress(directions);

      setState(() {
        userDestinationAddress = directions.locationName!;
      });
      Navigator.pop(context, "obtainedDestination");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.orange, width: 1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: ElevatedButton(
        onPressed: () {
          getPlacePredictionDetails(widget.predictedPlaces!.place_id, context);
        },
        style: ElevatedButton.styleFrom(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          backgroundColor: Colors.white,
          elevation: 0, // Remove shadow for cleaner appearance
          padding:
              EdgeInsets.zero, // Remove default padding from ElevatedButton
        ),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                color: Colors.black,
              ),
              const SizedBox(
                width: 10,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.predictedPlaces!.main_text!,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 16, color: Colors.black),
                    ),
                    Text(
                      widget.predictedPlaces!.secondary_text!,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 16, color: Colors.black),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
