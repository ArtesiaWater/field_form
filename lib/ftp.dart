import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ftpconnect/ftpconnect.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dartssh2/dartssh2.dart';
import 'l10n/app_localizations.dart';
import 'ftp_configurations.dart';
import 'native_ftp.dart';

import 'dialogs.dart';

class FtpTransferResult {
  const FtpTransferResult(
      {required this.success, this.errorMessage, this.isEmptyFile = false});

  final bool success;
  final String? errorMessage;
  final bool isEmptyFile;
}

Future<Object?>? connectToFtp(BuildContext context, SharedPreferences prefs, {path}) async {
  final activeConfig = await getActiveFtpConfiguration(prefs);
  var host = activeConfig.hostname;
  var user = await getActiveFtpUsername(prefs);
  var pass = await getActiveFtpPassword(prefs);
  var use_ftps = activeConfig.useFtps;
  var use_sftp = activeConfig.useSftp;
  var use_implicit_ftps = activeConfig.useImplicitFtps;
  var texts = AppLocalizations.of(context)!;

  if (host == '') {
    showErrorDialog(context, texts.noHostnameDefined, title:texts.connectToFtpFailed);
    return null;
  }


  if (host.contains('/')) {
    var idx = host.indexOf('/');
    host = host.substring(0, idx);
  }
  if (use_sftp) {
    try {
      final client = SSHClient(
        await SSHSocket.connect(host, 22, timeout: const Duration(seconds: 3)),
        username: user,
        onPasswordRequest: () => pass,
      );
      final sftp = await client.sftp();
      return sftp;
    } on SocketException catch (e) {
      showErrorDialog(context, _socketConnectErrorMessage(texts, e, host),
          title: texts.connectToFtpFailed,
          hiddenDetails: _buildDiagnosticsText(
            operation: 'sftp_connect',
            host: host,
            port: 22,
            useSftp: true,
            step: 'socket_connect',
            error: e,
          ));
      return null;
    } on SSHAuthFailError catch (e) {
      showErrorDialog(context, e.toString() + ': ' + texts.authenticationError,
          title: texts.connectToFtpFailed,
          hiddenDetails: _buildDiagnosticsText(
            operation: 'sftp_connect',
            host: host,
            port: 22,
            useSftp: true,
            step: 'auth',
            error: e,
          ));
      return null;
    } catch (e) {
      showErrorDialog(context, e.toString(),
          title: texts.connectToFtpFailed,
          hiddenDetails: _buildDiagnosticsText(
            operation: 'sftp_connect',
            host: host,
            port: 22,
            useSftp: true,
            error: e,
          ));
      return null;
    }
  } else if (Platform.isAndroid) {
    path ??= getFtpPath(prefs);
    final port = use_implicit_ftps ? 990 : 21;
    try {
      final nativeConnection = await NativeFtpConnection.connect(
        host: host,
        username: user,
        password: pass,
        useFtps: use_ftps,
        useImplicitFtps: use_implicit_ftps,
        path: path,
        port: port,
      );
      displayInformation(context, texts.connected);
      return nativeConnection;
    } on PlatformException catch (e) {
      if (e.code == 'tls_cert_error') {
        final shouldContinue = await showContinueDialog(
          context,
          "The server certificate is not trusted. Do you want to connect anyway?",
          title: texts.connectToFtpFailed,
          yesButton: texts.continueAction,
          noButton: texts.cancel,
        );
        if (shouldContinue == true) {
          try {
            final nativeConnection = await NativeFtpConnection.connect(
              host: host,
              username: user,
              password: pass,
              useFtps: use_ftps,
              useImplicitFtps: use_implicit_ftps,
              path: path,
              port: port,
              acceptAnyCertificate: true,
            );
            displayInformation(context, texts.connected);
            return nativeConnection;
          } on PlatformException catch (e2) {
            showErrorDialog(
              context,
              _nativeFtpErrorMessage(texts, e2, host),
              title: texts.connectToFtpFailed,
              hiddenDetails: _nativeFtpDiagnosticsText(e2),
            );
            return null;
          } catch (e2) {
            showErrorDialog(context, e2.toString(), title: texts.connectToFtpFailed);
            return null;
          }
        }
      }
      showErrorDialog(
        context,
        _nativeFtpErrorMessage(texts, e, host),
        title: texts.connectToFtpFailed,
        hiddenDetails: _nativeFtpDiagnosticsText(e),
      );
      return null;
    } catch (e) {
      showErrorDialog(context, e.toString(), title: texts.connectToFtpFailed);
      return null;
    }
  }
  var securityType;
  final port = use_implicit_ftps ? 990 : 21;
  if (use_implicit_ftps) {
    securityType = SecurityType.ftps;
  } else if (use_ftps) {
    securityType = SecurityType.ftpes;
  } else {
    securityType = SecurityType.ftp;
  }
  var ftpConnect = FTPConnect(host,
      user: user,
      pass: pass,
      port: port,
      timeout: 5,
      securityType: securityType,
      logger: Logger(isEnabled: true));
  if (use_implicit_ftps) {
    ftpConnect.listCommand = ListCommand.nlst;
  }
  try {
    await ftpConnect.connect();
  } catch (e) {
    showErrorDialog(context, e.toString(),
        title: texts.connectToFtpFailed,
        hiddenDetails: _buildDiagnosticsText(
            operation: 'ftpconnect_connect',
            host: host,
            port: port,
            useFtps: use_ftps,
            useImplicitFtps: use_implicit_ftps,
            step: 'connect',
            error: e));
    return null;
  }
  await ftpConnect.setTransferType(TransferType.binary);
  displayInformation(context, texts.connected);
  path ??= getFtpPath(prefs);
  if (path.isEmpty) {
    // we do not need to change path
    return ftpConnect;
  }
  // we do need to change path
  var success = await changeDirectory(ftpConnect, context, path, prefs);
  if (!success){
    return null;
  }
  return ftpConnect;
}

