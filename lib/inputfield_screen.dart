import 'package:field_form/locations.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'constants.dart';
import 'dialogs.dart';

class InputFieldsScreen extends StatelessWidget {
  InputFieldsScreen({Key? key, required this.inputFields}) : super(key: key);

  final Map<String, InputField> inputFields;

  @override
  Widget build(BuildContext context) {
    final children = <Widget> [];
    for (final id in inputFields.keys){
      final inputField = inputFields[id]!;
      children.add(ListTile(
        title: Text(inputField.name ?? id),
        onTap: () async {
          final new_inputField = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) {
              return InputFieldScreen(id: id, inputField: inputField);
            }),
          );
          if (new_inputField != null) {
            inputFields[id] = new_inputField;
          }
        }
      ));
    }
    return Scaffold(
        appBar: AppBar(
          title: const Text('Input fields'),
          backgroundColor: Constant.primaryColor,
          actions: <Widget>[
            Padding(
                padding: EdgeInsets.only(right: 20.0),
                child: GestureDetector(
                  onTap: () {
                    addInputField(context);
                  },
                  child: Icon(
                    Icons.add,
                  ),
                )
            ),
          ],
        ),
        body:  ListView(
          children: children,
        )
    );
  }

  void addInputField(BuildContext context) async {

    var id = await showInputDialog(context, 'Please supply the id of the input-field');
    while (inputFields.containsKey(id)) {
      id = await showInputDialog(context, 'The id $id already exists. Please supply another id of the input-field',
          initialValue:id);
    }

    if (id == null){
      return;
    }

    final inputField = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) {
        final inputField = InputField(type: 'text');
        return InputFieldScreen(id: id!, inputField: inputField);
      }),
    );
    if (inputField != null) {
      inputFields[id] = inputField;
    }
  }
}

class InputFieldScreen extends StatelessWidget {

  InputFieldScreen({Key? key, required this.id, required this.inputField}) : super(key: key);

  final String id;
  final InputField inputField;

  @override
  Widget build(BuildContext context) {
    var items = <DropdownMenuItem<String>>[];
    for (final type in ['number', 'text', 'choice']) {
      items.add(
          DropdownMenuItem(
            value: type,
            child: Text(type),
          )
      );
    }
    return Scaffold(
        appBar: AppBar(
          title: Text(id),
          backgroundColor: Constant.primaryColor,
        ),
        body:  ListView(
          padding: EdgeInsets.all(Constant.padding),
          children: [
            TextFormField(
              decoration: InputDecoration(
                labelText: 'name',
              ),
              initialValue: inputField.name,
            ),
            DropdownButtonFormField(
              decoration: InputDecoration(
                labelText: 'type',
              ),
              isExpanded: true,
              items: items,
              value: inputField.type,
              onChanged: (String? text) {
                if (text != null) {
                  inputField.type = text;
                }
              },
            ),
            TextFormField(
              decoration: InputDecoration(
                labelText: 'hint',
              ),
              initialValue: inputField.hint,
              onChanged: (String text) {
                inputField.hint = text;
              },
            ),
            Row(
              children: [
                Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        // Navigate back to the map when tapped.
                        Navigator.pop(context, inputField);
                      },
                      style: ElevatedButton.styleFrom(
                        primary: Constant.primaryColor,
                      ),
                      child: Text('Done'),
                    )
                )
              ]
            )
          ]
        )
    );
  }
}