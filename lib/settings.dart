import 'package:field_form/inputfield_screen.dart';
import 'package:flutter/material.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'constants.dart';
import 'dialogs.dart';
import 'ftp.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class SettingsScreen extends StatefulWidget {
  SettingsScreen({key, required this.prefs}) : super(key: key);

  final SharedPreferences prefs;

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  var isLoading = false;
  var redrawMap = false;
  late AppLocalizations texts;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    texts = AppLocalizations.of(context)!;
    return WillPopScope(
        onWillPop: () async {
          Navigator.pop(context, redrawMap);
          return false;
        },
      child: Scaffold(
          appBar: AppBar(
            title: Text(texts.settings),
            backgroundColor: Constant.primaryColor,
        ),

        body:  Stack(
          children: [
            buildSettings(),
            if (isLoading) buildLoadingIndicator(),
          ],
        )
      )
    );
  }

  SettingsList buildSettings(){
    var password = '';
    if (widget.prefs.containsKey('ftp_password')) {
      password = widget.prefs.getString('ftp_password')!;
    };
    final wmsOn = widget.prefs.getBool('wms_on') ?? false;
    return SettingsList(
      sections: [
        SettingsSection(
          title: texts.input,
          tiles: [
            SettingsTile(
                title: texts.editInputFields,
                leading: Icon(Icons.wysiwyg_rounded),
                onPressed: (BuildContext context) async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) {
                      return InputFieldsScreen();
                    }),
                  );
                }
            ),
            SettingsTile.switchTile(
              title: texts.useStandardTime,
              subtitle: texts.useStandardTimeSubtitle,
              leading: Icon(Icons.access_time),
              switchValue: widget.prefs.getBool('use_standard_time') ?? false,
              onToggle: (bool value) {
                setState(() {
                  widget.prefs.setBool('use_standard_time', value);
                });
              },
            ),
          ]
        ),
        SettingsSection(
            title: texts.wms,
            tiles: [
            SettingsTile.switchTile(
              title: texts.addWms,
              leading: Icon(Icons.map),
              switchValue: wmsOn,
              onToggle: (bool value) {
                setState(() {
                  widget.prefs.setBool('wms_on', value);
                  redrawMap = true;
                });
              },
            ),
            if (wmsOn) SettingsTile(
              title: texts.wmsUrl,
              subtitle: widget.prefs.getString('wms_url'),
              leading: Icon(Icons.computer),
              onPressed: (BuildContext context) {
                editStringSetting(context, 'wms_url', texts.changeWmsUrl);
                redrawMap = true;
              },
            ),
            if (wmsOn) SettingsTile(
              title: texts.wmsLayers,
              subtitle: widget.prefs.getString('wms_layers'),
              leading: Icon(Icons.layers),
              onPressed: (BuildContext context) {
                editStringSetting(context, 'wms_layers', texts.changeWmsLayers);
                redrawMap = true;
              },
            ),
          ]
        ),
        SettingsSection(
          title: 'FTP',
          tiles: [
            SettingsTile(
              title: texts.hostname,
              subtitle: widget.prefs.getString('ftp_hostname'),
              leading: Icon(Icons.cloud),
              onPressed: (BuildContext context) {
                editStringSetting(context, 'ftp_hostname', texts.changeFtpHostname);
              },
            ),
            SettingsTile(
              title: texts.username,
              subtitle: widget.prefs.getString('ftp_username'),
              leading: Icon(Icons.person),
              onPressed: (BuildContext context) {
                editStringSetting(context, 'ftp_username', texts.changeFtpUsername);
              },
            ),
            SettingsTile(
              title: texts.password,
              subtitle: '*' * password.length,
              subtitleTextStyle: TextStyle(),
              leading: Icon(Icons.lock),
              onPressed: (BuildContext context) {
                editStringSetting(context, 'ftp_password', texts.changeFtpPassword, password: true);
              },
            ),
            SettingsTile(
              title: texts.path,
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
            if (false) SettingsTile.switchTile(
              title: texts.useFtps,
              leading: Icon(Icons.security),
              switchValue: widget.prefs.getBool('use_ftps') ?? false,
              onToggle: (bool value) {
                setState(() {
                  widget.prefs.setBool('use_ftps', value);
                });
              },
            ),
            SettingsTile.switchTile(
              title: texts.onlyExportNewMeasurements,
              leading: Icon(Icons.fiber_new),
              switchValue: widget.prefs.getBool('only_export_new_data') ?? true,
              onToggle: (bool value) {
                setState(() {
                  widget.prefs.setBool('only_export_new_data', value);
                });
              },
            ),
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
              child: Text(texts.cancel),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  widget.prefs.setString(key, settingValue);
                  Navigator.pop(context);
                });
              },
              child: Text(texts.ok),
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
      case 'wms_url':
      case 'wms_layers':
      // string setting
        await prefs.setString(key, settings[key]!);
        break;
      case 'use_ftps':
      case 'only_export_new_data':
      case 'use_standard_time':
      case 'automatic_synchronisation_on':
      case 'disable_adding_locations':
      case 'replace_locations':
      case 'only_upload_measurements':
      case 'settings_button_off':
      case 'wms_on':
      // boolean setting
        var stringValue = settings[key]!.toLowerCase();
        var value = (stringValue == 'yes') || (stringValue == 'true');
        await prefs.setBool(key, value);
        break;
    }
  }
}
