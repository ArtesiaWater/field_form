import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'constants.dart';
import 'dialogs.dart';
import 'locations.dart';
import 'l10n/app_localizations.dart';

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
  late AppLocalizations texts;

  @override
  void initState() {
    super.initState();
    location = Location(lat:widget.latLng.latitude, lon:widget.latLng.longitude);
    locData = LocationData();
  }

  @override
  Widget build(BuildContext context) {
    texts = AppLocalizations.of(context)!;
    final node = FocusScope.of(context);
    return Scaffold(
        appBar: AppBar(
          title: Text(texts.newLocation),
          backgroundColor:Theme.of(context).primaryColor,
          foregroundColor: Theme.of(context).secondaryHeaderColor,
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
              decoration: InputDecoration(
                hintText: texts.specifyUniqueId,
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
              decoration: InputDecoration(
                hintText: texts.anOptionalName,
                labelText: texts.name,
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
              decoration: InputDecoration(
                hintText: texts.anOptionalGroup,
                labelText: texts.group_optional,
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
                labelText: texts.inputfields_optional,
                hintText: texts.tapToAddInputFields,
              ),
              controller: TextEditingController(text: (location.inputfields ?? '').toString()),
              onTap: () async {
                final items = <MultiSelectDialogItem<String>>[];
                locData.inputFields.forEach((id, inputField){
                  var label = inputField.name ?? id;
                  var icon = Icon(Icons.input);
                  items.add(MultiSelectDialogItem(id, label, icon));
                });
                final initialSelectedValues = location.inputfields ?? <String>[];
                final selection = await showDialog<Set<String>>(
                  context: context,
                  builder: (BuildContext context) {
                    return MultiSelectDialog(
                      items: items,
                      initialSelectedValues: initialSelectedValues.toSet(),
                      title: texts.selectInputFields,
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
                  showErrorDialog(context, texts.specifyId);
                  return;
                }
                if (locData.locations.containsKey(id)) {
                  showErrorDialog(context, id +  texts.locationIdExists);
                  return;
                }
                locData.locations[id] = location;
                locData.save_locations();
                Navigator.pop(context, location);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
              ),
              child: Text(texts.done),
            )
          ],
        )
    );
  }
}