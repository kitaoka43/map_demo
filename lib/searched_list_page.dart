import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_place/google_place.dart';
import 'package:map_demo/place.dart';

class SearchedListPage extends StatefulWidget {
  const SearchedListPage({Key? key}) : super(key: key);

  @override
  State<SearchedListPage> createState() => _SearchedListPageState();
}

class _SearchedListPageState extends State<SearchedListPage> {
  late GooglePlace googlePlace;
  List<AutocompletePrediction>? predictions = [];
  List<Place> places =[];

  // 緯度軽度の検索処理
  Future<void> searchLatlng(String txt) async {
    final result = await googlePlace.autocomplete.get(txt);
    if (result != null){
      predictions = result.predictions;
      if (predictions != null){
       print(predictions![0].description);
       for (AutocompletePrediction prediction in predictions!){
         googlePlace.details.get(prediction.placeId!).then((value) async{
           if(value != null && value.result != null && value.result!.photos != null){
             List<Uint8List?> photos = [];
             await Future.forEach(value.result!.photos!, (element) {
               Photo photo = element;
               googlePlace.photos.get(photo.photoReference!, 200, 200).then((value){
                 photos.add(value);
               });
             });
             setState(() {
             places.add(Place(name: value.result!.name, address: prediction.description, images: photos));
             });
           }
         });
       }
      }
    }
  }

  @override
  void initState() {
    super.initState();
    googlePlace = GooglePlace("AIzaSyDfyTUZ_0i0zAEZFqqvL77xsYPzktre_Xw");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.black),
        elevation: 0,
        backgroundColor: Colors.white,
        title: SizedBox(
          height: 40,
          child: TextField(
            autofocus: true,
            decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.only(left: 10)),
            onSubmitted: (value) async {
              searchLatlng(value);
            }
          ),
        ),
      ),
      body: ListView.builder(itemCount: places.length,itemBuilder: (context, index) {
        return ListTile(
          title: Text(places[index].address ?? ''),
          onTap: (){
            print(places[index]);
            Navigator.pop(context, places[index]);
          },
        );
      },),
    );
  }
}
