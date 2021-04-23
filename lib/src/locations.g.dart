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
  );
}

Map<String, dynamic> _$LocationToJson(Location instance) => <String, dynamic>{
      'coords': instance.coords,
      'id': instance.id,
      'name': instance.name,
    };

Locations _$LocationsFromJson(Map<String, dynamic> json) {
  return Locations(
    locations: (json['locations'] as List<dynamic>)
        .map((e) => Location.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}

Map<String, dynamic> _$LocationsToJson(Locations instance) => <String, dynamic>{
      'locations': instance.locations,
    };
