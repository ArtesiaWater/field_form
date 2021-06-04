import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:field_form/constants.dart';
import 'package:field_form/settings.dart';
import 'package:field_form/src/measurements.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share/share.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'add_measurements.dart';
import 'dialogs.dart';
import 'ftp.dart';
import 'src/locations.dart';
import 'package:path/path.dart' as p;

// TODO: Make a manual
// TODO: Show last measured locations
// TODO: Test on iOS
// TODO: Generate app-icons
// TODO: Minimal and maximal values (HHNK)
// TODO: Add localisation
// TODO: Handle failed login (check for empty hostname)
// TODO: Zoom to all locations after import

//void main() => runApp(MyApp());
void main() => runApp(MaterialApp(home: MyApp()));

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final markers = <Marker>[];
  var locations = <String, Location>{};
  var inputFields = <String, InputField>{};
  var groups = <String, Group>{};
  var isLoading = false;
  SharedPreferences? prefs;
  late MeasurementProvider measurementProvider;
  var mapController;
  static const maptypes = {
    'normal': MapType.normal,
    'satellite': MapType.satellite,
    'hybrid': MapType.hybrid,
    'terrain': MapType.terrain
  };
  late BitmapDescriptor markedIcon;

  @override
  void initState() {
    super.initState();
    getprefs();
    measurementProvider = MeasurementProvider();
    measurementProvider.open();
    requestPermission();
    setMarkedIcon();
  }

  Future<void> setMarkedIcon() async {
    //var bytes = await getBytesFromAsset('assets/check-mark-icon-transparent-6.png', 64);
    var bytes = await getBytesFromCanvas('✓');
    markedIcon = BitmapDescriptor.fromBytes(bytes);
  }

  Future<Uint8List> getBytesFromCanvas(String text) async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    final int size = 100; //change this according to your app
    TextPainter painter = TextPainter(textDirection: TextDirection.ltr);
    painter.text = TextSpan(
      text: text,
      style: TextStyle(
        fontSize: size.toDouble(),
        color: Colors.green,
      ),
    );
    painter.layout();
    painter.paint(
      canvas,
      Offset(size / 2 - painter.width / 2 + 10, size / 2 - painter.height / 2 - 20),
    );

    final img = await pictureRecorder.endRecording().toImage(size, size);
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    return data!.buffer.asUint8List();
  }

  static Future<Uint8List> getBytesFromAsset(String path, int width) async {
    final data = await rootBundle.load(path);
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List(), targetWidth: width);
    final fi = await codec.getNextFrame();
    return (await fi.image.toByteData(format: ui.ImageByteFormat.png))!.buffer.asUint8List();
  }

  Future<void> requestPermission() async {
    // request location-permission programatically
    // https://github.com/flutter/flutter/issues/30171
    await Permission.location.request();
  }

  void getprefs() async{
    prefs = await SharedPreferences.getInstance();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (prefs == null) {
      return buildLoadingScreen();
    } else {
      return Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: buildAppBar(),
        drawer: buildDrawer(),
        body: Stack(
          children: [
            buildMap(),
            buildShowAllMarkerButton(),
            buildChangeMapTypeButton(),
            if (isLoading) buildLoadingIndicator(),
          ]
        ),
      );
    }
  }

  ButtonStyle getMapButtonStyle() {
    return TextButton.styleFrom(
      padding: EdgeInsets.all(0),
      primary: Colors.black54,
      backgroundColor: Color.fromRGBO(255, 255, 255, 0.7),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2),
      side: BorderSide(width: 0.2, color: Colors.grey),
      ),
    );
  }

  Align buildChangeMapTypeButton(){
    var maptype = prefs!.getString('map_type') ?? 'normal';
    return Align(
      alignment: Alignment.topCenter,
      child: Container(
        margin: EdgeInsets.all(12),
        width: 100,
        height: 38,
        child: TextButton(
          onPressed: () async {
            // choose maptype
            var options = <Widget>[];
            for (var key in maptypes.keys){
              options.add(SimpleDialogOption(
                onPressed: () {
                  Navigator.of(context).pop(key);
                },
                child: Row(
                  children:[
                    getMapIcon(key),
                    SizedBox(width: 10),
                    Text(key),
                  ]
                )
              ));
            }

            var action = await showDialog(
                context: context,
                builder: (context) {
                  return SimpleDialog(
                    title: const Text('Choose a maptype'),
                    children: options,
                  );
                }
            );
            if (action != null) {
              setState(() {
                prefs!.setString('map_type', action);
              });
            }
          },
          style: getMapButtonStyle(),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              getMapIcon(maptype),
              SizedBox(width: 10),
              Text(maptype),
            ],
          )
        )
      )
    );
  }

  Icon getMapIcon(String key){
    if ((key == 'satellite') | (key == 'hybrid')) {
      return Icon(Icons.satellite);
    } else if (key == 'terrain') {
      return Icon(Icons.terrain);
    } else {
      return Icon(Icons.map);
    }
  }

  Align buildShowAllMarkerButton(){
    return Align(
      alignment: Alignment.topLeft,
      child: Container(
        margin: EdgeInsets.all(12),
        width: 38,
        height: 38,
        child: TextButton(
          onPressed: () {
            // Zoom out to all locations
            if (markers.length > 1){
              double x0, x1, y0, y1;
              x0 = x1 = markers[0].position.latitude;
              y0 = y1 = markers[0].position.longitude;
              for (var marker in markers) {
                var latLng = marker.position;
                if (latLng.latitude > x1) x1 = latLng.latitude;
                if (latLng.latitude < x0) x0 = latLng.latitude;
                if (latLng.longitude > y1) y1 = latLng.longitude;
                if (latLng.longitude < y0) y0 = latLng.longitude;
              }
              var bounds = LatLngBounds(northeast: LatLng(x1, y1), southwest: LatLng(x0, y0));
              mapController.animateCamera(CameraUpdate.newLatLngBounds(bounds, 20));
            } else if (markers.length == 1) {
              var latLng = LatLng(markers[0].position.latitude, markers[0].position.longitude);
              mapController.animateCamera(CameraUpdate.newLatLng(latLng));
            }
          },
          style: getMapButtonStyle(),
          child: const Icon(Icons.zoom_out_map),
        )
      )
    );
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
      backgroundColor: Constant.primaryColor,
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
            title: Text('Choose groups'),
            onTap: () async {
              // Close the drawer
              Navigator.pop(context);
              final items = <MultiSelectDialogItem<String>>[];
              groups.forEach((id, group){
                var label = group.name ?? id;
                items.add(MultiSelectDialogItem(id, label));
              });
              final initialSelectedValues = prefs!.getStringList('selected_groups') ?? groups.keys.toList();
              final selectedGroups = await showDialog<Set<String>>(
                context: context,
                builder: (BuildContext context) {
                  return MultiSelectDialog(
                    items: items,
                    initialSelectedValues: initialSelectedValues.toSet(),
                  );
                },
              );

              print(selectedGroups);
              if (selectedGroups != null) {
                await prefs!.setStringList('selected_groups', selectedGroups.toList());
                setState(() {
                  setMarkers();
                });
              }
            },
            leading: Icon(Icons.group_work)
          ),
          ListTile(
              title: Text('Show measured locations'),
              onTap: () async {
                // Close the drawer
                Navigator.pop(context);
                chooseMeasuredInterval(context, prefs!);
              },
              leading: Icon(Icons.verified_user)
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

  void chooseMeasuredInterval(BuildContext context, SharedPreferences prefs) async{
    var options = <Widget>[];
    for (var interval in [0, 1, 7, 30]){
      options.add(SimpleDialogOption(
          onPressed: () {
            Navigator.of(context).pop(interval);
          },
          child: Row(
              children:[
                Text(interval.toString()),
              ]
          )
      ));
    }

    var action = await showDialog(
        context: context,
        builder: (context) {
          return SimpleDialog(
            title: const Text('Choose a maptype'),
            children: options,
          );
        }
    );
    if (action != null) {
      await prefs.setInt('mark_measured_days', action);
      setState(() {
        setMarkers();
      });
    }
  }

  GoogleMap buildMap() {
    var lat = prefs!.getDouble('latitude') ?? 30;
    var lng = prefs!.getDouble('longitude') ?? 0;
    var zoom = prefs!.getDouble('zoom') ?? 2;
    var initialCameraPosition = CameraPosition(
      target: LatLng(lat, lng),
      zoom: zoom,
    );
    var mapType = maptypes[prefs!.getString('map_type') ?? 'normal'];

    return GoogleMap(
      onMapCreated: _onMapCreated,
      myLocationEnabled: true,
      initialCameraPosition: initialCameraPosition,
      compassEnabled: true,
      markers: markers.toSet(),
      mapType: mapType!,
      mapToolbarEnabled: false,
      onLongPress: (latlng) {
        if (prefs!.getBool('disable_adding_locations') ?? true) {
          return;
        }
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
          markers.add(marker);
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
    mapController = controller;
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

    if (location_file.settings != null) {
      parseSettings(location_file.settings!, prefs!);
    }
    if (location_file.locations != null) {
      locations = location_file.locations!;
    }
    if (location_file.inputfields == null) {
      inputFields = getDefaultInputFields();
    } else {
      inputFields = location_file.inputfields!;
    }
    if (location_file.groups == null) {
      groups = <String, Group>{};
    } else {
      groups = location_file.groups!;
    }
    setState(() {
      setMarkers();
    });
  }

  BitmapDescriptor? getIconFromString(String? color) {
    if (color == null) {
      return null;
    }
    var hue;
    if (color[0] == '#') {
      // HEX color
      try {
        var col = Color(int.parse(color.substring(1, 7), radix: 16) + 0xFF000000);
        hue = HSLColor.fromColor(col).hue;
      } catch (e) {
        return null;
      }
    } else {
      switch (color){
        case 'red':
          hue = BitmapDescriptor.hueRed;
          break;
        case 'orange':
          hue = BitmapDescriptor.hueOrange;
          break;
        case 'yellow':
          hue = BitmapDescriptor.hueYellow;
          break;
        case 'green':
          hue = BitmapDescriptor.hueGreen;
          break;
        case 'cyan':
          hue = BitmapDescriptor.hueCyan;
          break;
        case 'azure':
          hue = BitmapDescriptor.hueAzure;
          break;
        case 'blue':
          hue = BitmapDescriptor.hueBlue;
          break;
        case 'violet':
          hue = BitmapDescriptor.hueViolet;
          break;
        case 'magenta':
          hue = BitmapDescriptor.hueOrange;
          break;
        case 'rose':
          hue = BitmapDescriptor.hueRose;
          break;
        default:
          return null;
      }
    }
    return BitmapDescriptor.defaultMarkerWithHue(hue);
  }

  BitmapDescriptor getIconForLocation(Location location, groups){
    var icon = getIconFromString(location.color);
    if (icon == null) {
      if (location.group != null) {
        if (groups.containsKey(location.group)) {
          var group = groups[location.group];
          icon = getIconFromString(group.color);
        }
      }
    }
    if (icon == null) {
      return BitmapDescriptor.defaultMarker;
    }
    return icon;
  }

  void setMarkers() async{
    var mark_measured_days = prefs!.getInt('mark_measured_days') ?? 0;
    final now = DateTime.now();
    final reftime = DateTime(now.year, now.month, now.day - mark_measured_days + 1);
    final lastMeasPerLoc;
    if (mark_measured_days > 0) {
      //markedIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
      // get the last measured time for each location
      lastMeasPerLoc = await measurementProvider.getLastMeasurementPerLocation();
    } else {
      lastMeasPerLoc = <String, DateTime>{};
    }
    markers.clear();
    final selectedGroups = prefs!.getStringList('selected_groups') ?? groups.keys.toList();
    for (var id in locations.keys) {
      var location = locations[id]!;
      if ((location.lat == null) | (location.lon==null)){
        continue;
      }
      if (location.group != null){
        if (!selectedGroups.contains(location.group)) {
          continue;
        }
      }
      var icon = getIconForLocation(location, groups);
      var snippet;
      if (location.sublocations == null) {
        snippet = null;
      } else {
        final n = location.sublocations!.length;
        snippet = '$n sublocations';
      }
      markers.add(Marker(
        markerId: MarkerId(id),
        position: LatLng(location.lat!, location.lon!),
        icon: icon,
        infoWindow: InfoWindow(
          title: location.name ?? id,
          snippet: snippet,
          onTap: () async {
            if (location.sublocations == null) {
              open_add_measurements(id, location);
            } else{
              if (location.sublocations!.length == 1){
                open_add_measurements(location.sublocations!.keys.first,
                    location.sublocations!.values.first);
              } else {
                // choose a sublocation
                var options = <Widget>[];
                location.sublocations!.forEach((var subid, var sublocation){
                  var name = sublocation.name ?? subid;
                  options.add(SimpleDialogOption(
                    onPressed: () {
                      Navigator.of(context).pop(subid);
                    },
                    child: Text(name),
                  ));
                });

                var result = await showDialog(
                    context: context,
                    builder: (context) {
                      return SimpleDialog(
                        title: const Text('Choose a sublocation'),
                        children: options,
                      );
                    }
                );
                if (result == null) {
                  return;
                }
                open_add_measurements(result, location.sublocations![result]!);
              }
            }
          },
        ),
      ));

      var lastMeasurement = DateTime(0);
      if (lastMeasPerLoc.containsKey(id)) {
        if (lastMeasPerLoc[id].isAfter(lastMeasurement)) {
          lastMeasurement = lastMeasPerLoc[id];
        }
      }
      if (location.sublocations != null) {
        for (var key in location.sublocations!.keys){
          if (lastMeasPerLoc.containsKey(key)) {
            if (lastMeasPerLoc[key].isAfter(lastMeasurement)){
              lastMeasurement = lastMeasPerLoc[key];
            }
          }
        }
      }
      if (lastMeasurement.isAfter(reftime)) {
        // add a marker with a vink
        markers.add(Marker(
          markerId: MarkerId(id + '_v'),
          position: LatLng(location.lat!, location.lon!),
          icon: markedIcon,
          zIndex: 1.0,
          consumeTapEvents: false,
          onTap: () {
            return mapController.showMarkerInfoWindow(MarkerId(id));
          }
        ));
      }
    }
  }

  void open_add_measurements(locationId, location) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) {
        return AddMeasurements(
            locationId: locationId,
            location: location,
            groups: groups,
            inputFields: inputFields,
            measurementProvider: measurementProvider,
            prefs: prefs!);
      }),
    );
    if (result != null) {
      if ((prefs!.getInt('mark_measured_days') ?? 0) > 0) {
        setState(() {
          setMarkers();
        });
      }
    }
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
    groups = <String, Group>{};

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
    setState(() {isLoading = true;});
    // connect to ftp folder
    var prefs = await SharedPreferences.getInstance();
    var ftpConnect = await connectToFtp(context, prefs, path:'');
    if (ftpConnect == null) {
      setState(() {isLoading = false;});
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
            setState(() {isLoading = false;});
            return;
          }
        }
        var success = await sendMeasurementsToFtp(ftpConnect, prefs);
        if (!success) {
          setState(() {isLoading = false;});
          return;
        }
        if (path.isNotEmpty) {
          // Go to root of ftp server again
          var success = await changeDirectory(ftpConnect, context, '..');
          if (!success){
            setState(() {isLoading = false;});
            return;
          }
        }
      }
    }

    // Choose FTP folder
    var path = await chooseFtpPath(ftpConnect, context, prefs);
    if (path != null) {
      // Delete all data
      deleteAllData();

      // Go to the specified folder
      var success = await changeDirectory(ftpConnect, context, path);
      if (!success) {
        setState(() {isLoading = false;});
        return;
      }

      // sync with the new ftp folder
      success = await downloadDataFromFtp(ftpConnect, context, prefs);
      if (!success) {
        setState(() {isLoading = false;});
        return;
      }

      displayInformation(context, 'Synchronisation complete');
    }
    // finish up
    await ftpConnect.disconnect();
    setState(() {isLoading = false;});
  }

  Future<bool> sendMeasurementsToFtp(ftpConnect, prefs) async {
    var only_export_new_data = prefs.getBool('only_export_new_data') ?? true;
    var new_file_name = getMeasurementFileName();
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
    setState(() {isLoading = true;});
    //showLoaderDialog(context, text: 'Synchronising with FTP server');
    var prefs = await SharedPreferences.getInstance();
    var ftpConnect = await connectToFtp(context, prefs);
    if (ftpConnect==null){
      setState(() {isLoading = false;});
      return;
    }

    // send measurements
    if (await measurementProvider.areThereMessagesToBeSent(prefs)) {
      success = await sendMeasurementsToFtp(ftpConnect, prefs);
      if (!success) {
        setState(() {isLoading = false;});
        return;
      }
    }

    // download (new) locations and measurements
    success = await downloadDataFromFtp(ftpConnect, context, prefs);
    if (!success) {
      setState(() {isLoading = false;});
      return;
    }

    // finish up
    await ftpConnect.disconnect();
    setState(() {isLoading = false;});
    displayInformation(context, 'Synchronisation complete');
  }

  Future <bool> downloadDataFromFtp(ftpConnect, context, prefs) async{
    var importedMeasurementFiles = prefs.getStringList('imported_measurement_files') ?? <String>[];
    var importedLocationFiles = prefs.getStringList('imported_location_files') ?? <String>[];
    var tempDir = await getTemporaryDirectory();

    displayInformation(context, 'Retrieving file list');
    var names = await ftpConnect.listDirectoryContentOnlyNames();

    names.sort((a, b) => a.toString().compareTo(b.toString()));

    displayInformation(context, 'Retrieved files');

    // Read last locations-file
    var name;
    for (var iname in names) {
      if (iname.startsWith('locations') & iname.endsWith('.json')){
        name = iname;
      }
    }
    if ((name != null) & !importedLocationFiles.contains(name)) {
      displayInformation(context, 'Downloading $name');
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
      save_locations(locations, inputFields, groups);
      importedLocationFiles.add(name);
      await prefs.setStringList('imported_location_files', importedLocationFiles);
    }

    // TODO: first collect all measurements, then add to database
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

  void save_locations(locations, inputFields, groups) async {
    var docsDir = await getApplicationDocumentsDirectory();
    var file = File(p.join(docsDir.path, 'locations.json'));
    var location_file = LocationFile(locations: locations,
        inputfields: inputFields,
        groups: groups);
    await file.writeAsString(json.encode(location_file.toJson()));
  }

  Future share_data() async {
    final directory = await getApplicationDocumentsDirectory();
    var files = <String>[];
    var measurement_path = '${directory.path}/locations.json';
    if (await File(measurement_path).exists()){
      files.add(measurement_path);
    }
    var new_file_name = getMeasurementFileName();
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

String getMeasurementFileName(){
  return 'measurements-' + Constant.file_datetime_format.format(DateTime.now()) + '.csv';
}


Future newLocationDialog(BuildContext context, latlng, locations) async {
  //TODO: Finish the new-location dialog
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
