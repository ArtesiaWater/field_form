import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:easy_search_bar/easy_search_bar.dart';
import 'package:field_form/constants.dart';
import 'package:field_form/new_location_screen.dart';
import 'package:field_form/settings.dart';
import 'package:field_form/measurements.dart';
import 'package:field_form/wms.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_archive/flutter_archive.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:map_launcher/map_launcher.dart' as map_launcher;
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
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

// TODO: Make a manual
// TODO: Minimal and maximal values (HHNK)
// TODO: Improve localisation

void main() {
  runApp(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      debugShowCheckedModeBanner: false,
      home: MyApp()
    )
  );
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final markers = <String, Marker>{};
  final locData = LocationData();
  var isLoading = false;
  SharedPreferences? prefs;
  late MeasurementProvider measurementProvider;
  late GoogleMapController mapController;
  var maptype = 'normal';
  static const maptypes = {
    'normal': MapType.normal,
    'satellite': MapType.satellite,
    'hybrid': MapType.hybrid,
    'terrain': MapType.terrain,
    'OSM': MapType.none
  };
  late BitmapDescriptor notMeasuredIcon;
  late BitmapDescriptor halfMeasuredIcon;
  late BitmapDescriptor fullMeasuredIcon;
  bool myLocationEnabled = false;
  late AppLocalizations texts;
  var activeMarker;

  @override
  void initState() {
    super.initState();
    getprefs();

    measurementProvider = MeasurementProvider();
    measurementProvider.open();
    requestPermission();
    setMeasuredIcons();

  }

  Future<void> setMeasuredIcons() async {
    var bytes;

    bytes = await getBytesFromCanvas('⦻', color:Colors.red);
    notMeasuredIcon = BitmapDescriptor.fromBytes(bytes);

    bytes = await getBytesFromCanvas('✓', color:Colors.yellow, offset_x: 10);
    halfMeasuredIcon = BitmapDescriptor.fromBytes(bytes);

    bytes = await getBytesFromCanvas('✓', color: Colors.green, offset_x: 10);
    fullMeasuredIcon = BitmapDescriptor.fromBytes(bytes);
  }

  Future<Uint8List> getBytesFromCanvas(String text, {color = Colors.green, size = 100, offset_x=0, offset_y=30}) async {
    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);
    final painter = TextPainter(textDirection: TextDirection.ltr);
    painter.text = TextSpan(
      text: text,
      style: TextStyle(
        fontSize: size.toDouble(),
        color: color,
      ),
    );
    painter.layout();
    painter.paint(
      canvas,
      Offset(size / 2 - painter.width / 2 + offset_x, size / 2 - painter.height / 2 - offset_y),
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
    texts = AppLocalizations.of(context)!;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: buildAppBar(),
      drawer: buildDrawer(),
      body: Stack(
        children: [
          buildMap(),
          buildShowAllMarkerButton(),
          buildChangeMapTypeButton(),
          if (checkPreviuosButton()) buildPreviousButton(),
          if (checkNextButton()) buildNextButton(),
          if (isLoading) buildLoadingIndicator(text:texts.loading),
        ]
      ),
    );
  }

  ButtonStyle getMapButtonStyle() {
    return TextButton.styleFrom(
      padding: EdgeInsets.all(0),
      foregroundColor: Colors.black54,
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
                    title: Text(texts.chooseMaptype),
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
      x0 = x1 = markers.values.first.position.latitude;
      y0 = y1 = markers.values.first.position.longitude;

      markers.values.forEach((marker){
        var latLng = marker.position;
        if (latLng.latitude > x1) x1 = latLng.latitude;
        if (latLng.latitude < x0) x0 = latLng.latitude;
        if (latLng.longitude > y1) y1 = latLng.longitude;
        if (latLng.longitude < y0) y0 = latLng.longitude;
      });
      var bounds = LatLngBounds(northeast: LatLng(x1, y1), southwest: LatLng(x0, y0));
      mapController.animateCamera(CameraUpdate.newLatLngBounds(bounds, 20));
    } else if (markers.length == 1) {
      final position = markers.values.first.position;
      var latLng = LatLng(position.latitude, position.longitude);
      mapController.animateCamera(CameraUpdate.newLatLng(latLng));
    }
  }

  bool checkPreviuosButton(){
    if (prefs == null){
      return false;
    }
    if (prefs!.getBool('show_previous_and_next_location') ?? true){
      if (activeMarker == null){
        return false;
      }
      if (activeMarker == locData.locations.keys.first){
        return false;
      }
      return true;
    }
    return false;
  }

  bool checkNextButton(){
    if (prefs == null){
      return false;
    }
    if (prefs!.getBool('show_previous_and_next_location') ?? true){
      if (activeMarker == null){
        return false;
      }
      if (activeMarker == locData.locations.keys.last){
        return false;
      }
      return true;
    }
    return false;
  }

  Align buildPreviousButton(){
    return Align(
        alignment: Alignment.centerLeft,
        child: Container(
            margin: EdgeInsets.all(12),
            width: 38,
            height: 38,
            child: TextButton(
              onPressed: () {
                selectPreviousLocation();
              },
              style: getMapButtonStyle(),
              child: const Icon(Icons.navigate_before),
            )
        )
    );
  }

  Align buildNextButton(){
    return Align(
        alignment: Alignment.centerRight,
        child: Container(
            margin: EdgeInsets.all(12),
            width: 38,
            height: 38,
            child: TextButton(
              onPressed: () {
                selectNextLocation();
              },
              style: getMapButtonStyle(),
              child: const Icon(Icons.navigate_next),
            )
        )
    );
  }

  void selectPreviousLocation() {
    var keys = locData.locations.keys.toList();
    selectLocation(keys[keys.indexOf(activeMarker)-1]);
  }

  void selectNextLocation() {
    var keys = locData.locations.keys.toList();
    selectLocation(keys[keys.indexOf(activeMarker)+1]);
  }

  @override
  void dispose() {
    // Dispose of the controller when the widget is disposed.
    mapController.dispose();
    super.dispose();
  }

  Widget buildLoadingScreen(){
    return Container(
      child: Center(
        child: Text(
          texts.loadingMap,
          style:
          TextStyle(fontFamily: 'Avenir-Medium', color: Colors.grey[400]),
        ),
      ),
    );
  }

  EasySearchBar buildAppBar() {
    var actions = <Widget>[];
    if (activeMarker != null) {
      actions.add(Padding(
          padding: EdgeInsets.only(right: 20.0),
          child: GestureDetector(
            onTap: () {
              navigateToActiveMarker(true, activeMarker);
            },
            child: Icon(
              Icons.navigation,
            ),
          )
      ));
    }
    actions.add(Padding(
        padding: EdgeInsets.only(right: 20.0),
        child: GestureDetector(
          onTap: () {
            synchroniseWithFtp(context);
          },
          child: Icon(
            Icons.sync,
          ),
        )
    ));

    var esb = EasySearchBar(
      title: Text(texts.fieldForm),
      backgroundColor: Constant.primaryColor,
      actions: actions,
      onSearch: (String key) {
        selectLocation(key);
      },
      suggestions: getSuggestions(),
      openOverlayOnSearch: true,
    );
    return esb;
  }

  void selectLocation(String key) {
    if (locData.locations.containsKey(key)){
      var location = locData.locations[key]!;
      // first move the camera to the marker
      if ((location.lat != null) & (location.lon != null)){
        mapController.animateCamera(CameraUpdate.newLatLng(LatLng(location.lat!, location.lon!)));
        // then show the infowindow
        mapController.showMarkerInfoWindow(MarkerId(key));
        setState(() {activeMarker = key;});
        // close the search overlay, so the user can select other actions (navigation, synchronisation) again
        // closeOverlay();
      }
    }
  }

  Drawer buildDrawer() {
    bool showSettingsButton = true;
    if (prefs != null) {
      if (prefs!.getBool('hide_settings_button') ?? false) {
        showSettingsButton = false;
      }
    }
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
            child: Text(texts.menu),
          ),
          ListTile(
            title: Text(texts.addDataFromFile),
            onTap: () {
              // Close the drawer
              Navigator.pop(context);
              choose_file();
            },
            leading: Icon(Icons.insert_drive_file),
          ),
          ListTile(
            title: Text(texts.shareData),
            onTap: () {
              // Close the drawer
              Navigator.pop(context);
              share_data();
            },
            leading: Icon(Icons.share),
          ),
          ListTile(
            title: Text(texts.changeFtpFolder),
            onTap: () async {
              // Close the drawer
              Navigator.pop(context);
              await switchFtpFolder(context);
            },
            leading: Icon(Icons.reset_tv),
          ),
          if (locData.groups.isNotEmpty) ListTile(
            title: Text(texts.chooseGroups),
            onTap: () async {
              // Close the drawer
              Navigator.pop(context);
              final items = <MultiSelectDialogItem<String>>[];
              locData.groups.forEach((id, group){
                var label = group.name ?? id;
                var color = getIconColor(group.color);
                var icon = Icon(Icons.location_pin, color:color);
                items.add(MultiSelectDialogItem(id, label, icon));
              });
              final initialSelectedValues = prefs!.getStringList('selected_groups') ?? locData.groups.keys.toList();
              final selectedGroups = await showDialog<Set<String>>(
                context: context,
                builder: (BuildContext context) {
                  return MultiSelectDialog(
                    items: items,
                    initialSelectedValues: initialSelectedValues.toSet(),
                    title: texts.selectGroups,
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
              title: Text(texts.markMeasuredLocations),
              onTap: () async {
                // Close the drawer
                Navigator.pop(context);
                var interval = await chooseMeasuredInterval(context, prefs!, texts);
                if (interval != null) {
                  await prefs!.setInt('mark_measured_days', interval);
                  await setMarkers();
                  setState(() {});
                }
              },
              leading: Icon(Icons.verified_user)
          ),
          ListTile(
            title: Text(texts.deleteAllData),
            onTap: () async {
              // Close the drawer
              Navigator.pop(context);
              final action = await showContinueDialog(context, texts.sureToDeleteData,
                  title: texts.deleteAllData, yesButton: texts.yes, noButton: texts.no);
              if (action == true) {
                var prefs = await SharedPreferences.getInstance();
                if (await measurementProvider.areThereMessagesToBeSent(prefs)) {
                  final action = await showContinueDialog(context,
                      texts.unsentMeasurements,
                      title: texts.deleteAllData,
                      yesButton: texts.yes,
                      noButton: texts.no);
                  if (action == true) {
                    await deleteAllData();
                  }
                } else {
                  await deleteAllData();
                }
              }
            },
            leading: Icon(Icons.delete),
          ),
          if (showSettingsButton) ListTile(
            title: Text(texts.settings),
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
                setState(() {
                  setMarkers();
                });
              }
            },
            leading: Icon(Icons.settings),
          ),
        ],
      ),
    );
  }

  List<String>? getSuggestions() {
    return locData.locations.keys.toList();
  }

  Future<void> navigateToActiveMarker(bool isDir, String activeMarker) async {
    if (!locData.locations.containsKey(activeMarker)) {
      return;
    }
    var location = locData.locations[activeMarker]!;
    if ((location.lat == null) | (location.lon==null)) {
      return;
    }
    var lat = location.lat!;
    var lon = location.lon!;

    final availableMaps = await map_launcher.MapLauncher.installedMaps;
    await availableMaps.first.showDirections(
        destination: map_launcher.Coords(lat, lon),
      );
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
      markers: markers.values.toSet(),
      mapType: mapType,
      mapToolbarEnabled: false,
      tileOverlays: tileOverlays,
      onLongPress: (latlng) {
        if (prefs!.getBool('disable_adding_locations') ?? false) {
          return;
        }
        setState(() {
          activeMarker = null;
          final id = 'new_marker';
          final marker = Marker(
            markerId: MarkerId(id),
            position: latlng,
            infoWindow: InfoWindow(
              title: texts.addNewLocation,
              onTap: () {
                addNewLocation(context, latlng);
              },
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueBlue),
          );
          markers[id] = marker;
          mapController.showMarkerInfoWindow(MarkerId(id));
        });
      },
      onTap: (latlng) async {
        await checkActiveMarker();
        final id = 'new_marker';
        if (markers.containsKey(id)){
          setState(() {
            markers.remove(id);
          }
          );
        }
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

  Future <void> checkActiveMarker() async {
    if (activeMarker != null){
      final markerIsActive = await mapController.isMarkerInfoWindowShown(MarkerId(activeMarker));
      if (!markerIsActive) {
        setState(() {activeMarker = null;});
      }
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
      if (zoom) {
        ZoomToAllLocations();
      }
    }
    if (prefs!.getBool('request_user') ?? false){
      final user = await editStringSettingDialog(context, 'user', texts.setUser, prefs, texts) ?? '';
      if (user != ''){
        await prefs!.setString('user', user);
        await prefs!.setBool('request_user', false);
      }
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
    final markNotMeasured = prefs!.getBool('mark_not_measured') ?? false;
    if (markNotMeasured){

    }
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
        snippet = texts.n_sublocations(n);
      }
      var marker = Marker(
        markerId: MarkerId(id),
        position: LatLng(location.lat!, location.lon!),
        icon: icon,
        onTap: () {
          setState(() {
            activeMarker = id;
            if (markers.containsKey('new_marker')) {
              markers.remove('new_marker');
            }
          });
        },
        infoWindow: InfoWindow(
          title: location.name ?? id,
          snippet: snippet,
          onTap: () async {
            if (location.sublocations == null) {
              open_add_measurements(id, null);
            } else{
              if (location.sublocations!.length == 1){
                open_add_measurements(location.sublocations!.keys.first, id);
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
                        title: Text(texts.chooseSublocation),
                        children: options,
                      );
                    }
                );
                if (result == null) {
                  return;
                }
                open_add_measurements(result, id);
              }
            }
          },
        ),
      );
      markers[id] = marker;

      // Add extra icon for non-measured locations
      var extraIcon;
      if (markNotMeasured){
        extraIcon = notMeasuredIcon;
      }

      if (location.sublocations == null) {
        if (lastMeasPerLoc.containsKey(id) && lastMeasPerLoc[id].isAfter(reftime)) {
          extraIcon = fullMeasuredIcon;
        }
      } else {
        var halfMeasured = false;
        var fullMeasured = true;
        for (var key in location.sublocations!.keys){
          if (lastMeasPerLoc.containsKey(key) && lastMeasPerLoc[key].isAfter(reftime)) {
              halfMeasured = true;
            } else {
              fullMeasured = false;
            }
          }

        if (fullMeasured) {
          extraIcon = fullMeasuredIcon;
        } else if (halfMeasured) {
          extraIcon = halfMeasuredIcon;
        }
      }

      if (extraIcon != null){
        // add a secondary marker with added information
        markers[id + '_v'] = Marker(
            markerId: MarkerId(id + '_v'),
            position: LatLng(location.lat!, location.lon!),
            icon: extraIcon,
            onTap: () {
              mapController.showMarkerInfoWindow(MarkerId(id));
              setState(() {activeMarker = id;});
            },
            zIndex: 1.0
        );
      }
    }
    activeMarker = null;
  }

  void open_add_measurements(locationId, parentId) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) {
        return AddMeasurements(
            locationId: locationId,
            parentId: parentId,
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
      if (file.path.startsWith('locations') || (file.path.endsWith('.json'))) {
        is_location_file = true;
      } else if (file.path.startsWith('measurements') || (file.path.endsWith('.csv'))) {
        is_location_file = false;
      } else {
        // Ask whether the file contains locations or measurements
        var action = await showContinueDialog(context, texts.locsOrMeas,
            yesButton: texts.locations, noButton: texts.measurements, title: texts.locsOrMeasTitle);
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
                  texts.removeExistingLocations,
                  yesButton: texts.yes,
                  noButton: texts.no,
                  title: texts.removeExistingLocationsTitle);
              if (action == true) {
                await read_location_file(file);
                locData.save_locations();
              }
            }
          } catch (e) {
            showErrorDialog(context, e.toString(), title:texts.importFailed);
          }
        } else if (file.path.endsWith('.csv')) {
          showErrorDialog(context, texts.csvNotImplemented);
        } else {
          showErrorDialog(context, texts.unknownFileExtension);
        }
      } else {
        try {
          await measurementProvider.importFromCsv(file);
        } catch (e) {
          showErrorDialog(context, e.toString(), title:texts.importFailed);
        }
      }
    }
  }

  Future<bool> deleteAllData() async {
    var prefs = await SharedPreferences.getInstance();

    // delete all locations
    locData.locations.clear();
    locData.inputFields = getDefaultInputFields();
    locData.groups = <String, Group>{};
    unawaited(prefs.remove('selected_groups'));

    //delete all data in the documents-directory (location-data and photos)
    var docsDir = await getApplicationDocumentsDirectory();
    if (docsDir.existsSync()){
      // Delete location file
      var file = File(p.join(docsDir.path, 'locations.json'));
      if (await file.exists()){
        unawaited(file.delete());
      }
      // Delete photos
      var dir = Directory(p.join(docsDir.path, 'photos'));
      if (dir.existsSync()){
        for (var file in dir.listSync()) {
          unawaited(file.delete());
        }
      }
    }

    await setMarkers();
    setState(() {});
    await prefs.remove('imported_location_files');

    // delete all measurements
    await measurementProvider.deleteAllMeasurements();
    await prefs.remove('imported_measurement_files');

    await prefs.remove('disable_adding_locations');
    await prefs.remove('hide_settings_button');
    return true;
  }

  Future<void> switchFtpFolder(context) async{
    setState(() {isLoading = true;});
    // connect to ftp folder
    var prefs = await SharedPreferences.getInstance();
    var root = getFtpRoot(prefs);
    var ftp = await connectToFtp(context, prefs, path:root);
    if (ftp == null) {
      setState(() {isLoading = false;});
      return;
    }
    var use_sftp = prefs.getBool('use_sftp') ?? false;
    // First upload existing measurements
    if (await measurementProvider.areThereMessagesToBeSent(prefs)){
      // Check if user wants to send unsent measurements
      var action = await showContinueDialog(context, texts.uploadUnsentMeasurements,
          yesButton: texts.yes, noButton: texts.no, title: texts.unsentMeasurementsTitle);
      if (action == true){
        // connect to the current ftp folder and send the measurements
        var path = prefs.getString('ftp_path') ?? '';
        if (!use_sftp && path.isNotEmpty) {
          var success = await changeDirectory(ftp, context, path);
          if (!success){
            setState(() {isLoading = false;});
            return;
          }
        }
        var success = await sendMeasurementsToFtp(ftp, prefs);
        if (!success) {
          setState(() {isLoading = false;});
          return;
        }
        if (!use_sftp && path.isNotEmpty) {
          // Go to root of ftp server again
          var success = await changeDirectory(ftp, context, '..');
          if (!success){
            setState(() {isLoading = false;});
            return;
          }
        }
      }
    }

    // Choose FTP folder
    var path = await chooseFtpPath(ftp, context, prefs);
    if (path != null) {
      unawaited(prefs.setString('ftp_path', path));
      // Delete all data
      await deleteAllData();

      if (!use_sftp){
        // Go to the specified folder
        var success = await changeDirectory(ftp, context, path);
        if (!success) {
          setState(() {isLoading = false;});
          return;
        }
      }

      // sync with the new ftp folder
      var success = await downloadDataFromFtp(ftp, context, prefs);
      if (!success) {
        setState(() {isLoading = false;});
        return;
      }

      displayInformation(context, texts.syncCompleted);
    }
    // finish up
    closeFtp(ftp, prefs);
    setState(() {isLoading = false;});
  }

  Future<bool> sendMeasurementsToFtp(connection, SharedPreferences prefs) async {
    var only_export_new_data = prefs.getBool('only_export_new_data') ?? true;
    var new_file_name = getMeasurementFileName();
    final tempDir = await getTemporaryDirectory();
    final docsDir = await getApplicationDocumentsDirectory();
    var file = File(p.join(tempDir.path, new_file_name));
    // Get photos
    // get measurements
    List<Measurement> measurements;
    if (only_export_new_data) {
      measurements = await measurementProvider.getMeasurements(where: 'exported = ?', whereArgs: [0]);
    } else {
      measurements = await measurementProvider.getMeasurements();
    }
    if (measurements.isEmpty) {
      return false;
    }
    file = await measurementProvider.measurementsToCsv(measurements, file);

    displayInformation(context, texts.sendingMeasurements);
    var success = await uploadFileToFtp(connection, file, prefs);
    if (!success) {
      showErrorDialog(context, texts.uploadMeasurementsFailed);
      return false;
    }
    // Send photos
    for (var measurement in measurements){
      if (!locData.inputFields.containsKey(measurement.type)) {
        continue;
      }
      if (locData.inputFields[measurement.type]!.type == 'photo') {
        var file = File(p.join(docsDir.path, 'photos', measurement.value));
        if (await file.exists()) {
          var success = await uploadFileToFtp(connection, file, prefs);
          if (!success){
            showErrorDialog(context, texts.uploadPhotoFailed + measurement.value);
            return false;
          }
        }
      }
    }
    var importedMeasurementFiles = prefs.getStringList('imported_measurement_files') ?? <String>[];
    importedMeasurementFiles.add(new_file_name);
    await prefs.setStringList(
        'imported_measurement_files', importedMeasurementFiles);
    // set all measurements to exported
    await measurementProvider.setAllExported();
    return true;
  }

  void synchroniseWithFtp(BuildContext context) async {
    var success;
    setState(() {isLoading = true;});
    //showLoaderDialog(context, text: 'Synchronising with FTP server');
    var prefs = await SharedPreferences.getInstance();
    var ftp = await connectToFtp(context, prefs);
    if (ftp==null){
      setState(() {isLoading = false;});
      return;
    }

    // send measurements
    if (await measurementProvider.areThereMessagesToBeSent(prefs)) {
      success = await sendMeasurementsToFtp(ftp, prefs);
      if (!success) {
        setState(() {isLoading = false;});
        return;
      }
    }

    // download (new) locations and measurements
    success = await downloadDataFromFtp(ftp, context, prefs);
    if (!success) {
      setState(() {isLoading = false;});
      return;
    }

    // finish up
    closeFtp(ftp, prefs);
    setState(() {isLoading = false;});
    displayInformation(context, texts.syncCompleted);
  }

  Future <bool> downloadDataFromFtp(connection, BuildContext context, SharedPreferences prefs) async {
    var importedMeasurementFiles = prefs.getStringList('imported_measurement_files') ?? <String>[];
    var importedLocationFiles = prefs.getStringList('imported_location_files') ?? <String>[];
    var tempDir = await getTemporaryDirectory();

    displayInformation(context, texts.retreivingFiles);
    final names  = await listFilesOnFtp(connection, prefs, context);
    if (names == null) {
      return false;
    }
    displayInformation(context, texts.retreivedFiles);

    // Read last locations-file
    var name;
    for (var iname in names) {
      if (iname.startsWith('locations') & iname.endsWith('.json')){
        name = iname;
      }
    }
    if ((name != null) & !importedLocationFiles.contains(name)) {
      displayInformation(context, texts.downloading + name);
      // download locations
      var file = File(p.join(tempDir.path, name));
      var success = await downloadFileFromFtp(connection, file, prefs);
      if (!success){
        showErrorDialog(context, texts.downloadFailed + name);
        return false;
      }
      // read locations
      try {
        await read_location_file(file);
      } catch (e) {
        closeFtp(connection, prefs);
        showErrorDialog(context, e.toString());
        return false;
      }

      // save locations
      locData.save_locations();
      importedLocationFiles.add(name);
      unawaited(prefs.setStringList('imported_location_files', importedLocationFiles));
    }

    // TODO: first collect all measurements, then add to database
    var importedMeasurements = false;
    for (var name in names) {
      if (name.startsWith('measurements')) {
        if (importedMeasurementFiles.contains(name)){
          continue;
        }
        displayInformation(context, texts.downloading + name);
        // download measurements
        var file = File(p.join(tempDir.path, name));
        try {
          var success = await downloadFileFromFtp(connection, file, prefs);
          if (!success) {
            showErrorDialog(context, texts.downloadFailed + name);
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
          importedMeasurements = true;
        } catch (e) {
          closeFtp(connection, prefs);
          showErrorDialog(context, e.toString());
          return false;
        }
        importedMeasurementFiles.add(name);
        await prefs.setStringList('imported_measurement_files', importedMeasurementFiles);
      }
    }
    // update markers
    final mark_measured_days = prefs.getInt('mark_measured_days') ?? 0;
    if (importedMeasurements && mark_measured_days > 0) {
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

    final measurements = await measurementProvider.getMeasurements();
    if (measurements.isNotEmpty) {
      var new_file_name = getMeasurementFileName();
      final tempDir = await getTemporaryDirectory();
      file = File(p.join(tempDir.path, new_file_name));
      file = await measurementProvider.measurementsToCsv(measurements, file);
      files.add(file.path);

      // Combine photos in a zip-file
      final photos = <File>[];
      final photosDir = p.join(docsDir.path, 'photos');
      for (var measurement in measurements){
        if (!locData.inputFields.containsKey(measurement.type)) {
          continue;
        }
        if (locData.inputFields[measurement.type]!.type == 'photo') {
          var file = File(p.join(photosDir, measurement.value));
          if (await file.exists()) {
            // add file to zip
            photos.add(file);
          }
        }
      }
      if (photos.isNotEmpty){
        // zip photos and add zip-file to files
        final zipname = new_file_name.replaceAll('measurements', 'photos').replaceAll('.csv', '.zip');
        final zipFile = File(p.join(tempDir.path, zipname));
        try {
          await ZipFile.createFromFiles(
              sourceDir: Directory(photosDir), files: photos, zipFile: zipFile);
        } catch (e) {
          showErrorDialog(context, e.toString());
        }
        files.add(zipFile.path);
      }
    }

    if (files.isEmpty){
      showErrorDialog(context, texts.noDataToShare);
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
