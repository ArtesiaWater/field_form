import 'package:flutter/widgets.dart';
import 'package:json_annotation/json_annotation.dart';
import 'dart:convert';
part 'locations.g.dart';

@JsonSerializable()
class Location {
  // TODO add sublocations or clusters
  Location({
    required this.id,
    this.lat,
    this.lon,
    this.name,
    this.properties,
    this.photo,
  });

  factory Location.fromJson(Map<String, dynamic> json) => _$LocationFromJson(json);
  Map<String, dynamic> toJson() => _$LocationToJson(this);

  final String id;
  final double? lat;
  final double? lon;
  final String? name;
  final List<Property>? properties;
  final String? photo;
}

@JsonSerializable()
class LocationFile {
  LocationFile({
    this.locations,
    this.inputfields
  });

  factory LocationFile.fromJson(Map<String, dynamic> json) =>
      _$LocationFileFromJson(json);
  Map<String, dynamic> toJson() => _$LocationFileToJson(this);

  final List<Location>? locations;
  final List<InputField>? inputfields;
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