import 'dart:async';
import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:map_demo/place.dart';
import 'package:map_demo/searched_list_page.dart';

class MapPage extends StatefulWidget {
  const MapPage({Key? key}) : super(key: key);

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  // マップのコントローラー
  late GoogleMapController controller;
  final TextEditingController controller2 = TextEditingController();

  // 定点地（自宅）
  static const CameraPosition position = CameraPosition(
      target: LatLng(34.86982423461154, 135.77321115944304), zoom: 18);

  // 現在地
  late final CameraPosition currentPosition;
  String? errorTxt;
  Place? searchedPlace;
  String distance = "0.0";

  // 現在地取得
  Future<void> getCurrentPosition() async {
    // 権限取得
    LocationPermission permission = await Geolocator.checkPermission();
    // 権限がない場合、リクエストを送る
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('取得不可');
      }
    }
    // ジオロケーターから現在地取得
    final Position _currentPosition = await Geolocator.getCurrentPosition();
    currentPosition = CameraPosition(
        target: LatLng(_currentPosition.latitude, _currentPosition.longitude),
        zoom: 18);
  }

  // マーカーの値（緯度、軽度）
  final Set<Marker> makers = {};

  // 緯度軽度の検索処理
  Future<CameraPosition> searchLatlng(String address) async {
    List<Location> location = await locationFromAddress(address);
    return CameraPosition(
        target: LatLng(location[0].latitude, location[0].longitude), zoom: 18);
  }
  Timer? timer;
  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(Duration(seconds: 1), (t) {
      getCurrentPosition();
      print("latitude：" + currentPosition.target.latitude.toString());
      print("longitude：" + currentPosition.target.longitude.toString());
    });
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
              controller: controller2,
              decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.only(left: 10)),
              onTap: () async {
                Place? result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (builder) => const SearchedListPage()));
                print(result);
                setState(() {
                  searchedPlace = result;
                });
                if (searchedPlace != null) {
                  controller2.text = searchedPlace!.name!;
                  CameraPosition searchedPosition =
                      await searchLatlng(searchedPlace!.address ?? '');
                  setState(() {
                    makers.add(Marker(
                        markerId: const MarkerId('6'),
                        position: searchedPosition.target,
                        infoWindow: const InfoWindow(title: "検索結果")));
                  });
                  controller.animateCamera(
                      CameraUpdate.newCameraPosition(searchedPosition));
                  double _distance = Geolocator.distanceBetween(
                      currentPosition.target.latitude,
                      currentPosition.target.longitude,
                      searchedPosition.target.latitude,
                      searchedPosition.target.longitude);
                  distance = (_distance / 1000).toStringAsFixed(1) + " km";
                }
              },
              // onSubmitted: (value) async {
              //   try {
              //     CameraPosition result = await searchLatlng(value);
              //     controller
              //         .animateCamera(CameraUpdate.newCameraPosition(result));
              //     setState(() {
              //       makers.add(Marker(
              //           markerId: MarkerId('4'),
              //           position: result.target,
              //           infoWindow: InfoWindow(title: "検索場所")));
              //     });
              //     if (errorTxt != null) {
              //       setState(() {
              //         errorTxt = null;
              //       });
              //     }
              //   } catch (e) {
              //     print(e);
              //     setState(() {
              //       errorTxt = "正しい住所を入力してください";
              //     });
              //   }
              // },
            ),
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              errorTxt == null ? Container() : Text(errorTxt!),
              searchedPlace == null
                  ? Container()
                  : SizedBox(
                      height: 100,
                      child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: searchedPlace!.images.length,
                          itemBuilder: ((context, index) {
                            return Image.memory(searchedPlace!.images[index]!);
                          })),
                    ),
              Expanded(
                child: GoogleMap(
                  markers: makers,
                  mapType: MapType.normal,
                  // 初期の位置
                  initialCameraPosition: position,
                  // 右下のボタン制御
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  // はじめに走る処理
                  onMapCreated: ((controller) async {
                    await getCurrentPosition();
                    this.controller = controller;
                    // カメラの位置を移動
                    this.controller.animateCamera(
                        CameraUpdate.newCameraPosition(currentPosition));
                  }),
                ),
              ),
              Text(distance)
            ],
          ),
        ));
  }
}
