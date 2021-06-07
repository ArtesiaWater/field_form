import 'package:flutter/material.dart';

import 'constants.dart';
import 'locations.dart';

class PropertiesScreen extends StatelessWidget {
  PropertiesScreen({key, required this.location}) : super(key: key);

  final Location location;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Properties'),
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