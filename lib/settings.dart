import 'package:field_form/inputfield_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_settings_ui/flutter_settings_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'dialogs.dart';
import 'ftp_configuration_screen.dart';
import 'ftp_configurations.dart';
import 'l10n/app_localizations.dart';

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
  Widget build(BuildContext context) {
    texts = AppLocalizations.of(context)!;
    return PopScope(
        canPop: false,
        onPopInvokedWithResult: (bool didPop, dynamic result) {
          if (didPop) return;
          Navigator.pop(context, redrawMap);
        },
        child: Scaffold(
            appBar: AppBar(
              title: Text(texts.settings),
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
            ),
            body: Stack(
              children: [
                buildSettings(),
                if (isLoading) buildLoadingIndicator(),
              ],
            )));
  }

  SettingsList buildSettings() {
    var resolutions = {
      'low': texts.photoResolutionLow,
      'medium': texts.photoResolutionMedium,
      'high': texts.photoResolutionHigh,
      'veryHigh': texts.photoResolutionVeryHigh,
      'ultraHigh': texts.photoResolutionUltraHigh,
      'max': texts.photoResolutionMax,
    };
    final wmsOn = widget.prefs.getBool('wms_on') ?? false;
    final mark_measured_days = widget.prefs.getInt('mark_measured_days') ?? 0;
    final add_user_to_measurements =
        widget.prefs.getBool('add_user_to_measurements') ?? false;
    return SettingsList(
      sections: [
        SettingsSection(title: Text(texts.input), tiles: [
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
              }),
          SettingsTile.switchTile(
            title: Text(texts.addUserToMeasurements),
            leading: Icon(Icons.account_circle_outlined),
            initialValue: add_user_to_measurements,
            onToggle: (bool value) {
              setState(() {
                widget.prefs.setBool('add_user_to_measurements', value);
                if (value) {
                  editStringSetting(context, 'user', texts.setUser);
                }
              });
            },
          ),
          if (add_user_to_measurements)
            SettingsTile(
              title: Text(texts.user),
              description: Text(widget.prefs.getString('user') ?? ''),
              leading: Icon(Icons.account_circle),
              onPressed: (BuildContext context) {
                editStringSetting(context, 'user', texts.setUser);
              },
            ),
          if (add_user_to_measurements)
            SettingsTile(
              title: Text(texts.userInputfield),
              description:
                  Text(widget.prefs.getString('user_inputfield') ?? 'user'),
              leading: Icon(Icons.manage_accounts_outlined),
              onPressed: (BuildContext context) {
                editStringSetting(
                    context, 'user_inputfield', texts.changeUserInputfield,
                    default_value: 'user');
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
        ]),
        SettingsSection(title: Text(texts.wms), tiles: [
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
          if (wmsOn)
            SettingsTile(
              title: Text(texts.wmsUrl),
              description: Text(widget.prefs.getString('wms_url') ?? ""),
              leading: Icon(Icons.computer),
              onPressed: (BuildContext context) {
                editStringSetting(context, 'wms_url', texts.changeWmsUrl);
                redrawMap = true;
              },
            ),
          if (wmsOn)
            SettingsTile(
              title: Text(texts.wmsLayers),
              description: Text(widget.prefs.getString('wms_layers') ?? ""),
              leading: Icon(Icons.layers),
              onPressed: (BuildContext context) {
                editStringSetting(context, 'wms_layers', texts.changeWmsLayers);
                redrawMap = true;
              },
            ),
        ]),
        SettingsSection(title: Text(texts.map), tiles: [
          SettingsTile.switchTile(
            title: Text(texts.showPreviousAndNextLocation),
            leading: Icon(Icons.switch_left),
            initialValue:
                widget.prefs.getBool('show_previous_and_next_location') ?? true,
            onToggle: (bool value) {
              setState(() {
                widget.prefs.setBool('show_previous_and_next_location', value);
                redrawMap = true;
              });
            },
          ),
          SettingsTile.switchTile(
            title: Text(texts.showSequenceNumber),
            leading: Icon(Icons.numbers),
            initialValue: widget.prefs.getBool('show_sequence_number') ?? true,
            onToggle: (bool value) {
              setState(() {
                widget.prefs.setBool('show_sequence_number', value);
                redrawMap = true;
              });
            },
          ),
          SettingsTile(
              title: Text(texts.markMeasuredLocations),
              description: Text(mark_measured_days == 0
                  ? texts.doNotMarkMeasuredLocations
                  : texts.withinIntervalDays(mark_measured_days)),
              leading: Icon(Icons.verified_user),
              onPressed: (BuildContext context) async {
                var interval =
                    await chooseMeasuredInterval(context, widget.prefs, texts);
                if (interval != null) {
                  setState(() {
                    widget.prefs.setInt('mark_measured_days', interval);
                    redrawMap = true;
                  });
                }
              }),
          if (mark_measured_days > 0)
            SettingsTile.switchTile(
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
        ]),
        SettingsSection(title: Text(texts.photos), tiles: [
          SettingsTile(
              title: Text(texts.resolution),
              description: Text(resolutions[
                      widget.prefs.getString('photo_resolution') ?? 'medium'] ??
                  'medium'),
              leading: Icon(Icons.apps),
              onPressed: (BuildContext context) async {
                var options = <Widget>[];
                resolutions.forEach((key, value) {
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
                    });
                if (resolution != null) {
                  setState(() {
                    widget.prefs.setString('photo_resolution', resolution);
                  });
                }
              }),
        ]),
        SettingsSection(
          title: Text(texts.ftp),
          tiles: [
            SettingsTile(
              title: Text(texts.ftpConfigurations),
              description: Text(widget.prefs.getString('ftp_hostname') ?? ''),
              leading: Icon(Icons.cloud),
              onPressed: (BuildContext context) async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) {
                    return FtpConfigurationScreen(prefs: widget.prefs);
                  }),
                );
                setState(() {});
              },
            ),
            SettingsTile.switchTile(
              title: Text(texts.onlyExportNewMeasurements),
              leading: Icon(Icons.fiber_new),
              initialValue:
                  widget.prefs.getBool('only_export_new_data') ?? true,
              onToggle: (bool value) {
                setState(() {
                  widget.prefs.setBool('only_export_new_data', value);
                });
              },
            ),
            SettingsTile.switchTile(
              title: Text(texts.uploadDataInstantly),
              leading: Icon(Icons.fiber_new),
              initialValue:
                  widget.prefs.getBool('upload_data_instantly') ?? false,
              onToggle: (bool value) {
                setState(() {
                  widget.prefs.setBool('upload_data_instantly', value);
                });
              },
            ),
          ],
        ),
      ],
    );
  }

  void editStringSetting(BuildContext context, String key, String title,
      {bool password = false, default_value = ''}) async {
    final new_setting = await editStringSettingDialog(
        context, key, title, widget.prefs, texts,
        password: password, default_value: default_value);
    if (new_setting != null) {
      await widget.prefs.setString(key, new_setting);
      if (!mounted) {
        return;
      }
      setState(() {});
    }
  }
}

