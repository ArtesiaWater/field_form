import 'package:field_form/locations.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'constants.dart';
import 'dialogs.dart';

class InputFieldsScreen extends StatefulWidget {
  InputFieldsScreen({Key? key}) : super(key: key);

  @override
  _InputFieldsScreenState createState() => _InputFieldsScreenState();
}

class _InputFieldsScreenState extends State<InputFieldsScreen> {
  final locData = LocationData();

  @override
  Widget build(BuildContext context) {
    final children = <Widget> [];
    for (final id in locData.inputFields.keys){
      final inputField = locData.inputFields[id]!;
      children.add(ListTile(
        title: Text(inputField.name ?? id),
        onTap: () async {
          final new_inputField = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) {
              return InputFieldScreen(id: id);
            }),
          );
          if (new_inputField == null){
            return;
          }
          if (new_inputField == false) {
            locData.inputFields.remove(id);
          } else {
            locData.inputFields[id] = new_inputField;
          }
          locData.save_locations();
          setState(() {});
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

    var id = await showInputDialog(context, 'Please supply the id of the input field.',
        title: 'Choose id');
    while (locData.inputFields.containsKey(id)) {
      id = await showInputDialog(context, 'The id $id already exists. Please supply another id of the input field.',
          title: 'Choose id', initialValue:id);
    }

    if (id == null){
      return;
    }

    final inputField = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) {
        return InputFieldScreen(id: id!);
      }),
    );
    if (inputField != null) {
      locData.inputFields[id] = inputField;
      locData.save_locations();
      setState(() {});
    }
  }
}

class InputFieldScreen extends StatefulWidget {

  InputFieldScreen({Key? key, required this.id}) : super(key: key);

  final String id;

  @override
  _InputFieldScreenState createState() => _InputFieldScreenState();
}

class _InputFieldScreenState extends State<InputFieldScreen> {
  late InputField inputField;
  late bool existing;

  @override
  void initState() {
    super.initState();
    final locData = LocationData();
    existing = locData.inputFields.containsKey(widget.id);
    if (existing) {
      // copy inputField, so we do not alter the original inputField
      inputField = locData.inputFields[widget.id]!.copy();
    } else {
      inputField = InputField(type: 'text');
    }
  }

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
          title: Text(widget.id),
          backgroundColor: Constant.primaryColor,
          actions: <Widget>[
            if (existing) Padding(
                padding: EdgeInsets.only(right: 20.0),
                child: GestureDetector(
                  onTap: () {
                    deleteInputField(context);
                  },
                  child: Icon(
                    Icons.delete,
                  ),
                )
            ),
          ],
        ),
        body:  ListView(
          padding: EdgeInsets.all(Constant.padding),
          children: [
            TextFormField(
              decoration: InputDecoration(
                labelText: 'name',
              ),
              initialValue: inputField.name,
              onChanged: (String text) {
                inputField.name = text;
              },
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
                  setState((){
                    inputField.type = text;
                  });
                }
              },
            ),
            if (inputField.type == 'choice') TextButton(
              onPressed: () async {
                final new_options = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) {
                    return OptionsScreen(options: inputField.options!);
                  }),
                );
                if (new_options != null) {
                  setState(() {
                    inputField.options = new_options;
                  });
                }
              },
              child: Text(inputField.options.toString()),
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

  void deleteInputField(BuildContext context) async {
    var text = 'Are you sure you want to delete this input field?';
    var action = await showContinueDialog(context, text);
    if (action == true) {
      setState(() {
        Navigator.pop(context, false);
      });
    }
  }
}


class OptionsScreen extends StatefulWidget {

  OptionsScreen({Key? key, required this.options}) : super(key: key);

  final List<String> options;

  @override
  _OptionsScreenState createState() => _OptionsScreenState();
}

class _OptionsScreenState extends State<OptionsScreen> {
  late List<String> options;


  @override
  void initState() {
    super.initState();
    // copy options so we do not alter the original list
    options = List.from(widget.options);
  }

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

    final children = <Widget> [];
    options.asMap().forEach((index, option){
      children.add(Row(
        children: [
          Expanded(
            flex: 3,
            child:TextFormField(
              initialValue: option,
              onChanged: (String text) {
                options[index] = text;
              }
            )
          ),
          Expanded(
              flex: 1,
              child: ElevatedButton(
                onPressed: () async {
                  var text = 'Are you sure you want to delete this option?';
                  var action = await showContinueDialog(context, text);
                  if (action == true) {
                    setState(() {
                      options.removeAt(index);
                    });
                  }
                },
                style: ElevatedButton.styleFrom(
                  primary: Constant.primaryColor,
                ),
                child: Text('x'),
              )
          ),
        ]
      ));
    });

    children.add(Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () async {
              // Navigate back to the map when tapped.
              Navigator.pop(context, options);
            },
            style: ElevatedButton.styleFrom(
              primary: Constant.primaryColor,
            ),
            child: Text('Done'),
          )
        ),
      ]
    ));

    return Scaffold(
      appBar: AppBar(
        title: Text('Options'),
        backgroundColor: Constant.primaryColor,
        actions: <Widget>[
          Padding(
            padding: EdgeInsets.only(right: 20.0),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  options.add('');
                });
              },
              child: Icon(
                Icons.add,
              ),
            )
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.all(Constant.padding),
        children: children,
      )
    );
  }
}