// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'locations.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Location _$LocationFromJson(Map<String, dynamic> json) {
  return Location(
    lat: (json['lat'] as num?)?.toDouble(),
    lon: (json['lon'] as num?)?.toDouble(),
    name: json['name'] as String?,
    inputfields: (json['inputfields'] as List<dynamic>?)
        ?.map((e) => e as String)
        .toList(),
    properties: json['properties'] as Map<String, dynamic>?,
    photo: json['photo'] as String?,
    sublocations: (json['sublocations'] as Map<String, dynamic>?)?.map(
      (k, e) => MapEntry(k, Location.fromJson(e as Map<String, dynamic>)),
    ),
    group: json['group'] as String?,
    color: json['color'] as String?,
  );
}

Map<String, dynamic> _$LocationToJson(Location instance) => <String, dynamic>{
      'lat': instance.lat,
      'lon': instance.lon,
      'name': instance.name,
      'inputfields': instance.inputfields,
      'properties': instance.properties,
      'photo': instance.photo,
      'sublocations': instance.sublocations,
      'group': instance.group,
      'color': instance.color,
    };

LocationFile _$LocationFileFromJson(Map<String, dynamic> json) {
  return LocationFile(
    settings: (json['settings'] as Map<String, dynamic>?)?.map(
      (k, e) => MapEntry(k, e as String),
    ),
    inputfields: (json['inputfields'] as Map<String, dynamic>?)?.map(
      (k, e) => MapEntry(k, InputField.fromJson(e as Map<String, dynamic>)),
    ),
    groups: (json['groups'] as Map<String, dynamic>?)?.map(
      (k, e) => MapEntry(k, Group.fromJson(e as Map<String, dynamic>)),
    ),
    locations: (json['locations'] as Map<String, dynamic>?)?.map(
      (k, e) => MapEntry(k, Location.fromJson(e as Map<String, dynamic>)),
    ),
  );
}

Map<String, dynamic> _$LocationFileToJson(LocationFile instance) =>
    <String, dynamic>{
      'settings': instance.settings,
      'inputfields': instance.inputfields,
      'groups': instance.groups,
      'locations': instance.locations,
    };

InputField _$InputFieldFromJson(Map<String, dynamic> json) {
  return InputField(
    type: json['type'] as String,
    hint: json['hint'] as String?,
    name: json['name'] as String?,
    options:
        (json['options'] as List<dynamic>?)?.map((e) => e as String).toList(),
    required: json['required'] as bool?,
  );
}

Map<String, dynamic> _$InputFieldToJson(InputField instance) =>
    <String, dynamic>{
      'type': instance.type,
      'hint': instance.hint,
      'name': instance.name,
      'options': instance.options,
      'required': instance.required,
    };

Group _$GroupFromJson(Map<String, dynamic> json) {
  return Group(
    name: json['name'] as String?,
    color: json['color'] as String?,
    inputfields: (json['inputfields'] as List<dynamic>?)
        ?.map((e) => e as String)
        .toList(),
  );
}

Map<String, dynamic> _$GroupToJson(Group instance) => <String, dynamic>{
      'name': instance.name,
      'color': instance.color,
      'inputfields': instance.inputfields,
    };
