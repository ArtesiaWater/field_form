import 'package:flutter/material.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ftp.dart';

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
                onPressed: (BuildContext context) async {
                  var ftpConnect = await connectToFtp(context, prefs, path:'');
                  var ftp_path = await chooseFtpPath(ftpConnect, context, prefs);
                  if (ftp_path != null) {
                    setState(() {
                      prefs!.setString('ftp_path', ftp_path);
                    });
                  }
                  //editStringSetting(context, 'ftp_path', 'Change ftp path');
                },
              ),
              SettingsTile.switchTile(
                title: 'Only export new measurements',
                leading: Icon(Icons.fiber_new),
                switchValue: prefs?.getBool('only_export_new_data') ?? true,
                onToggle: (bool value) {
                  setState(() {
                    prefs!.setBool('only_export_new_data', value);
                  });
                },
              ),
            ],
          ),
        ],
      )
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