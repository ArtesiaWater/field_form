import 'package:flutter/widgets.dart';
import 'package:json_annotation/json_annotation.dart';
import 'dart:convert';
part 'locations.g.dart';

@JsonSerializable()
class LatLng {
  LatLng({
    required this.lat,
    required this.lng,
  });

  factory LatLng.fromJson(Map<String, dynamic> json) => _$LatLngFromJson(json);
  Map<String, dynamic> toJson() => _$LatLngToJson(this);

  final double lat;
  final double lng;
}

@JsonSerializable()
class Location {
  Location({
    required this.coords,
    required this.id,
    this.name,
  });

  factory Location.fromJson(Map<String, dynamic> json) => _$LocationFromJson(json);
  Map<String, dynamic> toJson() => _$LocationToJson(this);

  final LatLng coords;
  final String id;
  final String? name;
}

@JsonSerializable()
class Locations {
  Locations({
    required this.locations,
  });

  factory Locations.fromJson(Map<String, dynamic> json) =>
      _$LocationsFromJson(json);
  Map<String, dynamic> toJson() => _$LocationsToJson(this);

  final List<Location> locations;
}

Future<Locations> getLocations(context) async {
  String data = await DefaultAssetBundle.of(context).loadString("assets/locations.json");
  return Locations.fromJson(json.decode(data));
}
