import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:ftpconnect/ftpconnect.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dartssh2/dartssh2.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:pure_ftp/pure_ftp.dart' as pure_ftp;

import 'dialogs.dart';

bool use_pure_ftp = false;

Future<Object?>? connectToFtp(BuildContext context, SharedPreferences prefs, {path}) async {
  final secure_storage = FlutterSecureStorage();
  var host = prefs.getString('ftp_hostname') ?? '';
  var user = await secure_storage.read(key: 'ftp_username') ?? '';
  var pass = await secure_storage.read(key: 'ftp_password') ?? '';
  var use_ftps = prefs.getBool('use_ftps') ?? false;
  var use_sftp = prefs.getBool('use_sftp') ?? false;
  var use_implicit_ftps = prefs.getBool('use_implicit_ftps') ?? false;
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
        await SSHSocket.connect(host, 22, timeout:const Duration(seconds: 5)),
        username: user,
        onPasswordRequest: () => pass,
      );
      final sftp = await client.sftp();
      return sftp;
    } on SSHAuthFailError catch (e) {
      showErrorDialog(context, e.toString() + ': ' + texts.authenticationError, title: texts.connectToFtpFailed);
      return null;
    } catch (e) {
      showErrorDialog(context, e.toString(), title: texts.connectToFtpFailed);
      return null;
    }
  } else if (use_implicit_ftps & use_pure_ftp) {
    try {
      final client = pure_ftp.FtpClient(
        socketInitOptions: pure_ftp.FtpSocketInitOptions(
          host: host,
          timeout: const Duration(seconds: 5),
          securityType: pure_ftp.SecurityType.FTPS,
          transferType: pure_ftp.FtpTransferType.binary,
        ),
        authOptions: pure_ftp.FtpAuthOptions(
          username: user,
          password: pass,
        ),
        logCallback: print,
      );
      await client.connect();
      return client;
    } catch (e) {
      showErrorDialog(context, e.toString(), title: texts.connectToFtpFailed);
      return null;
    }
  }
  var securityType;
  if (use_implicit_ftps){
    securityType = SecurityType.FTPS;
  } else if (use_ftps) {
    securityType = SecurityType.FTPES;
  } else {
    securityType = SecurityType.FTP;
  }
  var ftpConnect = FTPConnect(host, user: user, pass: pass, timeout: 5, securityType: securityType, logger: Logger(isEnabled: true));
  if (use_implicit_ftps){
    ftpConnect.listCommand = ListCommand.NLST;
  }
  try {
    await ftpConnect.connect();
  } catch (e) {
    showErrorDialog(context, e.toString(), title:texts.connectToFtpFailed);
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

Future<bool> changeDirectory(FTPConnect connection, BuildContext context, String path, SharedPreferences prefs) async {
  var success = true;
  for (var folder in path.split('/')){
    if (folder.isNotEmpty) {
      var success;
      var error_text;
      try {
        success = await connection.changeDirectory(folder);
        if (!success) {
          var texts = AppLocalizations.of(context)!;
          error_text = texts.unableToFindPathOnFtp + folder;
        }
      } catch (e) {
        success = false;
        error_text = e.toString();
      }
      if (!success) {
        await connection.disconnect();
        showErrorDialog(context, error_text);
        return success;
      }
    }
  }
  return success;
}

Future<bool> uploadFileToFtp(connection, File file, SharedPreferences prefs) async {
  var use_sftp = prefs.getBool('use_sftp') ?? false;
  var success;
  if (use_sftp){
    SftpClient sftp = connection;
    try {
      var ftpPath = getFtpPath(prefs) + '/' + basename(file.path);
      final sftpFile = await sftp.open(ftpPath, mode: SftpFileOpenMode.create | SftpFileOpenMode.write);
      await sftpFile.write(file.openRead().cast());
      await sftpFile.close();
      success = true;
    } catch (e) {
      sftp.close();
      success = false;
    }
  } else {
    FTPConnect ftp = connection;
    try {
      success = await ftp.uploadFile(file);
    } catch (e) {
      success = false;
    }

    if (!success) {
      unawaited(ftp.disconnect());
    }
  }
  return success;
}

Future<bool> downloadFileFromFtp(connection, File file, SharedPreferences prefs) async {
  var use_sftp = prefs.getBool('use_sftp') ?? false;
  var success;
  if (use_sftp){
    SftpClient sftp = connection;
    try {
      var ftpPath = getFtpPath(prefs) + '/' + basename(file.path);
      final sftpFile = await sftp.open(ftpPath);
      final data = await sftpFile.readBytes();
      // final buffer = data.buffer;
      // await file.writeAsBytes(buffer.asUint8List(data.offsetInBytes, data.lengthInBytes));
      await file.writeAsBytes(data);
      success = true;
    } catch (e) {
      success = false;
    }
  } else {
    FTPConnect ftp = connection;
    try {
      success = await ftp.downloadFile(basename(file.path), file);
    } catch (e) {
      success = false;
    }
  }
  if (!success){
    closeFtp(connection, prefs);
  }
  return success;
}

void closeFtp(connection, prefs){
  var use_sftp = prefs.getBool('use_sftp') ?? false;
  if (use_sftp){
    SftpClient sftp = connection;
    sftp.close();
  } else {
    FTPConnect ftp = connection;
    unawaited(ftp.disconnect());
  }
}

Future<List<String>?> listFilesOnFtp(connection, SharedPreferences prefs, BuildContext context, {String? ftpPath}) async {
  var names;
  var use_sftp = prefs.getBool('use_sftp') ?? false;
  var use_implicit_ftps = prefs.getBool('use_implicit_ftps') ?? false;
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
  } else if (use_implicit_ftps & use_pure_ftp) {
    pure_ftp.FtpClient ftps = connection;
    try {
      names = await ftps.currentDirectory.listNames();
    } catch (e) {
      await ftps.disconnect();
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