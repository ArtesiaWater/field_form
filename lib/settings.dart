import 'package:field_form/inputfield_screen.dart';
import 'package:flutter/material.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'constants.dart';
import 'dialogs.dart';
import 'ftp.dart';
import 'locations.dart';

class SettingsScreen extends StatefulWidget {
  SettingsScreen({key, required this.prefs, required this.inputFields}) : super(key: key);

  final SharedPreferences prefs;
  final Map<String, InputField> inputFields;

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  var isLoading = false;


  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Settings'),
          backgroundColor: Constant.primaryColor,
      ),

      body:  Stack(
        children: [
          buildSettings(),
          if (isLoading) buildLoadingIndicator(),
        ],
      )
    );
  }

  SettingsList buildSettings(){
    var password = '';
    if (widget.prefs.containsKey('ftp_password')) {
      password = widget.prefs.getString('ftp_password')!;
    };
    return SettingsList(
      sections: [
        SettingsSection(
          title: 'FTP',
          tiles: [
            SettingsTile(
              title: 'Hostname',
              subtitle: widget.prefs.getString('ftp_hostname'),
              leading: Icon(Icons.cloud),
              onPressed: (BuildContext context) {
                editStringSetting(context, 'ftp_hostname', 'Change ftp hostname');
              },
            ),
            SettingsTile(
              title: 'Username',
              subtitle: widget.prefs.getString('ftp_username'),
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
              subtitle: widget.prefs.getString('ftp_path'),
              leading: Icon(Icons.folder),
              onPressed: (BuildContext context) async {
                setState(() {isLoading = true;});
                var ftpConnect = await connectToFtp(context, widget.prefs, path:'');
                if (ftpConnect == null) {
                  setState(() {isLoading = false;});
                  return;
                }
                var ftp_path = await chooseFtpPath(ftpConnect, context, widget.prefs);
                if (ftp_path != null) {
                  setState(() {
                    widget.prefs.setString('ftp_path', ftp_path);
                    isLoading = false;
                  });
                } else {
                  setState(() {isLoading = false;});
                }
                //editStringSetting(context, 'ftp_path', 'Change ftp path');
              },
            ),
            SettingsTile.switchTile(
              title: 'Only export new measurements',
              leading: Icon(Icons.fiber_new),
              switchValue: widget.prefs.getBool('only_export_new_data') ?? true,
              onToggle: (bool value) {
                setState(() {
                  widget.prefs.setBool('only_export_new_data', value);
                });
              },
            ),
            SettingsTile.switchTile(
              title: 'Use standard time',
              subtitle: 'Disable daylight saving time',
              leading: Icon(Icons.access_time),
              switchValue: widget.prefs.getBool('use_standard_time') ?? false,
              onToggle: (bool value) {
                setState(() {
                  widget.prefs.setBool('use_standard_time', value);
                });
              },
            ),
            SettingsTile(
              title: 'Edit input fields',
              leading: Icon(Icons.wysiwyg_rounded),
              onPressed: (BuildContext context) async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) {
                    return InputFieldsScreen(inputFields: widget.inputFields);
                  }),
                );
              }
            )
          ],
        ),
      ],
    );
  }

  void editStringSetting(BuildContext context, String key, String title, {bool password=false}) async {
    var settingValue = widget.prefs.getString(key) ?? '';
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
                  widget.prefs.setString(key, settingValue);
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

void parseSettings(Map<String, String> settings, SharedPreferences prefs) async{
  for (var key in settings.keys) {
    switch (key) {
      case 'email_address':
      case 'ftp_hostname':
      case 'ftp_username':
      case 'ftp_password':
      case 'ftp_path':
      // string setting
        await prefs.setString(key, settings[key]!);
        break;
      case 'use_ftps':
      case 'only_export_new_data':
      case 'use_standard_time':
      // boolean setting
        var stringValue = settings[key]!.toLowerCase();
        var value = (stringValue == 'yes') || (stringValue == 'true');
        await prefs.setBool(key, value);
        break;
    }
  }
}