String _nativeFtpErrorMessage(
    AppLocalizations texts, PlatformException e, String host) {
  switch (e.code) {
    case 'unknown_host':
      return _unknownHostErrorMessage(texts, host);
    case 'auth_failed':
      return texts.authenticationError;
    case 'timeout':
      return texts.ftpErrorTimeout;
    case 'connect_failed':
      return texts.ftpErrorConnectFailed;
    case 'tls_error':
      return texts.ftpErrorTls;
    case 'tls_cert_error':
      return "The server certificate is untrusted.";
    case 'network_error':
      return texts.ftpErrorNetwork;
    case 'path_not_found':
      return texts.ftpErrorPathNotFound;
    case 'list_failed':
      return texts.ftpErrorListFailed;
    case 'upload_failed':
      return texts.ftpErrorUploadFailed;
    case 'download_failed':
      return texts.ftpErrorDownloadFailed;
    case 'session_not_found':
      return texts.ftpErrorSessionNotFound;
    case 'invalid_argument':
      return texts.ftpErrorInvalidArgument;
  }

  final msg = e.message?.trim();
  if (_looksLikeUnknownHost(msg, host)) {
    return _unknownHostErrorMessage(texts, host);
  }
  if (msg != null && msg.isNotEmpty) {
    return msg;
  }
  return texts.connectToFtpFailed;
}

String? _nativeFtpDiagnosticsText(PlatformException e) {
  final details = e.details;
  if (details is! Map) {
    return null;
  }

  String pick(String key) {
    final value = details[key];
    if (value == null) {
      return '-';
    }
    final text = value.toString().trim();
    return text.isEmpty ? '-' : text;
  }

  final lines = <String>[
    'Diagnostic report',
    'operation: ${pick('operation')}',
    'timestampEpochMs: ${pick('timestampEpochMs')}',
    'elapsedMs: ${pick('elapsedMs')}',
    'host: ${pick('host')}',
    'port: ${pick('port')}',
    'useFtps: ${pick('useFtps')}',
    'useImplicitFtps: ${pick('useImplicitFtps')}',
    'acceptAnyCertificate: ${pick('acceptAnyCertificate')}',
    'timeoutSeconds: ${pick('timeoutSeconds')}',
    'step: ${pick('step')}',
    'errorCode: ${e.code}',
    'errorClass: ${pick('errorClass')}',
    'errorMessage: ${pick('errorMessage')}',
    'rootErrorClass: ${pick('rootErrorClass')}',
    'rootErrorMessage: ${pick('rootErrorMessage')}',
  ];

  return lines.join('\n');
}

