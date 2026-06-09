import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _ftpConfigurationsKey = 'ftp_configurations';
const _ftpActiveHostnameKey = 'ftp_active_hostname';
const settingsFormatVersion = 2;

class FtpConfiguration {
  const FtpConfiguration({
    required this.hostname,
    this.path = '',
    this.useFtps = false,
    this.useSftp = false,
    this.useImplicitFtps = false,
  });

  final String hostname;
  final String path;
  final bool useFtps;
  final bool useSftp;
  final bool useImplicitFtps;

  FtpConfiguration copyWith({
    String? hostname,
    String? path,
    bool? useFtps,
    bool? useSftp,
    bool? useImplicitFtps,
  }) {
    return FtpConfiguration(
      hostname: hostname ?? this.hostname,
      path: path ?? this.path,
      useFtps: useFtps ?? this.useFtps,
      useSftp: useSftp ?? this.useSftp,
      useImplicitFtps: useImplicitFtps ?? this.useImplicitFtps,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'hostname': hostname,
      'path': path,
      'use_ftps': useFtps,
      'use_sftp': useSftp,
      'use_implicit_ftps': useImplicitFtps,
    };
  }

  static FtpConfiguration fromJson(Map<String, dynamic> map) {
    return FtpConfiguration(
      hostname: (map['hostname'] ?? '').toString(),
      path: (map['path'] ?? '').toString(),
      useFtps: map['use_ftps'] == true,
      useSftp: map['use_sftp'] == true,
      useImplicitFtps: map['use_implicit_ftps'] == true,
    );
  }
}

Future<void> ensureFtpConfigurationsMigrated(SharedPreferences prefs) async {
  final configs = _readConfigurations(prefs);
  if (configs.isNotEmpty) {
    await _ensureActiveAndSyncLegacy(prefs, configs);
    return;
  }

  final legacyHostname = (prefs.getString('ftp_hostname') ?? '').trim();
  if (legacyHostname.isNotEmpty) {
    final migrated = FtpConfiguration(
      hostname: legacyHostname,
      path: prefs.getString('ftp_path') ?? '',
      useFtps: prefs.getBool('use_ftps') ?? false,
      useSftp: prefs.getBool('use_sftp') ?? false,
      useImplicitFtps: prefs.getBool('use_implicit_ftps') ?? false,
    );
    await _writeConfigurations(prefs, [migrated]);
    await prefs.setString(_ftpActiveHostnameKey, migrated.hostname);
    await _migrateLegacyCredentialsToHost(migrated.hostname);
    await _syncLegacyActive(prefs, [migrated], migrated.hostname);
  }
}

Future<List<FtpConfiguration>> getFtpConfigurations(SharedPreferences prefs) async {
  await ensureFtpConfigurationsMigrated(prefs);
  return _readConfigurations(prefs);
}

Future<FtpConfiguration> getActiveFtpConfiguration(SharedPreferences prefs) async {
  await ensureFtpConfigurationsMigrated(prefs);
  final configs = _readConfigurations(prefs);
  if (configs.isEmpty) {
    return const FtpConfiguration(hostname: '');
  }

  final activeHostname = (prefs.getString(_ftpActiveHostnameKey) ?? '').trim();
  final active = configs.where((config) => config.hostname == activeHostname).toList();
  if (active.isNotEmpty) {
    return active.first;
  }

  final fallback = configs.first;
  await prefs.setString(_ftpActiveHostnameKey, fallback.hostname);
  await _syncLegacyActive(prefs, configs, fallback.hostname);
  return fallback;
}

Future<FtpConfiguration?> getFtpConfigurationByHostname(
    SharedPreferences prefs, String hostname) async {
  await ensureFtpConfigurationsMigrated(prefs);
  final normalized = hostname.trim();
  if (normalized.isEmpty) {
    return null;
  }
  for (final config in _readConfigurations(prefs)) {
    if (config.hostname == normalized) {
      return config;
    }
  }
  return null;
}

Future<void> setActiveFtpConfiguration(SharedPreferences prefs, String hostname) async {
  await ensureFtpConfigurationsMigrated(prefs);
  final normalized = hostname.trim();
  if (normalized.isEmpty) {
    return;
  }

  final configs = _readConfigurations(prefs);
  final exists = configs.any((config) => config.hostname == normalized);
  if (!exists) {
    return;
  }

  await prefs.setString(_ftpActiveHostnameKey, normalized);
  await _syncLegacyActive(prefs, configs, normalized);
}

