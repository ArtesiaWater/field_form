
import 'dart:math';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

// https://docs.geoserver.org/master/en/user/services/wms/reference.html
class WmsTileProvider implements TileProvider {
  WmsTileProvider({
    required this.url,
    required this.layers,
    this.styles,
    this.service= 'wms',
    this.version= '1.3.0',
    this.request= 'GetMap',
    this.crs= 'EPSG:4326',
    this.width= 512,
    this.height= 512,
    this.format= 'image/png',
    this.transparent= false,
    this.bgcolor= 'FFFFFF',
  });

  String url;
  String service;
  String version;
  String request;
  List<String> layers;
  List<String>? styles;
  String crs;
  int width;
  int height;
  String format;
  bool transparent;
  String bgcolor;

  @override
  Future<Tile> getTile(int x, int y, int? zoom) async {
    if (crs != 'EPSG:4326'){
      throw ('Only EPSG:4326 supported');
    }
    zoom = zoom ?? 0;
    var ymin = xToLat(x, zoom);
    var ymax = xToLat(x + 1, zoom);
    var xmin = yToLon(y + 1, zoom);
    var xmax = yToLon(y, zoom);

    var tile_url = url;
    tile_url = '${tile_url}SERVICE=$service';
    tile_url = '$tile_url&VERSION=$version';
    tile_url = '$tile_url&REQUEST=$request';
    final layers_string = layers.join(',');
    tile_url = '$tile_url&LAYERS=$layers_string';
    var styles_string = '';
    if (styles!= null) {
      styles_string = styles!.join(',');
    }
    tile_url = '$tile_url&STYLES=$styles_string';
    if (version == '1.3.0') {
      tile_url = '$tile_url&CRS=$crs';
    } else {
      tile_url = '$tile_url&SRS=$crs';
      if (crs == 'EPSG:4326') {
        var temp;
        temp = xmin;
        xmin = ymin;
        ymin = temp;
        temp = xmax;
        xmax = ymax;
        ymax = temp;
      }
    }
    tile_url = '$tile_url&BBOX=$xmin,$ymin,$xmax,$ymax';
    tile_url = '$tile_url&WIDTH=$width';
    tile_url = '$tile_url&HEIGHT=$height';
    tile_url = '$tile_url&FORMAT=$format';
    if (transparent) {
      tile_url = '$tile_url&TRANSPARENT=TRUE';
    }
    if (bgcolor != 'FFFFFF'){
      tile_url = '$tile_url&BGCOLOR=$bgcolor';
    }
    final response = await http.get(Uri.parse(tile_url));
    final data = response.bodyBytes;
    return Tile(width, height, data);
  }

  double xToLat(int x, int z) {
    return x / pow(2.0, z) * 360.0 - 180;
  }

  double yToLon(int y, int z) {
    final n = pi - 2.0 * pi * y / pow(2.0, z);
    return 180.0 / pi * atan(0.5 * (exp(n) - exp(-n)));
  }
}