String _socketConnectErrorMessage(
    AppLocalizations texts, SocketException e, String host) {
  final msg = e.message.trim();
  if (_looksLikeUnknownHost(msg, host)) {
    return _unknownHostErrorMessage(texts, host);
  }
  if (msg.toLowerCase().contains('timed out')) {
    return texts.ftpErrorTimeout;
  }
  return msg.isNotEmpty ? msg : texts.connectToFtpFailed;
}

bool _looksLikeUnknownHost(String? message, String host) {
  if (message == null) {
    return false;
  }
  final msg = message.trim();
  if (msg.isEmpty) {
    return false;
  }
  if (msg == host) {
    return true;
  }

  final lower = msg.toLowerCase();
  final lowerHost = host.toLowerCase();
  return lower.contains('unknown host') ||
      lower.contains('failed host lookup') ||
      lower.contains('name or service not known') ||
      lower.contains('no address associated') ||
      lower.contains('unresolved') ||
      lower.contains('eai_') ||
      lower.contains(lowerHost);
}

Future<bool> changeDirectory(dynamic connection, BuildContext context, String path, SharedPreferences prefs) async {
  if (connection is NativeFtpConnection) {
    try {
      return await connection.changeDirectory(path);
    } on PlatformException catch (e) {
      var texts = AppLocalizations.of(context)!;
      final activeConfig = await getActiveFtpConfiguration(prefs);
      final host = activeConfig.hostname.split('/').first.trim();
      showErrorDialog(context, _nativeFtpErrorMessage(texts, e, host));
      return false;
    } catch (e) {
      showErrorDialog(context, e.toString());
      return false;
    }
  }

  FTPConnect ftpConnection = connection;
  var success = true;
  for (var folder in path.split('/')){
    if (folder.isNotEmpty) {
      var success;
      var error_text;
      try {
        success = await ftpConnection.changeDirectory(folder);
        if (!success) {
          var texts = AppLocalizations.of(context)!;
          error_text = texts.unableToFindPathOnFtp + folder;
        }
      } catch (e) {
        success = false;
        error_text = e.toString();
      }
      if (!success) {
        await ftpConnection.disconnect();
        showErrorDialog(context, error_text);
        return success;
      }
    }
  }
  return success;
}

Future<FtpTransferResult> uploadFileToFtp(
    connection, File file, SharedPreferences prefs, BuildContext context) async {
  var use_sftp = prefs.getBool('use_sftp') ?? false;
  var success;
  final texts = AppLocalizations.of(context)!;
  final activeConfig = await getActiveFtpConfiguration(prefs);
  final host = activeConfig.hostname.split('/').first.trim();
  if (use_sftp){
    SftpClient sftp = connection;
    try {
      var ftpPath = getFtpPath(prefs) + '/' + basename(file.path);
      final sftpFile = await sftp
          .open(ftpPath, mode: SftpFileOpenMode.create | SftpFileOpenMode.write)
          .timeout(const Duration(minutes: 1));
      await sftpFile.write(file.openRead().cast());
      await sftpFile.close();
      success = true;
    } catch (e) {
      sftp.close();
      success = false;
    }
  } else {
    if (connection is NativeFtpConnection) {
      try {
        success = await connection
            .uploadFile(file)
            .timeout(const Duration(minutes: 1));
      } on TimeoutException {
        success = false;
        unawaited(connection.disconnect());
        return FtpTransferResult(
          success: false,
          errorMessage: texts.ftpErrorTimeout,
        );
      } on PlatformException catch (e) {
        success = false;
        unawaited(connection.disconnect());
        return FtpTransferResult(
          success: false,
          errorMessage: _nativeFtpErrorMessage(texts, e, host),
        );
      } catch (e) {
        success = false;
      }
      if (!success) {
        unawaited(connection.disconnect());
      }
      return FtpTransferResult(success: success);
    }

    FTPConnect ftp = connection;
    try {
      success = await ftp.uploadFile(file).timeout(const Duration(minutes: 1));
    } on TimeoutException {
      success = false;
    } catch (e) {
      success = false;
    }

    if (!success) {
      unawaited(ftp.disconnect());
    }
  }
  return FtpTransferResult(success: success);
}