Future<void> upsertFtpConfiguration(
  SharedPreferences prefs,
  FtpConfiguration config, {
  String? username,
  String? password,
  bool setActive = false,
}) async {
  await ensureFtpConfigurationsMigrated(prefs);
  final normalizedHostname = config.hostname.trim();
  if (normalizedHostname.isEmpty) {
    return;
  }

  final configs = _readConfigurations(prefs);
  final next = <FtpConfiguration>[];
  var replaced = false;
  for (final existing in configs) {
    if (existing.hostname == normalizedHostname) {
      next.add(config.copyWith(hostname: normalizedHostname));
      replaced = true;
    } else {
      next.add(existing);
    }
  }
  if (!replaced) {
    next.add(config.copyWith(hostname: normalizedHostname));
  }

  await _writeConfigurations(prefs, next);
  if (username != null) {
    await _writeUsername(normalizedHostname, username);
  }
  if (password != null) {
    await _writePassword(normalizedHostname, password);
  }

  final activeHostname = setActive
      ? normalizedHostname
      : (prefs.getString(_ftpActiveHostnameKey) ?? '').trim();
  if (activeHostname.isEmpty || !next.any((entry) => entry.hostname == activeHostname)) {
    await prefs.setString(_ftpActiveHostnameKey, normalizedHostname);
    await _syncLegacyActive(prefs, next, normalizedHostname);
  } else {
    if (setActive) {
      await prefs.setString(_ftpActiveHostnameKey, normalizedHostname);
    }
    await _syncLegacyActive(
      prefs,
      next,
      setActive ? normalizedHostname : activeHostname,
    );
  }
}

Future<void> renameActiveFtpHostname(SharedPreferences prefs, String newHostname) async {
  await ensureFtpConfigurationsMigrated(prefs);
  final normalizedNew = newHostname.trim();
  if (normalizedNew.isEmpty) {
    return;
  }

  final active = await getActiveFtpConfiguration(prefs);
  if (active.hostname.isEmpty || active.hostname == normalizedNew) {
    if (active.hostname == normalizedNew) {
      return;
    }
    await upsertFtpConfiguration(
      prefs,
      active.copyWith(hostname: normalizedNew),
      setActive: true,
    );
    return;
  }

  final username = await readFtpUsername(active.hostname);
  final password = await readFtpPassword(active.hostname);

  await upsertFtpConfiguration(
    prefs,
    active.copyWith(hostname: normalizedNew),
    username: username,
    password: password,
    setActive: true,
  );

  await _deleteCredentials(active.hostname);

  final configs = _readConfigurations(prefs)
      .where((config) => config.hostname != active.hostname)
      .toList();
  await _writeConfigurations(prefs, configs);
  await _syncLegacyActive(prefs, configs, normalizedNew);
}

Future<void> removeFtpConfiguration(SharedPreferences prefs, String hostname) async {
  await ensureFtpConfigurationsMigrated(prefs);
  final normalized = hostname.trim();
  if (normalized.isEmpty) {
    return;
  }

  final configs = _readConfigurations(prefs);
  final next = configs.where((config) => config.hostname != normalized).toList();
  await _writeConfigurations(prefs, next);
  await _deleteCredentials(normalized);

  final activeHostname = (prefs.getString(_ftpActiveHostnameKey) ?? '').trim();
  if (next.isEmpty) {
    await prefs.remove(_ftpActiveHostnameKey);
    await _clearLegacyActive(prefs);
    return;
  }

  final nextActive = (activeHostname == normalized || activeHostname.isEmpty)
      ? next.first.hostname
      : activeHostname;
  await prefs.setString(_ftpActiveHostnameKey, nextActive);
  await _syncLegacyActive(prefs, next, nextActive);
}

Future<void> updateActiveFtpConfiguration(
  SharedPreferences prefs, {
  String? path,
  bool? useFtps,
  bool? useSftp,
  bool? useImplicitFtps,
}) async {
  final active = await getActiveFtpConfiguration(prefs);
  if (active.hostname.isEmpty) {
    return;
  }

  var normalizedUseFtps = useFtps ?? active.useFtps;
  var normalizedUseSftp = useSftp ?? active.useSftp;
  var normalizedUseImplicitFtps = useImplicitFtps ?? active.useImplicitFtps;

  // If the user explicitly enables one mode, that mode wins and the others
  // are disabled to keep protocol selection mutually exclusive.
  if (useFtps == true) {
    normalizedUseFtps = true;
    normalizedUseSftp = false;
    normalizedUseImplicitFtps = false;
  } else if (useSftp == true) {
    normalizedUseSftp = true;
    normalizedUseFtps = false;
    normalizedUseImplicitFtps = false;
  } else if (useImplicitFtps == true) {
    normalizedUseImplicitFtps = true;
    normalizedUseFtps = false;
    normalizedUseSftp = false;
  } else {
    // Keep legacy values sane when no explicit "enable" action was provided.
    if (normalizedUseFtps) {
      normalizedUseSftp = false;
      normalizedUseImplicitFtps = false;
    } else if (normalizedUseSftp) {
      normalizedUseImplicitFtps = false;
    }
  }

  final next = active.copyWith(
    path: path,
    useFtps: normalizedUseFtps,
    useSftp: normalizedUseSftp,
    useImplicitFtps: normalizedUseImplicitFtps,
  );
  await upsertFtpConfiguration(prefs, next, setActive: true);
}

