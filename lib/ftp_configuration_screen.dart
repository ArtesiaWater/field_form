import 'package:flutter/material.dart';
import 'package:flutter_settings_ui/flutter_settings_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'dialogs.dart';
import 'ftp.dart';
import 'ftp_configurations.dart';
import 'l10n/app_localizations.dart';

class FtpConfigurationScreen extends StatefulWidget {
  const FtpConfigurationScreen({
    super.key,
    required this.prefs,
    required this.onSwitchFtpFolder,
  });

  final SharedPreferences prefs;
  final Future<bool> Function(BuildContext context,
      {bool chooseFolder, bool downloadNow, bool connectNow}) onSwitchFtpFolder;

  @override
  State<FtpConfigurationScreen> createState() => _FtpConfigurationScreenState();
}

class _FtpConfigurationScreenState extends State<FtpConfigurationScreen> {
  var isLoading = false;
  late AppLocalizations texts;
  var ftpUsername = '';
  var ftpPassword = '';
  var activeFtpHostname = '';
  var ftpHostnames = <String>[];
  var didSwitchFtpFolder = false;

  @override
  void initState() {
    super.initState();
    _loadFtpConfigurations();
  }

  Future<void> _loadFtpConfigurations() async {
    await ensureFtpConfigurationsMigrated(widget.prefs);
    final configs = await getFtpConfigurations(widget.prefs);
    final active = await getActiveFtpConfiguration(widget.prefs);
    final username = await getActiveFtpUsername(widget.prefs);
    final password = await getActiveFtpPassword(widget.prefs);

    if (!mounted) {
      return;
    }
    setState(() {
      ftpHostnames = configs.map((config) => config.hostname).toList();
      activeFtpHostname = active.hostname;
      ftpUsername = username;
      ftpPassword = password;
    });
  }

