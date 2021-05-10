// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'locations.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LatLng _$LatLngFromJson(Map<String, dynamic> json) {
  return LatLng(
    lat: (json['lat'] as num).toDouble(),
    lng: (json['lng'] as num).toDouble(),
  );
}

Map<String, dynamic> _$LatLngToJson(LatLng instance) => <String, dynamic>{
      'lat': instance.lat,
      'lng': instance.lng,
    };

Location _$LocationFromJson(Map<String, dynamic> json) {
  return Location(
    coords: LatLng.fromJson(json['coords'] as Map<String, dynamic>),
    id: json['id'] as String,
    name: json['name'] as String?,
    properties: (json['properties'] as List<dynamic>?)
        ?.map((e) => Property.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}

Map<String, dynamic> _$LocationToJson(Location instance) => <String, dynamic>{
      'coords': instance.coords,
      'id': instance.id,
      'name': instance.name,
      'properties': instance.properties,
    };

LocationFile _$LocationFileFromJson(Map<String, dynamic> json) {
  return LocationFile(
    locations: (json['locations'] as List<dynamic>?)
        ?.map((e) => Location.fromJson(e as Map<String, dynamic>))
        .toList(),
    inputfields: (json['inputfields'] as List<dynamic>?)
        ?.map((e) => InputField.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}

Map<String, dynamic> _$LocationFileToJson(LocationFile instance) =>
    <String, dynamic>{
      'locations': instance.locations,
      'inputfields': instance.inputfields,
    };

InputField _$InputFieldFromJson(Map<String, dynamic> json) {
  return InputField(
    id: json['id'] as String,
    type: json['type'] as String,
    hint: json['hint'] as String?,
    name: json['name'] as String?,
    options:
        (json['options'] as List<dynamic>?)?.map((e) => e as String).toList(),
  );
}

Map<String, dynamic> _$InputFieldToJson(InputField instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': instance.type,
      'hint': instance.hint,
      'name': instance.name,
      'options': instance.options,
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
