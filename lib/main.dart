import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:field_form/settings.dart';
import 'package:field_form/src/measurements.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share/share.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'add_measurements.dart';
import 'dialogs.dart';
import 'ftp.dart';
import 'src/locations.dart';
import 'package:path/path.dart' as p;

//void main() => runApp(MyApp());
void main() => runApp(MaterialApp(home: MyApp()));

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final Map<String, Marker> markers = {};
  var locations = <Location>[];
  var inputFields = <InputField>[];
  CameraPosition? initialCameraPosition;
  late MeasurementProvider measurementProvider;

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
      return buildLoadingScreen();
    } else {
      return Scaffold(
        appBar: buildAppBar(),
        drawer: buildDrawer(),
        body: buildMap(),
      );
    }
  }

  Scaffold buildLoadingScreen(){
    return Scaffold(
      body: Container(
        child: Center(
          child: Text(
            'loading map..',
            style:
            TextStyle(fontFamily: 'Avenir-Medium', color: Colors.grey[400]),
          ),
        ),
      )
    );
  }

  AppBar buildAppBar() {
    return AppBar(
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
    );
  }

  Drawer buildDrawer() {
    return Drawer(
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
              choose_file();
            },
            leading: Icon(Icons.insert_drive_file),
          ),
          ListTile(
            title: Text('Share data'),
            onTap: () {
              // Close the drawer
              Navigator.pop(context);
              share_data();
            },
            leading: Icon(Icons.share),
          ),
          ListTile(
            title: Text('Change FTP Folder'),
            onTap: () async {
              // Close the drawer
              Navigator.pop(context);
              await switchFtpFolder(context);
            },
            leading: Icon(Icons.reset_tv),
          ),
          ListTile(
            title: Text('Delete all data'),
            onTap: () async {
              // Close the drawer
              Navigator.pop(context);
              final action = await showContinueDialog(context, 'Are you sure you wish to delete all data?',
                  title:'Delete all data', yesButton: 'Yes', noButton: 'No');
              if (action == DialogAction.yes) {
                var prefs = await SharedPreferences.getInstance();
                if (await measurementProvider.areThereMessagesToBeSent(prefs)) {
                  final action = await showContinueDialog(context,
                      'There are still unsent measurements. Are you really sure you want to delete all data?',
                      title: 'Delete all data',
                      yesButton: 'Yes',
                      noButton: 'No');
                  if (action == DialogAction.yes) {
                    deleteAllData();
                  }
                } else {
                  deleteAllData();
                }
              }
            },
            leading: Icon(Icons.delete),
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
        ],
      ),
    );
  }

  GoogleMap buildMap() {
    return GoogleMap(
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
    );
  }

  Future<void> _onMapCreated(GoogleMapController controller) async {
    //final location_file = await getLocationFile(context);
    var docsDir = await getApplicationDocumentsDirectory();
    var file = File(p.join(docsDir.path, 'locations.json'));
    if (! await file.exists()) {
      return;
    }
    try {
      await read_location_file(file);
    } catch (e) {
      showErrorDialog(context, e.toString());
    }
  }

  Future <void> read_location_file(File file) async {
    var location_file = LocationFile.fromJson(
        json.decode(await file.readAsString()));
    if (location_file.locations != null) {
      locations = location_file.locations!;
    }
    if (location_file.inputfields == null) {
      inputFields = getDefaultInputFields();
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
      if ((location.lat == null) | (location.lon==null)){
        continue;
      }
      print(location.lat);
      final marker = Marker(
        markerId: MarkerId(location.id),
        position: LatLng(location.lat!, location.lon!),
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

  void choose_file() async {
    var result = await FilePicker.platform.pickFiles();
    if (result != null) {
      var file = File(result.files.single.path!);
      var is_location_file;
      if (file.path.startsWith('locations')) {
        is_location_file = true;
      } else if (file.path.startsWith('measurements')) {
        is_location_file = false;
      } else {
        // Ask whether the file contains locations or measurements
        var action = await showContinueDialog(context, 'Does this file contain locations or measurements?',
            yesButton: 'Locations', noButton: 'Measurements', title: 'Locations or measurements');
        if (action == DialogAction.yes){
          is_location_file = true;
        } else if (action == DialogAction.no){
          is_location_file = false;
        } else {
          // the dialog was cancelled
          return;
        }
      }
      if (is_location_file) {
        if (file.path.endsWith('.json')) {
          try {
            await read_location_file(file);
          } catch (e) {
            showErrorDialog(context, e.toString());
          }
        } else if (file.path.endsWith('.csv')) {
          showErrorDialog(context, 'csv-loction files not implemented yet. Use json-files instead');
        }
      } else {
        measurementProvider.importFromCsv(file);
      }
    }
  }

  void deleteAllData() async {
    var prefs = await SharedPreferences.getInstance();

    // delete all locations
    locations.clear();
    inputFields = getDefaultInputFields();

    //delete all data in the documents-directory (for the photos)
    var docsDir = await getApplicationDocumentsDirectory();
    if(docsDir.existsSync()){
      docsDir.deleteSync(recursive: true);
    }
    //save_locations(locations, inputFields);

    setState(() {
      setMarkers();
    });
    await prefs.remove('imported_measurement_files');

    // delete all measurements
    await measurementProvider.deleteAllMeasurements();
    await prefs.remove('imported_location_files');
  }

  Future<void> switchFtpFolder(context) async{
    showLoaderDialog(context);
    // connect to ftp folder
    var prefs = await SharedPreferences.getInstance();
    var ftpConnect = await connectToFtp(context, prefs, path:'');
    if (ftpConnect == null) {
      Navigator.pop(context);
      return;
    }
    // First upload existing measurements
    if (await measurementProvider.areThereMessagesToBeSent(prefs)){
      // Check if user wants to send unsent measurements
      var action = await showContinueDialog(context, 'There are unsent measurements. Do you want to upload these first? Otherwise they will be lost.',
          yesButton: 'Yes', noButton: 'No', title: 'Unsent measurements');
      var ftpConnect;
      if (action == DialogAction.yes){

        // connect to the current ftp folder and send the measurements
        var path = prefs.getString('ftp_path') ?? '';
        if (path.isNotEmpty) {
          var success = await changeDirectory(ftpConnect, context, path);
          if (!success){
            Navigator.pop(context);
            return;
          }
        }
        var success = await sendMeasurementsToFtp(ftpConnect, prefs);
        if (!success) {
          Navigator.pop(context);
          return;
        }
        if (path.isNotEmpty) {
          // Go to root of ftp server again
          var success = ftpConnect.changeDirectory('..');
          if (!success){
            await ftpConnect.disconnect();
            Navigator.pop(context);
            return;
          }
        }
      }
    }
    Navigator.pop(context);
    // Choose FTP folder
    var path = await chooseFtpPath(ftpConnect, context, prefs);
    if (path != null) {
      showLoaderDialog(context);

      // Delete all data
      deleteAllData();

      // Go to the specified folder
      var success = await changeDirectory(ftpConnect, context, path);
      if (!success) {
        Navigator.pop(context);
        return;
      }

      // sync with the new ftp folder
      success = await downloadDataFromFtp(ftpConnect, context, prefs);
      if (!success) {
        Navigator.pop(context);
        return;
      }

      // finish up
      await ftpConnect.disconnect();
      Navigator.pop(context);
      displayInformation(context, 'Synchronisation complete');
    }
  }

  Future<bool> sendMeasurementsToFtp(ftpConnect, prefs) async {
    var only_export_new_data = prefs.getBool('only_export_new_data') ?? true;
    var formattedDate =
    DateFormat('yyyy-MM-dd-HH:mm:ss').format(DateTime.now());
    var new_file_name = 'measurements-' + formattedDate + '.csv';
    var tempDir = await getTemporaryDirectory();
    File? file = File(p.join(tempDir.path, new_file_name));
    file = await measurementProvider.exportToCsv(file,
        only_export_new_data: only_export_new_data);
    if (file == null) {
      return false;
    } else {
      displayInformation(context, 'Sending measurements');
      // file is null when there are no (new) measurements
      bool success = await ftpConnect.uploadFile(file);
      if (!success) {
        await ftpConnect.disconnect();
        Navigator.pop(context);
        showErrorDialog(context, 'Unable to upload measurements');
        return false;
      }
      var importedMeasurementFiles = prefs.getStringList('imported_measurement_files') ?? <String>[];
      importedMeasurementFiles.add(new_file_name);
      await prefs.setStringList(
          'imported_measurement_files', importedMeasurementFiles);
      // set all measurements to exported
      await measurementProvider.setAllExported();
      return true;
    }
  }

  void synchroniseWithFtp(context) async {
    var success;
    showLoaderDialog(context, text: 'Synchronising with FTP server');
    var prefs = await SharedPreferences.getInstance();
    var ftpConnect = await connectToFtp(context, prefs);
    if (ftpConnect==null){
      Navigator.pop(context);
      return;
    }

    // send measurements
    if (await measurementProvider.areThereMessagesToBeSent(prefs)) {
      success = await sendMeasurementsToFtp(ftpConnect, prefs);
      if (!success) {
        Navigator.pop(context);
        return;
      }
    }

    // download (new) locations and measurements
    success = await downloadDataFromFtp(ftpConnect, context, prefs);
    if (!success) {
      Navigator.pop(context);
      return;
    }

    // finish up
    await ftpConnect.disconnect();
    Navigator.pop(context);
    displayInformation(context, 'Synchronisation complete');
  }

  Future <bool> downloadDataFromFtp(ftpConnect, context, prefs) async{
    var importedMeasurementFiles = prefs.getStringList('imported_measurement_files') ?? <String>[];
    var importedLocationFiles = prefs.getStringList('imported_location_files') ?? <String>[];
    var tempDir = await getTemporaryDirectory();

    displayInformation(context, 'Retrieving file list');
    var names = await ftpConnect.listDirectoryContentOnlyNames();
    displayInformation(context, 'Retrieved files');

    var name = 'locations.json';
    if (names.contains(name) & !importedLocationFiles.contains(name)) {
      displayInformation(context, 'Downloading locations.json');
      // download locations
      var file = File(p.join(tempDir.path, name));
      bool success = await ftpConnect.downloadFile(name, file);
      if (!success){
        await ftpConnect.disconnect();
        showErrorDialog(context, 'Unable to download ' + name);
        return false;
      }
      // read locations
      try {
        await read_location_file(file);
      } catch (e) {
        await ftpConnect.disconnect();
        showErrorDialog(context, e.toString());
        return false;
      }

      // save locations
      save_locations(locations, inputFields);
      importedLocationFiles.add(name);
      await prefs.setStringList('imported_location_files', importedLocationFiles);
    }

    for (var name in names) {
      if (name.startsWith('measurements')) {
        if (importedMeasurementFiles.contains(name)){
          continue;
        }
        displayInformation(context, 'Downloading ' + name);
        // download measurements
        var file = File(p.join(tempDir.path, name));
        bool success = await ftpConnect.downloadFile(name, file);
        if (!success){
          await ftpConnect.disconnect();
          showErrorDialog(context, 'Unable to download ' + name);
          return false;
        }
        // read measurements
        try {
          measurementProvider.importFromCsv(file);
        } catch (e) {
          await ftpConnect.disconnect();
          showErrorDialog(context, e.toString());
          return false;
        }
        importedMeasurementFiles.add(name);
        await prefs.setStringList('imported_measurement_files', importedMeasurementFiles);
      }
    }
    return true;
  }

  void save_locations(locations, inputFields) async {
    var docsDir = await getApplicationDocumentsDirectory();
    var file = File(p.join(docsDir.path, 'locations.json'));
    var location_file = LocationFile(locations: locations,
        inputfields: inputFields);
    await file.writeAsString(json.encode(location_file.toJson()));
  }

  Future share_data() async {
    final directory = await getApplicationDocumentsDirectory();
    var files = <String>[];
    var measurement_path = '${directory.path}/locations.json';
    if (await File(measurement_path).exists()){
      files.add(measurement_path);
    }
    var formattedDate =
    DateFormat('yyyy-MM-dd-HH:mm:ss').format(DateTime.now());
    var new_file_name = 'measurements-' + formattedDate + '.csv';
    var tempDir = await getTemporaryDirectory();
    File? file = File(p.join(tempDir.path, new_file_name));
    file = await measurementProvider.exportToCsv(file,
        only_export_new_data: false);
    if (file != null) {
      files.add(file.path);
    }
    await Share.shareFiles(files);
  }
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
              showErrorDialog(context, 'Not implemented yet');
            },
            child: Text('Ok'),
          ),
        ],
      );
    },
  );
}