Future<FtpTransferResult> downloadFileFromFtp(
    connection, File file, SharedPreferences prefs, BuildContext context) async {
  var use_sftp = prefs.getBool('use_sftp') ?? false;
  var success;
  var isEmptyFile = false;
  final texts = AppLocalizations.of(context)!;
  final activeConfig = await getActiveFtpConfiguration(prefs);
  final host = activeConfig.hostname.split('/').first.trim();
  final tempFile = File('${file.path}.part');

  if (await tempFile.exists()) {
    await tempFile.delete();
  }

  if (use_sftp){
    SftpClient sftp = connection;
    try {
      var ftpPath = getFtpPath(prefs) + '/' + basename(file.path);
      final sftpFile =
          await sftp.open(ftpPath).timeout(const Duration(minutes: 1));
      final data = await sftpFile.readBytes();
      await tempFile.writeAsBytes(data);
      success = true;
    } catch (e) {
      success = false;
    }
  } else {
    if (connection is NativeFtpConnection) {
      try {
        success = await connection
            .downloadFile(basename(file.path), tempFile)
            .timeout(const Duration(minutes: 1));
      } on TimeoutException {
        success = false;
        if (await tempFile.exists()) {
          await tempFile.delete();
        }
        closeFtp(connection, prefs);
        return FtpTransferResult(
          success: false,
          errorMessage: texts.ftpErrorTimeout,
        );
      } on PlatformException catch (e) {
        success = false;
        if (await tempFile.exists()) {
          await tempFile.delete();
        }
        closeFtp(connection, prefs);
        return FtpTransferResult(
          success: false,
          errorMessage: _nativeFtpErrorMessage(texts, e, host),
        );
      } catch (e) {
        success = false;
      }
    } else {
      FTPConnect ftp = connection;
      try {
        success = await ftp
            .downloadFile(basename(file.path), tempFile)
            .timeout(const Duration(minutes: 1));
      } on TimeoutException {
        success = false;
      } catch (e) {
        success = false;
      }
    }
  }

  if (success) {
    final hasValidTempFile =
        await tempFile.exists() && (await tempFile.length()) > 0;
    success = hasValidTempFile;
    if (!hasValidTempFile) {
      isEmptyFile = true;
    }
  }

  if (success) {
    if (await file.exists()) {
      await file.delete();
    }
    await tempFile.rename(file.path);
  }

  if (!success){
    if (await tempFile.exists()) {
      await tempFile.delete();
    }
    if (!isEmptyFile) {
      closeFtp(connection, prefs);
    }
  }
  return FtpTransferResult(success: success, isEmptyFile: isEmptyFile);
}

void closeFtp(connection, prefs){
  var use_sftp = prefs.getBool('use_sftp') ?? false;
  if (use_sftp){
    SftpClient sftp = connection;
    sftp.close();
  } else {
    if (connection is NativeFtpConnection) {
      unawaited(connection.disconnect());
    } else {
      FTPConnect ftp = connection;
      unawaited(ftp.disconnect());
    }
  }
}

