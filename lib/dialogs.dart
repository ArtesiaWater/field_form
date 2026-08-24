import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'l10n/app_localizations.dart';

final _infoMessageNotifier = ValueNotifier<String>('');
ScaffoldFeatureController<SnackBar, SnackBarClosedReason>? _infoSnackBarController;
Timer? _infoSnackBarHideTimer;

void showLoaderDialog(BuildContext context, {String text = 'Loading...'}) {
  showDialog(
    barrierDismissible: false,
    context: context,
    builder: (BuildContext context) {
      return buildLoadingIndicator(text: text);
    },
  );
}

AlertDialog buildLoadingIndicator({String text = 'Loading...'}) {
  return AlertDialog(
    content: Row(
      children: [
        CircularProgressIndicator(),
        Container(margin: EdgeInsets.only(left: 7), child: Text(text)),
      ],
    ),
  );
}

void showErrorDialog(BuildContext context, String text,
    {String? title, String? hiddenDetails}) {
  final texts = AppLocalizations.of(context);
  var showDetails = false;
  showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final hasHiddenDetails = (hiddenDetails?.trim().isNotEmpty ?? false);
            final detailsText = hiddenDetails ?? '';
            return AlertDialog(
              title: Text(title ?? texts?.error ?? 'Error'),
              content: SingleChildScrollView(
                child: ListBody(
                  children: <Widget>[
                    Text(text),
                    if (showDetails && hasHiddenDetails)
                      const SizedBox(height: 12),
                    if (showDetails && hasHiddenDetails)
                      SelectableText(detailsText),
                  ],
                ),
              ),
              actions: <Widget>[
                if (!showDetails && hasHiddenDetails)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        showDetails = true;
                      });
                    },
                    child: const Text('Meer info'),
                  ),
                if (showDetails && hasHiddenDetails)
                  TextButton(
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: detailsText));
                      if (context.mounted) {
                        displayInformation(context, 'Diagnostic details copied');
                      }
                    },
                    child: const Text('Copy details'),
                  ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text(texts?.ok ?? 'Ok'),
                ),
              ],
            );
          },
        );
      });
}

Future<bool?> showContinueDialog(BuildContext context, String text,
    {String? title,
    String? yesButton,
    String? noButton}) async {
  final texts = AppLocalizations.of(context);
  // show the dialog
  var action = await showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(title ?? texts?.continueQuestion ?? 'Continue?'),
        content: Text(text),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(false);
            },
            child: Text(noButton ?? texts?.cancel ?? 'Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(true);
            },
            child: Text(yesButton ?? texts?.continueAction ?? 'Continue'),
          ),
        ],
      );
    },
  );
  return action;
}

Future<String?> showInputDialog(BuildContext context,
    {String? title,
    String? text,
    String? yesButton,
    String? noButton,
    String? initialValue,
    String type = 'text',
    bool selectInitialValue = true}) async {
  final texts = AppLocalizations.of(context);
  final controller = TextEditingController();
  if (initialValue != null) {
    controller.value = TextEditingValue(
      text: initialValue,
      selection: selectInitialValue
          ? TextSelection(baseOffset: 0, extentOffset: initialValue.length)
          : TextSelection.collapsed(offset: initialValue.length),
    );
  }

  var keyboardType;
  var inputFormatters;
  if (type == 'integer') {
    keyboardType = TextInputType.number;
    inputFormatters = <TextInputFormatter>[
      FilteringTextInputFormatter.digitsOnly
    ];
  }
  // show the dialog
  var action = await showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(title ?? texts?.input ?? 'Input'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (text != null) Text(text),
            TextFormField(
              controller: controller,
              autofocus: true,
              keyboardType: keyboardType,
              inputFormatters: inputFormatters,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(null);
            },
            child: Text(noButton ?? texts?.cancel ?? 'Cancel'),
          ),
          TextButton(
            onPressed: () {
              final id = controller.text;
              Navigator.of(context).pop(id);
            },
            child: Text(yesButton ?? texts?.ok ?? 'Ok'),
          ),
        ],
      );
    },
  );
  return action;
}

void displayInformation(context, text) {
  final message = text.toString();
  if (message.trim().isEmpty) {
    return;
  }

  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) {
    return;
  }

  _infoMessageNotifier.value = message;

  if (_infoSnackBarController == null) {
    _infoSnackBarController = messenger.showSnackBar(
      SnackBar(
        duration: const Duration(days: 1),
        content: ValueListenableBuilder<String>(
          valueListenable: _infoMessageNotifier,
          builder: (context, value, _) {
            return Text(value);
          },
        ),
      ),
    );
    _infoSnackBarController!.closed.then((_) {
      _infoSnackBarController = null;
      _infoSnackBarHideTimer?.cancel();
      _infoSnackBarHideTimer = null;
    });
  }

  _infoSnackBarHideTimer?.cancel();
  _infoSnackBarHideTimer = Timer(const Duration(seconds: 2), () {
    messenger.hideCurrentSnackBar();
  });
}

class MultiSelectDialogItem<V> {
  MultiSelectDialogItem(this.value, this.label, [this.icon]);

  final V value;
  final String label;
  final Icon? icon;
}

class MultiSelectDialog<V> extends StatefulWidget {
  MultiSelectDialog(
      {required this.items,
      this.initialSelectedValues,
  this.title,
      this.selectNone,
      this.selectAll,
  this.ok,
  this.cancel});

  final List<MultiSelectDialogItem<V>> items;
  final Set<V>? initialSelectedValues;
  final String? title;
  final String? selectNone;
  final String? selectAll;
  final String? ok;
  final String? cancel;

