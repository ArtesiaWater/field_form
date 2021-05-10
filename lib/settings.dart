import 'package:flutter/material.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ftpconnect/ftpconnect.dart';

import 'dialogs.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool  value = true;

  SharedPreferences? prefs;

  @override
  void initState() {
    super.initState();
    getprefs();
  }

  void getprefs() async{
    prefs = await SharedPreferences.getInstance();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    var password = '';
    if (prefs != null) {
      if (prefs!.containsKey('ftp_password')) {
        password = prefs!.getString('ftp_password')!;
      };
    }
    return Scaffold(
        appBar: AppBar(
          title: Text('Settings'),
      ),

      body:  SettingsList(
        sections: [
          SettingsSection(
            title: 'FTP',
            tiles: [
              SettingsTile(
                title: 'Hostname',
                subtitle: prefs?.getString('ftp_hostname'),
                leading: Icon(Icons.cloud),
                onPressed: (BuildContext context) {
                  editStringSetting(context, 'ftp_hostname', 'Change ftp hostname');
                },
              ),
              SettingsTile(
                title: 'Username',
                subtitle: prefs?.getString('ftp_username'),
                leading: Icon(Icons.person),
                onPressed: (BuildContext context) {
                  editStringSetting(context, 'ftp_username', 'Change ftp username');
                },
              ),
              SettingsTile(
                title: 'Password',
                subtitle: '*' * password.length,
                subtitleTextStyle: TextStyle(),
                leading: Icon(Icons.lock),
                onPressed: (BuildContext context) {
                  editStringSetting(context, 'ftp_password', 'Change ftp password', password: true);
                },
              ),
              SettingsTile(
                title: 'Path',
                subtitle: prefs?.getString('ftp_path'),
                leading: Icon(Icons.folder),
                onPressed: (BuildContext context) {
                  chooseFtpPath(context);
                  //editStringSetting(context, 'ftp_path', 'Change ftp path');
                },
              ),
            ],
          ),
        ],
      )
    );
  }

  Future<void> chooseFtpPath(context) async {
    var host = prefs!.getString('ftp_hostname') ?? '';
    var user = prefs!.getString('ftp_username') ?? '';
    var pass = prefs!.getString('ftp_password') ?? '';
    var ftpConnect = FTPConnect(host, user:user, pass:pass);
    var names;
    showLoaderDialog(context);
    try {
      //Get directory content
      await ftpConnect.connect();
      names = await ftpConnect.listDirectoryContentOnlyNames();
      await ftpConnect.disconnect();
    } catch (e) {
      Navigator.pop(context);
      showErrorDialog(context, e.toString());
      return;
    }
    var options = <Widget>[];
    for (var name in names){
      options.add(SimpleDialogOption(
        onPressed: () {
          setState(() {
            prefs!.setString('ftp_path', name);
          });
          Navigator.of(context).pop();
        },
        child: Text(name),
      ));
    }
    Navigator.pop(context);

    await showDialog(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: const Text('Choose a folder'),
          children: options,
        );
      }
    );
  }

  void editStringSetting(BuildContext context, String key, String title, {bool password=false}) async {
    var settingValue = prefs?.getString(key) ?? '';
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: TextEditingController(text: settingValue),
            onChanged: (value) {
              settingValue = value;
            },
            obscureText: password,
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('CANCEL'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  prefs?.setString(key, settingValue);
                  Navigator.pop(context);
                });
              },
              child: Text('OK'),
            ),
          ],
        );
      }
    );
  }
}