Future<List<String>?> listFilesOnFtp(connection, SharedPreferences prefs, BuildContext context, {String? ftpPath}) async {
  var names;
  var use_sftp = prefs.getBool('use_sftp') ?? false;
  if (use_sftp){
    SftpClient sftp = connection;
    try {
      ftpPath ??= getFtpPath(prefs);
      final items = await sftp.listdir('/' + ftpPath);
      names = items.map((f) => f.filename).whereType<String>().toList();
    } catch (e) {
      sftp.close();
      showErrorDialog(context, e.toString());
      return null;
    }
  } else {
    if (connection is NativeFtpConnection) {
      try {
        names = await connection.listDirectoryContent(ftpPath: ftpPath);
      } on PlatformException catch (e) {
        await connection.disconnect();
        var texts = AppLocalizations.of(context)!;
        final activeConfig = await getActiveFtpConfiguration(prefs);
        final host = activeConfig.hostname.split('/').first.trim();
        showErrorDialog(context, _nativeFtpErrorMessage(texts, e, host));
        return null;
      } catch (e) {
        await connection.disconnect();
        showErrorDialog(context, e.toString());
        return null;
      }
    } else {
      FTPConnect ftp = connection;
      try {
        //Get directory content
        final list = await ftp.listDirectoryContent();
        names = list.map((f) => f.name).whereType<String>().toList();
      } catch (e) {
        await ftp.disconnect();
        showErrorDialog(context, e.toString());
        return null;
      }
    }
  }
  names.remove('.');
  names.remove('..');
  // sort the files alphabetcally, but igore the extension
  names.sort((a, b) => basenameWithoutExtension(a).compareTo(basenameWithoutExtension(b)));
  return names;
}

Future<String?> chooseFtpPath(connection, BuildContext context, SharedPreferences prefs) async {
  var root = getFtpRoot(prefs);
  var names = await listFilesOnFtp(connection, prefs, context, ftpPath: root);
  if (names == null) {
    return null;
  }
  names.insert(0, "");
  var options = <Widget>[];
  for (var name in names){
    options.add(SimpleDialogOption(
      onPressed: () {
        Navigator.of(context).pop(name);
      },
      child: Text(name),
    ));
  }

  var action = await showDialog(
      context: context,
      builder: (context) {
        var texts = AppLocalizations.of(context)!;
        return SimpleDialog(
          title: Text(texts.chooseAFolder),
          children: options,
        );
      }
  );
  return action;
}

String getFtpRoot(SharedPreferences prefs) {
  var root = '';
  var host = prefs.getString('ftp_hostname') ?? '';
  if (host.contains('/')) {
    var idx = host.indexOf('/');
    root = host.substring(idx+1).trim();
  }
  return root;
}

String getFtpPath(SharedPreferences prefs) {
  var path = prefs.getString('ftp_path') ?? '';
  var root = getFtpRoot(prefs);
  if (root.isNotEmpty){
    var start = 0;
    var end = root.length;
    if (root.startsWith('/')){
      start = start + 1;
    }
    if (root.endsWith('/')){
      end = end - 1;
    }
    path = root.substring(start, end) + '/' + path;
  }
  return path;
}

String _unknownHostErrorMessage(AppLocalizations texts, String host) {
  final normalizedHost = host.trim();
  if (normalizedHost.isEmpty) {
    return texts.ftpErrorUnknownHost;
  }
  return texts.ftpErrorUnknownHostWithHostname(normalizedHost);
}

String _buildDiagnosticsText({
  required String operation,
  required String host,
  required int port,
  bool? useFtps,
  bool? useImplicitFtps,
  bool? useSftp,
  bool? acceptAnyCertificate,
  int? timeoutSeconds,
  String? step,
  required Object error,
  String? errorCode,
}) {
  final now = DateTime.now().millisecondsSinceEpoch;
  final lines = <String>[
    'Diagnostic report',
    'operation: $operation',
    'timestampEpochMs: $now',
    'host: $host',
    'port: $port',
    if (useFtps != null) 'useFtps: $useFtps',
    if (useImplicitFtps != null) 'useImplicitFtps: $useImplicitFtps',
    if (useSftp != null) 'useSftp: $useSftp',
    if (acceptAnyCertificate != null) 'acceptAnyCertificate: $acceptAnyCertificate',
    if (timeoutSeconds != null) 'timeoutSeconds: $timeoutSeconds',
    if (step != null) 'step: $step',
    if (errorCode != null) 'errorCode: $errorCode',
    'errorClass: ${error.runtimeType}',
    'errorMessage: $error',
  ];
  return lines.join('\n');
}