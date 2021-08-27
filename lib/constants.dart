import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Constant {
  static const Color? primaryColor = Color(0xFF388E3C);
  static const double padding = 5;
  static final date_format = DateFormat('yyyy-MM-dd');
  static final time_format = DateFormat('HH:mm:ss');
  static final datetime_format = DateFormat('yyyy-MM-dd HH:mm:ss');
  static final file_datetime_format = DateFormat('yyyyMMdd-HHmmss');
}

void unawaited(Future<void>? future) {}
