// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'locations.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Location _$LocationFromJson(Map<String, dynamic> json) {
  return Location(
    id: json['id'] as String,
    lat: (json['lat'] as num?)?.toDouble(),
    lon: (json['lon'] as num?)?.toDouble(),
    name: json['name'] as String?,
    properties: json['properties'] as Map<String, dynamic>?,
    photo: json['photo'] as String?,
    sublocations: (json['sublocations'] as List<dynamic>?)
        ?.map((e) => Location.fromJson(e as Map<String, dynamic>))
        .toList(),
    group: json['group'] as String?,
    color: json['color'] as String?,
  );
}

Map<String, dynamic> _$LocationToJson(Location instance) => <String, dynamic>{
      'id': instance.id,
      'lat': instance.lat,
      'lon': instance.lon,
      'name': instance.name,
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
    inputfields: (json['inputfields'] as List<dynamic>?)
        ?.map((e) => InputField.fromJson(e as Map<String, dynamic>))
        .toList(),
    groups: (json['groups'] as Map<String, dynamic>?)?.map(
      (k, e) => MapEntry(k, Group.fromJson(e as Map<String, dynamic>)),
    ),
    locations: (json['locations'] as List<dynamic>?)
        ?.map((e) => Location.fromJson(e as Map<String, dynamic>))
        .toList(),
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
    id: json['id'] as String,
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
      'id': instance.id,
      'type': instance.type,
      'hint': instance.hint,
      'name': instance.name,
      'options': instance.options,
      'required': instance.required,
    };

Property _$PropertyFromJson(Map<String, dynamic> json) {
  return Property(
    name: json['name'] as String,
    value: json['value'] as String,
  );
}

Map<String, dynamic> _$PropertyToJson(Property instance) => <String, dynamic>{
      'name': instance.name,
      'value': instance.value,
    };

Setting _$SettingFromJson(Map<String, dynamic> json) {
  return Setting(
    name: json['name'] as String,
    value: json['value'] as String,
  );
}

Map<String, dynamic> _$SettingToJson(Setting instance) => <String, dynamic>{
      'name': instance.name,
      'value': instance.value,
    };

Group _$GroupFromJson(Map<String, dynamic> json) {
  return Group(
    name: json['name'] as String?,
    color: json['color'] as String?,
  );
}

Map<String, dynamic> _$GroupToJson(Group instance) => <String, dynamic>{
      'name': instance.name,
      'color': instance.color,
    };
