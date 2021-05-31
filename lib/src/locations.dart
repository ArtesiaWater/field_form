import 'package:flutter/widgets.dart';
import 'package:json_annotation/json_annotation.dart';
import 'dart:convert';
part 'locations.g.dart';

@JsonSerializable()
class Location {
  // TODO: add groups
  Location({
    required this.id,
    this.lat,
    this.lon,
    this.name,
    this.properties,
    this.photo,
    this.sublocations,
    this.group,
    this.color,
  });

  factory Location.fromJson(Map<String, dynamic> json) => _$LocationFromJson(json);
  Map<String, dynamic> toJson() => _$LocationToJson(this);

  final String id;
  final double? lat;
  final double? lon;
  final String? name;
  final Map<String, dynamic>? properties;
  final String? photo;
  final List<Location>? sublocations;
  final String? group;
  final String? color;
}

@JsonSerializable()
class LocationFile {
  LocationFile({
    this.settings,
    this.inputfields,
    this.groups,
    this.locations,
  });

  factory LocationFile.fromJson(Map<String, dynamic> json) =>
      _$LocationFileFromJson(json);
  Map<String, dynamic> toJson() => _$LocationFileToJson(this);

  final Map<String, String>? settings;
  final List<InputField>? inputfields;
  final Map<String, Group>? groups;
  final List<Location>? locations;
}

Future<LocationFile> getLocationFile(context) async {
  var data = await DefaultAssetBundle.of(context).loadString('assets/locations.json');
  return LocationFile.fromJson(json.decode(data));
}

@JsonSerializable()
class InputField {
  InputField({
    required this.id,
    required this.type,
    this.hint,
    this.name,
    this.options,
    this.required,
  });

  factory InputField.fromJson(Map<String, dynamic> json) => _$InputFieldFromJson(json);
  Map<String, dynamic> toJson() => _$InputFieldToJson(this);

  final String id;
  final String type;
  final String? hint;
  final String? name;
  final List<String>? options;
  final bool? required;
}

List<InputField> getDefaultInputFields(){
  var inputFields = <InputField>[];
  inputFields.add(InputField(
      id: 'head', type: 'number', hint: 'from top of tube'));
  inputFields.add(InputField(
      id: 'comment', type: 'text', hint: 'place a comment'));
  return inputFields;
}

@JsonSerializable()
class Property {
  Property({
    required this.name,
    required this.value
  });

  factory Property.fromJson(Map<String, dynamic> json) => _$PropertyFromJson(json);
  Map<String, dynamic> toJson() => _$PropertyToJson(this);

  final String name;
  final String value;
}

@JsonSerializable()
class Setting {
  Setting({
    required this.name,
    required this.value
  });

  factory Setting.fromJson(Map<String, dynamic> json) => _$SettingFromJson(json);
  Map<String, dynamic> toJson() => _$SettingToJson(this);

  final String name;
  final String value;
}

@JsonSerializable()
class Group {
  Group({
    this.name,
    this.color
  });

  factory Group.fromJson(Map<String, dynamic> json) => _$GroupFromJson(json);
  Map<String, dynamic> toJson() => _$GroupToJson(this);

  final String? name;
  final String? color;
}