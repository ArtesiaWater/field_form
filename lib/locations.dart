import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
part 'locations.g.dart';

@JsonSerializable()
class Location {
  Location({
    this.lat,
    this.lon,
    this.name,
    this.inputfields,
    this.properties,
    this.photo,
    this.sublocations,
    this.group,
    this.color,
    this.min_values,
    this.max_values
  });

  factory Location.fromJson(Map<String, dynamic> json) => _$LocationFromJson(json);
  Map<String, dynamic> toJson() => _$LocationToJson(this);

  final double? lat;
  final double? lon;
  String? name;
  List<String>? inputfields;
  final Map<String, dynamic>? properties;
  final String? photo;
  final Map<String, Location>? sublocations;
  String? group;
  final String? color;
  final Map<String, double>? min_values;
  final Map<String, double>? max_values;
}

@JsonSerializable()
class LocationFile {
  LocationFile({
    this.settings,
    this.inputfields,
    this.inputfield_groups,
    this.groups,
    this.locations,
  });

  factory LocationFile.fromJson(Map<String, dynamic> json) =>
      _$LocationFileFromJson(json);
  Map<String, dynamic> toJson() => _$LocationFileToJson(this);

  final Map<String, String>? settings;
  final Map<String, InputField>? inputfields;
  final Map<String, InputFieldGroup>? inputfield_groups;
  final Map<String, Group>? groups;
  final Map<String, Location>? locations;
}

@JsonSerializable()
class InputField {
  InputField({
    required this.type,
    this.hint,
    this.name,
    this.options,
    this.default_value,
    this.required=false,
  });

  factory InputField.fromJson(Map<String, dynamic> json) => _$InputFieldFromJson(json);
  Map<String, dynamic> toJson() => _$InputFieldToJson(this);

  InputField copy() {
    return InputField.fromJson(toJson());
  }

  String type;
  String? hint;
  String? name;
  List<String>? options;
  String? default_value;
  bool required;
}

@JsonSerializable()
class InputFieldGroup {
  InputFieldGroup({
      required this.inputfields,
      this.name,
  });
  factory InputFieldGroup.fromJson(Map<String, dynamic> json) => _$InputFieldGroupFromJson(json);
  Map<String, dynamic> toJson() => _$InputFieldGroupToJson(this);
  List<String> inputfields;
  String? name;
}

Map<String, InputField> getDefaultInputFields(){
  var inputFields = <String, InputField>{};
  inputFields['head'] = InputField(type: 'number', hint: 'from top of tube');
  inputFields['comment'] = InputField(type: 'text', hint: 'place a comment');
  return inputFields;
}

@JsonSerializable()
class Group {
  Group({
    this.name,
    this.color,
    this.inputfields,
  });

  factory Group.fromJson(Map<String, dynamic> json) => _$GroupFromJson(json);
  Map<String, dynamic> toJson() => _$GroupToJson(this);

  final String? name;
  final String? color;
  final List<String>? inputfields;
}

class LocationData {
  LocationData._internal();

  factory LocationData() {
    return _instance;
  }

  Map<String, Location> locations = <String, Location>{};
  var inputFields = <String, InputField>{};
  var inputFieldGroups = <String, InputFieldGroup>{};
  var groups = <String, Group>{};

  // A static class to hold all data of FieldForm
  static final LocationData _instance = LocationData._internal();

  void save_locations() async {
    var docsDir = await getApplicationDocumentsDirectory();
    var file = File(p.join(docsDir.path, 'locations.json'));
    var location_file = LocationFile(locations: locations,
        inputfields: inputFields,
        inputfield_groups: inputFieldGroups,
        groups: groups);
    var encoder = JsonEncoder.withIndent('  ');
    await file.writeAsString(encoder.convert(location_file.toJson()));
  }
}

BitmapDescriptor getIconForLocation(Location location, groups){
  var icon = getIconFromString(location.color);
  if (icon == null) {
    if (location.group != null) {
      if (groups.containsKey(location.group)) {
        var group = groups[location.group];
        icon = getIconFromString(group.color);
      }
    }
  }
  if (icon == null) {
    return BitmapDescriptor.defaultMarker;
  }
  return icon;
}

BitmapDescriptor? getIconFromString(String? color) {
  if (color == null) {
    return null;
  }
  var hue;
  if (color[0] == '#') {
    // HEX color
    try {
      var col = getIconColor(color);
      hue = HSLColor.fromColor(col!).hue;
    } catch (e) {
      return null;
    }
  } else {
    switch (color){
      case 'red':
        hue = BitmapDescriptor.hueRed;
        break;
      case 'orange':
        hue = BitmapDescriptor.hueOrange;
        break;
      case 'yellow':
        hue = BitmapDescriptor.hueYellow;
        break;
      case 'green':
        hue = BitmapDescriptor.hueGreen;
        break;
      case 'cyan':
        hue = BitmapDescriptor.hueCyan;
        break;
      case 'azure':
        hue = BitmapDescriptor.hueAzure;
        break;
      case 'blue':
        hue = BitmapDescriptor.hueBlue;
        break;
      case 'violet':
        hue = BitmapDescriptor.hueViolet;
        break;
      case 'magenta':
        hue = BitmapDescriptor.hueOrange;
        break;
      case 'rose':
        hue = BitmapDescriptor.hueRose;
        break;
      default:
        return null;
    }
  }
  return BitmapDescriptor.defaultMarkerWithHue(hue);
}

Color? getIconColor(String? color){
  if (color == null) {
    return null;
  }
  if (color[0] == '#') {
    try {
      return Color(int.parse(color.substring(1, 7), radix: 16) + 0xFF000000);
    } catch (e) {
      return null;
    }
  } else {
    switch (color) {
      case 'red':
        return Colors.red;
      case 'orange':
        return Colors.orange;
      case 'yellow':
        return Colors.yellow;
      case 'green':
        return Colors.green;
      case 'cyan':
        return Colors.cyan;
      case 'azure':
        return Colors.lightBlueAccent;
      case 'blue':
        return Colors.blue;
      case 'violet':
        return Colors.purple;
      case 'magenta':
        return Colors.pink;
      case 'rose':
        return Colors.purpleAccent;
      default:
        return null;
    }
  }
}