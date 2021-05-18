import 'package:flutter/material.dart';
import 'package:ftpconnect/ftpconnect.dart';

import 'dialogs.dart';

Future<FTPConnect?> connectToFtp(context, prefs, {path}) async {
  var host = prefs.getString('ftp_hostname') ?? '';
  var user = prefs.getString('ftp_username') ?? '';
  var pass = prefs.getString('ftp_password') ?? '';

  var ftpConnect = FTPConnect(host, user: user, pass: pass, timeout: 5);
  await ftpConnect.connect();
  if (path == null) {
    path = prefs.getString('ftp_path') ?? '';
    if (path.isEmpty) {
      displayInformation(context, 'Connected');
      return ftpConnect;
    }
    displayInformation(context, 'Connected, changing path');
    await changeDirectory(ftpConnect, context, path);
    return ftpConnect;
  }
}

Future<void> changeDirectory(ftpConnect, context, path) async {
  var success = await ftpConnect.changeDirectory(path);
  if (!success) {
    await ftpConnect.disconnect();
    showErrorDialog(context, 'Unable to find FTP-path: ' + path);
    return null;
  }
}

Future<String?> chooseFtpPath(ftpConnect, context, prefs) async {
  var names;
  showLoaderDialog(context);
  try {
    //Get directory content
    names = await ftpConnect.listDirectoryContentOnlyNames();
    await ftpConnect.disconnect();
  } catch (e) {
    Navigator.pop(context);
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
  Navigator.pop(context);

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
