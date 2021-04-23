import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'src/locations.dart' as locs;

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final Map<String, Marker> _markers = {};
  Future<void> _onMapCreated(GoogleMapController controller) async {
    final locations = await locs.getLocations(context);
    setState(() {
      _markers.clear();
      for (final location in locations.locations) {
        final marker = Marker(
          markerId: MarkerId(location.id),
          position: LatLng(location.coords.lat, location.coords.lng),
          infoWindow: InfoWindow(
            title: location.name,
          ),
        );
        _markers[location.id] = marker;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('FieldForm'),
          backgroundColor: Colors.green[700],
        ),
        body: GoogleMap(
          onMapCreated: _onMapCreated,
          initialCameraPosition: CameraPosition(
            target: const LatLng(0, 0),
            zoom: 2,
            ),
          markers: _markers.values.toSet(),
        ),
      ),
    );
  }
}
