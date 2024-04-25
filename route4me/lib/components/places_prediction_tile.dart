import 'package:flutter/material.dart';
import 'package:route4me/models/predicted_places.dart';

class PlacePredictionTile extends StatefulWidget {
  final PredictedPlaces? predictedPlaces;
  PlacePredictionTile({this.predictedPlaces});

  @override
  State<PlacePredictionTile> createState() => _PlacePredictionTileState();
}

class _PlacePredictionTileState extends State<PlacePredictionTile> {
  //getPlacePredictionDetails();

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {},
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.black,
      ),
      child: Padding(
          padding: EdgeInsets.all(8),
          child: Row(
            children: [
              Icon(
                Icons.add_location,
                color: Colors.black,
              ),
              SizedBox(
                width: 10,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.predictedPlaces!.main_text!,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 16, color: Colors.black),
                    ),
                    Text(
                      widget.predictedPlaces!.secondary_text!,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 16, color: Colors.black),
                    ),
                  ],
                ),
              ),
            ],
          )),
    );
  }
}
