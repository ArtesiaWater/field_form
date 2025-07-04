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
      sequence_number: (json['sequence_number'] as num?)?.toInt(),
      measurements: (json['measurements'] as List<dynamic>?)
          ?.map((e) => Map<String, String>.from(e as Map))
          .toList(),
    )
      ..next_location = json['next_location'] as String?
      ..previous_location = json['previous_location'] as String?;

Map<String, dynamic> _$LocationToJson(Location instance) => <String, dynamic>{
      if (instance.lat case final value?) 'lat': value,
      if (instance.lon case final value?) 'lon': value,
      if (instance.name case final value?) 'name': value,
      if (instance.inputfields case final value?) 'inputfields': value,
      if (instance.properties case final value?) 'properties': value,
      if (instance.photo case final value?) 'photo': value,
      if (instance.sublocations case final value?) 'sublocations': value,
      if (instance.group case final value?) 'group': value,
      if (instance.color case final value?) 'color': value,
      if (instance.min_values case final value?) 'min_values': value,
      if (instance.max_values case final value?) 'max_values': value,
      if (instance.sequence_number case final value?) 'sequence_number': value,
      if (instance.measurements case final value?) 'measurements': value,
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
      if (instance.settings case final value?) 'settings': value,
      if (instance.inputfields case final value?) 'inputfields': value,
      if (instance.inputfield_groups case final value?)
        'inputfield_groups': value,
      if (instance.groups case final value?) 'groups': value,
      if (instance.locations case final value?) 'locations': value,
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
      if (instance.hint case final value?) 'hint': value,
      if (instance.name case final value?) 'name': value,
      if (instance.options case final value?) 'options': value,
      if (instance.default_value case final value?) 'default_value': value,
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
      if (instance.name case final value?) 'name': value,
    };

Group _$GroupFromJson(Map<String, dynamic> json) => Group(
      name: json['name'] as String?,
      color: json['color'] as String?,
      inputfields: (json['inputfields'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$GroupToJson(Group instance) => <String, dynamic>{
      if (instance.name case final value?) 'name': value,
      if (instance.color case final value?) 'color': value,
      if (instance.inputfields case final value?) 'inputfields': value,
    };
