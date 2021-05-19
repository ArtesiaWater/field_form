

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

enum DialogAction  {yes, no}

Future<DialogAction?> showContinueDialog(BuildContext context, String text,
    {String title = 'Continue?', String yesButton = 'Continue',
    String noButton = 'Cancel'}) async {

  // set up the buttons
  Widget cancelButton = TextButton(
    onPressed:  () {
      Navigator.of(context).pop(DialogAction.no);
    },
    child: Text(noButton),
  );
  Widget continueButton = TextButton(
    onPressed:  () {
      Navigator.of(context).pop(DialogAction.yes);
    },
    child: Text(yesButton),
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
  var action = await showDialog(
    context: context,
    builder: (BuildContext context) {
      return alert;
    },
  );
  return action;
}

void displayInformation(context, text){
  var snackBar = SnackBar(content: Text(text));
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(snackBar);
}
