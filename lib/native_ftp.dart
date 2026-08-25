import 'dart:io';

import 'package:flutter/services.dart';

class NativeFtpConnection {
  NativeFtpConnection({
    required this.sessionId,
    required this.basePath,
  });

  static const MethodChannel _channel = MethodChannel('nl.artesia.field_form/native_ftp');

  final String sessionId;
  String basePath;

  static Future<NativeFtpConnection> connect({
    required String host,
    required String username,
    required String password,
    required bool useFtps,
    required bool useImplicitFtps,
    required String path,
    int? port,
    bool acceptAnyCertificate = false,
    int timeoutSeconds = 5,
  }) async {
    final arguments = <String, dynamic>{
      'host': host,
      'username': username,
      'password': password,
      'useFtps': useFtps,
      'useImplicitFtps': useImplicitFtps,
      'path': path,
      'acceptAnyCertificate': acceptAnyCertificate,
      'timeout': timeoutSeconds,
    };
    if (port != null) {
      arguments['port'] = port;
    }

    final sessionId = await _channel.invokeMethod<String>('connect', arguments);
    if (sessionId == null || sessionId.isEmpty) {
      throw Exception('Native FTP connect returned no session id');
    }
    return NativeFtpConnection(sessionId: sessionId, basePath: path);
  }

  Future<bool> changeDirectory(String path) async {
    final ok = await _channel.invokeMethod<bool>('changeDirectory', {
      'sessionId': sessionId,
      'path': path,
    });
    if (ok == true) {
      final normalized = _normalizePath(path);
      if (normalized.isNotEmpty) {
        final current = _normalizePath(basePath);
        if (path.startsWith('/')) {
          basePath = normalized;
        } else {
          basePath = current.isEmpty ? normalized : '$current/$normalized';
        }
      }
      return true;
    }
    return false;
  }

  Future<bool> uploadFile(File file) async {
    final ok = await _channel.invokeMethod<bool>('upload', {
      'sessionId': sessionId,
      'localPath': file.path,
      'remoteFileName': _basename(file.path),
    });
    return ok ?? false;
  }

  Future<bool> downloadFile(String remoteFileName, File localFile) async {
    final ok = await _channel.invokeMethod<bool>('download', {
      'sessionId': sessionId,
      'localPath': localFile.path,
      'remoteFileName': remoteFileName,
    });
    return ok ?? false;
  }

  Future<List<String>> listDirectoryContent({String? ftpPath}) async {
    final resolvedPath = _resolveListPath(ftpPath);
    final names = await _channel.invokeMethod<List<dynamic>>('list', {
      'sessionId': sessionId,
      'path': resolvedPath,
    });
    return names?.map((value) => value.toString()).toList() ?? <String>[];
  }

  Future<void> disconnect() async {
    await _channel.invokeMethod<bool>('disconnect', {
      'sessionId': sessionId,
    });
  }

  String _basename(String path) {
    var normalized = path.replaceAll('\\', '/');
    if (normalized.endsWith('/')) {
      normalized = normalized.substring(0, normalized.length - 1);
    }
    final idx = normalized.lastIndexOf('/');
    if (idx < 0) {
      return normalized;
    }
    return normalized.substring(idx + 1);
  }

  String _normalizePath(String value) {
    var path = value.trim().replaceAll('\\', '/');
    while (path.contains('//')) {
      path = path.replaceAll('//', '/');
    }
    if (path == '/') {
      return '';
    }
    if (path.startsWith('/')) {
      path = path.substring(1);
    }
    if (path.endsWith('/')) {
      path = path.substring(0, path.length - 1);
    }
    return path;
  }

  String? _resolveListPath(String? ftpPath) {
    if (ftpPath == null || ftpPath.trim().isEmpty) {
      return null;
    }
    final normalizedTarget = _normalizePath(ftpPath);
    if (normalizedTarget.isEmpty) {
      return null;
    }
    final normalizedBase = _normalizePath(basePath);
    if (normalizedTarget == normalizedBase) {
      return null;
    }
    return '/$normalizedTarget';
  }
}
