
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:async';

class Measurement{
  Measurement({
    required this.location,
    required this.datetime,
    required this.type,
    required this.value,
    this.id
  });

  String location;
  DateTime datetime;
  String type;
  String value;
  int? id;

  // Convert a Dog into a Map. The keys must correspond to the names of the
  // columns in the database.
  Map<String, dynamic> toMap() {
    return {
      'location': location,
      'datetime': datetime.microsecondsSinceEpoch,
      'type': type,
      'value': value,
    };
  }
}

class MeasurementProvider {
  late Database db;

  Future open() async {
    var path = join(await getDatabasesPath(), 'measurements.db');
    db = await openDatabase(path, version: 1,
        onCreate: (Database db, int version) async {
          await db.execute('''
create table measurements (
  id INTEGER primary key autoincrement, 
  location String,
  datetime INTEGER,
  type TEXT,
  value TEXT)
''');
        });
  }

  Future<Measurement> insert(Measurement measurement) async {
    measurement.id = await db.insert('measurements', measurement.toMap());
    return measurement;
  }

  Future<List<Measurement>> getMeasurementsFromLocation(String location) async {
    List<Map> maps = await db.query('measurements',
        columns: ['id', 'location', 'datetime', 'type', 'value'],
        where: 'location = ?',
        whereArgs: [location]);
    var measurements = <Measurement>[];
    if (maps.isNotEmpty) {
      for (var map in maps){
        var measurement = Measurement(
          location: map['location'],
          datetime : DateTime.fromMicrosecondsSinceEpoch(map['datetime']),
          type : map['type'],
          value : map['value'],
          id : map['id']);
        measurements.add(measurement);
      }
    }
    return measurements;
  }

  Future<int> delete(int id) async {
    return await db.delete('measurements', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> update(Measurement measurement) async {
    return await db.update('measurements', measurement.toMap(),
        where: 'id = ?', whereArgs: [measurement.id]);
  }

  Future close() async => db.close();
}

