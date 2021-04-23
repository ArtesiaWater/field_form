import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'add_measurements.dart';
import 'src/locations.dart' as locs;

//void main() => runApp(MyApp());
void main() => runApp( MaterialApp(home: MyApp()));

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final Map<String, Marker> markers = {};
  var locations = <locs.Location>[];
  CameraPosition? initialCameraPosition;

  Future<void> _onMapCreated(GoogleMapController controller) async {
    final location_file = await locs.getLocations(context);
    if (location_file.locations != null) {
      locations = location_file.locations!;
    }

    setState(() {
      markers.clear();
      for (final location in locations) {
        final marker = Marker(
          markerId: MarkerId(location.id),
          position: LatLng(location.coords.lat, location.coords.lng),
          infoWindow: InfoWindow(
            title: location.name,
            onTap:() {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AddMeasurements()),
              );
            },
          ),
        );
        markers[location.id] = marker;
      }

    });
  }

  void getInitialCameraPosition() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      initialCameraPosition = CameraPosition(
        target: LatLng(prefs.getDouble('latitude') ?? 30,
            prefs.getDouble('longitude') ?? 0),
        zoom: prefs.getDouble('zoom') ?? 2,
      );
    });
  }

  @override
  void initState(){
    super.initState();
    getInitialCameraPosition();
  }

  @override
  Widget build(BuildContext context) {
    if (initialCameraPosition == null) {
      return Scaffold(
        body: Container(
          child: Center(
            child:Text(
              'loading map..',
              style: TextStyle(
                fontFamily: 'Avenir-Medium',
                color: Colors.grey[400]
              ),
            ),
          ),
        )
      );
    } else {
      return Scaffold(
        appBar: AppBar(
          title: const Text('FieldForm'),
          backgroundColor: Colors.green[700],
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
            }
            );
          },
          onCameraMove: (CameraPosition position) async {
            var prefs = await SharedPreferences.getInstance();
            await prefs.setDouble('latitude', position.target.latitude);
            await prefs.setDouble('longitude', position.target.longitude);
            await prefs.setDouble('zoom', position.zoom);
          },
        ),
      );
    }
  }
}

Future newLocationDialog(BuildContext context, latlng, locations) async {
  var teamName = '';
  return showDialog(
    context: context,
    barrierDismissible: false, // dialog is dismissible with a tap on the barrier
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('New location'),
        content: Row(
          children: [
            Expanded(
                child: TextField(
                  autofocus: true,
                  decoration: InputDecoration(
                      labelText: 'Location name', hintText: 'Please enter the new location name'),
                  onChanged: (value) {
                    teamName = value;
                  },
                ))
          ],
        ),
        actions: [
          TextButton(
            child: Text('Ok'),
            onPressed: () {
              Navigator.of(context).pop(teamName);
            },
          ),
        ],
      );
    },
  );
}