Future<void> parseSettings(
    Map<String, dynamic> settings, SharedPreferences prefs) async {
  await ensureFtpConfigurationsMigrated(prefs);

  bool _toBool(dynamic value, bool fallback) {
    if (value is bool) {
      return value;
    }
    if (value is String) {
      var stringValue = value.toLowerCase();
      return (stringValue == 'yes') || (stringValue == 'true');
    }
    return fallback;
  }

  final importedHostname = (settings['ftp_hostname'] ?? '').toString().trim();
  final importedActiveHostname =
      (settings['ftp_active_hostname'] ?? '').toString().trim();
  final importedFtpConfigsRaw = settings['ftp_configurations'];
  final importedFtpConfigs = importedFtpConfigsRaw is List
      ? importedFtpConfigsRaw.whereType<Map>().toList()
      : <Map>[];

  if (importedFtpConfigs.isNotEmpty) {
    for (final item in importedFtpConfigs) {
      final map = Map<String, dynamic>.from(item);
      final hostname = (map['hostname'] ?? '').toString().trim();
      if (hostname.isEmpty) {
        continue;
      }
      final existing = await getFtpConfigurationByHostname(prefs, hostname);
      final config = (existing ?? FtpConfiguration(hostname: hostname)).copyWith(
        path: (map['path'] ?? existing?.path ?? '').toString(),
        useFtps: _toBool(map['use_ftps'], existing?.useFtps ?? false),
        useSftp: _toBool(map['use_sftp'], existing?.useSftp ?? false),
        useImplicitFtps:
            _toBool(map['use_implicit_ftps'], existing?.useImplicitFtps ?? false),
      );

      await upsertFtpConfiguration(
        prefs,
        config,
        username: map['ftp_username']?.toString(),
        password: map['ftp_password']?.toString(),
      );
    }

    final nextActive = importedActiveHostname.isNotEmpty
        ? importedActiveHostname
        : importedHostname;
    if (nextActive.isNotEmpty) {
      await setActiveFtpConfiguration(prefs, nextActive);
    }
  }

  final hasFtpUpdate = importedHostname.isNotEmpty ||
      settings.containsKey('ftp_path') ||
      settings.containsKey('use_ftps') ||
      settings.containsKey('use_sftp') ||
      settings.containsKey('use_implicit_ftps') ||
      settings.containsKey('ftp_username') ||
      settings.containsKey('ftp_password');

  if (hasFtpUpdate && importedFtpConfigs.isEmpty) {
    final baseConfig = importedHostname.isNotEmpty
        ? (await getFtpConfigurationByHostname(prefs, importedHostname) ??
            FtpConfiguration(hostname: importedHostname))
        : await getActiveFtpConfiguration(prefs);

    if (baseConfig.hostname.isNotEmpty) {
      final updatedConfig = baseConfig.copyWith(
        path: settings.containsKey('ftp_path')
            ? (settings['ftp_path'] ?? '').toString()
            : baseConfig.path,
        useFtps: settings.containsKey('use_ftps')
            ? _toBool(settings['use_ftps'], baseConfig.useFtps)
            : baseConfig.useFtps,
        useSftp: settings.containsKey('use_sftp')
            ? _toBool(settings['use_sftp'], baseConfig.useSftp)
            : baseConfig.useSftp,
        useImplicitFtps: settings.containsKey('use_implicit_ftps')
            ? _toBool(settings['use_implicit_ftps'], baseConfig.useImplicitFtps)
            : baseConfig.useImplicitFtps,
      );
      await upsertFtpConfiguration(
        prefs,
        updatedConfig,
        username: settings['ftp_username']?.toString(),
        password: settings['ftp_password']?.toString(),
        setActive: importedHostname.isNotEmpty,
      );
    }
  }

  for (var key in settings.keys) {
    switch (key) {
      case 'settings_format_version':
        break;
      case 'ftp_username':
      case 'ftp_password':
      case 'ftp_hostname':
      case 'ftp_path':
      case 'use_ftps':
      case 'use_sftp':
      case 'use_implicit_ftps':
        break;
      case 'email_address':
      case 'photo_resolution':
      case 'wms_url':
      case 'wms_layers':
      case 'user_inputfield':
      case 'user':
      case 'block_character_set':
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
      case 'show_sequence_number':
      case "upload_data_instantly":
      case 'request_user':
      case 'add_user_to_measurements':
      case 'mark_not_measured':
      case 'allow_required_override':
      case 'group_previous_measurements_by_date':
        // boolean setting
        var value = settings[key]!;
        if (value is String) {
          var stringValue = value.toLowerCase();
          value = (stringValue == 'yes') || (stringValue == 'true');
        }
        await prefs.setBool(key, value);
        break;
    }
  }
}
