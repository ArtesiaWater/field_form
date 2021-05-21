import 'package:flutter/material.dart';

import 'constants.dart';
import 'src/locations.dart';

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
          var property = location.properties![index];
          return Container(
            height: 30,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  flex: 1,
                  child: Text(property.name),
                ),
                Expanded(
                  flex: 1,
                  child: Text(property.value),
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