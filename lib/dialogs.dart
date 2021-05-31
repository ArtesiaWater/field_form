

import 'package:flutter/material.dart';

void showLoaderDialog(BuildContext context, {String text='Loading...'}) {
  showDialog(barrierDismissible: false,
    context: context,
    builder: (BuildContext context) {
      return buildLoadingIndicator(text: text);
    },
  );
}

AlertDialog buildLoadingIndicator({String text='Loading...'}){
  return AlertDialog(
    content: Row(
      children: [
        CircularProgressIndicator(),
        Container(margin: EdgeInsets.only(left: 7), child: Text(text)),
      ],),
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


class MultiSelectDialogItem<V> {
  const MultiSelectDialogItem(this.value, this.label);

  final V value;
  final String label;
}

class MultiSelectDialog<V> extends StatefulWidget {
  MultiSelectDialog({
    required this.items,
    required this.initialSelectedValues});

  final List<MultiSelectDialogItem<V>> items;
  final Set<V> initialSelectedValues;

  @override
  State<StatefulWidget> createState() => _MultiSelectDialogState<V>();
}

class _MultiSelectDialogState<V> extends State<MultiSelectDialog<V>> {
  final _selectedValues = Set<V>();

  void initState() {
    super.initState();
    if (widget.initialSelectedValues != null) {
      _selectedValues.addAll(widget.initialSelectedValues);
    }
  }

  void _onItemCheckedChange(V itemValue, bool checked) {
    setState(() {
      if (checked) {
        _selectedValues.add(itemValue);
      } else {
        _selectedValues.remove(itemValue);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Select animals'),
      contentPadding: EdgeInsets.only(top: 12.0),
      content: SingleChildScrollView(
        child: ListTileTheme(
          contentPadding: EdgeInsets.fromLTRB(14.0, 0.0, 24.0, 0.0),
          child: ListBody(
            children: widget.items.map(_buildItem).toList(),
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: Text('Cancel'),
          onPressed: () {
            Navigator.pop(context);
          }
        ),
        TextButton(
          child: Text('Ok'),
          onPressed: (){
            Navigator.pop(context, _selectedValues);
          },
        )
      ],
    );
  }

  Widget _buildItem(MultiSelectDialogItem<V> item) {
    final checked = _selectedValues.contains(item.value);
    return CheckboxListTile(
      value: checked,
      title: Text(item.label),
      controlAffinity: ListTileControlAffinity.leading,
      onChanged: (checked) => _onItemCheckedChange(item.value, checked!),
    );
  }
}
