import 'dart:convert';

import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:presensi/model/api.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocationArea extends StatefulWidget {
  @override
  _LocationAreaState createState() => _LocationAreaState();
}

double jarakapi;

class _LocationAreaState extends State<LocationArea> {
  final Geolocator geolocator = Geolocator()..forceAndroidLocationManager;
  final Set<Marker> _markers = {};

  final snackbarKey = GlobalKey<ScaffoldState>();
  final GlobalKey<ScaffoldState> _scaffoldState =
      new GlobalKey<ScaffoldState>();

  Position _currentPosition;
  String _currentAddress;
  LatLng _position;
  bool _isLoading = false;
  var lat, lng;
  String nik;
  String userid;
  double jarak;
  List array_jarak;

  getPref() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    setState(() {
      nik = preferences.getString("nik");
      userid = preferences.getString("id");
    });
  }

  getjarak() async {
    final respose = await http.get(BaseUrl.getjarak);
    jarakapi = double.parse(jsonDecode(respose.body));
  }

  @override
  void initState() {
    if (this.mounted) {
      setState(() {
        getjarak();
        getPref();
        getLokasiKantor();
        _getCurrentLocation();
      });
    }
    super.initState();
  }

  void _snackbar(String str) {
    if (str.isEmpty) return;
    _scaffoldState.currentState.showSnackBar(new SnackBar(
      backgroundColor: Colors.red,
      content: new Text(str,
          style: new TextStyle(fontSize: 15.0, color: Colors.white)),
      duration: new Duration(seconds: 5),
    ));
  }

  Future<void> _alertDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Konfirmasi'),
          titleTextStyle: TextStyle(color: Colors.black),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(
                  'Apakah anda yakin !!!.',
                  style: TextStyle(fontSize: 13.0),
                ),
                // Text('You\’re like me. I’m never satisfied.'),
              ],
            ),
          ),
          actions: <Widget>[
            FlatButton(
              child: Text('OK'),
              onPressed: () {
                _isLoading
                    ? CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      )
                    : setlokasikantor(jarakapi);
                Navigator.of(context).pop();
              },
            ),
            FlatButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  String _valLokasi;
  List<dynamic> _dataLokasi = List();
  void getLokasiKantor() async {
    final respose = await http.get(BaseUrl.getlokasi);
    var listData = jsonDecode(respose.body);
    if (mounted) {
      setState(() {
        _dataLokasi = listData;
      });
    }
  }

  setlokasikantor(double jarakapi) async {
    for (int i = 0; i < _dataLokasi.length; i++) {
      double latkantor = double.parse(_dataLokasi[i]['latitude']);
      double longkantor = double.parse(_dataLokasi[i]['longitude']);
      jarak =
          await Geolocator().distanceBetween(lat, lng, latkantor, longkantor);

      if (jarak <= jarakapi) {
        break;
      }
    }

    if (jarak >= jarakapi) {
      _snackbar('Area lokasi anda diluar jangkuan kantor anda. ');
    } else {
      String latudete = lat.toString();
      String langtude = lng.toString();

      final response = await http.post(BaseUrl.setlokasi,
          body: {"user_id": userid, "lat": latudete, "lng": langtude});
      final data = jsonDecode(response.body);

      int value = data['value'];
      String pesan = data['message'];

      if (value == 1) {
        _snackbar(pesan);
      } else {
        _snackbar(pesan);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldState,
      appBar: AppBar(
        title: Text(
          "Set Lokasi kantor anda saat ini",
          style: TextStyle(fontSize: 16.0, color: Colors.white),
        ),
      ),
      body: Center(
        child: ListView(
          // mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            new Padding(padding: EdgeInsets.only(bottom: 10.0)),
            FlatButton(
              child: Text(
                "Search location your ",
                style: TextStyle(color: Colors.lightBlue),
              ),
              onPressed: () {
                _getCurrentLocation();
              },
            ),
            new Container(
              padding: EdgeInsets.all(8.0),
              height: MediaQuery.of(context).size.width,
              width: MediaQuery.of(context).size.width,
              child: lat == null || lng == null
                  ? Container()
                  : GoogleMap(
                      mapType: MapType.normal,
                      initialCameraPosition: CameraPosition(
                        target: _position,
                        zoom: 18.0,
                      ),
                      markers: _markers,
                    ),
            ),
            if (_currentPosition != null)
              new Container(
                  padding: EdgeInsets.all(8.0),
                  child: Text(_currentAddress ?? '')),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.place),
        backgroundColor: Colors.lightBlue,
        onPressed: () {
          _alertDialog();
        },
      ),
    );
  }

  _getCurrentLocation() async {
    await geolocator
        .getCurrentPosition(
            desiredAccuracy: LocationAccuracy.best,
            locationPermissionLevel: GeolocationPermission.locationWhenInUse)
        .then((Position position) {
      setState(() {
        _currentPosition = position;
      });

      _getAddressFromLatLng();
    }).catchError((e) {
      print(e);
      print("ini");
    });
  }

  _getAddressFromLatLng() async {
    try {
      List<Placemark> p = await geolocator.placemarkFromCoordinates(
          _currentPosition.latitude, _currentPosition.longitude);

      Placemark place = p[0];

      setState(() async {
        _position =
            LatLng(_currentPosition.latitude, _currentPosition.longitude);
        lat = _position.latitude;
        lng = _position.longitude;

        _currentAddress =
            "${place.locality}, ${place.postalCode},${place.subAdministrativeArea},${place.administrativeArea}, ${place.country},${_position.latitude}, ${_position.longitude} ";
        _markers.add(
          Marker(
            markerId: MarkerId("${_position.latitude}, ${_position.longitude}"),
            position: _position,
            icon: BitmapDescriptor.defaultMarker,
          ),
        );
      });
    } catch (e) {
      print(e);
    }
  }
}