Future<String> readFtpUsername(String hostname) async {
  final storage = FlutterSecureStorage();
  return await storage.read(key: _usernameKey(hostname)) ?? '';
}

Future<String> readFtpPassword(String hostname) async {
  final storage = FlutterSecureStorage();
  return await storage.read(key: _passwordKey(hostname)) ?? '';
}

Future<String> getActiveFtpUsername(SharedPreferences prefs) async {
  final active = await getActiveFtpConfiguration(prefs);
  if (active.hostname.isEmpty) {
    return '';
  }
  final storage = FlutterSecureStorage();
  final hostUsername = await storage.read(key: _usernameKey(active.hostname));
  if (hostUsername != null) {
    return hostUsername;
  }
  return await storage.read(key: 'ftp_username') ?? '';
}

Future<String> getActiveFtpPassword(SharedPreferences prefs) async {
  final active = await getActiveFtpConfiguration(prefs);
  if (active.hostname.isEmpty) {
    return '';
  }
  final storage = FlutterSecureStorage();
  final hostPassword = await storage.read(key: _passwordKey(active.hostname));
  if (hostPassword != null) {
    return hostPassword;
  }
  return await storage.read(key: 'ftp_password') ?? '';
}

Future<void> setActiveFtpUsername(SharedPreferences prefs, String username) async {
  final active = await getActiveFtpConfiguration(prefs);
  if (active.hostname.isEmpty) {
    return;
  }
  await _writeUsername(active.hostname, username);
  await _syncLegacyActive(prefs, _readConfigurations(prefs), active.hostname);
}

Future<void> setActiveFtpPassword(SharedPreferences prefs, String password) async {
  final active = await getActiveFtpConfiguration(prefs);
  if (active.hostname.isEmpty) {
    return;
  }
  await _writePassword(active.hostname, password);
  await _syncLegacyActive(prefs, _readConfigurations(prefs), active.hostname);
}

Future<void> _ensureActiveAndSyncLegacy(
    SharedPreferences prefs, List<FtpConfiguration> configs) async {
  var activeHostname = (prefs.getString(_ftpActiveHostnameKey) ?? '').trim();
  if (activeHostname.isEmpty || !configs.any((item) => item.hostname == activeHostname)) {
    activeHostname = configs.first.hostname;
    await prefs.setString(_ftpActiveHostnameKey, activeHostname);
  }
  await _migrateLegacyCredentialsToHost(activeHostname);
  await _syncLegacyActive(prefs, configs, activeHostname);
}

Future<void> _syncLegacyActive(
  SharedPreferences prefs,
  List<FtpConfiguration> configs,
  String activeHostname,
) async {
  final active = configs.where((config) => config.hostname == activeHostname).toList();
  if (active.isEmpty) {
    await _clearLegacyActive(prefs);
    return;
  }
  final selected = active.first;
  await prefs.setString('ftp_hostname', selected.hostname);
  await prefs.setString('ftp_path', selected.path);
  await prefs.setBool('use_ftps', selected.useFtps);
  await prefs.setBool('use_sftp', selected.useSftp);
  await prefs.setBool('use_implicit_ftps', selected.useImplicitFtps);

  final storage = FlutterSecureStorage();
  var username = await storage.read(key: _usernameKey(selected.hostname));
  var password = await storage.read(key: _passwordKey(selected.hostname));
  if (username == null) {
    final legacyUsername = await storage.read(key: 'ftp_username') ?? '';
    username = legacyUsername;
    await _writeUsername(selected.hostname, username);
  }
  if (password == null) {
    final legacyPassword = await storage.read(key: 'ftp_password') ?? '';
    password = legacyPassword;
    await _writePassword(selected.hostname, password);
  }

  await storage.write(key: 'ftp_username', value: username);
  await storage.write(key: 'ftp_password', value: password);
}