  @override
  State<StatefulWidget> createState() => _MultiSelectDialogState<V>();
}

class _MultiSelectDialogState<V> extends State<MultiSelectDialog<V>> {
  final _selectedValues = <V>{};

  @override
  void initState() {
    super.initState();
    if (widget.initialSelectedValues != null) {
      _selectedValues.addAll(widget.initialSelectedValues!);
    }
  }

  void _onItemCheckedChange(V itemValue, bool checked) {
    setState(() {
      if (checked) {
        _selectedValues.add(itemValue);
      } else {
        _selectedValues.remove(itemValue);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final texts = AppLocalizations.of(context);
    final title = widget.title ?? texts?.select ?? 'Select';
    final ok = widget.ok ?? texts?.ok ?? 'Ok';
    final cancel = widget.cancel ?? texts?.cancel ?? 'Cancel';
    var actions = <Widget>[];
    if (widget.selectNone != null && widget.selectAll != null) {
      var extra_actions = <Widget>[];
      if (widget.selectNone != null) {
        extra_actions.add(TextButton(
          onPressed: () {
            setState(() {
              _selectedValues.clear();
            });
          },
          child: Text(widget.selectNone!),
        ));
      }
      if (widget.selectAll != null) {
        extra_actions.add(TextButton(
          onPressed: () {
            setState(() {
              _selectedValues.clear();
              for (var widget in widget.items) {
                _selectedValues.add(widget.value);
              }
            });
          },
          child: Text(widget.selectAll!),
        ));
      }

      actions.add(Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: extra_actions));
    }
    actions
        .add(Row(mainAxisAlignment: MainAxisAlignment.end, children: <Widget>[
      TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: Text(cancel)),
      TextButton(
        onPressed: () {
          Navigator.pop(context, _selectedValues);
        },
        child: Text(ok),
      )
    ]));
    return AlertDialog(
      title: Text(title),
      contentPadding: EdgeInsets.only(top: 12.0),
      content: SingleChildScrollView(
        child: ListTileTheme(
          contentPadding: EdgeInsets.fromLTRB(14.0, 0.0, 24.0, 0.0),
          child: ListBody(
            children: widget.items.map(_buildItem).toList(),
          ),
        ),
      ),
      actions: actions,
    );
  }

  Widget _buildItem(MultiSelectDialogItem<V> item) {
    final checked = _selectedValues.contains(item.value);
    return CheckboxListTile(
      value: checked,
      title: Text(item.label),
      secondary: item.icon,
      controlAffinity: ListTileControlAffinity.leading,
      onChanged: (checked) => _onItemCheckedChange(item.value, checked!),
    );
  }
}

List<DropdownMenuItem<String>> getDropdownMenuItems(options,
    {add_empty = false}) {
  var items = <DropdownMenuItem<String>>[];
  if (add_empty) {
    // add an empty value
    items.add(DropdownMenuItem(
      value: '',
      child: Text(''),
    ));
  }
  for (var option in options) {
    items.add(
      DropdownMenuItem(
        value: option,
        child: Text(option),
      ),
    );
  }
  return items;
}

Future<int?> chooseMeasuredInterval(
    BuildContext context, SharedPreferences prefs, texts) async {
  final mark_measured_days = prefs.getInt('mark_measured_days') ?? 0;
  var options = <Widget>[];
  var fixed_intervals = [0, 1, 7, 30, 365];
  for (var interval in fixed_intervals) {
    final icon;
    if (interval == mark_measured_days) {
      icon = Icon(Icons.check_box_outlined);
    } else {
      icon = Icon(Icons.check_box_outline_blank);
    }
    final text = interval == 0
        ? texts.doNotMarkMeasuredLocations
        : texts.withinIntervalDays(interval);
    options.add(SimpleDialogOption(
        onPressed: () {
          Navigator.of(context).pop(interval);
        },
        child: Row(children: [
          icon,
          SizedBox(width: 10),
          Text(text),
        ])));
  }
  var text = texts.other;
  if (!fixed_intervals.contains(mark_measured_days)) {
    text = text + " (" + mark_measured_days.toString() + ")";
  }
  options.add(SimpleDialogOption(
      onPressed: () async {
        String? interval = await showInputDialog(context,
            title: texts.specifyInterval,
            type: "integer",
            initialValue: mark_measured_days.toString());
        if (interval != null && interval.isNotEmpty) {
          Navigator.of(context).pop(int.parse(interval));
        }
      },
      child: Row(children: [
        Icon(Icons.keyboard_outlined),
        SizedBox(width: 10),
        Text(text), // texts.customInterval
      ])));

  var interval = await showDialog(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: Text(texts.markMeasuredLocations),
          children: options,
        );
      });
  return interval;
}

Future<String?> editStringSettingDialog(
    BuildContext context, String key, String title, prefs, texts,
    {bool password = false, String default_value = ''}) async {
  var settingValue;
  if (key == "ftp_username" || key == "ftp_password") {
    final secure_storage = new FlutterSecureStorage();
    settingValue = await secure_storage.read(key: key) ?? default_value;
  } else {
    settingValue = prefs.getString(key) ?? default_value;
  }

  return showDialog(
      context: context,
      builder: (context) {
        var textEditingController = TextEditingController();
        textEditingController.value = TextEditingValue(
          text: settingValue,
          selection: TextSelection(
            baseOffset: 0,
            extentOffset: settingValue.length,
          ),
        );
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: textEditingController,
            onChanged: (value) {
              settingValue = value;
            },
            autofocus: true,
            obscureText: password,
            autocorrect: false,
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
                Navigator.pop(context, settingValue);
              },
              child: Text(texts.ok),
            ),
          ],
        );
      });
}
