// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'locations.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Location _$LocationFromJson(Map<String, dynamic> json) => Location(
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
      min_values: (json['min_values'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, (e as num).toDouble()),
      ),
      max_values: (json['max_values'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, (e as num).toDouble()),
      ),
    );

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
      'min_values': instance.min_values,
      'max_values': instance.max_values,
    };

LocationFile _$LocationFileFromJson(Map<String, dynamic> json) => LocationFile(
      settings: json['settings'] as Map<String, dynamic>?,
      inputfields: (json['inputfields'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, InputField.fromJson(e as Map<String, dynamic>)),
      ),
      inputfield_groups:
          (json['inputfield_groups'] as Map<String, dynamic>?)?.map(
        (k, e) =>
            MapEntry(k, InputFieldGroup.fromJson(e as Map<String, dynamic>)),
      ),
      groups: (json['groups'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, Group.fromJson(e as Map<String, dynamic>)),
      ),
      locations: (json['locations'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, Location.fromJson(e as Map<String, dynamic>)),
      ),
    );

Map<String, dynamic> _$LocationFileToJson(LocationFile instance) =>
    <String, dynamic>{
      'settings': instance.settings,
      'inputfields': instance.inputfields,
      'inputfield_groups': instance.inputfield_groups,
      'groups': instance.groups,
      'locations': instance.locations,
    };

InputField _$InputFieldFromJson(Map<String, dynamic> json) => InputField(
      type: json['type'] as String,
      hint: json['hint'] as String?,
      name: json['name'] as String?,
      options:
          (json['options'] as List<dynamic>?)?.map((e) => e as String).toList(),
      default_value: json['default_value'] as String?,
      required: json['required'] as bool? ?? false,
    );

Map<String, dynamic> _$InputFieldToJson(InputField instance) =>
    <String, dynamic>{
      'type': instance.type,
      'hint': instance.hint,
      'name': instance.name,
      'options': instance.options,
      'default_value': instance.default_value,
      'required': instance.required,
    };

InputFieldGroup _$InputFieldGroupFromJson(Map<String, dynamic> json) =>
    InputFieldGroup(
      inputfields: (json['inputfields'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      name: json['name'] as String?,
    );

Map<String, dynamic> _$InputFieldGroupToJson(InputFieldGroup instance) =>
    <String, dynamic>{
      'inputfields': instance.inputfields,
      'name': instance.name,
    };

Group _$GroupFromJson(Map<String, dynamic> json) => Group(
      name: json['name'] as String?,
      color: json['color'] as String?,
      inputfields: (json['inputfields'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$GroupToJson(Group instance) => <String, dynamic>{
      'name': instance.name,
      'color': instance.color,
      'inputfields': instance.inputfields,
    };
