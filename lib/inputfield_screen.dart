import 'package:field_form/locations.dart';
import 'package:flutter/material.dart';

import 'constants.dart';
import 'dialogs.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class InputFieldsScreen extends StatefulWidget {
  InputFieldsScreen({Key? key}) : super(key: key);

  @override
  _InputFieldsScreenState createState() => _InputFieldsScreenState();
}

class _InputFieldsScreenState extends State<InputFieldsScreen> {
  final locData = LocationData();
  late AppLocalizations texts;

  @override
  Widget build(BuildContext context) {
    texts = AppLocalizations.of(context)!;
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
          title: Text(texts.inputFields),
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
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

    var id = await showInputDialog(context, texts.supplyInputFieldId,
        title: texts.chooseId);
    while (locData.inputFields.containsKey(id)) {
      id = await showInputDialog(context, id! + texts.inputFieldIdExists,
          title: texts.chooseId, initialValue:id);
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
  late AppLocalizations texts;

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
    texts = AppLocalizations.of(context)!;
    final node = FocusScope.of(context);
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.id),
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
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
                labelText: texts.name,
                hintText: texts.anOptionalName,
              ),
              initialValue: inputField.name,
              onChanged: (String text) {
                if (text.isNotEmpty) {
                  inputField.name = text;
                }
              },
              textInputAction: TextInputAction.next,
              onEditingComplete: () => node.nextFocus(),
            ),
            DropdownButtonFormField(
              decoration: InputDecoration(
                labelText: texts.type,
              ),
              isExpanded: true,
              items: getDropdownMenuItems(['number', 'text', 'choice', 'multichoice', 'photo', 'check', 'date', 'time', 'datetime']),
              value: inputField.type,
              onChanged: (String? text) {
                if (text != null) {
                  setState((){
                    inputField.type = text;
                  });
                }
              },
            ),
            if (inputField.type == 'choice' || inputField.type == 'multichoice') TextFormField(
              readOnly: true,
              decoration: InputDecoration(
                labelText: texts.options,
                hintText: texts.tapToAddOptions,
              ),
              controller: TextEditingController(text: (inputField.options ?? '').toString()),
              onTap: () async {
                // make sure the text-field is not focussed
                final new_options = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) {
                    return OptionsScreen(options: inputField.options ?? <String>[]);
                  }),
                );
                if (new_options != null) {
                  setState(() {
                    if (new_options.isEmpty){
                      inputField.options = null;
                      inputField.default_value = null;
                    } else {
                      inputField.options = new_options;
                      if (!inputField.options!.contains(inputField.default_value)){
                        // the default option was removed, make it null
                        inputField.default_value = null;
                      }
                    }
                  });
                }
              },
            ),
            if (inputField.type == 'choice') DropdownButtonFormField(
              decoration: InputDecoration(
                labelText: texts.default_value,
              ),
              isExpanded: true,
              items: getDropdownMenuItems(inputField.options ?? <String>[], add_empty: true),
              value: (inputField.options ?? <String>[]).contains(inputField.default_value) ? inputField.default_value : '',
              onChanged: (String? text) {
                if (text != null) {
                  setState((){
                    inputField.default_value = text;
                  });
                }
              },
            ),
            TextFormField(
              decoration: InputDecoration(
                labelText: texts.hint,
                hintText: texts.anOptionalHint,
              ),
              controller: TextEditingController(text: inputField.hint),
              onChanged: (String text) {
                inputField.hint = text;
              },
            ),
            CheckboxListTile(
                value: inputField.required,
                onChanged: (bool? value) {
                  setState(() {
                    if (value != null) {
                      inputField.required = value;
                    }
                  });
                },
                title: Text(texts.required),
            ),
            ElevatedButton(
              onPressed: () async {
                // Navigate back to the map when tapped.
                Navigator.pop(context, inputField);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
              ),
              child: Text(texts.done),
            )
          ]
        )
    );
  }

  void deleteInputField(BuildContext context) async {
    var text = texts.deleteInputField;
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
  late AppLocalizations texts;

  @override
  void initState() {
    super.initState();
    // copy options so we do not alter the original list
    options = List.from(widget.options);
  }

  @override
  Widget build(BuildContext context) {
    texts = AppLocalizations.of(context)!;

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
                  var text = texts.deleteOption;
                  var action = await showContinueDialog(context, text);
                  if (action == true) {
                    setState(() {
                      options.removeAt(index);
                    });
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
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
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
            ),
            child: Text(texts.done),
          )
        ),
      ]
    ));

    return Scaffold(
      appBar: AppBar(
        title: Text(texts.options),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
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