# FieldForm

Perform location-bound measurements in the field

On Android:
https://play.google.com/store/apps/details?id=nl.artesia.field_form

On iOS:
https://apps.apple.com/bg/app/fieldform/id1571910702

## Getting Started

Use FieldForm to conduct location-bound measurements in the field, store the values on your phone, and share the measurements with other people. To use FieldForm for a set of locations with multiple people simultaneously, the use of an FTP-server is recommended.

FieldForm is the successor to FieldLogger. It is build platform-independent in Flutter, so there are no differences anymore in functionality between the Android- and iOS-app. The new structure makes it easier to add functionality or fix bugs. FieldForm is now completely open source.

## For FieldLogger-users
There are some important changes between the files used or generated by FieldLogger and FieldForm. The file with location-data is a json file (instead of a csv in FieldLogger), to better incorporate the nested structure of the location-data. The measurement-data still consists of csv-files. The date-format however is changed to yyyy-mm-dd (instead of dd-mm-yyyy in FieldLogger), to minimise potential errors.

## For Developers
This repository holds the source code of FieldForm, with which the app can be built using Android Studio (and Xcode for iOS). Because of security concerns the signing keys are not added to this repository, so only specific developers are able to update the app in the Play Store and App Store. The source code can be used by any developer to test the app, or to release an app with another name.

Also, the Google Maps api-key is not contained in the repository. When building the app, the Google Maps api-key is taken from an environmental variable named 'maps_api_key', defined in the operating system that builds the app. To get a working Google Maps, a developer should therefore request an api-key at Google, and add this environmental variable.

## Files
Currenly FieldForm uses two types of files: location- and measurement-files. Measurements are stored using a location-id. This id is the **location-id** (when no sublocations are used) or the **sublocation-id**. It is important that these id's are **unique strings**, which is not checked by FieldForm (yet).

### Location File
A location file contains the data of the locations, locations-groups, inputfields and settings. The location file is a json-file, of which the structure is described below, in simplified Dart-Code. Each field is preceded by the variable-type. When a variable is optional, which is the case for most variables, this type is followed by a question-mark. A short description follows the colon after the variable-name.
* Map<String, String>? settings: settings can be specified by key-value pairs.
* Map<String, InputField>? inputfields: specified in a map with inputfield-id's as keys.
* Map<String, InputFieldGroup>? inputfield_groups: specified in a map with inputfield-id's as keys (form version 1.1.5).
* Map<String, Group>? groups: specified in a map with group-id's as keys.
* Map<String, Location>? locations: specified in a map with location-id's as keys.

where:

**InputField**:
* String type: the type, must be 'number', 'text', 'choice', 'multichoice', 'photo', 'check', 'date', 'time' or 'datetime'.
* String? hint: the hint to display in the inputfield.
* String? name: the name to display, use inputfield-id when null.
* List<String>? options: the options between which the user can choose when type='choice' or type='multichoice'.
* String? default_value: the default value for an inputfield, only supported for type='choice'.

**InputFieldGroup**:
* List<String> inputfields: a list of inputfield-ids that belong to this group.
* String? name: the name to display, use inputfield_group-id when null.

**Group**:
* String? name: the name to display, use group-id when null.
* String? color: the color of the marker of the locations in the group (see color in Location).
* List<String>? inputfields: a list of inputfield-ids to be measured at the locations of the group (trumped by the inputfields of each location).

**Location**:
* double? lat: the longitude of the location.
* double? lon: the latitude of the location.
* String? name: the name to display, use location-id when null.
* List<String>? inputfields: a list of inputfield-ids to be measured at this location.
* Map<String, dynamic>? properties: a map of locations properties, displayed after pressing the i-button.
* final String? photo: the file-name of a photo. This can be a jpg-, png- or pdf-file.
* final Map<String, Location>? sublocations: sublocations, specified in a map with location-id's as keys.
* String? group: the group-id that a location belongs to.
* String? color: The color of the marker on the map. Can be 'red', 'orange', 'yellow', 'green', 'cyan', 'azure', 'blue', 'violet', 'margenta' or 'rose'. The color can also be a hex-string, like '#0000FF' (blue) or '#FFFF00' (yellow). As these colors are converted to a hue-value to transform the original Google Maps marker, '#000000' (black) or '#FFFFFF' (white) do not give the expected result.

An example of the contents of a location file without settings or inputfield-groups, but with inputfields, groups, locations and sublocations is:
```json
{
  "settings": {
    "use_standard_time": "YES"
  },
  "inputfields": {
    "value": {
      "type": "number"
    },
    "comment": {
      "type": "text",
      "hint": "place a comment"
    },
    "reliable": {
      "type": "choice",
      "hint": "is this measurement reliable?",
      "options": [
        "yes",
        "no"
      ]
    },
    "photo": {
      "type": "photo",
      "hint": "take a picture"
    }
  },
  "groups": {
    "group_1": {
      "name": "Group 1",
      "color": "orange"
    },
    "group_2": {
      "name": "Group 2",
      "color": "blue"
    }
  },
  "locations": {
    "location_1": {
      "lat": 51.9,
      "lon": 6.5,
      "group": "group_1",
      "sublocations": {
        "loc_1_1": {
          "inputfields": [
            "value",
            "reliable",
            "comment"
          ],
          "photo": "loc_1.png",
          "properties": {
            "surface level": "20.74",
            "filter level": 18.64
          }
        },
        "loc_1_2": {
          "inputfields": [
            "value",
            "reliable",
            "comment"
          ],
          "photo": "loc_1.png",
          "properties": {
            "surface level": "20.74",
            "filter level": 10.0
          }
        }
      }
    },
    "location_2": {
      "lat": 52.1,
      "lon": 6.3,
      "group": "group_2",
      "sublocations": {
        "loc_2_1": {
          "inputfields": [
            "value",
            "photo"
          ],
          "photo": "loc_2.pdf",
          "properties": {
            "surface level": "10.41",
            "filter level": 8.26
          }
        }
      }
    }
  }
}
```

Possible keys for the settings are:
* 'use_standard_time' (boolean)
* 'wms_on' (boolean)
* 'wms_url' (string)
* 'wms_layers' (string, use , to separate layers)
* 'photo_resolution' (string, possible values: 'low', 'medium', 'high', 'veryHigh', 'ultraHigh' and 'max')
* 'ftp_hostname' (string, optionally use / behind the hostname to separate folders and to specify the ftp-root)
* 'ftp_username' (string)
* 'ftp_password' (string)
* 'ftp_path' (string)
* 'use_ftps' (boolean)
* 'use_sftp' (boolean)
* 'only_export_new_data' (boolean)
* 'show_previous_and_next_location' (boolean)
* 'request_user' (boolean)
* 'add_user_to_measurements' (boolean)
* 'user_inputfield' (string)
* 'user' (string)
* 'mark_measured_days' (integer)
* 'mark_not_measured' (boolean)
* 'hide_settings' (boolean)

Boolean settings will be either true or false. To set a setting to true, use a string like 'yes', 'Yes', 'true' or 'True'. Otherwise the setting will be set to false.

### Measurement File
A measurement-file contains measurements performed by the user or other users. The measurement-file is a ';'-delimited csv-file with the header LOCATION;DATE;TIME;TYPE;VALUE.
* LOCATION: The location- or sublocation-id
* DATE: the date in yyyy-mm-dd notation
* TIME: the time in HH:MM:SS notation
* TYPE: the inputfield-id
* VALUE: the value of the measurement
