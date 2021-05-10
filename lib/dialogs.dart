

import 'package:flutter/material.dart';

void showLoaderDialog(BuildContext context, {String text='Loading...'}) {
  showDialog(barrierDismissible: false,
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            Container(margin: EdgeInsets.only(left: 7), child: Text(text)),
          ],),
      );
    },
  );
}

void showErrorDialog(BuildContext context, String text, {String title = 'Error'}) {
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

void showContinueDialog(BuildContext context, String text, onPressed, {String title = 'Continue?'}) {

  // set up the buttons
  Widget cancelButton = TextButton(
    onPressed:  () {
      Navigator.of(context).pop();
    },
    child: Text('Cancel'),
  );
  Widget continueButton = TextButton(
    onPressed:  () {
      onPressed();
      Navigator.of(context).pop();
    },
    child: Text('Continue'),
  );

  // set up the AlertDialog
  var alert = AlertDialog(
    title: Text(title),
    content: Text(text),
    actions: [
      cancelButton,
      continueButton,
    ],
  );

  // show the dialog
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return alert;
    },
  );
}