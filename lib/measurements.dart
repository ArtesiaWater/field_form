import 'dart:io';

import 'package:csv/csv.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:async';

import 'package:sqflite/utils/utils.dart';

import 'constants.dart';

class Measurement {
  Measurement(
      {required this.location,
      required this.datetime,
      required this.type,
      required String value,
      this.id,
      this.exported = false})
      : value = value.trim();

  Measurement.fromMap(Map map)
      : location = map['location'].toString(),
        datetime = DateTime.fromMicrosecondsSinceEpoch(map['datetime'] as int),
        type = map['type'].toString(),
        value = map['value'].toString().trim(),
        id = map['id'] as int?,
        exported = map['exported'] == 1;

  String location;
  DateTime datetime;
  String type;
  String value;
  int? id;
  bool exported;

  // Convert a Measurement into a Map. The keys must correspond to the names of the
  // columns in the database.
  Map<String, dynamic> toMap() {
    return {
      'location': location,
      'datetime': datetime.microsecondsSinceEpoch,
      'type': type,
      'value': value,
      'exported': exported ? 1 : 0,
    };
  }
}

class MeasurementProvider {
  late Database db;
  static String table = 'measurements';
  static const String _upsertSql =
      'INSERT INTO measurements(location, datetime, type, value, exported) '
      'VALUES (?, ?, ?, ?, ?) '
      'ON CONFLICT(location, datetime, type) DO UPDATE SET '
      'value = excluded.value, exported = excluded.exported';

  Future open() async {
    var path = join(await getDatabasesPath(), 'measurements.db');
    db = await openDatabase(path, version: 1,
        onCreate: (Database db, int version) async {
      await db.execute('''
create table measurements (
  id INTEGER primary key autoincrement, 
  location TEXT,
  datetime INTEGER,
  type TEXT,
  value TEXT,
  exported INTEGER)
''');
    });
    await db.transaction((txn) async {
      await txn.execute(
          'DELETE FROM measurements WHERE id NOT IN (SELECT MAX(id) FROM measurements GROUP BY location, datetime, type)');
      await txn.execute(
          'CREATE UNIQUE INDEX IF NOT EXISTS measurements_unique_key ON measurements(location, datetime, type)');
    });
  }

  Future<Measurement> insert(Measurement measurement) async {
    measurement.id = await db.insert(table, measurement.toMap());
    return measurement;
  }

  Future<List<Measurement>> getMeasurementsFromLocation(String location) async {
    return getMeasurements(where: 'location = ?', whereArgs: [location]);
  }

  Future<List<Measurement>> getMeasurements(
      {String? where, List<Object?>? whereArgs}) async {
    List<Map> maps = await db.query(
      table,
      columns: ['id', 'location', 'datetime', 'type', 'value', 'exported'],
      where: where,
      whereArgs: whereArgs,
      orderBy: 'datetime DESC',
    );
    var measurements = <Measurement>[];
    if (maps.isNotEmpty) {
      for (var map in maps) {
        measurements.add(Measurement.fromMap(map));
      }
    }
    return measurements;
  }

  Future<int> delete(Measurement measurement) async {
    return await db.delete(table, where: 'id = ?', whereArgs: [measurement.id]);
  }

  Future<int> update(Measurement measurement) async {
    return await db.update(table, measurement.toMap(),
        where: 'id = ?', whereArgs: [measurement.id]);
  }

  Future<int> setAllExported() async {
    return await db.update(table, {'exported': 1});
  }

  Future<int> deleteAllMeasurements() async {
    return await db.delete(table);
  }

  Future<bool> areThereMessagesToBeSent(prefs) async {
    var only_export_new_data = prefs.getBool('only_export_new_data') ?? true;
    var result;
    if (only_export_new_data) {
      result = db.rawQuery('select count(*) from $table where exported=?', [0]);
    } else {
      result = db.rawQuery('select count(*) from $table');
    }
    return firstIntValue(await result)! > 0;
  }

