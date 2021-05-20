import 'dart:io';

import 'package:field_form/dialogs.dart';
import 'package:field_form/photo.dart';
import 'package:field_form/properties.dart';
import 'package:field_form/src/locations.dart';
import 'package:field_form/src/measurements.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart' as p;
import 'ftp.dart';

class AddMeasurements extends StatefulWidget {
  AddMeasurements({key, required this.location, required this.inputFields,
    required this.measurementProvider})
      : super(key: key);

  final Location location;
  final List<InputField>? inputFields;
  final MeasurementProvider measurementProvider;

  @override
  _AddMeasurementsState createState() => _AddMeasurementsState();
}

class _AddMeasurementsState extends State<AddMeasurements> {
  late DateTime now;
  final Map<String, String> values = {};
  static DateFormat date_format = DateFormat('dd-MM-yyyy');
  static DateFormat time_format = DateFormat('HH:mm:ss');
  List<Measurement> measurements = <Measurement>[];

  @override
  void initState() {
    super.initState();
    now = DateTime.now();
    getPreviousMeasurements();
  }

  void getPreviousMeasurements() async{
    measurements = await widget.measurementProvider.getMeasurementsFromLocation(
        widget.location.id);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    var date = date_format.format(now);
    var time = time_format.format(now);
    final rows = <Widget>[];

    // add a row with the date and time
    rows.add(Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(date),
          Text('     '),
          Text(time)
        ]
    ));

    // Add a row for each inputfield
    for (var inputField in widget.inputFields!) {
      var keyboardType = TextInputType.text;
      if (inputField.type == 'number'){
        keyboardType = TextInputType.number;
      }
      var input;
      if (inputField.type == 'choice'){
        var items = <DropdownMenuItem<String>>[];
        // add an empty value
        items.add(
            DropdownMenuItem(
              value: '',
              child: Text(''),
            )
        );
        for (var option in inputField.options!) {
          items.add(
            DropdownMenuItem(
              value: option,
              child: Text(option),
            ),
          );
        }
        input = DropdownButton(
          isExpanded: true,
          items: items,
          onChanged: (String? text) {
            setState(() {
              values[inputField.id] = text!;
            });
          },
          value: values[inputField.id],
        );
      } else {
        input = TextField(
          decoration: InputDecoration(
              hintText: inputField.hint
          ),
          keyboardType: keyboardType,
          onChanged: (text) {
            values[inputField.id] = text;
          },
        );
      }
      rows.add(Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              flex: 1,
              child: Text(inputField.id),
            ),
            Expanded(
              flex: 2,
              child: input,
            )
          ]
      ));
    }

    rows.add(Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [Expanded(
          child: ElevatedButton(
            onPressed: () {
              for (var inputfield in widget.inputFields!){
                if (values.containsKey(inputfield.id)){
                  var measurement = Measurement(
                      location: widget.location.id,
                      datetime: now,
                      type: inputfield.id,
                      value:values[inputfield.id]!);
                  widget.measurementProvider.insert(measurement);
                }
              }

              // Navigate back to the map when tapped.
              Navigator.pop(context);
            },
            child: Text('Done'),
          )
      )]
    ));

    // Add previous measurements
    for (var measurement in measurements){
      if (measurement.value == ''){
        continue;
      }
      rows.add(Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              flex: 2,
              child: Text(date_format.format(measurement.datetime)),
            ),
            Expanded(
              flex: 2,
              child: Text(time_format.format(measurement.datetime)),
            ),
            Expanded(
              flex: 2,
              child: Text(measurement.value),
            ),
            Expanded(
              flex: 2,
              child: Text(measurement.type),
            ),
            Expanded(
              flex: 1,
              child: ElevatedButton(
                onPressed: () async {
                  var text = 'Are you sure you want to delete this measurement?';
                  var action = await showContinueDialog(context, text);
                  if (action == DialogAction.yes) {
                    deleteMeasurement(measurement);
                  }
                },
                child: Text('x'),
              )
            ),
          ]
      ));
    }

    var actions = <Widget>[];
    if (widget.location.photo != null){
      actions.add(Padding(
          padding: EdgeInsets.only(right: 20.0),
          child: GestureDetector(
            onTap: () {
              displayPhoto(widget.location.photo!);
            },
            child: Icon(
              Icons.photo,
            ),
          )
      ));
    }
    if (widget.location.properties != null){
      actions.add(Padding(
        padding: EdgeInsets.only(right: 20.0),
        child: GestureDetector(
          onTap: () {
            // Open the properties screen
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) {
                return PropertiesScreen(location: widget.location);
              }),
            );
          },
          child: Icon(
            Icons.info,
          ),
        )
      ));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.location.name ?? widget.location.id),
        backgroundColor: Colors.green[700],
        actions: actions,
      ),

      body:  ListView(
        children: rows,
      )
    );
  }

  void deleteMeasurement(Measurement measurement){
    setState(() {
      measurement.value = '';
      widget.measurementProvider.update(measurement);
    });
  }

  Future<void> displayPhoto(String name) async {
    if (!name.endsWith('.jpg') & !name.endsWith('.png') & !name.endsWith('.jpg')){
      showErrorDialog(context, 'Current file $name is not supported. Only jpg, png and pdf are supported');
      return;
    }
    // check if photo exists in documents-directory
    var docsDir = await getApplicationDocumentsDirectory();
    File? file = File(p.join(docsDir.path, name));
    // check if photo exists on ftp-server
    if (!file.existsSync()){
      var prefs = await SharedPreferences.getInstance();
      var ftpConnect = await connectToFtp(context, prefs);
      if (ftpConnect == null) {
        showErrorDialog(context, 'Unable to connect to ftp-server');
        return;
      }
      if (await ftpConnect.existFile(name)) {
        // Download photo
        showLoaderDialog(context, text: 'Downloading $name');
        var success = await ftpConnect.downloadFile(name, file);
        await ftpConnect.disconnect();
        Navigator.pop(context);
        if (!success){
          showErrorDialog(context, 'Unable to download ' + name);
          return;
        }
      } else {
        showErrorDialog(context, 'Unable to find on ftp-server: ' + name);
        return;
      }
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
