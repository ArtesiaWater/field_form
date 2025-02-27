import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:field_form/dialogs.dart';
import 'package:field_form/photo.dart';
import 'package:field_form/properties.dart';
import 'package:field_form/locations.dart';
import 'package:field_form/measurements.dart';
import 'package:field_form/take_picture_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_datetime_picker_plus/flutter_datetime_picker_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart' as p;
import 'constants.dart';
import 'ftp.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class AddMeasurements extends StatefulWidget {
  AddMeasurements(
      {key,
      required this.locationId,
      this.parentId,
      required this.measurementProvider,
      required this.prefs})
      : super(key: key);

  final String locationId;
  final String? parentId;
  final MeasurementProvider measurementProvider;
  final SharedPreferences prefs;

  @override
  _AddMeasurementsState createState() => _AddMeasurementsState();
}

class _AddMeasurementsState extends State<AddMeasurements> {
  final locData = LocationData();
  var location;
  var parent;
  late DateTime now;
  final Map<String, String> values = {};
  final Map<String, String> requiredCheck = {};
  List<Measurement> measurements = <Measurement>[];
  var isLoading = false;
  List<String>? inputFieldIds;
  String? firstInputField;
  String? lastInputField;
  final _formKey = GlobalKey<FormState>();
  late AppLocalizations texts;
  var changedMeasurements;
  var editedForm;

  @override
  void initState() {
    super.initState();
    changedMeasurements = false;
    editedForm = true;
    now = DateTime.now();
    if (widget.prefs.getBool('use_standard_time') ?? false) {
      var offset =
          now.timeZoneOffset - (DateTime(now.year, 1, 1).timeZoneOffset);
      now = now.subtract(offset);
    }
    if (widget.parentId == null) {
      location = locData.locations[widget.locationId];
    } else {
      parent = locData.locations[widget.parentId]!;
      location = parent.sublocations![widget.locationId];
    }
    inputFieldIds = location.inputfields;
    if (inputFieldIds == null) {
      if (location.group != null) {
        if (locData.groups.containsKey(location.group)) {
          var group = locData.groups[location.group]!;
          if (group.inputfields != null) {
            inputFieldIds = group.inputfields;
          }
        }
      }
    }
    inputFieldIds ??= locData.inputFields.keys.toList();

    // Drop inputFields that are not defined
    // copy the inputfields, so we do not alter the original list
    inputFieldIds = List.from(inputFieldIds!);
    //inputFieldIds!.removeWhere((id) => !locData.inputFields.containsKey(id));
    // set Default values
    for (final id in inputFieldIds!) {
      if (locData.inputFieldGroups.containsKey(id)) {
        var inputFieldGroup = locData.inputFieldGroups[id]!;
        for (var inputfield_id in inputFieldGroup.inputfields) {
          if (firstInputField == null) {
            firstInputField = inputfield_id;
          }
          lastInputField = inputfield_id;
          addDefaultValue(inputfield_id);
        }
      } else {
        if (firstInputField == null) {
          firstInputField = id;
        }
        lastInputField = id;
        addDefaultValue(id);
      }
    }
    getPreviousMeasurements();
  }

  void addDefaultValue(id) {
    if (locData.inputFields.containsKey(id)) {
      var inputField = locData.inputFields[id]!;
      if (inputField.type == 'choice') {
        if (inputField.default_value != null) {
          if ((inputField.options ?? <String>[])
              .contains(inputField.default_value)) {
            values[id] = inputField.default_value!;
          }
        }
      }
    }
  }

