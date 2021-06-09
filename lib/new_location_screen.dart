


import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'constants.dart';
import 'dialogs.dart';
import 'locations.dart';

class NewLocationScreen extends StatefulWidget {

  NewLocationScreen({Key? key, required this.latLng}) : super(key: key);

  final LatLng latLng;

  @override
  _NewLocationScreenState createState() => _NewLocationScreenState();
}

class _NewLocationScreenState extends State<NewLocationScreen> {
  late Location location;
  String id = '';
  late LocationData locData;

  @override
  void initState() {
    super.initState();
    location = Location(lat:widget.latLng.latitude, lon:widget.latLng.longitude);
    locData = LocationData();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
        appBar: AppBar(
          title: Text('New Location'),
          backgroundColor: Constant.primaryColor,
        ),
        body: ListView(
          padding: EdgeInsets.all(Constant.padding),
          children: [
            Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(location.lat.toString()),
                  SizedBox(width: 30),
                  Text(location.lon.toString()),
                ]
            ),
            TextFormField(
              decoration: const InputDecoration(
                hintText: 'Please specify a unique id',
                labelText: 'Id',
              ),
              onChanged: (String text) {
                id = text;
              },
              autofocus: true,
            ),
            TextFormField(
              decoration: const InputDecoration(
                hintText: 'An optional name',
                labelText: 'Name',
              ),
              onChanged: (String text) {
                if (text.isNotEmpty) {
                  location.name = text;
                }
              },
              autofocus: true,
            ),
            DropdownButtonFormField(
              decoration: const InputDecoration(
                hintText: 'An optional group',
                labelText: 'Group',
              ),
              items: getDropdownMenuItems(locData.groups.keys),
              onChanged: (String? text) {
                setState(() {
                  if (text!.isEmpty) {
                    location.group = null;
                  } else {
                    location.group = text;
                  }
                });
              },
            ),
            // TODO: add inputfields to new location dialog
            Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        if (locData.locations.containsKey(id)) {
                          // TODO: show dialog that id allready exists
                          return;
                        }
                        locData.locations[id] = location;
                        locData.save_locations();
                        Navigator.pop(context, location);
                      },
                      style: ElevatedButton.styleFrom(
                        primary: Constant.primaryColor,
                      ),
                      child: Text('Done'),
                    )
                )]
            )
          ],
        )
    );
  }
}