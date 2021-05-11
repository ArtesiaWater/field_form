import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:field_form/settings.dart';
import 'package:field_form/src/measurements.dart';
import 'package:flutter/material.dart';
import 'package:ftpconnect/ftpconnect.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'add_measurements.dart';
import 'dialogs.dart';
import 'src/locations.dart' as locs;
import 'package:path/path.dart' as p;

//void main() => runApp(MyApp());
void main() => runApp(MaterialApp(home: MyApp()));

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final Map<String, Marker> markers = {};
  var locations = <locs.Location>[];
  var inputFields = <locs.InputField>[];
  CameraPosition? initialCameraPosition;
  late MeasurementProvider measurementProvider;

  Future<void> _onMapCreated(GoogleMapController controller) async {
    final location_file = await locs.getLocationFile(context);
    if (location_file.locations != null) {
      locations = location_file.locations!;
    }
    if (location_file.inputfields == null) {
      inputFields = locs.getDefaultInputFields();
    } else {
      inputFields = location_file.inputfields!;
    }

    setState(() {
      setMarkers();
    });
  }

  void setMarkers(){
    markers.clear();
    for (final location in locations) {
      final marker = Marker(
        markerId: MarkerId(location.id),
        position: LatLng(location.coords.lat, location.coords.lng),
        infoWindow: InfoWindow(
          title: location.name,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) {
                return AddMeasurements(
                    location: location,
                    inputFields: inputFields,
                    measurementProvider: measurementProvider);
              }),
            );
          },
        ),
      );
      markers[location.id] = marker;
    }
  }

  void getInitialCameraPosition() async {
    var prefs = await SharedPreferences.getInstance();
    setState(() {
      initialCameraPosition = CameraPosition(
        target: LatLng(prefs.getDouble('latitude') ?? 30,
            prefs.getDouble('longitude') ?? 0),
        zoom: prefs.getDouble('zoom') ?? 2,
      );
    });
  }

  @override
  void initState() {
    super.initState();
    getInitialCameraPosition();
    measurementProvider = MeasurementProvider();
    measurementProvider.open();
  }

  @override
  Widget build(BuildContext context) {
    if (initialCameraPosition == null) {
      return Scaffold(
          body: Container(
        child: Center(
          child: Text(
            'loading map..',
            style:
                TextStyle(fontFamily: 'Avenir-Medium', color: Colors.grey[400]),
          ),
        ),
      ));
    } else {
      return Scaffold(
        appBar: AppBar(
          title: const Text('FieldForm'),
          backgroundColor: Colors.green[700],
          actions: <Widget>[
            Padding(
                padding: EdgeInsets.only(right: 20.0),
                child: GestureDetector(
                  onTap: () {
                    synchroniseWithFtp(context);
                  },
                  child: Icon(
                    Icons.sync,
                  ),
                )),
          ],
        ),
        body: GoogleMap(
          onMapCreated: _onMapCreated,
          myLocationEnabled: true,
          initialCameraPosition: initialCameraPosition!,
          markers: markers.values.toSet(),
          onLongPress: (latlng) {
            setState(() {
              final id = 'new_marker';
              final marker = Marker(
                markerId: MarkerId(id),
                position: latlng,
                infoWindow: InfoWindow(
                  title: 'New marker',
                  onTap: () {
                    newLocationDialog(context, latlng, locations);
                  },
                ),
                icon: BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueBlue),
              );
              markers[id] = marker;
            });
          },
          onCameraMove: (CameraPosition position) async {
            var prefs = await SharedPreferences.getInstance();
            await prefs.setDouble('latitude', position.target.latitude);
            await prefs.setDouble('longitude', position.target.longitude);
            await prefs.setDouble('zoom', position.zoom);
          },
        ),
        drawer: Drawer(
          // Add a ListView to the drawer. This ensures the user can scroll
          // through the options in the drawer if there isn't enough vertical
          // space to fit everything.
          child: ListView(
            // Important: Remove any padding from the ListView.
            padding: EdgeInsets.zero,
            children: <Widget>[
              DrawerHeader(
                decoration: BoxDecoration(
                  color: Colors.green,
                ),
                child: Text('Menu'),
              ),
              ListTile(
                title: Text('Add data from file'),
                onTap: () {
                  // Close the drawer
                  Navigator.pop(context);
                  showErrorDialog(context, 'Not inplemented yet');
                },
                leading: Icon(Icons.insert_drive_file),
              ),
              ListTile(
                title: Text('Share data'),
                onTap: () {
                  // Close the drawer
                  Navigator.pop(context);
                  showErrorDialog(context, 'Not inplemented yet');
                },
                leading: Icon(Icons.share),
              ),
              ListTile(
                title: Text('Settings'),
                onTap: () {
                  // Close the drawer
                  Navigator.pop(context);
                  // Open the settings screen
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) {
                      return SettingsScreen();
                    }),
                  );
                },
                leading: Icon(Icons.settings),
              ),
              ListTile(
                title: Text('Delete all data'),
                onTap: () async {
                  // Close the drawer
                  Navigator.pop(context);
                  final action = await showContinueDialog(context, 'Are you sure you want to delete all data?');
                  if (action == DialogAction.yes){
                    deleteAllData();
                  }
                },
                leading: Icon(Icons.delete),
              )
            ],
          ),
        ),
      );
    }
  }

  void deleteAllData(){
    locations.clear();
    inputFields = locs.getDefaultInputFields();
    save_locations(locations, inputFields);
    setMarkers();
  }



  void synchroniseWithFtp(context) async {
    var ftpConnect;
    try {
      showLoaderDialog(context, text: 'Synchronising with FTP server');
      var prefs = await SharedPreferences.getInstance();
      var host = prefs.getString('ftp_hostname') ?? '';
      var user = prefs.getString('ftp_username') ?? '';
      var pass = prefs.getString('ftp_password') ?? '';
      var path = prefs.getString('ftp_path') ?? '';
      ftpConnect = FTPConnect(host, user: user, pass: pass);

      await ftpConnect.connect();
      var snackBar = SnackBar(content: Text('Connected, retreiving file list'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
      if (path.isNotEmpty) {
        bool success = await ftpConnect.changeDirectory(path);
        if (!success) {
          await ftpConnect.disconnect();
          Navigator.pop(context);
          showErrorDialog(context, 'Unable to find FTP-path: ' + path);
          return;
        }
      }

      var tempDir = await getTemporaryDirectory();

      // send measurements
      var only_export_new_data = prefs.getBool('only_export_new_data') ?? true;
      var formattedDate =
          DateFormat('yyyy-MM-dd-HH:mm:ss').format(DateTime.now());
      var file =
          File(p.join(tempDir.path, 'measurements-' + formattedDate + '.csv'));
      await measurementProvider.exportToCsv(file,
            only_export_new_data: only_export_new_data);
      ftpConnect.uploadFile(file);

      // download measurements and (new) locations
      snackBar = SnackBar(content: Text('Connected, retreiving file list'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
      var names = await ftpConnect.listDirectoryContentOnlyNames();
      snackBar = SnackBar(content: Text('Retreived files'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
      snackBar = SnackBar(content: Text('Retreived files 2'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
      if (names.contains('locations.json')) {
        // download locations
        var file = File(p.join(tempDir.path, 'locations.json'));
        await ftpConnect.downloadFile('locations.json', file);
        // read locations
        var location_file =
            locs.LocationFile.fromJson(json.decode(await file.readAsString()));
        if (location_file.locations != null) {
          locations = location_file.locations!;
        }
        // save locations
        save_locations(locations, inputFields);
      }
      for (var name in names) {
        if (name.startsWith('measurements')) {
          // download measurements
          var file = File(p.join(tempDir.path, name));
          await ftpConnect.downloadFile(name, file);
          // read measurements
          measurementProvider.importFromCsv(file);
        }
      }
    } catch (e) {
      await ftpConnect.disconnect();
      Navigator.pop(context);
      showErrorDialog(context, e.toString());
      return;
    }
    await ftpConnect.disconnect();
    Navigator.pop(context);
  }

  void save_locations(locations, inputFields) async {
    var docsDir = await getApplicationDocumentsDirectory();
    var file = File(p.join(docsDir.path, 'locations.json'));
    var location_file = locs.LocationFile(locations: locations,
        inputfields: inputFields);
    await file.writeAsString(json.encode(location_file.toJson()));
  }
}

Future share_data() async {
  final directory = await getApplicationDocumentsDirectory();
}

Future newLocationDialog(BuildContext context, latlng, locations) async {
  var teamName = '';
  return showDialog(
    context: context,
    barrierDismissible:
        false, // dialog is dismissible with a tap on the barrier
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('New location'),
        content: Row(
          children: [
            Expanded(
                child: TextField(
              autofocus: true,
              decoration: InputDecoration(
                  labelText: 'Location name',
                  hintText: 'Please enter the new location name'),
              onChanged: (value) {
                teamName = value;
              },
            ))
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(teamName);
            },
            child: Text('Ok'),
          ),
        ],
      );
    },
  );
}