Future<void> _clearLegacyActive(SharedPreferences prefs) async {
  await prefs.remove('ftp_hostname');
  await prefs.remove('ftp_path');
  await prefs.remove('use_ftps');
  await prefs.remove('use_sftp');
  await prefs.remove('use_implicit_ftps');
  final storage = FlutterSecureStorage();
  await storage.write(key: 'ftp_username', value: '');
  await storage.write(key: 'ftp_password', value: '');
}

List<FtpConfiguration> _readConfigurations(SharedPreferences prefs) {
  final jsonValue = prefs.getString(_ftpConfigurationsKey);
  if (jsonValue == null || jsonValue.isEmpty) {
    return <FtpConfiguration>[];
  }

  try {
    final decoded = json.decode(jsonValue);
    if (decoded is! List) {
      return <FtpConfiguration>[];
    }

    final configs = <FtpConfiguration>[];
    for (final item in decoded) {
      if (item is Map) {
        final config = FtpConfiguration.fromJson(Map<String, dynamic>.from(item));
        if (config.hostname.trim().isNotEmpty) {
          configs.add(config.copyWith(hostname: config.hostname.trim()));
        }
      }
    }

    configs.sort((a, b) => a.hostname.toLowerCase().compareTo(b.hostname.toLowerCase()));
    return configs;
  } catch (_) {
    return <FtpConfiguration>[];
  }
}

Future<void> _writeConfigurations(
    SharedPreferences prefs, List<FtpConfiguration> configs) async {
  final payload = configs
      .where((config) => config.hostname.trim().isNotEmpty)
      .map((config) => config.copyWith(hostname: config.hostname.trim()).toJson())
      .toList();
  await prefs.setString(_ftpConfigurationsKey, json.encode(payload));
}

String _usernameKey(String hostname) => 'ftp_username::${hostname.trim()}';
String _passwordKey(String hostname) => 'ftp_password::${hostname.trim()}';

Future<void> _writeUsername(String hostname, String username) async {
  final storage = FlutterSecureStorage();
  await storage.write(key: _usernameKey(hostname), value: username);
}

Future<void> _writePassword(String hostname, String password) async {
  final storage = FlutterSecureStorage();
  await storage.write(key: _passwordKey(hostname), value: password);
}

Future<void> _deleteCredentials(String hostname) async {
  final storage = FlutterSecureStorage();
  await storage.delete(key: _usernameKey(hostname));
  await storage.delete(key: _passwordKey(hostname));
}

Future<void> _migrateLegacyCredentialsToHost(String hostname) async {
  final normalized = hostname.trim();
  if (normalized.isEmpty) {
    return;
  }

  final storage = FlutterSecureStorage();
  final legacyUsername = await storage.read(key: 'ftp_username') ?? '';
  final legacyPassword = await storage.read(key: 'ftp_password') ?? '';
  final hostUsername = await storage.read(key: _usernameKey(normalized)) ?? '';
  final hostPassword = await storage.read(key: _passwordKey(normalized)) ?? '';

  if (hostUsername.isEmpty && legacyUsername.isNotEmpty) {
    await storage.write(key: _usernameKey(normalized), value: legacyUsername);
  }
  if (hostPassword.isEmpty && legacyPassword.isNotEmpty) {
    await storage.write(key: _passwordKey(normalized), value: legacyPassword);
  }
}

Future<Map<String, dynamic>> buildFtpExportSettings(
    SharedPreferences prefs) async {
  await ensureFtpConfigurationsMigrated(prefs);
  final configs = await getFtpConfigurations(prefs);
  final active = await getActiveFtpConfiguration(prefs);

  final serializedConfigs = <Map<String, dynamic>>[];
  for (final config in configs) {
    serializedConfigs.add({
      'hostname': config.hostname,
      'path': config.path,
      'use_ftps': config.useFtps,
      'use_sftp': config.useSftp,
      'use_implicit_ftps': config.useImplicitFtps,
      'ftp_username': await readFtpUsername(config.hostname),
      'ftp_password': await readFtpPassword(config.hostname),
    });
  }

  return {
    'settings_format_version': settingsFormatVersion,
    'ftp_configurations': serializedConfigs,
    'ftp_active_hostname': active.hostname,
    'ftp_hostname': active.hostname,
    'ftp_path': active.path,
    'use_ftps': active.useFtps,
    'use_sftp': active.useSftp,
    'use_implicit_ftps': active.useImplicitFtps,
    'ftp_username': await getActiveFtpUsername(prefs),
    'ftp_password': await getActiveFtpPassword(prefs),
  };
}
