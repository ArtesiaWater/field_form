import 'dart:async';
import 'dart:io';

import 'package:field_form/dialogs.dart';
import 'package:field_form/photo.dart';
import 'package:field_form/properties.dart';
import 'package:field_form/locations.dart';
import 'package:field_form/measurements.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_datetime_picker/flutter_datetime_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart' as p;
import 'constants.dart';
import 'ftp.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:camera/camera.dart';
import 'take_picture_screen.dart';

class AddMeasurements extends StatefulWidget {
  AddMeasurements({key, required this.locationId, required this.location,
    required this.measurementProvider, required this.prefs})
      : super(key: key);

  final String locationId;
  final Location location;
  final MeasurementProvider measurementProvider;
  final SharedPreferences prefs;

  @override
  _AddMeasurementsState createState() => _AddMeasurementsState();
}

class _AddMeasurementsState extends State<AddMeasurements> {
  final locData = LocationData();
  late DateTime now;
  final Map<String, String> values = {};
  List<Measurement> measurements = <Measurement>[];
  var isLoading = false;
  List<String>? inputFieldIds;
  final _formKey = GlobalKey<FormState>();
  late AppLocalizations texts;

  @override
  void initState() {
    super.initState();
    now = DateTime.now();
    if (widget.prefs.getBool('use_standard_time') ?? false) {
      var offset = now.timeZoneOffset - (DateTime(now.year, 1, 1).timeZoneOffset);
      now = now.subtract(offset);
    }
    final location = widget.location;
    inputFieldIds = location.inputfields;
    if (inputFieldIds == null) {
      if (location.group != null){
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
    inputFieldIds!.removeWhere((id) => !locData.inputFields.containsKey(id));
    // set Default values
    for (final id in inputFieldIds!) {
      var inputField = locData.inputFields[id]!;
      if (inputField.type == 'choice'){
        if (inputField.default_value != null) {
          if ((inputField.options ?? <String>[]).contains(inputField.default_value)) {
            values[id] = inputField.default_value!;
          }
        }
      }
    }
    getPreviousMeasurements();
  }

  void getPreviousMeasurements() async{
    measurements = await widget.measurementProvider.getMeasurementsFromLocation(
        widget.locationId);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    texts = AppLocalizations.of(context)!;
    return WillPopScope(
      onWillPop: () async {
        return checkToGoBack();
      },
      child: Scaffold(
        appBar: buildAppBar(),
        body:  Stack(
          children: [
            Form(
              key: _formKey,
              child: ListView(
                padding: EdgeInsets.all(Constant.padding),
                children: buildRows(),
              ),
            ),
            if (isLoading) buildLoadingIndicator(text:texts.loading),
          ],
        )
      )
    );
  }

  AppBar buildAppBar() {
    final location = widget.location;
    var actions = <Widget>[];
    if (location.photo != null){
      actions.add(Padding(
        padding: EdgeInsets.only(right: 20.0),
        child: GestureDetector(
          onTap: () {
            displayPhoto(location.photo!);
          },
          child: Icon(
            Icons.photo,
          ),
        )
      ));
    } else if (false) {
      // add a button to take a picture
      actions.add(Padding(
          padding: EdgeInsets.only(right: 20.0),
          child: GestureDetector(
            onTap: () async {
              // Obtain a list of the available cameras on the device.
              final cameras = await availableCameras();
              if (cameras.isEmpty){
                return;
              }
              // Get a specific camera from the list of available cameras.
              final firstCamera = cameras.first;
              // Open the camera screen
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) {
                  return TakePictureScreen(camera: firstCamera);
                }),
              );
            },
            child: Icon(
              Icons.camera_alt,
            ),
          )
      ));
    }
    if (location.properties != null){
      actions.add(Padding(
          padding: EdgeInsets.only(right: 20.0),
          child: GestureDetector(
            onTap: () {
              // Open the properties screen
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) {
                  return PropertiesScreen(location: location, locationId:widget.locationId);
                }),
              );
            },
            child: Icon(
              Icons.info,
            ),
          )
      ));
    }
    return AppBar(
      title: Text(location.name ?? widget.locationId),
      backgroundColor: Constant.primaryColor,
      actions: actions,
    );
  }

  List<Widget> buildRows(){
    var docsDir = getApplicationDocumentsDirectory();
    var date = Constant.date_format.format(now);
    var time = Constant.time_format.format(now);
    final rows = <Widget>[];

    // add a row with the date and time
    rows.add(Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(date),
          SizedBox(width: 30),
          Text(time)
        ]
    ));

    // Add a row for each inputField
    final node = FocusScope.of(context);
    for (final id in inputFieldIds!) {
      var inputField = locData.inputFields[id]!;
      var keyboardType = TextInputType.text;
      var validator;
      List<TextInputFormatter>? inputFormatters = [];
      if (inputField.type == 'number'){
        keyboardType = TextInputType.number;
        if (inputField.required){
          validator = requiredNumberValidator;
        } else {
          validator = numberValidator;
        }
        inputFormatters.add(CommaTextInputFormatter());
      } else {
        inputFormatters.add(FilteringTextInputFormatter.deny(RegExp('[;]')));
        if (inputField.required){
          validator = requiredValidator;
        }
      }
      var input;
      if (inputField.type == 'choice'){
        final hint;
        if (inputField.hint == null) {
          hint = null;
        } else {
          hint = Text(inputField.hint!);
        }
        input = DropdownButtonFormField(
          isExpanded: true,
          items: getDropdownMenuItems(inputField.options ?? <String>[], add_empty:true),
          onChanged: (String? text) {
            setState(() {
              values[id] = text!;
            });
          },
          value: values[id],
          onTap: () {
            //  'steal' focuses off of the TextField that was previously focused on the dropdown tap
            node.requestFocus(FocusNode());
          },
          validator: validator,
          hint: hint,
        );
      } else if (inputField.type == 'photo') {
        input = TextButton(
          onPressed: () async {
            if (values[id] == null) {
              // take a new photo
              // Obtain a list of the available cameras on the device.
              final cameras = await availableCameras();
              if (cameras.isEmpty){
                return;
              }
              // Get a specific camera from the list of available cameras.
              final firstCamera = cameras.first;
              // Open the camera screen
              final image = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) {
                  var resolution = widget.prefs.getString('photo_resolution');
                  return TakePictureScreen(camera: firstCamera, resolution: resolution);
                }),
              );
              if (image != null) {
                // copy the image to the documents-directory
                var name = id + '_' + widget.locationId + '_' +
                    Constant.file_datetime_format.format(now) + '.jpg';
                setState(() {
                  // Set the filename as the measurement
                  values[id] = name;
                });
                var dir = Directory(p.join((await docsDir).path, 'photos'));
                if (!dir.existsSync()){
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
              var action = await showContinueDialog(context,
                  texts.removeValueFromId(values[id]!, id),
                  yesButton: texts.yes,
                  noButton: texts.no,
                  title: texts.removePhotoTitle);
              if (action == true) {
                // remove photo from disk and remove filename from values
                var file = File(p.join((await docsDir).path, 'photos', values[id]));
                if (await file.exists()) {
                  unawaited(file.delete());
                }
                setState(() {
                  values.remove(id);
                });

              }
            }
          },
          child: Text(values[id] ?? inputField.hint ?? ''),
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
                // values[id] = 'false';
              }
            });
          },
          title: Text(inputField.hint ?? ''),
        );
      } else if ((inputField.type == 'date') |  (inputField.type == 'time') | (inputField.type == 'datetime')) {
        var date_format;
        if (inputField.type == 'date') {
          date_format = Constant.date_format;
        } else if (inputField.type == 'time'){
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
              await DatePicker.showDatePicker(context,
                  showTitleActions: true,
                  onChanged: (date) {
                    print('change $date');
                  },
                  onConfirm: (date) {
                    print('confirm $date');
                    values[id] = date_format.format(date);
                  },
                  currentTime: currentTime);
            } else if (inputField.type == 'time'){
              await DatePicker.showTimePicker(context,
                  showTitleActions: true,
                  onChanged: (date) {
                    print('change $date');
                  },
                  onConfirm: (date) {
                    print('confirm $date');
                    values[id] = date_format.format(date);
                  },
                  currentTime: currentTime);
            } else {
              await DatePicker.showDateTimePicker(context,
                  showTitleActions: true,
                  onChanged: (date) {
                    print('change $date');
                  },
                  onConfirm: (date) {
                    print('confirm $date');
                    values[id] = date_format.format(date);
                  },
                  currentTime: currentTime);
            }
          },
          onLongPress: () async {
            if (values[id] != null) {
              var action = await showContinueDialog(context,
                  texts.removeValueFromId(values[id]!, id),
                  yesButton: texts.yes,
                  noButton: texts.no,
                  title: texts.removeDateTitle);
              if (action == true) {
                setState(() {
                  values.remove(id);
                });
              }
            }
          },
          child: Text(values[id] ?? inputField.hint ?? ''),
        );
      } else {
        input = TextFormField(
          autofocus: (id == inputFieldIds![0]),
          decoration: InputDecoration(
              hintText: inputField.hint
          ),
          keyboardType: keyboardType,
          onChanged: (text) {
            values[id] = text;
          },
          validator: validator,
          inputFormatters: inputFormatters,
          textInputAction: id == inputFieldIds!.last ? null: TextInputAction.next,
          onEditingComplete: () => node.nextFocus(), // Move focus to next
        );
      }
      rows.add(Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              flex: 1,
              child: Text(inputField.name ?? id),
            ),
            Expanded(
              flex: 2,
              child: input,
            )
          ]
      ));
    };

    // Add Done button
    rows.add(ElevatedButton(
      onPressed: () async {
        if (_formKey.currentState!.validate()) {
          for (var id in inputFieldIds!) {
            var inputField = locData.inputFields[id]!;
            if (values.containsKey(id)) {
              if (values[id]!.isEmpty) {
                if (inputField.required) {

                  return;
                }
                continue;
              }
              var measurement = Measurement(
                  location: widget.locationId,
                  datetime: now,
                  type: id,
                  value: values[id]!);
              await widget.measurementProvider.insert(measurement);
            } else if (inputField.required) {
              showErrorDialog(context, inputField.name ?? id + texts.isRequired);
              return;
            }

          }

          // Navigate back to the map when tapped.
          Navigator.pop(context, true);
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Constant.primaryColor,
      ),
      child: Text(texts.done),
    ));

    // Add previous measurements
    for (var measurement in measurements){
      if (measurement.value == ''){
        continue;
      }
      Widget valueWidget = Text(measurement.value);
      if (locData.inputFields.containsKey(measurement.type)) {
        if (locData.inputFields[measurement.type]!.type == 'photo') {
          valueWidget = TextButton(
            onPressed: () {
              displayPhoto(measurement.value);
            },
            child: valueWidget
          );
        }
      }
      rows.add(Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              flex: 2,
              child: Text(Constant.date_format.format(measurement.datetime)),
            ),
            Expanded(
              flex: 2,
              child: Text(Constant.time_format.format(measurement.datetime)),
            ),
            Expanded(
              flex: 2,
              child: valueWidget,
            ),
            Expanded(
              flex: 2,
              child: Text(measurement.type),
            ),
            Expanded(
                flex: 1,
                child: ElevatedButton(
                  onPressed: () async {
                    var action = await showContinueDialog(context,
                        texts.sureToDeleteMeasurement(measurement.value, measurement.type));
                    if (action == true) {
                      deleteMeasurement(measurement);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Constant.primaryColor,
                  ),
                  child: Text('x'),
                )
            ),
          ]
      ));
    }
    return rows;
  }

  String? numberValidator(String? value) {
    if ((value == null) || (value.isEmpty)) {
      return null;
    }
    final n = num.tryParse(value);
    if(n == null) {
      return value + texts.isNotValidNumber;
    }
    return null;
  }

  String? requiredValidator(String? value) {
    if ((value == null) || (value.isEmpty)) {
      return texts.requiredInputField;
    }
  }

  String? requiredNumberValidator(String? value) {
    if ((value == null) || (value.isEmpty)) {
      return texts.requiredInputField;
    }
    final n = num.tryParse(value);
    if(n == null) {
      return value + texts.isNotValidNumber;
    }
    return null;
  }


  Future<bool> checkToGoBack() async {
    var hasValues = false;

    for (var id in values.keys){
      if (values[id]!.isNotEmpty){
        var inputField = locData.inputFields[id]!;
        if (inputField.default_value != null){
          if (values[id] == inputField.default_value){
            continue;
          }
        }
        hasValues = true;
        break;
      }
    }
    if (hasValues){
      // ask if the user really wants to go back
      var action = await showContinueDialog(context, texts.ignoreFilledValues,
          yesButton:texts.yes, noButton: texts.no, title: texts.ignoreFilledValuesTitle);
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
        return true;
      } else {
        return false;
      }
    }
    return true;
  }

  void deleteMeasurement(Measurement measurement){
    setState(() {
      measurement.value = '';
      widget.measurementProvider.update(measurement);
    });
  }

  Future<void> displayPhoto(String name) async {
    if (!name.endsWith('.jpg') & !name.endsWith('.png') & !name.endsWith('.pdf')){
      showErrorDialog(context, name + texts.imageNotSupported);
      return;
    }
    // check if photo exists in documents-directory
    var docsDir = await getApplicationDocumentsDirectory();
    var dir = Directory(p.join((docsDir).path, 'photos'));
    File? file = File(p.join(dir.path, name));
    // check if photo exists on ftp-server
    if (!file.existsSync()){
      setState(() {isLoading = true;});
      var prefs = await SharedPreferences.getInstance();
      var connection = await connectToFtp(context, prefs);
      if (connection == null) {
        setState(() {isLoading = false;});
        showErrorDialog(context, texts.connectToFtpFailed);
        return;
      }
      displayInformation(context, texts.downloading + name);
      if (!dir.existsSync()){
        await dir.create();
      }
      var success = await downloadFileFromFtp(connection, file, prefs);
      if (!success){
        setState(() {isLoading = false;});
        showErrorDialog(context, texts.downloadFailed + name);
        return;
      }
      closeFtp(connection, prefs);
      setState(() {isLoading = false;});
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
  TextEditingValue formatEditUpdate(TextEditingValue oldValue,
      TextEditingValue newValue) {
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