  Future<Map<dynamic, DateTime>> getLastMeasurementPerLocation() async {
    var result = await db.rawQuery(
        'select location, MAX(datetime) from $table group by location having value!="";');

    var lastMeas = <String, DateTime>{};
    for (var e in result) {
      if (e['MAX(datetime)'] != null) {
        lastMeas[e['location'].toString()] =
            DateTime.fromMicrosecondsSinceEpoch(e['MAX(datetime)'] as int);
      }
    }
    return lastMeas;
  }

  Future close() async => db.close();

  Future<File> measurementsToCsv(List<Measurement> measurements, File file) {
    // create a list of lists for csv-output
    var rows = <List<String>>[];

    // the header
    var row = <String>[];
    row.add('LOCATION');
    row.add('DATE');
    row.add('TIME');
    row.add('TYPE');
    row.add('VALUE');
    rows.add(row);

    // the data
    Measurement measurement;
    for (measurement in measurements) {
      var row = <String>[];
      row.add(measurement.location);
      row.add(Constant.date_format.format(measurement.datetime));
      row.add(Constant.time_format.format(measurement.datetime));
      row.add(measurement.type);
      row.add(measurement.value.trim());
      rows.add(row);
    }

    // make a string
    var converter = Csv(fieldDelimiter: ';');
    return file.writeAsString(converter.encode(rows));
  }

  Future<File?> exportToCsv(File file,
      {bool only_export_new_data = true}) async {
    // get measurements
    List<Measurement> measurements;
    if (only_export_new_data) {
      measurements =
          await getMeasurements(where: 'exported = ?', whereArgs: [0]);
    } else {
      measurements = await getMeasurements();
    }
    if (measurements.isEmpty) {
      return null;
    }
    return measurementsToCsv(measurements, file);
  }

  Future<void> importFromCsv(File file, {exported = true}) async {
    var converter = Csv(
        fieldDelimiter: ';', dynamicTyping: false);
    var text = await file.readAsString();
    if (text.trim().isEmpty) {
      // Ignore empty files gracefully.
      return;
    }
    var rows = converter.decode(text);
    if (rows.isEmpty) {
      return;
    }
    var row = rows[0];
    if (row.last.endsWith('\r')) {
      row.last = row.last.substring(0, row.last.length - 1);
    }
    var LOCATION = rows[0].indexOf('LOCATION');
    var DATE = rows[0].indexOf('DATE');
    var TIME = rows[0].indexOf('TIME');
    var TYPE = rows[0].indexOf('TYPE');
    var VALUE = rows[0].indexOf('VALUE');
    if (LOCATION < 0 || DATE < 0 || TIME < 0 || TYPE < 0 || VALUE < 0) {
      return;
    }
    final requiredIndex = [LOCATION, DATE, TIME, TYPE, VALUE]
        .reduce((a, b) => a > b ? a : b);
    final exportInt = exported ? 1 : 0;
    await db.transaction((txn) async {
      final batch = txn.batch();
      for (row in rows.sublist(1)) {
        if (row.isEmpty) {
          continue;
        }
        if (row.last.endsWith('\r')) {
          row.last = row.last.substring(0, row.last.length - 1);
        }
        if (row.length <= requiredIndex) {
          continue;
        }
        var date = Constant.datetime_format
            .parse('${row[DATE]} ${row[TIME]}');
        batch.rawInsert(_upsertSql, [
          row[LOCATION].toString(),
          date.microsecondsSinceEpoch,
          row[TYPE].toString(),
          row[VALUE].toString().trim(),
          exportInt,
        ]);
      }
      await batch.commit(noResult: true);
    });
  }

  Future<void> update_or_insert(meas) async {
    await db.rawInsert(_upsertSql, [
      meas.location,
      meas.datetime.microsecondsSinceEpoch,
      meas.type,
      meas.value,
      meas.exported ? 1 : 0,
    ]);
  }
}

String getMeasurementFileName() {
  return 'measurements-' +
      Constant.file_datetime_format.format(DateTime.now()) +
      '.csv';
}
