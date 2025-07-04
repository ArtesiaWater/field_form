import 'package:flutter/material.dart';
import 'l10n/app_localizations.dart';

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
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        ),
      body:  ListView.separated(
        padding: EdgeInsets.all(Constant.padding),
        itemCount: location.properties!.length,
        itemBuilder: (BuildContext context, int index) {
          final key = location.properties!.keys.elementAt(index);
          var value = location.properties![key] == null ? "" : location.properties![key]!.toString();
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
                  child: Text(value),
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
