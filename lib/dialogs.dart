

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

Future<bool?> showContinueDialog(BuildContext context, String text,
    {String title = 'Continue?', String yesButton = 'Continue',
    String noButton = 'Cancel'}) async {

  // show the dialog
  var action = await showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(title),
        content: Text(text),
        actions: [
          TextButton(
            onPressed:  () {
              Navigator.of(context).pop(false);
            },
            child: Text(noButton),
          ),
          TextButton(
            onPressed:  () {
              Navigator.of(context).pop(true);
            },
            child: Text(yesButton),
          ),
        ],
      );
    },
  );
  return action;
}

Future<String?> showInputDialog(BuildContext context, String text,
    {String title = 'Input', String yesButton = 'ok',
      String noButton = 'cancel', String? initialValue}) async {

  final myController = TextEditingController(text: initialValue);
  // show the dialog
  var action = await showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(text),
            TextFormField(
              controller: myController,
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed:  () {
              Navigator.of(context).pop(null);
            },
            child: Text(noButton),
          ),
          TextButton(
            onPressed:  () {
              final id = myController.text;
              Navigator.of(context).pop(id);
            },
            child: Text(yesButton),
          ),
        ],
      );
    },
  );
  return action;
}

void displayInformation(context, text){
  var snackBar = SnackBar(content: Text(text));
  ScaffoldMessenger.of(context)
    ..removeCurrentSnackBar()
    ..showSnackBar(snackBar);
}

class MultiSelectDialogItem<V> {
  MultiSelectDialogItem(this.value, this.label, this.icon);

  final V value;
  final String label;
  final Icon icon;
}

class MultiSelectDialog<V> extends StatefulWidget {
  MultiSelectDialog({
    required this.items,
    this.initialSelectedValues,
    this.title});

  final List<MultiSelectDialogItem<V>> items;
  final Set<V>? initialSelectedValues;
  final String? title;

  @override
  State<StatefulWidget> createState() => _MultiSelectDialogState<V>();
}

class _MultiSelectDialogState<V> extends State<MultiSelectDialog<V>> {
  final _selectedValues = <V>{};

  @override
  void initState() {
    super.initState();
    if (widget.initialSelectedValues != null) {
      _selectedValues.addAll(widget.initialSelectedValues!);
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
      title: Text(widget.title ?? 'Select'),
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
          onPressed: () {
            Navigator.pop(context);
          },
          child: Text('Cancel')
        ),
        TextButton(
          onPressed: (){
            Navigator.pop(context, _selectedValues);
          },
          child: Text('Ok'),
        )
      ],
    );
  }

  Widget _buildItem(MultiSelectDialogItem<V> item) {
    final checked = _selectedValues.contains(item.value);
    return CheckboxListTile(
      value: checked,
      title: Text(item.label),
      secondary: item.icon,
      controlAffinity: ListTileControlAffinity.leading,
      onChanged: (checked) => _onItemCheckedChange(item.value, checked!),
    );
  }
}

List<DropdownMenuItem<String>> getDropdownMenuItems(options, {add_empty=false}) {
  var items = <DropdownMenuItem<String>>[];
  if (add_empty) {
    // add an empty value
    items.add(
        DropdownMenuItem(
          value: '',
          child: Text(''),
        )
    );
  }
  for (var option in options) {
    items.add(
      DropdownMenuItem(
        value: option,
        child: Text(option),
      ),
    );
  }
  return items;
}