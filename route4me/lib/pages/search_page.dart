import 'package:flutter/material.dart';
import 'package:route4me/models/predicted_places.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  List<PredictedPlaces> placesPredictedList = [];

  findPlaceAutoCompleteSearch(String inputText) async {}

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.amber.shade400,
          leading: GestureDetector(
            onTap: () {
              Navigator.pop(context);
            },
            child: Icon(
              Icons.arrow_back,
              color: Colors.black,
            ),
          ),
          title: Text(
            "Search & Set dropoff location",
            style: TextStyle(color: Colors.orange[600]),
          ),
          elevation: 0.0,
        ),
        body: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.amber.shade400,
                boxShadow: [
                  BoxShadow(
                    color: Colors.white,
                    blurRadius: 8,
                    spreadRadius: 0.5,
                    offset: Offset(
                      0.7,
                      0.7,
                    ),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.all(10.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.adjust_sharp,
                          color: Colors.black,
                        ),
                        SizedBox(
                          height: 18.0,
                        ),
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.all(8),
                            child: TextField(
                              onChanged: (value) {
                                findPlaceAutoCompleteSearch(value);
                              },
                              decoration: InputDecoration(
                                  hintText: "Search location here...",
                                  fillColor: Colors.orange,
                                  filled: true,
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.only(
                                    left: 11,
                                    top: 8,
                                    bottom: 8,
                                  )),
                            ),
                          ),
                        )
                      ],
                    ),
                  ],
                ),
              ),
            ),

            //display places prediction
            (placesPredictedList.length > 0)
            ? Expanded(
              child: ListView.separated(
                itemCount: placesPredictedList.length,
                physics: ClampingScrollPhysics(),
                itemBuilder: (context, index){
                  return
                }, 
                separatorBuilder: separatorBuilder, 
              ),
            )
          ],
        ),
      ),
    );
  }
}
