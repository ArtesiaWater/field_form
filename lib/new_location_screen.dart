


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
    final node = FocusScope.of(context);
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
              textInputAction: TextInputAction.next,
              onEditingComplete: () => node.nextFocus(),
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
              textInputAction: TextInputAction.next,
              onEditingComplete: () => node.nextFocus(),
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
                node.requestFocus(FocusNode());
              },
            ),
            TextFormField(
              readOnly: true,
              decoration: InputDecoration(
                labelText: 'Input fields',
                hintText: 'Tap to add input fields',
              ),
              controller: TextEditingController(text: (location.inputfields ?? '').toString()),
              onTap: () async {
                final items = <MultiSelectDialogItem<String>>[];
                locData.inputFields.forEach((id, inputField){
                  var label = inputField.name ?? id;
                  items.add(MultiSelectDialogItem(id, label));
                });
                final initialSelectedValues = location.inputfields ?? <String>[];
                final selection = await showDialog<Set<String>>(
                  context: context,
                  builder: (BuildContext context) {
                    return MultiSelectDialog(
                      items: items,
                      initialSelectedValues: initialSelectedValues.toSet(),
                      title: 'Select input fields',
                    );
                  },
                );

                if (selection != null) {
                  setState(() {
                    if (selection.isEmpty){
                      location.inputfields = null;
                    } else {
                      location.inputfields = selection.toList();
                    }
                  });
                }
              },
            ),

            ElevatedButton(
              onPressed: () async {
                if (id.isEmpty) {
                  showErrorDialog(context, 'Please specify an id.');
                  return;
                }
                if (locData.locations.containsKey(id)) {
                  showErrorDialog(context, 'The id $id already exists. Please enter another id.');
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
          ],
        )
    );
  }
}