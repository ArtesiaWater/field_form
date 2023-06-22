import 'package:flutter/material.dart';

import 'constants.dart';
import 'locations.dart';

class PropertiesScreen extends StatelessWidget {
  PropertiesScreen({key, required this.location, required this.locationId}) : super(key: key);

  final Location location;
  final String locationId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Properties ' + (location.name ?? locationId)),
        backgroundColor: Constant.primaryColor,
        ),
      body:  ListView.separated(
        padding: EdgeInsets.all(Constant.padding),
        itemCount: location.properties!.length,
        itemBuilder: (BuildContext context, int index) {
          final key = location.properties!.keys.elementAt(index);
          final value = location.properties![key]!;
          return Container(
            height: 30,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  flex: 1,
                  child: Text(key),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Text(
                      value.toString(),
                      overflow: TextOverflow.visible,
                    ),
                  ),
                ),
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
