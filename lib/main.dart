import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:field_form/constants.dart';
import 'package:field_form/new_location_screen.dart';
import 'package:field_form/settings.dart';
import 'package:field_form/measurements.dart';
import 'package:field_form/wms.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ftpconnect/ftpconnect.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share/share.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'add_measurements.dart';
import 'dialogs.dart';
import 'ftp.dart';
import 'locations.dart';
import 'package:path/path.dart' as p;

// TODO: Make a manual
// TODO: Minimal and maximal values (HHNK)
// TODO: Add localisation

//void main() => runApp(MyApp());
void main() => runApp(MaterialApp(home: MyApp()));

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final markers = <Marker>[];
  final locData = LocationData();
  var isLoading = false;
  SharedPreferences? prefs;
  late MeasurementProvider measurementProvider;
  var mapController;
  var maptype = 'normal';
  static const maptypes = {
    'normal': MapType.normal,
    'satellite': MapType.satellite,
    'hybrid': MapType.hybrid,
    'terrain': MapType.terrain,
    'OSM': MapType.none
  };
  late BitmapDescriptor markedIcon;
  bool myLocationEnabled = false;


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
    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);
    final size = 100; //change this according to your app
    final painter = TextPainter(textDirection: TextDirection.ltr);
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

  Future<void> requestPermission() async {
    // request location-permission programatically
    // https://github.com/flutter/flutter/issues/30171
    final status = await Permission.location.status;
    if (status == PermissionStatus.granted){
      myLocationEnabled = true;
    } else {
      final permissionStatus = await Permission.location.request();
      if (permissionStatus == PermissionStatus.granted) {
        setState(() {
          myLocationEnabled = true;
        });
      }
    }
  }

  void getprefs() async{
    prefs = await SharedPreferences.getInstance();
    setState(() {
      maptype = prefs!.getString('map_type') ?? 'normal';
    });
  }

  @override
  Widget build(BuildContext context) {
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
                setState(() {
                  maptype = action;
                });
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
            ZoomToAllLocations();
          },
          style: getMapButtonStyle(),
          child: const Icon(Icons.zoom_out_map),
        )
      )
    );
  }

  void ZoomToAllLocations() {
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
  }

  Widget buildLoadingScreen(){
    return Container(
      child: Center(
        child: Text(
          'loading map..',
          style:
          TextStyle(fontFamily: 'Avenir-Medium', color: Colors.grey[400]),
        ),
      ),
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
          )
        ),
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
              locData.groups.forEach((id, group){
                var label = group.name ?? id;
                items.add(MultiSelectDialogItem(id, label));
              });
              final initialSelectedValues = prefs!.getStringList('selected_groups') ?? locData.groups.keys.toList();
              final selectedGroups = await showDialog<Set<String>>(
                context: context,
                builder: (BuildContext context) {
                  return MultiSelectDialog(
                    items: items,
                    initialSelectedValues: initialSelectedValues.toSet(),
                    title: 'Select groups',
                  );
                },
              );

              if (selectedGroups != null) {
                await prefs!.setStringList('selected_groups', selectedGroups.toList());
                await setMarkers();
                setState(() {});
              }
            },
            leading: Icon(Icons.group_work)
          ),
          ListTile(
              title: Text('Mark measured locations'),
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
              if (action == true) {
                var prefs = await SharedPreferences.getInstance();
                if (await measurementProvider.areThereMessagesToBeSent(prefs)) {
                  final action = await showContinueDialog(context,
                      'There are still unsent measurements. Are you really sure you want to delete all data?',
                      title: 'Delete all data',
                      yesButton: 'Yes',
                      noButton: 'No');
                  if (action == true) {
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
            onTap: () async {
              // Close the drawer
              Navigator.pop(context);
              // Open the settings screen
              final redrawMap = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) {
                  return SettingsScreen(prefs: prefs!);
                }),
              );
              if (redrawMap) {
                setState(() {});
              }
            },
            leading: Icon(Icons.settings),
          ),
        ],
      ),
    );
  }

  void chooseMeasuredInterval(BuildContext context, SharedPreferences prefs) async{
    final mark_measured_days = prefs.getInt('mark_measured_days') ?? 0;
    var options = <Widget>[];
    for (var interval in [0, 1, 7, 30]){
      final icon;
      if (interval == mark_measured_days){
        icon = Icon(Icons.check_box_outlined);
      } else {
        icon = Icon(Icons.check_box_outline_blank);
      }
      options.add(SimpleDialogOption(
          onPressed: () {
            Navigator.of(context).pop(interval);
          },
          child: Row(
              children:[
                icon,
                SizedBox(width: 10),
                Text(interval.toString()),
              ]
          )
      ));
    }

    var action = await showDialog(
        context: context,
        builder: (context) {
          return SimpleDialog(
            title: const Text('Choose number of days'),
            children: options,
          );
        }
    );
    if (action != null) {
      await prefs.setInt('mark_measured_days', action);
      await setMarkers();
      setState(() {});
    }
  }

  Widget buildMap() {
    if (prefs == null) {
      return buildLoadingScreen();
    }
    var lat = prefs!.getDouble('latitude') ?? 30;
    var lng = prefs!.getDouble('longitude') ?? 0;
    var zoom = prefs!.getDouble('zoom') ?? 2;
    var initialCameraPosition = CameraPosition(
      target: LatLng(lat, lng),
      zoom: zoom,
    );
    var mapType = maptypes[maptype]!;

    final tileOverlays = <TileOverlay>{};
    if (maptype == 'OSM') {
      tileOverlays.add(TileOverlay(
        tileOverlayId: TileOverlayId('OpenSTreetmap'),
        tileProvider: OsmTileProvider(),
      ));
    }
    if (prefs!.getBool('wms_on') ?? false){
      final wms_url = prefs!.getString('wms_url') ?? '';
      final wms_layers = prefs!.getString('wms_layers') ?? '';
      if (wms_url.isNotEmpty & wms_layers.isNotEmpty) {
        tileOverlays.add(TileOverlay(
          tileOverlayId: TileOverlayId('WMS'),
          tileProvider: WmsTileProvider(
              url: wms_url,
              layers: wms_layers.split(','),
              transparent: true
          ),
        ));
      }
    }

    return GoogleMap(
      onMapCreated: _onMapCreated,
      myLocationEnabled: myLocationEnabled,
      initialCameraPosition: initialCameraPosition,
      compassEnabled: true,
      markers: markers.toSet(),
      mapType: mapType,
      mapToolbarEnabled: false,
      tileOverlays: tileOverlays,
      onLongPress: (latlng) {
        if (prefs!.getBool('disable_adding_locations') ?? false) {
          return;
        }
        setState(() {
          final id = 'new_marker';
          final marker = Marker(
            markerId: MarkerId(id),
            position: latlng,
            infoWindow: InfoWindow(
              title: 'Add a new location',
              onTap: () {
                addNewLocation(context, latlng);
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
      await read_location_file(file, zoom: false);
    } catch (e) {
      showErrorDialog(context, e.toString());
    }
  }

  Future <void> read_location_file(File file, {zoom=true}) async {
    var location_file = LocationFile.fromJson(
        json.decode(await file.readAsString()));

    if (location_file.settings != null) {
      parseSettings(location_file.settings!, prefs!);
    }
    if (location_file.locations != null) {
      locData.locations = location_file.locations!;
      if (zoom) {
        ZoomToAllLocations();
      }
    }
    if (location_file.inputfields == null) {
      locData.inputFields = getDefaultInputFields();
    } else {
      locData.inputFields = location_file.inputfields!;
    }
    if (location_file.groups == null) {
      locData.groups = <String, Group>{};
    } else {
      locData.groups = location_file.groups!;
    }
    await setMarkers();
    setState(() {});
    if (location_file.locations != null) {
      ZoomToAllLocations();
    }
  }

  Future<void> setMarkers() async {
    var mark_measured_days = prefs!.getInt('mark_measured_days') ?? 0;
    final now = DateTime.now();
    final reftime = DateTime(now.year, now.month, now.day - mark_measured_days + 1);
    final lastMeasPerLoc;
    if (mark_measured_days > 0) {
      // get the last measured time for each location
      lastMeasPerLoc = await measurementProvider.getLastMeasurementPerLocation();
    } else {
      lastMeasPerLoc = <String, DateTime>{};
    }
    markers.clear();
    final selectedGroups = prefs!.getStringList('selected_groups') ?? locData.groups.keys.toList();
    for (var id in locData.locations.keys) {
      var location = locData.locations[id]!;
      if ((location.lat == null) | (location.lon==null)){
        continue;
      }
      if (location.group != null){
        if (!selectedGroups.contains(location.group)) {
          continue;
        }
      }
      var icon = getIconForLocation(location, locData.groups);
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
            measurementProvider: measurementProvider,
            prefs: prefs!);
      }),
    );
    if (result != null) {
      if ((prefs!.getInt('mark_measured_days') ?? 0) > 0) {
        await setMarkers();
        setState(() {});
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
        if (action == true){
          is_location_file = true;
        } else if (action == false){
          is_location_file = false;
        } else {
          // the dialog was cancelled
          return;
        }
      }
      if (is_location_file) {
        if (file.path.endsWith('.json')) {
          try {
            if (locData.locations.isEmpty) {
              await read_location_file(file);
              locData.save_locations();
            } else {
              var action = await showContinueDialog(context,
                  'Importing new locations will remove all existing locations. Do you want to continue?',
                  yesButton: 'Yes',
                  noButton: 'No',
                  title: 'Import will remove existing locations');
              if (action == true) {
                await read_location_file(file);
                locData.save_locations();
              }
            }
          } catch (e) {
            showErrorDialog(context, e.toString(), title:'Import failed');
          }
        } else if (file.path.endsWith('.csv')) {
          showErrorDialog(context, 'csv-loction files not implemented yet. Use json-files instead');
        } else {
          showErrorDialog(context, 'Unknown file-extension. Extension needs to be .json');
        }
      } else {
        try {
          await measurementProvider.importFromCsv(file);
        } catch (e) {
          showErrorDialog(context, e.toString(), title:'Import failed');
        }
      }
    }
  }

  void deleteAllData() async {
    var prefs = await SharedPreferences.getInstance();

    // delete all locations
    locData.locations.clear();
    locData.inputFields = getDefaultInputFields();
    locData.groups = <String, Group>{};

    //delete all data in the documents-directory (location-data and photos)
    var docsDir = await getApplicationDocumentsDirectory();
    if (docsDir.existsSync()){
      for (var file in await docsDir.listSync()) {
        if (p.basename(file.path) == 'measurements.db'){
          // Do not delete the empty databse with measurements
          continue;
        }
        file.delete();
      }
    }

    await setMarkers();
    setState(() {});
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
      if (action == true){
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
    unawaited(ftpConnect.disconnect());
    setState(() {isLoading = false;});
  }

  void unawaited(Future<void>? future) {}

  Future<bool> sendMeasurementsToFtp(FTPConnect ftpConnect, SharedPreferences prefs) async {
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
      var success = await ftpConnect.uploadFile(file, supportIPV6: supportIPv6);
      if (!success) {
        unawaited(ftpConnect.disconnect());
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

  void synchroniseWithFtp(BuildContext context) async {
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
    unawaited(ftpConnect.disconnect());
    setState(() {isLoading = false;});
    displayInformation(context, 'Synchronisation complete');
  }

  Future <bool> downloadDataFromFtp(FTPConnect ftpConnect, BuildContext context, SharedPreferences prefs) async{
    var importedMeasurementFiles = prefs.getStringList('imported_measurement_files') ?? <String>[];
    var importedLocationFiles = prefs.getStringList('imported_location_files') ?? <String>[];
    var tempDir = await getTemporaryDirectory();

    displayInformation(context, 'Retrieving file list');
    final list = await ftpConnect.listDirectoryContent(supportIPv6:supportIPv6);
    var names = list.map((f) => f.name).whereType<String>().toList();
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
      var success = await ftpConnect.downloadFile(name, file, supportIPv6: supportIPv6);
      if (!success){
        unawaited(ftpConnect.disconnect());
        showErrorDialog(context, 'Unable to download ' + name);
        return false;
      }
      // read locations
      try {
        await read_location_file(file);
      } catch (e) {
        unawaited(ftpConnect.disconnect());
        showErrorDialog(context, e.toString());
        return false;
      }

      // save locations
      locData.save_locations();
      importedLocationFiles.add(name);
      unawaited(prefs.setStringList('imported_location_files', importedLocationFiles));
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
        try {
          var success = await ftpConnect.downloadFile(name, file, supportIPv6:supportIPv6);
          if (!success) {
            unawaited(ftpConnect.disconnect());
            showErrorDialog(context, 'Unable to download ' + name);
            return false;
          }
        } catch (e) {
          print(e);
          showErrorDialog(context, e.toString());
          return false;
        }
        // read measurements
        try {
          await measurementProvider.importFromCsv(file);
        } catch (e) {
          unawaited(ftpConnect.disconnect());
          showErrorDialog(context, e.toString());
          return false;
        }
        importedMeasurementFiles.add(name);
        await prefs.setStringList('imported_measurement_files', importedMeasurementFiles);
      }
    }
    // update markers
    if ((prefs.getInt('mark_measured_days') ?? 0) > 0) {
      await setMarkers();
      setState(() {});
    }
    return true;
  }

  Future share_data() async {
    final docsDir = await getApplicationDocumentsDirectory();
    var files = <String>[];
    var file = File(p.join(docsDir.path, 'locations.json'));
    if (await file.exists()){
      files.add(file.path);
    }
    var new_file_name = getMeasurementFileName();
    var tempDir = await getTemporaryDirectory();
    file = File(p.join(tempDir.path, new_file_name));
    var meas_file = await measurementProvider.exportToCsv(file,
        only_export_new_data: false);
    if (meas_file != null) {
      files.add(meas_file.path);
    }
    if (files.isEmpty){
      showErrorDialog(context, 'There is no data to share');
      return;
    }
    await Share.shareFiles(files);
  }

  Future addNewLocation(BuildContext context, LatLng latlng) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) {
        return NewLocationScreen(latLng: latlng);
      }),
    );
    if (result != null) {
      await setMarkers();
      setState(() {});
    }
  }
}

class OsmTileProvider implements TileProvider {
  static const int width = 256;
  static const int height = 256;

  @override
  Future<Tile> getTile(int x, int y, int? zoom) async {
    final url = 'https://tile.openstreetmap.org/$zoom/$x/$y.png';
    final response = await http.get(Uri.parse(url));
    final data = response.bodyBytes;
    return Tile(width, height, data);
  }
}
