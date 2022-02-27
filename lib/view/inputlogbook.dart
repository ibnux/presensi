import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'package:async/async.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:presensi/model/api.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart' as path;
import 'package:datetime_picker_formfield/datetime_picker_formfield.dart';
import 'package:intl/intl.dart';

class InputLogBook extends StatefulWidget {
  @override
  _InputLogBookState createState() => _InputLogBookState();
}

class _InputLogBookState extends State<InputLogBook> {
  final snackbarKey = GlobalKey<ScaffoldState>();
  final GlobalKey<ScaffoldState> _scaffoldState =
      new GlobalKey<ScaffoldState>();
  final _key = new GlobalKey<FormState>();

  void _snackbar(String str) {
    if (str.isEmpty) return;
    _scaffoldState.currentState.showSnackBar(new SnackBar(
      backgroundColor: Colors.red,
      content: new Text(str,
          style: new TextStyle(fontSize: 15.0, color: Colors.white)),
      duration: new Duration(seconds: 5),
    ));
  }

  bool _isLoading = false;
  DateTime tanggal;
  String pesan;
  String selama;
  String nik;
  TextEditingController txtpesan = TextEditingController();
  TextEditingController txtselama = TextEditingController();
  TimeOfDay selectedTime1 = TimeOfDay.now();
  TimeOfDay selectedTime2 = TimeOfDay.now();

  getPref() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    setState(() {
      nik = preferences.getString("nik");
    });
  }

  check() {
    if (!_isLoading) {
      setState(() {
        _isLoading = true;
      });
    }

    final form = _key.currentState;
    if (form.validate()) {
      form.save();
      if (nik == null) {
        _snackbar('Tanggal wajib diisi !');
      } else if (selectedTime1 == null) {
        _snackbar('Kolom jam mulai wajib disi !');
      } else if (selectedTime2 == null) {
        _snackbar('Kolom jam selesai wajib disi !');
      } else if (pesan == null) {
        _snackbar('Kolom pesan wajib disi');
      } else {
        prosessimpan();
      }
    }
  }

  prosessimpan() async {
    final response = await http.post(BaseUrl.inputlogbook, body: {
      "nik": nik,
      "mulai": selectedTime1.format(context),
      "tgl": tanggal.toString(),
      "selesai": selectedTime2.format(context),
      "keterangan": pesan
    });

    final data = jsonDecode(response.body);

    String message = data['message'];
    _snackbar(message);
    setState(() {
      _isLoading = false;
    });
  }

  Future<Null> _selectedTime1(BuildContext context) async {
    final TimeOfDay picked_time = await showTimePicker(
        context: context,
        initialTime: selectedTime1,
        builder: (BuildContext context, Widget child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
            child: child,
          );
        });

    if (picked_time != null && picked_time != selectedTime1)
      setState(() {
        selectedTime1 = picked_time;
        print(selectedTime1);
      });
  }

  Future<Null> _selectedTime2(BuildContext context) async {
    final TimeOfDay picked_time = await showTimePicker(
        context: context,
        initialTime: selectedTime2,
        builder: (BuildContext context, Widget child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
            child: child,
          );
        });

    if (picked_time != null && picked_time != selectedTime2)
      setState(() {
        selectedTime2 = picked_time;
      });
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getPref();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldState,
      appBar: AppBar(
        title: Text(
          'Input Log Book',
          style: TextStyle(fontSize: 16.0, color: Colors.white),
        ),
      ),
      body: Container(
        padding: EdgeInsets.all(20.0),
        child: Form(
          key: _key,
          child: ListView(
            children: <Widget>[
              DateTimePickerFormField(
                style: TextStyle(fontSize: 13.0, color: Colors.black),
                inputType: InputType.date,
                format: DateFormat("yyyy-MM-dd"),
                initialDate: DateTime.now(),
                editable: false,
                decoration: InputDecoration(
                  labelText: 'Tanggal',
                  labelStyle:
                      TextStyle(fontSize: 13.0, color: Colors.lightBlue),
                ),
                onChanged: (dt) {
                  setState(() => tanggal = dt);
                  print(tanggal);
                },
              ),
              SizedBox(
                height: 20.0,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  RaisedButton(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5)),
                    color: Colors.lightBlue,
                    textColor: Colors.white,
                    onPressed: () => _selectedTime1(context),
                    child: Text('jam Mulai'),
                  ),
                  Text(
                    "${selectedTime1.format(context)}",
                    style: TextStyle(
                      fontSize: 20,
                      foreground: Paint()
                        ..style = PaintingStyle.stroke
                        ..strokeWidth = 1
                        ..color = Colors.lightBlue[700],
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  RaisedButton(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5)),
                    color: Colors.lightBlue,
                    textColor: Colors.white,
                    onPressed: () => _selectedTime2(context),
                    child: Text('Jam Selesai'),
                  ),
                  Text(
                    "${selectedTime2.format(context)}",
                    style: TextStyle(
                      fontSize: 20,
                      foreground: Paint()
                        ..style = PaintingStyle.stroke
                        ..strokeWidth = 1
                        ..color = Colors.lightBlue[700],
                    ),
                  ),
                ],
              ),
              TextFormField(
                maxLines: 10,
                controller: txtpesan,
                onSaved: (e) => pesan = e,
                decoration: InputDecoration(labelText: 'keterangan'),
              ),
              SizedBox(
                height: 20.0,
              ),
              GestureDetector(
                  onTap: () {
                    check();
                  },
                  child: Container(
                    height: 50,
                    margin: EdgeInsets.symmetric(horizontal: 50),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(50),
                        color: Colors.lightBlue[900]),
                    child: Center(
                      child: _isLoading
                          ? CircularProgressIndicator(
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            )
                          : Text(
                              "Proses",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold),
                            ),
                    ),
                  )),
            ],
          ),
        ),
      ),
    );
  }
}
