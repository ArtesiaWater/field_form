import 'package:flutter/material.dart';
import 'package:ftpconnect/ftpconnect.dart';

import 'dialogs.dart';

Future<FTPConnect?> connectToFtp(context, prefs, {path}) async {
  var host = prefs.getString('ftp_hostname') ?? '';
  var user = prefs.getString('ftp_username') ?? '';
  var pass = prefs.getString('ftp_password') ?? '';

  if (host == '') {
    showErrorDialog(context, 'No hostname defined. Please assign a hostname in the settings',
        title:'Cannot connect of ftp-server');
    return null;
  }

  var ftpConnect = FTPConnect(host, user: user, pass: pass, timeout: 5);
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

Future<bool> changeDirectory(ftpConnect, context, path) async {
  var success = await ftpConnect.changeDirectory(path);
  if (!success) {
    await ftpConnect.disconnect();
    showErrorDialog(context, 'Unable to find FTP-path: ' + path);
  }
  return success;
}

Future<String?> chooseFtpPath(ftpConnect, context, prefs) async {
  var names;
  try {
    //Get directory content
    names = await ftpConnect.listDirectoryContentOnlyNames();
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
