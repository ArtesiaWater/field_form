import 'package:field_form/inputfield_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_settings_ui/flutter_settings_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
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
    var resolutions = {
      'low': texts.photoResolutionLow,
      'medium': texts.photoResolutionMedium,
      'high': texts.photoResolutionHigh,
      'veryHigh': texts.photoResolutionVeryHigh,
      'ultraHigh': texts.photoResolutionUltraHigh,
      'max': texts.photoResolutionMax,
    };
    var password = '';
    if (widget.prefs.containsKey('ftp_password')) {
      password = widget.prefs.getString('ftp_password')!;
    };
    final wmsOn = widget.prefs.getBool('wms_on') ?? false;
    final mark_measured_days = widget.prefs.getInt('mark_measured_days') ?? 0;
    final add_user_to_measurements = widget.prefs.getBool('add_user_to_measurements')?? false;
    return SettingsList(
      sections: [
        SettingsSection(
          title: Text(texts.input),
          tiles: [
            SettingsTile(
                title: Text(texts.editInputFields),
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
              title: Text(texts.addUserToMeasurements),
              leading: Icon(Icons.account_circle_outlined),
              initialValue: add_user_to_measurements,
              onToggle: (bool value) {
                setState(() {
                  widget.prefs.setBool('add_user_to_measurements', value);
                  if (value){
                    editStringSetting(context, 'user', texts.setUser);
                  }
                });
              },
            ),
            if (add_user_to_measurements) SettingsTile(
              title: Text(texts.user),
              description: Text(widget.prefs.getString('user') ?? ''),
              leading: Icon(Icons.account_circle),
              onPressed: (BuildContext context) {
                editStringSetting(context, 'user', texts.setUser);
              },
            ),
            if (add_user_to_measurements) SettingsTile(
              title: Text(texts.userInputfield),
              description: Text(widget.prefs.getString('user_inputfield') ?? 'user'),
              leading: Icon(Icons.manage_accounts_outlined),
              onPressed: (BuildContext context) {
                editStringSetting(context, 'user_inputfield', texts.changeUserInputfield, default_value: 'user');
              },
            ),
            SettingsTile.switchTile(
              title: Text(texts.useStandardTime),
              description: Text(texts.useStandardTimeSubtitle),
              leading: Icon(Icons.access_time),
              initialValue: widget.prefs.getBool('use_standard_time') ?? false,
              onToggle: (bool value) {
                setState(() {
                  widget.prefs.setBool('use_standard_time', value);
                });
              },
            ),
          ]
        ),
        SettingsSection(
            title: Text(texts.wms),
            tiles: [
            SettingsTile.switchTile(
              title: Text(texts.addWms),
              leading: Icon(Icons.map),
              initialValue: wmsOn,
              onToggle: (bool value) {
                setState(() {
                  widget.prefs.setBool('wms_on', value);
                  redrawMap = true;
                });
              },
            ),
            if (wmsOn) SettingsTile(
              title: Text(texts.wmsUrl),
              description: Text(widget.prefs.getString('wms_url') ?? ""),
              leading: Icon(Icons.computer),
              onPressed: (BuildContext context) {
                editStringSetting(context, 'wms_url', texts.changeWmsUrl);
                redrawMap = true;
              },
            ),
            if (wmsOn) SettingsTile(
              title: Text(texts.wmsLayers),
              description: Text(widget.prefs.getString('wms_layers') ?? ""),
              leading: Icon(Icons.layers),
              onPressed: (BuildContext context) {
                editStringSetting(context, 'wms_layers', texts.changeWmsLayers);
                redrawMap = true;
              },
            ),
          ]
        ),
        SettingsSection(
          title: Text(texts.map),
          tiles: [
            SettingsTile.switchTile(
              title: Text(texts.showPreviousAndNextLocation),
              leading: Icon(Icons.switch_left),
              initialValue: widget.prefs.getBool('show_previous_and_next_location') ?? true,
              onToggle: (bool value) {
                setState(() {
                  widget.prefs.setBool('show_previous_and_next_location', value);
                });
              },
            ),
            SettingsTile(
              title: Text(texts.markMeasuredLocations),
              description: Text(texts.withinIntervalDays(mark_measured_days)),
              leading: Icon(Icons.verified_user),
              onPressed: (BuildContext context) async {
                var interval = await chooseMeasuredInterval(context, widget.prefs, texts);
                if (interval != null) {
                  setState(() {
                    widget.prefs.setInt('mark_measured_days', interval);
                    redrawMap = true;
                  });
                }
              }
            ),
            if (mark_measured_days > 0) SettingsTile.switchTile(
              title: Text(texts.markNotMeasured),
              leading: Icon(Icons.dangerous_outlined),
              initialValue: widget.prefs.getBool('mark_not_measured') ?? false,
              onToggle: (bool value) {
                setState(() {
                  widget.prefs.setBool('mark_not_measured', value);
                  redrawMap = true;
                });
              },
            ),
          ]
        ),
        SettingsSection(
          title: Text(texts.photos),
          tiles: [
            SettingsTile(
              title: Text(texts.resolution),
              description: Text(resolutions[widget.prefs.getString('photo_resolution') ?? 'medium'] ?? 'medium'),
              leading: Icon(Icons.apps),
              onPressed: (BuildContext context) async {
                var options = <Widget>[];
                resolutions.forEach((key, value){
                  options.add(SimpleDialogOption(
                    onPressed: () {
                      Navigator.of(context).pop(key);
                    },
                    child: Text(value),
                  ));
                });
                var resolution = await showDialog(
                    context: context,
                    builder: (context) {
                      var texts = AppLocalizations.of(context)!;
                      return SimpleDialog(
                        title: Text(texts.choosePhotoResolution),
                        children: options,
                      );
                    }
                );
                if (resolution != null) {
                  setState(() {
                    widget.prefs.setString('photo_resolution', resolution);
                  });
                }
              }
            ),
          ]
        ),
        SettingsSection(
          title: Text(texts.ftp),
          tiles: [
            SettingsTile(
              title: Text(texts.hostname),
              description: Text(widget.prefs.getString('ftp_hostname') ?? ""),
              leading: Icon(Icons.cloud),
              onPressed: (BuildContext context) {
                editStringSetting(context, 'ftp_hostname', texts.changeFtpHostname);
              },
            ),
            SettingsTile(
              title: Text(texts.username),
              description: Text(widget.prefs.getString('ftp_username') ?? ""),
              leading: Icon(Icons.person),
              onPressed: (BuildContext context) {
                editStringSetting(context, 'ftp_username', texts.changeFtpUsername);
              },
            ),
            SettingsTile(
              title: Text(texts.password),
              description: Text('*' * password.length),
              leading: Icon(Icons.lock),
              onPressed: (BuildContext context) {
                editStringSetting(context, 'ftp_password', texts.changeFtpPassword, password: true);
              },
            ),
            SettingsTile(
              title: Text(texts.path),
              description: Text(widget.prefs.getString('ftp_path') ?? ""),
              leading: Icon(Icons.folder),
              onPressed: (BuildContext context) async {
                setState(() {isLoading = true;});
                var root = getFtpRoot(widget.prefs);
                var ftp = await connectToFtp(context, widget.prefs, path:root);
                if (ftp == null) {
                  setState(() {isLoading = false;});
                  return;
                }
                var ftp_path = await chooseFtpPath(ftp, context, widget.prefs);
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
            if (true) SettingsTile.switchTile(
              title: Text(texts.useFtps),
              leading: Icon(Icons.security),
              initialValue: widget.prefs.getBool('use_ftps') ?? false,
              onToggle: (bool value) {
                setState(() {
                  widget.prefs.setBool('use_ftps', value);
                  if (value){
                    widget.prefs.setBool('use_sftp', false);
                  }
                });
              },
            ),
            SettingsTile.switchTile(
              title: Text(texts.useSftp),
              leading: Icon(Icons.security),
              initialValue: widget.prefs.getBool('use_sftp') ?? false,
              onToggle: (bool value) {
                setState(() {
                  widget.prefs.setBool('use_sftp', value);
                  if (value){
                    widget.prefs.setBool('use_ftps', false);
                  }
                });
              },
            ),
            SettingsTile.switchTile(
              title: Text(texts.onlyExportNewMeasurements),
              leading: Icon(Icons.fiber_new),
              initialValue: widget.prefs.getBool('only_export_new_data') ?? true,
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

  void editStringSetting(BuildContext context, String key, String title, {bool password=false, default_value=''}) async {
    final new_setting = await editStringSettingDialog(context, key, title, widget.prefs, texts, password:password, default_value:default_value);
    if (new_setting != null){
      setState(() {
        widget.prefs.setString(key, new_setting);
      });
    }
  }
}

void parseSettings(Map<String, dynamic> settings, SharedPreferences prefs) async{
  for (var key in settings.keys) {
    switch (key) {
      case 'email_address':
      case 'photo_resolution':
      case 'ftp_hostname':
      case 'ftp_username':
      case 'ftp_password':
      case 'ftp_path':
      case 'wms_url':
      case 'wms_layers':
      case 'user_inputfield':
      case 'user':
        // string setting
        await prefs.setString(key, settings[key]!);
        break;
      case 'mark_measured_days':
        // integer setting
        var value = settings[key]!;
        if (value is String) {
          value = int.parse(value);
        }
        await prefs.setInt(key, value);
        break;
      case 'use_ftps':
      case 'use_sftp':
      case 'only_export_new_data':
      case 'use_standard_time':
      case 'automatic_synchronisation_on':
      case 'disable_adding_locations':
      case 'hide_settings':
      case 'replace_locations':
      case 'only_upload_measurements':
      case 'settings_button_off':
      case 'wms_on':
      case 'show_previous_and_next_location':
      case 'request_user':
      case 'add_user_to_measurements':
      case 'mark_not_measured':
        // boolean setting
        var value = settings[key]!;
        if (value is String) {
          var stringValue = value.toLowerCase();
          value = (stringValue == 'yes') || (stringValue == 'true');
        }
        if (key == 'use_ftps' && value){
          await prefs.setBool('use_sftp', false);
        }
        if (key == 'use_sftp' && value){
          await prefs.setBool('use_ftps', false);
        }
        await prefs.setBool(key, value);
        break;
    }
  }
}