  Future<void> _chooseActiveFtpConfiguration(BuildContext context) async {
    if (ftpHostnames.isEmpty) {
      return;
    }

    var options = <Widget>[];
    for (var hostname in ftpHostnames) {
      options.add(SimpleDialogOption(
        onPressed: () {
          Navigator.of(context).pop(hostname);
        },
        child: Text(hostname),
      ));
    }

    final chosen = await showDialog(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: Text(texts.activeFtpConfiguration),
          children: options,
        );
      },
    );
    if (chosen != null) {
      if (chosen.toString() == activeFtpHostname) {
        return;
      }
      final switched = await _onSwitchFtpFolder(context,
          chooseFolder: false, downloadNow: false, connectNow: false);
      if (switched) {
        await setActiveFtpConfiguration(widget.prefs, chosen.toString());
        didSwitchFtpFolder = true;
      }
      await _loadFtpConfigurations();
    }
  }

  Future<void> _addFtpConfiguration(BuildContext context) async {
    var hostname = await showInputDialog(context,
        title: texts.addFtpHostname, initialValue: '', type: 'string');
    if (hostname == null) {
      return;
    }
    hostname = hostname.trim();
    if (hostname.isEmpty) {
      return;
    }

    final existing = await getFtpConfigurationByHostname(widget.prefs, hostname);
    if (existing != null) {
      final overwrite = await showContinueDialog(
        context,
        texts.ftpConfigOverwriteWarning,
        title: texts.overwriteFtpConfigurationTitle,
        yesButton: texts.yes,
        noButton: texts.no,
      );
      if (overwrite != true) {
        return;
      }
    }

    final switched = await _onSwitchFtpFolder(context,
        chooseFolder: false, downloadNow: false, connectNow: false);
    if (!switched) {
      return;
    }

    final config = existing ?? FtpConfiguration(hostname: hostname);
    await upsertFtpConfiguration(widget.prefs, config, setActive: true);
    await setActiveFtpUsername(widget.prefs, '');
    await setActiveFtpPassword(widget.prefs, '');
    didSwitchFtpFolder = true;
    await _loadFtpConfigurations();
  }

  Future<void> _removeFtpConfiguration(BuildContext context) async {
    final selected = activeFtpHostname.trim();
    if (selected.isEmpty) {
      return;
    }

    final remove = await showContinueDialog(
      context,
      texts.removeFtpConfigurationPrompt(selected),
      title: texts.removeFtpConfigurationTitle,
      yesButton: texts.yes,
      noButton: texts.no,
    );
    if (remove == true) {
      await removeFtpConfiguration(widget.prefs, selected);
      await _loadFtpConfigurations();
    }
  }

  Future<void> _editStringSetting(BuildContext context, String key, String title,
      {bool password = false, defaultValue = ''}) async {
    final newSetting = await editStringSettingDialog(
        context, key, title, widget.prefs, texts,
        password: password, default_value: defaultValue);
    if (newSetting == null) {
      return;
    }

    if (key == 'ftp_username') {
      final switched = await _onSwitchFtpFolder(context,
          chooseFolder: false, downloadNow: false, connectNow: false);
      if (!switched) {
        return;
      }
      await setActiveFtpUsername(widget.prefs, newSetting);
      didSwitchFtpFolder = true;
    } else if (key == 'ftp_password') {
      await setActiveFtpPassword(widget.prefs, newSetting);
    } else if (key == 'ftp_hostname') {
      final switched = await _onSwitchFtpFolder(context,
          chooseFolder: false, downloadNow: false, connectNow: false);
      if (!switched) {
        return;
      }
      await renameActiveFtpHostname(widget.prefs, newSetting);
      didSwitchFtpFolder = true;
    } else if (key == 'ftp_path') {
      final switched = await _onSwitchFtpFolder(context,
          chooseFolder: false, downloadNow: false, connectNow: false);
      if (!switched) {
        return;
      }
      await updateActiveFtpConfiguration(widget.prefs, path: newSetting);
      didSwitchFtpFolder = true;
    }
    await _loadFtpConfigurations();
  }

  Future<bool> _onSwitchFtpFolder(BuildContext context,
      {bool chooseFolder = true,
      bool downloadNow = true,
      bool connectNow = true}) async {
    setState(() {
      isLoading = true;
    });
    try {
      return await widget.onSwitchFtpFolder(context,
          chooseFolder: chooseFolder,
          downloadNow: downloadNow,
          connectNow: connectNow);
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _testConnection(BuildContext context) async {
    setState(() {
      isLoading = true;
    });
    final ftp = await connectToFtp(context, widget.prefs);
    if (ftp != null) {
      closeFtp(ftp, widget.prefs);
      if (mounted) {
        displayInformation(context, texts.connected);
      }
    }
    if (!mounted) {
      return;
    }
    setState(() {
      isLoading = false;
    });
  }

  String _selectedHostnameLabel() {
    if (activeFtpHostname.trim().isEmpty) {
      return '-';
    }
    return activeFtpHostname;
  }

  @override
  Widget build(BuildContext context) {
    texts = AppLocalizations.of(context)!;
    final selectedHostname = _selectedHostnameLabel();
    final colorScheme = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (didPop) return;
        Navigator.pop(context, didSwitchFtpFolder);
      },
      child: Scaffold(
      appBar: AppBar(
        title: Text(texts.ftp),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        actions: [
          IconButton(
            tooltip: texts.addConfiguration,
            icon: const Icon(Icons.add),
            onPressed: () async {
              await _addFtpConfiguration(context);
            },
          ),
          IconButton(
            tooltip: texts.removeConfiguration,
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              await _removeFtpConfiguration(context);
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Padding(
            padding: EdgeInsets.only(bottom: bottomInset + 12),
            child: SettingsList(sections: [
            SettingsSection(
              title: Text(texts.ftpConfigurations),
              tiles: [
              CustomSettingsTile(
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () async {
                    await _chooseActiveFtpConfiguration(context);
                  },
                  child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colorScheme.primary, width: 1),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.tune, color: colorScheme.onPrimaryContainer),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              texts.activeConfiguration,
                              style: TextStyle(
                                  color: colorScheme.onPrimaryContainer,
                                  fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              selectedHostname,
                              style: TextStyle(
                                color: colorScheme.onPrimaryContainer,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.keyboard_arrow_down,
                          color: colorScheme.onPrimaryContainer),
                    ],
                  ),
                ),
                ),
              ),
            ]),
            SettingsSection(
              title: Text(texts.properties),
              tiles: [
              SettingsTile(
                title: Text(texts.hostname),
                description: Text(widget.prefs.getString('ftp_hostname') ?? ''),
                leading: const Icon(Icons.cloud),
                onPressed: (BuildContext context) {
                  _editStringSetting(context, 'ftp_hostname', texts.changeFtpHostname);
                },
              ),
              SettingsTile(
                title: Text(texts.username),
                description: Text(ftpUsername),
                leading: const Icon(Icons.person),
                onPressed: (BuildContext context) {
                  _editStringSetting(context, 'ftp_username', texts.changeFtpUsername);
                },
              ),
              SettingsTile(
                title: Text(texts.password),
                description: Text('*' * ftpPassword.length),
                leading: const Icon(Icons.lock),
                onPressed: (BuildContext context) {
                  _editStringSetting(context, 'ftp_password', texts.changeFtpPassword,
                      password: true);
                },
              ),
              SettingsTile(
                title: Text(texts.path),
                description: Text(widget.prefs.getString('ftp_path') ?? ''),
                leading: const Icon(Icons.folder),
                onPressed: (BuildContext context) async {
                  final switched = await _onSwitchFtpFolder(context,
                      chooseFolder: true,
                      downloadNow: false,
                      connectNow: true);
                  if (switched) {
                    didSwitchFtpFolder = true;
                    await _loadFtpConfigurations();
                  }
                },
              ),
              SettingsTile.switchTile(
                title: Text(texts.useFtps),
                leading: const Icon(Icons.security),
                initialValue: widget.prefs.getBool('use_ftps') ?? false,
                onToggle: (bool value) async {
                  await updateActiveFtpConfiguration(widget.prefs, useFtps: value);
                  await _loadFtpConfigurations();
                },
              ),
              SettingsTile.switchTile(
                title: Text(texts.useImplicitFtps),
                leading: const Icon(Icons.security),
                initialValue: widget.prefs.getBool('use_implicit_ftps') ?? false,
                onToggle: (bool value) async {
                  await updateActiveFtpConfiguration(widget.prefs,
                      useImplicitFtps: value);
                  await _loadFtpConfigurations();
                },
              ),
              SettingsTile.switchTile(
                title: Text(texts.useSftp),
                leading: const Icon(Icons.security),
                initialValue: widget.prefs.getBool('use_sftp') ?? false,
                onToggle: (bool value) async {
                  await updateActiveFtpConfiguration(widget.prefs, useSftp: value);
                  await _loadFtpConfigurations();
                },
              ),
              SettingsTile(
                title: Text(texts.testFtpConnection),
                leading: const Icon(Icons.wifi_tethering),
                onPressed: (BuildContext context) async {
                  await _testConnection(context);
                },
              ),
            ]),
          ]),
          ),
          if (isLoading) buildLoadingIndicator(),
        ],
      ),
      ),
    );
  }
}