  void getPreviousMeasurements() async {
    measurements = await widget.measurementProvider
        .getMeasurementsFromLocation(widget.locationId);
    // combine the measurements with the measurements in the location
    if (location.measurements != null) {
      for (var meas_dict in location.measurements) {
        if (meas_dict.containsKey('type') &&
            meas_dict.containsKey('value') &&
            meas_dict.containsKey('date') &&
            meas_dict.containsKey('time')) {
          var datetime = Constant.datetime_format
              .parse(meas_dict['date'] + ' ' + meas_dict['time']);
          var measurement = Measurement(
              location: widget.locationId,
              datetime: datetime,
              type: meas_dict['type'],
              value: meas_dict['value']);
          measurements.add(measurement);
        }
      }
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    texts = AppLocalizations.of(context)!;
    return PopScope(
        canPop: false,
        onPopInvokedWithResult: (bool didPop, dynamic result) async {
          if (didPop) return;
          if (await checkToGoBack()) {
            Navigator.pop(context, changedMeasurements);
          }
        },
        child: Scaffold(
            appBar: buildAppBar(),
            body: Stack(
              children: [
                Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                      padding: EdgeInsets.all(Constant.padding),
                      child: Column(
                        children: buildRows(),
                      )),
                ),
                if (isLoading) buildLoadingIndicator(text: texts.loading),
              ],
            )));
  }

  AppBar buildAppBar() {
    var actions = <Widget>[];
    if (parent != null &&
        (widget.prefs.getBool('show_previous_and_next_location') ?? true)) {
      if (widget.locationId != parent.sublocations.keys.first) {
        actions.add(Padding(
            padding: EdgeInsets.only(right: 20.0),
            child: GestureDetector(
              onTap: () {
                var keys = parent.sublocations!.keys.toList();
                var locationId = keys[keys.indexOf(widget.locationId) - 1];
                open_add_measurements(locationId, widget.parentId);
              },
              child: Icon(
                Icons.keyboard_arrow_left,
              ),
            )));
      }
      if (widget.locationId != parent.sublocations.keys.last) {
        actions.add(Padding(
            padding: EdgeInsets.only(right: 20.0),
            child: GestureDetector(
              onTap: () {
                var keys = parent.sublocations!.keys.toList();
                var locationId = keys[keys.indexOf(widget.locationId) + 1];
                open_add_measurements(locationId, widget.parentId);
              },
              child: Icon(
                Icons.keyboard_arrow_right,
              ),
            )));
      }
    }
    if (location.photo != null) {
      actions.add(Padding(
          padding: EdgeInsets.only(right: 20.0),
          child: GestureDetector(
            onTap: () {
              displayPhoto(location.photo!);
            },
            child: Icon(
              Icons.photo,
            ),
          )));
    } else if (false) {
      // add a button to take a picture
      actions.add(Padding(
          padding: EdgeInsets.only(right: 20.0),
          child: GestureDetector(
            onTap: () async {},
            child: Icon(
              Icons.camera_alt,
            ),
          )));
    }
    if (location.properties != null) {
      actions.add(Padding(
          padding: EdgeInsets.only(right: 20.0),
          child: GestureDetector(
            onTap: () {
              // Open the properties screen
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) {
                  return PropertiesScreen(
                      location: location, locationId: widget.locationId);
                }),
              );
            },
            child: Icon(
              Icons.info,
            ),
          )));
    }
    return AppBar(
      title: Text(location.name ?? widget.locationId),
      backgroundColor: Theme.of(context).colorScheme.primary,
      foregroundColor: Theme.of(context).colorScheme.onPrimary,
      actions: actions,
    );
  }

  Row getRowForInputfield(id) {
    var inputField = locData.inputFields[id]!;
    var keyboardType = TextInputType.text;
    var validator;
    List<TextInputFormatter>? inputFormatters = [];
    if (inputField.type == 'number') {
      keyboardType =
          TextInputType.numberWithOptions(decimal: true, signed: true);
      if (inputField.required) {
        validator = requiredNumberValidator;
      } else {
        validator = numberValidator;
      }
      inputFormatters.add(CommaTextInputFormatter());
    } else {
      var block_character_set =
          widget.prefs.getString('block_character_set') ?? ";";
      if (!block_character_set.contains(";")) {
        block_character_set = block_character_set + ";";
      }
      final filterPattern = RegExp('[' + block_character_set + ']');
      inputFormatters.add(FilteringTextInputFormatter.deny(filterPattern));
      if (inputField.required) {
        validator = requiredValidator;
      }
    }
    var input;
    if (inputField.type == 'choice') {
      final hint;
      if (inputField.hint == null) {
        hint = null;
      } else {
        hint = Text(inputField.hint!);
      }
      input = DropdownButtonFormField(
        isExpanded: true,
        items: getDropdownMenuItems(inputField.options ?? <String>[],
            add_empty: true),
        onChanged: (String? text) {
          setState(() {
            values[id] = text!;
            editedForm = true;
          });
        },
        value: values[id],
        onTap: () {
          //  'steal' focuses off of the TextField that was previously focused on the dropdown tap
          var node = FocusScope.of(context);
          node.requestFocus(FocusNode());
        },
        validator: validator,
        hint: hint,
      );
    } else if (inputField.type == 'multichoice') {
      input = TextButton(
        onPressed: () async {
          final items = <MultiSelectDialogItem<String>>[];
          for (var option in inputField.options ?? <String>[]) {
            items.add(MultiSelectDialogItem(option, option));
          }

          List<String> initialSelectedValues;
          if (values[id] == null) {
            initialSelectedValues = <String>[];
          } else {
            initialSelectedValues = values[id]!.split('|');
          }

          final selectedItems = await showDialog<Set<String>>(
            context: context,
            builder: (BuildContext context) {
              return MultiSelectDialog(
                items: items,
                initialSelectedValues: initialSelectedValues.toSet(),
                title: inputField.hint ?? inputField.name ?? id,
              );
            },
          );

          if (selectedItems != null && selectedItems.isNotEmpty) {
            values[id] = selectedItems.toList().join('|');
          } else {
            values.remove(id);
          }
          editedForm = true;
        },
        onLongPress: () async {
          if (values[id] != null) {
            var action = await showContinueDialog(
                context, texts.removeValueFromId(values[id]!, id),
                yesButton: texts.yes, noButton: texts.no);
            if (action == true) {
              setState(() {
                values.remove(id);
                editedForm = true;
              });
            }
          }
        },
        child: Text(values[id] ?? inputField.hint ?? ''),
      );
    } else if (inputField.type == 'photo') {
      input = TextButton(
        onPressed: () async {
          if (values[id] == null) {
            // take a new photo
            // Obtain a list of the available cameras on the device.
            final cameras = await availableCameras();
            if (cameras.isEmpty) {
              return;
            }
            // Get a specific camera from the list of available cameras.
            final firstCamera = cameras.first;
            // Open the camera screen
            final image = await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) {
                var resolution = widget.prefs.getString('photo_resolution');
                return TakePictureScreen(
                    camera: firstCamera, resolution: resolution);
              }),
            );
            if (image != null) {
              // copy the image to the documents-directory
              var name = id +
                  '_' +
                  widget.locationId +
                  '_' +
                  Constant.file_datetime_format.format(now) +
                  '.jpg';
              setState(() {
                // Set the filename as the measurement
                values[id] = name;
                editedForm = true;
              });
              var docsDir = getApplicationDocumentsDirectory();
              var dir = Directory(p.join((await docsDir).path, 'photos'));
              if (!dir.existsSync()) {
                await dir.create();
              }
              await File(image.path).copy(p.join(dir.path, name));
            }
          } else {
            // Show the current photo
            await displayPhoto(values[id]!);
          }
        },
        onLongPress: () async {
          if (values[id] != null) {
            var action = await showContinueDialog(
                context, texts.removeValueFromId(values[id]!, id),
                yesButton: texts.yes,
                noButton: texts.no,
                title: texts.removePhotoTitle);
            if (action == true) {
              // remove photo from disk and remove filename from values
              var docsDir = getApplicationDocumentsDirectory();
              var file =
                  File(p.join((await docsDir).path, 'photos', values[id]));
              if (await file.exists()) {
                unawaited(file.delete());
                imageCache.clear();
              }
              setState(() {
                values.remove(id);
                editedForm = true;
              });
            }
          }
        },
        child: Text(values[id] ?? inputField.hint ?? texts.tapToTakePhoto),
      );
    } else if (inputField.type == 'check') {
      var value = (values[id] ?? 'false') == 'true';
      input = CheckboxListTile(
        value: value,
        onChanged: (bool? value) {
          setState(() {
            if (value!) {
              values[id] = 'true';
            } else {
              values.remove(id);
            }
            editedForm = true;
          });
        },
        title: Text(inputField.hint ?? ''),
      );
    } else if ((inputField.type == 'date') |
        (inputField.type == 'time') |
        (inputField.type == 'datetime')) {
      var date_format;
      if (inputField.type == 'date') {
        date_format = Constant.date_format;
      } else if (inputField.type == 'time') {
        date_format = Constant.time_format;
      } else {
        date_format = Constant.datetime_format;
      }
      input = TextButton(
        onPressed: () async {
          var currentTime;
          if (values[id] == null) {
            // start date is now
            currentTime = DateTime.now();
          } else {
            // start date is previous value
            currentTime = date_format.parse(values[id]!);
          }
          if (inputField.type == 'date') {
            await DatePicker.showDatePicker(context, showTitleActions: true,
                onConfirm: (date) {
              values[id] = date_format.format(date);
            }, currentTime: currentTime);
          } else if (inputField.type == 'time') {
            await DatePicker.showTimePicker(context, showTitleActions: true,
                onConfirm: (date) {
              values[id] = date_format.format(date);
            }, currentTime: currentTime);
          } else {
            await DatePicker.showDateTimePicker(context, showTitleActions: true,
                onConfirm: (date) {
              values[id] = date_format.format(date);
            }, currentTime: currentTime);
          }
          editedForm = true;
        },
        onLongPress: () async {
          if (values[id] != null) {
            var action = await showContinueDialog(
                context, texts.removeValueFromId(values[id]!, id),
                yesButton: texts.yes,
                noButton: texts.no,
                title: texts.removeDateTitle);
            if (action == true) {
              setState(() {
                values.remove(id);
                editedForm = true;
              });
            }
          }
        },
        child: Text(values[id] ?? inputField.hint ?? ''),
      );
    } else {
      final node = FocusScope.of(context);
      input = TextFormField(
        autofocus: (id == firstInputField),
        decoration: InputDecoration(hintText: inputField.hint),
        keyboardType: keyboardType,
        onChanged: (text) {
          values[id] = text;
          editedForm = true;
        },
        validator: validator,
        inputFormatters: inputFormatters,
        textInputAction: id == lastInputField ? null : TextInputAction.next,
        onEditingComplete: () => node.nextFocus(), // Move focus to next
      );
    }
    var row = Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
      Expanded(
        flex: 1,
        child: Text(inputField.name ?? id),
      ),
      Expanded(
        flex: 2,
        child: input,
      )
    ]);
    return row;
  }

  List<Widget> buildRows() {
    var date = Constant.date_format.format(now);
    var time = Constant.time_format.format(now);
    final rows = <Widget>[];

    // add a row with the date and time
    rows.add(Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [Text(date), SizedBox(width: 30), Text(time)]));

    // Add a row for each inputField
    for (final id in inputFieldIds!) {
      if (locData.inputFieldGroups.containsKey(id)) {
        rows.add(const Divider(
          height: 10,
          thickness: 4,
          color: Colors.black,
        ));
        var inputFieldGroup = locData.inputFieldGroups[id]!;
        rows.add(Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(inputFieldGroup.name ?? id),
        ]));
        for (var inputfield_id in inputFieldGroup.inputfields) {
          if (locData.inputFields.containsKey(inputfield_id)) {
            rows.add(getRowForInputfield(inputfield_id));
          }
        }
        rows.add(const Divider(
          height: 10,
          thickness: 4,
          color: Colors.black,
        ));
      } else if (locData.inputFields.containsKey(id)) {
        rows.add(getRowForInputfield(id));
      }
    }
    ;

    // Add Done button
    rows.add(SizedBox(
        width: double.infinity, // <-- match_parent
        child: ElevatedButton(
          onPressed: () async {
            if (_formKey.currentState!.validate()) {
              var added_measurements = false;
              for (var id in inputFieldIds!) {
                if (locData.inputFieldGroups.containsKey(id)) {
                  var inputFieldGroup = locData.inputFieldGroups[id]!;
                  for (var inputfield_id in inputFieldGroup.inputfields) {
                    if (locData.inputFields.containsKey(inputfield_id)) {
                      var code = await storeMeasurement(inputfield_id);
                      if (code == 0) {
                        return;
                      } else if (code == 2) {
                        added_measurements = true;
                      }
                    }
                  }
                } else {
                  var code = await storeMeasurement(id);
                  if (code == 0) {
                    return;
                  } else if (code == 2) {
                    added_measurements = true;
                  }
                }
              }
              if (added_measurements) {
                if (widget.prefs.getBool('add_user_to_measurements') ?? false) {
                  final user = widget.prefs.getString('user') ?? '';
                  if (user != '') {
                    final user_inputfield =
                        widget.prefs.getString('user_inputfield') ?? 'user';
                    if (user_inputfield != '') {
                      var measurement = Measurement(
                          location: widget.locationId,
                          datetime: now,
                          type: user_inputfield,
                          value: user);
                      await widget.measurementProvider.insert(measurement);
                    }
                  }
                }
                changedMeasurements = true;
              }

              // Navigate back to the map when tapped.
              Navigator.pop(context, changedMeasurements);
            }
            editedForm = false;
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
          ),
          child: Text(texts.done),
        )));

    // Add previous measurements
    rows.add(Text(texts.previousMeasurements));
    rows.add(const Divider());

    // remove measurements where the value is empty
    measurements.removeWhere((measurement) => measurement.value == '');

    if (widget.prefs.getBool('group_previous_measurements_by_date') ?? true) {
      // group measurements by datetime
      final measurementsByDatetime = <DateTime, List<Measurement>>{};
      for (var measurement in measurements) {
        if (!measurementsByDatetime.containsKey(measurement.datetime)) {
          measurementsByDatetime[measurement.datetime] = <Measurement>[];
        }
        measurementsByDatetime[measurement.datetime]!.add(measurement);
      }
      // add a row per single datetime
      measurementsByDatetime.forEach((datetime, measurements) {
        var rows_per_datetime = <Widget>[];
        for (var measurement in measurements) {
          Widget valueWidget = Text(measurement.value);
          if (locData.inputFields.containsKey(measurement.type)) {
            if (locData.inputFields[measurement.type]!.type == 'photo') {
              valueWidget = TextButton(
                  onPressed: () {
                    displayPhoto(measurement.value);
                  },
                  child: valueWidget);
            }
          }
          rows_per_datetime.add(
              Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            Expanded(
              flex: 3,
              child: Text(measurement.type),
            ),
            Expanded(
              flex: 2,
              child: valueWidget,
            ),
          ]));
        }
        var delete_button;
        // check if any of the measurements has an id
        if (measurements.any((measurement) => measurement.id != null)) {
          delete_button = IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              var action = await showContinueDialog(
                  context,
                  texts.sureToDeleteMeasurementAt(
                      Constant.datetime_format.format(datetime)),
                  yesButton: texts.yes,
                  noButton: texts.no,
                  title: texts.sureToDeleteMeasurementTitle);
              if (action == true) {
                deleteMeasurements(measurements);
              }
            },
          );
        } else {
          delete_button = const Icon(Icons.delete_outline, color: Colors.grey);
        }

        var date_text = Constant.date_format.format(datetime);
        var time_text = Constant.time_format.format(datetime);
        if (time_text != "00:00:00") {
          date_text = date_text + "\n" + time_text;
        }
        rows.add(
            Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          Expanded(
            flex: 2,
            child: Text(date_text),
          ),
          Expanded(
            flex: 5,
            child: Column(children: rows_per_datetime),
          ),
          Expanded(
            flex: 1,
            child: delete_button,
          ),
        ]));
        rows.add(Divider());
      });
    } else {
      for (var measurement in measurements) {
        Widget valueWidget = Text(measurement.value);
        if (locData.inputFields.containsKey(measurement.type)) {
          if (locData.inputFields[measurement.type]!.type == 'photo') {
            valueWidget = TextButton(
                onPressed: () {
                  displayPhoto(measurement.value);
                },
                child: valueWidget);
          }
        }
        rows.add(
            Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          Expanded(
            flex: 2,
            child: Text(Constant.date_format.format(measurement.datetime) +
                "\n" +
                Constant.time_format.format(measurement.datetime)),
          ),
          Expanded(
            flex: 2,
            child: Text(measurement.type),
          ),
          Expanded(
            flex: 2,
            child: valueWidget,
          ),
          Expanded(
              flex: 1,
              child: IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () async {
                  var action = await showContinueDialog(
                      context,
                      texts.sureToDeleteMeasurement(
                          measurement.value, measurement.type),
                      yesButton: texts.yes,
                      noButton: texts.no,
                      title: texts.sureToDeleteMeasurementTitle);
                  if (action == true) {
                    deleteMeasurement(measurement);
                  }
                },
                //style: ElevatedButton.styleFrom(
                //backgroundColor: Constant.primaryColor,
                //),
              )),
        ]));
      }
    }
    return rows;
  }

  Future<int> storeMeasurement(id) async {
    var inputField = locData.inputFields[id]!;
    if (!values.containsKey(id) || values[id]!.isEmpty) {
      if (!['number', 'text'].contains(inputField.type) &&
          inputField.required) {
        showErrorDialog(context, inputField.name ?? id + texts.isRequired);
        return 0;
      }
      return 1;
    } else {
      if (inputField.type == "number") {
        // test if value does not exceed maximum value or minimum value
        if ((location.min_values != null) &&
            location.min_values.containsKey(id)) {
          var value = double.parse(values[id]!);
          if (value < location.min_values[id]) {
            var action = await showContinueDialog(
                context,
                texts.value_is_lower_than_min(
                    id, value, location.min_values[id]),
                title: texts.value_is_lower_than_min_title,
                yesButton: texts.yes,
                noButton: texts.no);
            if (action != true) {
              return 0;
            }
          }
        }

        if ((location.max_values != null) &&
            location.max_values.containsKey(id)) {
          var value = double.parse(values[id]!);
          if (value > location.max_values[id]) {
            var action = await showContinueDialog(
                context,
                texts.value_is_higher_than_max(
                    id, value, location.max_values[id]),
                title: texts.value_is_higher_than_max_title,
                yesButton: texts.yes,
                noButton: texts.no);
            if (action != true) {
              return 0;
            }
          }
        }
      }
      var measurement = Measurement(
          location: widget.locationId,
          datetime: now,
          type: id,
          value: values[id]!);
      await widget.measurementProvider.insert(measurement);
      return 2;
    }
  }

  String? numberValidator(String? value) {
    if ((value == null) || (value.isEmpty)) {
      return null;
    }
    final n = num.tryParse(value);
    if (n == null) {
      return value + texts.isNotValidNumber;
    }
    return null;
  }

  String? requiredValidator(String? value) {
    final allow_required_override =
        widget.prefs.getBool('allow_required_override') ?? false;
    if (allow_required_override && !editedForm) {
      return null;
    }
    if ((value == null) || (value.isEmpty)) {
      return texts.requiredInputField;
    }
    return null;
  }

  String? requiredNumberValidator(String? value) {
    var return_string = requiredValidator(value);
    if (return_string != null) {
      return return_string;
    }
    return numberValidator(value);
  }

  Future<bool> checkToGoBack() async {
    // did the user fill in any values yet?
    var hasValues = false;
    for (var id in values.keys) {
      if (values[id]!.isNotEmpty) {
        var inputField = locData.inputFields[id]!;
        if (inputField.default_value != null) {
          if (values[id] == inputField.default_value) {
            continue;
          }
        }
        hasValues = true;
        break;
      }
    }
    if (hasValues) {
      // ask if the user really wants to go back
      var action = await showContinueDialog(context, texts.ignoreFilledValues,
          yesButton: texts.yes,
          noButton: texts.no,
          title: texts.ignoreFilledValuesTitle);
      if (action == true) {
        var docsDir = getApplicationDocumentsDirectory();
        // delete photo's from disk
        for (final id in values.keys) {
          var inputField = locData.inputFields[id]!;
          if (inputField.type == 'photo') {
            // remove photo from disk
            var file = File(p.join((await docsDir).path, 'photos', values[id]));
            if (await file.exists()) {
              unawaited(file.delete());
            }
          }
        }
        return Future.value(true);
      } else {
        return Future.value(false);
      }
    }
    return Future.value(true);
  }

  void deleteMeasurement(Measurement measurement) {
    if (measurement.id == null) {
      return;
    }
    setState(() {
      measurement.value = '';
      widget.measurementProvider.update(measurement);
    });
    changedMeasurements = true;
  }

  void deleteMeasurements(List<Measurement> measurements) {
    for (var measurement in measurements) {
      deleteMeasurement(measurement);
    }
  }

  void open_add_measurements(locationId, parentId) async {
    if (await checkToGoBack()) {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) {
          return AddMeasurements(
              locationId: locationId,
              parentId: parentId,
              measurementProvider: widget.measurementProvider,
              prefs: widget.prefs);
        }),
      );
      if (result != null) {
        if (result) {
          // there are changed measurements in the other sublocation
          changedMeasurements = true;
        }
      }
      Navigator.pop(context, changedMeasurements);
    }
  }

  Future<void> displayPhoto(String name) async {
    if (!name.endsWith('.jpg') &
        !name.endsWith('.png') &
        !name.endsWith('.pdf')) {
      showErrorDialog(context, name + texts.imageNotSupported);
      return;
    }
    // check if photo exists in documents-directory
    var docsDir = await getApplicationDocumentsDirectory();
    var dir = Directory(p.join((docsDir).path, 'photos'));
    File? file = File(p.join(dir.path, name));
    // check if photo exists on ftp-server
    if (!file.existsSync()) {
      setState(() {
        isLoading = true;
      });
      var prefs = await SharedPreferences.getInstance();
      var connection = await connectToFtp(context, prefs);
      if (connection == null) {
        setState(() {
          isLoading = false;
        });
        showErrorDialog(context, texts.connectToFtpFailed);
        return;
      }
      displayInformation(context, texts.downloading + name);
      if (!dir.existsSync()) {
        await dir.create();
      }
      var success = await downloadFileFromFtp(connection, file, prefs);
      if (!success) {
        setState(() {
          isLoading = false;
        });
        showErrorDialog(context, texts.downloadFailed + name);
        return;
      }
      closeFtp(connection, prefs);
      setState(() {
        isLoading = false;
      });
    }
    // Open the photo screen
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) {
        return PhotoScreen(file: file);
      }),
    );
  }
}

class CommaTextInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    var truncated = newValue.text;
    final newSelection = newValue.selection;

    if (newValue.text.contains(',')) {
      truncated = newValue.text.replaceFirst(RegExp(','), '.');
    }
    return TextEditingValue(
      text: truncated,
      selection: newSelection,
    );
  }
}
