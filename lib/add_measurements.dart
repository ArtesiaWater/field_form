import 'dart:io';

import 'package:field_form/dialogs.dart';
import 'package:field_form/photo.dart';
import 'package:field_form/properties.dart';
import 'package:field_form/src/locations.dart';
import 'package:field_form/src/measurements.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart' as p;
import 'constants.dart';
import 'ftp.dart';

class AddMeasurements extends StatefulWidget {
  AddMeasurements({key, required this.locationId, required this.location, required this.groups, required this.inputFields,
    required this.measurementProvider, required this.prefs})
      : super(key: key);

  final String locationId;
  final Location location;
  final Map<String, Group>? groups;
  final Map<String, InputField>? inputFields;
  final MeasurementProvider measurementProvider;
  final SharedPreferences prefs;

  @override
  _AddMeasurementsState createState() => _AddMeasurementsState();
}

class _AddMeasurementsState extends State<AddMeasurements> {
  late DateTime now;
  final Map<String, String> values = {};
  List<Measurement> measurements = <Measurement>[];
  var isLoading = false;
  List<String>? inputFieldIds;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    now = DateTime.now();
    if (widget.prefs.getBool('use_standard_time') ?? false) {
      var offset = now.timeZoneOffset - (DateTime(now.year, 1, 1).timeZoneOffset);
      now = now.subtract(offset);
    }
    inputFieldIds = widget.location.inputfields;
    if (inputFieldIds == null) {
      if (widget.location.group != null){
        if (widget.groups!.containsKey(widget.location.group)) {
          var group = widget.groups![widget.location.group]!;
          if (group.inputfields != null) {
            inputFieldIds = group.inputfields;
          }
        }
      }
    }
    inputFieldIds ??= widget.inputFields!.keys.toList();

    // Drop inputFields that are not defined
    for (final id in inputFieldIds!) {
      if (!widget.inputFields!.containsKey(id)) {
        inputFieldIds!.remove(id);
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
            if (isLoading) buildLoadingIndicator(),
          ],
        )
      )
    );
  }

  AppBar buildAppBar() {
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
    return AppBar(
      title: Text(widget.location.name ?? widget.locationId),
      backgroundColor: Constant.primaryColor,
      actions: actions,
    );
  }

  List<Widget> buildRows(){
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
    for (final id in inputFieldIds!) {
      var inputField = widget.inputFields![id]!;
      var keyboardType = TextInputType.text;
      var validator;
      List<TextInputFormatter>? inputFormatters = [];
      if (inputField.type == 'number'){
        keyboardType = TextInputType.number;
        validator = numberValidator;
        inputFormatters.add(CommaTextInputFormatter());
      } else {
        inputFormatters.add(FilteringTextInputFormatter.deny(RegExp('[;]')));
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
              values[id] = text!;
            });
          },
          value: values[id],
        );
      } else {
        final node = FocusScope.of(context);
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
          textInputAction: TextInputAction.next,
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
    rows.add(Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [Expanded(
        child: ElevatedButton(
          onPressed: () async {
            if (_formKey.currentState!.validate()) {
              for (var id in inputFieldIds!) {
                if (values.containsKey(id)) {
                  if (values[id]!.isEmpty) {
                    continue;
                  }
                  var measurement = Measurement(
                      location: widget.locationId,
                      datetime: now,
                      type: id,
                      value: values[id]!);
                  await widget.measurementProvider.insert(measurement);
                }
              }

              // Navigate back to the map when tapped.
              Navigator.pop(context, true);
            }
          },
          style: ElevatedButton.styleFrom(
            primary: Constant.primaryColor,
          ),
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
              child: Text(Constant.date_format.format(measurement.datetime)),
            ),
            Expanded(
              flex: 2,
              child: Text(Constant.time_format.format(measurement.datetime)),
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
                    if (action == true) {
                      deleteMeasurement(measurement);
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
    }
    return rows;
  }

  String? numberValidator(String? value) {
    if ((value == null) || (value.isEmpty)) {
      return null;
    }
    final n = num.tryParse(value);
    if(n == null) {
      return '"$value" is not a valid number';
    }
    return null;
  }

  Future<bool> checkToGoBack() async {
    var hasValues = false;
    for (var value in values.values){
      if (value.isNotEmpty){
        hasValues = true;
        break;
      }
    }
    if (hasValues){
      // ask if the user really wants to go back
      var action = await showContinueDialog(context, 'All values will be deleted when going back. Do you still want to go back?',
          yesButton:'yes', noButton: 'No', title: 'Ignore values?');
      if (action == true) {
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
      showErrorDialog(context, 'Current file $name is not supported. Only jpg, png and pdf are supported');
      return;
    }
    // check if photo exists in documents-directory
    var docsDir = await getApplicationDocumentsDirectory();
    File? file = File(p.join(docsDir.path, name));
    // check if photo exists on ftp-server
    if (!file.existsSync()){
      setState(() {isLoading = true;});
      var prefs = await SharedPreferences.getInstance();
      var ftpConnect = await connectToFtp(context, prefs);
      if (ftpConnect == null) {
        setState(() {isLoading = false;});
        showErrorDialog(context, 'Unable to connect to ftp-server');
        return;
      }
      if (await ftpConnect.existFile(name)) {
        // Download photo
        displayInformation(context, 'Downloading ' + name);
        var success = await ftpConnect.downloadFile(name, file);
        await ftpConnect.disconnect();
        setState(() {isLoading = false;});
        if (!success){
          showErrorDialog(context, 'Unable to download ' + name);
          return;
        }
      } else {
        setState(() {isLoading = false;});
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