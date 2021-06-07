import 'package:json_annotation/json_annotation.dart';
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
    this.min,
    this.max
  });

  factory Location.fromJson(Map<String, dynamic> json) => _$LocationFromJson(json);
  Map<String, dynamic> toJson() => _$LocationToJson(this);

  final double? lat;
  final double? lon;
  final String? name;
  final List<String>? inputfields;
  final Map<String, dynamic>? properties;
  final String? photo;
  final Map<String, Location>? sublocations;
  final String? group;
  final String? color;
  final Map<String, double>? min;
  final Map<String, double>? max;
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
  final Map<String, InputField>? inputfields;
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
    this.required,
  });

  factory InputField.fromJson(Map<String, dynamic> json) => _$InputFieldFromJson(json);
  Map<String, dynamic> toJson() => _$InputFieldToJson(this);

  final String type;
  final String? hint;
  final String? name;
  final List<String>? options;
  final bool? required;
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