import 'package:flutter/material.dart';

import 'src/locations.dart';

class PropertiesScreen extends StatelessWidget {
  PropertiesScreen({key, required this.location}) : super(key: key);

  final Location location;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var property in location.properties!) {
      rows.add(Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
                flex: 1,
                child: Text(property.name),
            ),
            Expanded(
              flex: 2,
              child: Text(property.value),
            )
          ]
      ));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Properties'),
        backgroundColor: Colors.green[700],
        ),
      body:  ListView(
      children: rows,
      )
    );
  }
}