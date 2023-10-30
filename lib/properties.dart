import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'constants.dart';
import 'locations.dart';

class PropertiesScreen extends StatelessWidget {
  PropertiesScreen({key, required this.location, required this.locationId}) : super(key: key);

  final Location location;
  final String locationId;


  @override
  Widget build(BuildContext context) {
    var texts = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(texts.properties + ' ' + (location.name ?? locationId)),
        backgroundColor: Constant.primaryColor,
        ),
      body:  ListView.separated(
        padding: EdgeInsets.all(Constant.padding),
        itemCount: location.properties!.length,
        itemBuilder: (BuildContext context, int index) {
          final key = location.properties!.keys.elementAt(index);
          final value = location.properties![key]!;
          return Container(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  flex: 1,
                  child: Text(key),
                ),
                Expanded(
                  flex: 1,
                  child: Text(value.toString()),
                )
              ]
            ),
          );
        },
        separatorBuilder: (BuildContext context, int index) {
          return Divider();
        },
      )
    );
  }
}
