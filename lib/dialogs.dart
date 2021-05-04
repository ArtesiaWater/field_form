

import 'package:flutter/material.dart';

showLoaderDialog(BuildContext context, {String text="Loading..."}) {
  showDialog(barrierDismissible: false,
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        content: new Row(
          children: [
            CircularProgressIndicator(),
            Container(margin: EdgeInsets.only(left: 7), child: Text(text)),
          ],),
      );
    },
  );
}

showErrorDialog(BuildContext context, String text, {String title = 'Error'}) {
  showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(text),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        );
      }
  );
}