import 'package:flutter/material.dart';
import 'package:ftpconnect/ftpconnect.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'dialogs.dart';

const supportIPv6 = false;

Future<FTPConnect?> connectToFtp(BuildContext context, SharedPreferences prefs, {String? path}) async {
  var host = prefs.getString('ftp_hostname') ?? '';
  var user = prefs.getString('ftp_username') ?? '';
  var pass = prefs.getString('ftp_password') ?? '';
  var isSecured = prefs.getBool('use_ftps') ?? false;

  if (host == '') {
    showErrorDialog(context, 'No hostname defined. Please assign a hostname in the settings',
        title:'Cannot connect of ftp-server');
    return null;
  }

  var ftpConnect = FTPConnect(host, user: user, pass: pass, timeout: 30, isSecured:isSecured);
  try {
    await ftpConnect.connect();
  } catch (e) {
    showErrorDialog(context, e.toString(), title:'Cannot connect of ftp-server');
    return null;
  }
  displayInformation(context, 'Connected');
  path ??= prefs.getString('ftp_path') ?? '';
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
  var success = await ftpConnect.changeDirectory(path);
  if (!success) {
    await ftpConnect.disconnect();
    showErrorDialog(context, 'Unable to find FTP-path: ' + path);
  }
  return success;
}

Future<String?> chooseFtpPath(FTPConnect ftpConnect, BuildContext context, SharedPreferences prefs) async {
  var names;
  try {
    //Get directory content
    final list = await ftpConnect.listDirectoryContent(supportIPv6:supportIPv6);
    names = list.map((f) => f.name).whereType<String>().toList();
  } catch (e) {
    await ftpConnect.disconnect();
    showErrorDialog(context, e.toString());
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
