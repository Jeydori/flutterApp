import 'package:flutter/material.dart';
import 'package:route4me/models/direction_infos.dart';

class RouteSelectionSheet extends StatefulWidget {
  final List<DirectionDetailsInfo> directionsList;
  final Function(List<TransitInfo>?) calculateTotalFare;
  final Function(BuildContext, DirectionDetailsInfo, List<DirectionDetailsInfo>)
      drawSelectedRoute;
  final Function(BuildContext, DirectionDetailsInfo, List<DirectionDetailsInfo>,
      DirectionDetailsInfo?, String) showRouteInfoBottomSheet;
  final String carType; // Add carType parameter

  const RouteSelectionSheet({
    super.key,
    required this.directionsList,
    required this.calculateTotalFare,
    required this.drawSelectedRoute,
    required this.showRouteInfoBottomSheet,
    required this.carType, // Initialize carType
  });

  @override
  _RouteSelectionSheetState createState() => _RouteSelectionSheetState();
}

class _RouteSelectionSheetState extends State<RouteSelectionSheet> {
  bool sortByDuration = true;

  void toggleSortCriteria() {
    setState(() {
      sortByDuration = !sortByDuration;
    });
  }

  @override
  Widget build(BuildContext context) {
    List<DirectionDetailsInfo> sortedList = List.from(widget.directionsList);
    if (sortByDuration) {
      sortedList.sort(
          (a, b) => a.duration_value?.compareTo(b.duration_value ?? 0) ?? 0);
    } else {
      sortedList.sort((a, b) => widget
          .calculateTotalFare(a.transitSteps ?? [])
          .compareTo(widget.calculateTotalFare(b.transitSteps ?? [])));
    }

    return Container(
      padding: const EdgeInsets.only(top: 20, bottom: 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          Center(
            child: ToggleButtons(
              borderRadius:
                  BorderRadius.circular(10), // Sets border radius to 10
              fillColor:
                  Colors.orange.shade50, // Background color when selected
              selectedBorderColor:
                  Colors.orange.shade600, // Border color when selected
              borderColor: Colors.orange.shade600, // Normal border color
              borderWidth: 2, // Border width
              onPressed: (int index) {
                setState(() {
                  sortByDuration = index == 0;
                });
              },
              isSelected: [sortByDuration, !sortByDuration],
              children: const <Widget>[
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text("Fastest"),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text("Cheapest"),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.builder(
              itemCount: sortedList.length,
              itemBuilder: (ctx, index) {
                var info = sortedList[index];
                double totalFare =
                    widget.calculateTotalFare(info.transitSteps ?? []);
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    border:
                        Border.all(color: Colors.orange.shade600, width: 2.0),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: ListTile(
                    subtitle: Text(
                      'Distance: ${info.distance_text ?? "Not available"}, Duration: ${info.duration_text}, Fare: ₱${totalFare.toStringAsFixed(2)}',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    onTap: () {
                      widget.drawSelectedRoute(
                          context, info, widget.directionsList);
                    },
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }
}
