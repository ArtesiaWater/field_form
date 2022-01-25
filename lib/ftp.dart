import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:ftpconnect/ftpconnect.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dartssh2/dartssh2.dart';

import 'dialogs.dart';

const supportIPv6 = false;

connectToFtp(BuildContext context, SharedPreferences prefs, {String? path}) async {
  var host = prefs.getString('ftp_hostname') ?? '';
  var user = prefs.getString('ftp_username') ?? '';
  var pass = prefs.getString('ftp_password') ?? '';
  var use_ftps = prefs.getBool('use_ftps') ?? false;
  var use_sftp = prefs.getBool('use_sftp') ?? false;

  if (host == '') {
    showErrorDialog(context, 'No hostname defined. Please assign a hostname in the settings',
        title:'Cannot connect of ftp-server');
    return null;
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
    } catch (e) {
      showErrorDialog(
          context, e.toString(), title: 'Cannot connect of ftp-server');
      return null;
    }
  }

  var ftpConnect = FTPConnect(host, user: user, pass: pass, timeout: 5, isSecured:use_ftps);
  try {
    await ftpConnect.connect();
  } catch (e) {
    showErrorDialog(context, e.toString(), title:'Cannot connect of ftp-server');
    return null;
  }
  displayInformation(context, 'Connected');
  path ??= getFtpPath(prefs);
  if (path.isEmpty) {
    // we do not need to change path
    return ftpConnect;
  }
  // we do need to change path
  var success = await changeDirectory(ftpConnect, context, path);
  if (!success){
    return null;
  }
  return ftpConnect;
}

Future<bool> changeDirectory(FTPConnect ftpConnect, BuildContext context, String path) async {
  var success = true;
  for (var folder in path.split('/')){
    if (folder.isNotEmpty) {
      var success = await ftpConnect.changeDirectory(folder);
      if (!success) {
        await ftpConnect.disconnect();
        showErrorDialog(context, 'Unable to find FTP-path: ' + folder);
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
      success = true;
    } catch (e) {
      sftp.close();
      success = false;
    }
  } else {
    FTPConnect ftp = connection;
    success = await ftp.uploadFile(file, supportIPV6: supportIPv6);
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
    success = await ftp.downloadFile(basename(file.path), file, supportIPv6:supportIPv6);
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
  if (use_sftp){
    SftpClient sftp = connection;
    try {
      ftpPath ??= getFtpPath(prefs);
      final items = await sftp.listdir('/' + ftpPath);
      for (final item in items) {
        print(item.filename);
      }
      names = items.map((f) => f.filename).whereType<String>().toList();
    } catch (e) {
      sftp.close();
      showErrorDialog(context, e.toString());
      return null;
    }
  } else {
    FTPConnect ftp = connection;
    try {
      //Get directory content
      final list = await ftp.listDirectoryContent(supportIPv6:supportIPv6);
      names = list.map((f) => f.name).whereType<String>().toList();
    } catch (e) {
      await ftp.disconnect();
      showErrorDialog(context, e.toString());
      return null;
    }
  }
  // sort the files alphabetcally
  names.sort((a, b) => a.toString().compareTo(b.toString()));
  return names;
}

Future<String?> chooseFtpPath(connection, BuildContext context, SharedPreferences prefs) async {
  var root = prefs.getString('ftp_root') ?? '';
  var names = await listFilesOnFtp(connection, prefs, context, ftpPath: root);
  if (names == null) {
    return null;
  }
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
        return SimpleDialog(
          title: const Text('Choose a folder'),
          children: options,
        );
      }
  );
  return action;
}

String getFtpPath(SharedPreferences prefs) {
  var root = prefs.getString('ftp_root') ?? '';
  var path = prefs.getString('ftp_path') ?? '';
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