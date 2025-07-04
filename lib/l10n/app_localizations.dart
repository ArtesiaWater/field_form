import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_nl.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('nl')
  ];

  /// No description provided for @map.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get map;

  /// No description provided for @chooseMaptype.
  ///
  /// In en, this message translates to:
  /// **'Choose a maptype'**
  String get chooseMaptype;

  /// No description provided for @loadingMap.
  ///
  /// In en, this message translates to:
  /// **'loading map..'**
  String get loadingMap;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @fieldForm.
  ///
  /// In en, this message translates to:
  /// **'FieldForm'**
  String get fieldForm;

  /// No description provided for @menu.
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get menu;

  /// No description provided for @addDataFromFile.
  ///
  /// In en, this message translates to:
  /// **'Add data from file'**
  String get addDataFromFile;

  /// No description provided for @shareData.
  ///
  /// In en, this message translates to:
  /// **'Share data'**
  String get shareData;

  /// No description provided for @changeFtpFolder.
  ///
  /// In en, this message translates to:
  /// **'Change FTP Folder'**
  String get changeFtpFolder;

  /// No description provided for @chooseGroups.
  ///
  /// In en, this message translates to:
  /// **'Choose groups'**
  String get chooseGroups;

  /// No description provided for @selectGroups.
  ///
  /// In en, this message translates to:
  /// **'Select groups'**
  String get selectGroups;

  /// No description provided for @selectAll.
  ///
  /// In en, this message translates to:
  /// **'Select all'**
  String get selectAll;

  /// No description provided for @selectNone.
  ///
  /// In en, this message translates to:
  /// **'Select none'**
  String get selectNone;

  /// No description provided for @deleteAllData.
  ///
  /// In en, this message translates to:
  /// **'Delete data from phone'**
  String get deleteAllData;

  /// No description provided for @sureToDeleteData.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you wish to delete all data from your phone?'**
  String get sureToDeleteData;

  /// No description provided for @unsentMeasurementsTitle.
  ///
  /// In en, this message translates to:
  /// **'First send measurements?'**
  String get unsentMeasurementsTitle;

  /// No description provided for @unsentMeasurements.
  ///
  /// In en, this message translates to:
  /// **'There are still unsent measurements. Are you really sure you want to delete all data?'**
  String get unsentMeasurements;

  /// No description provided for @uploadUnsentMeasurements.
  ///
  /// In en, this message translates to:
  /// **'There are unsent measurements. Do you want to upload these first? Otherwise they will be lost.'**
  String get uploadUnsentMeasurements;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @markMeasuredLocations.
  ///
  /// In en, this message translates to:
  /// **'Mark measured locations'**
  String get markMeasuredLocations;

  /// No description provided for @doNotMarkMeasuredLocations.
  ///
  /// In en, this message translates to:
  /// **'Do not mark measured locations'**
  String get doNotMarkMeasuredLocations;

  /// No description provided for @withinIntervalDays.
  ///
  /// In en, this message translates to:
  /// **'Within {interval} days'**
  String withinIntervalDays(num interval);

  /// No description provided for @specifyInterval.
  ///
  /// In en, this message translates to:
  /// **'Specify a different number of days'**
  String get specifyInterval;

  /// No description provided for @other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get other;

  /// No description provided for @markNotMeasured.
  ///
  /// In en, this message translates to:
  /// **'Mark locations without measurements'**
  String get markNotMeasured;

  /// No description provided for @addNewLocation.
  ///
  /// In en, this message translates to:
  /// **'Add a new location'**
  String get addNewLocation;

  /// No description provided for @chooseSublocation.
  ///
  /// In en, this message translates to:
  /// **'Choose a sublocation'**
  String get chooseSublocation;

  /// No description provided for @locsOrMeasTitle.
  ///
  /// In en, this message translates to:
  /// **'Locations or measurements'**
  String get locsOrMeasTitle;

  /// No description provided for @locsOrMeas.
  ///
  /// In en, this message translates to:
  /// **'Does this file contain locations or measurements?'**
  String get locsOrMeas;

  /// No description provided for @locations.
  ///
  /// In en, this message translates to:
  /// **'Locations'**
  String get locations;

  /// No description provided for @measurements.
  ///
  /// In en, this message translates to:
  /// **'Measurements'**
  String get measurements;

  /// No description provided for @removeExistingLocationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Import of locations removes existing locations'**
  String get removeExistingLocationsTitle;

  /// No description provided for @removeExistingLocations.
  ///
  /// In en, this message translates to:
  /// **'Importing new locations will remove all existing locations. Do you want to continue?'**
  String get removeExistingLocations;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @importFailed.
  ///
  /// In en, this message translates to:
  /// **'Import failed'**
  String get importFailed;

  /// No description provided for @csvNotImplemented.
  ///
  /// In en, this message translates to:
  /// **'csv-location files not implemented (yet). Use json-files for location-data'**
  String get csvNotImplemented;

  /// No description provided for @unknownFileExtension.
  ///
  /// In en, this message translates to:
  /// **'Unknown file-extension. Location-data has to be supplied in a json-file.'**
  String get unknownFileExtension;

  /// No description provided for @syncCompleted.
  ///
  /// In en, this message translates to:
  /// **'Synchronisation complete'**
  String get syncCompleted;

  /// No description provided for @sendingMeasurements.
  ///
  /// In en, this message translates to:
  /// **'Sending measurements'**
  String get sendingMeasurements;

  /// No description provided for @uploadMeasurementsFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to upload measurements'**
  String get uploadMeasurementsFailed;

  /// No description provided for @retreivingFiles.
  ///
  /// In en, this message translates to:
  /// **'Requesting file list'**
  String get retreivingFiles;

  /// No description provided for @retreivedFiles.
  ///
  /// In en, this message translates to:
  /// **'Retrieved file list'**
  String get retreivedFiles;

  /// No description provided for @downloading.
  ///
  /// In en, this message translates to:
  /// **'Downloading '**
  String get downloading;

  /// No description provided for @downloadFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to download '**
  String get downloadFailed;

  /// No description provided for @noDataToShare.
  ///
  /// In en, this message translates to:
  /// **'There is no data to share'**
  String get noDataToShare;

  /// No description provided for @uploadPhotoFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to upload photo: '**
  String get uploadPhotoFailed;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @previousMeasurements.
  ///
  /// In en, this message translates to:
  /// **'Previous measurements:'**
  String get previousMeasurements;

  /// No description provided for @sureToDeleteMeasurement.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete {value} of type {id}?'**
  String sureToDeleteMeasurement(String value, String id);

  /// No description provided for @sureToDeleteMeasurementsAt.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete the measurements at {datetime}?'**
  String sureToDeleteMeasurementsAt(String datetime);

  /// No description provided for @sureToDeleteMeasurementTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete measurement?'**
  String get sureToDeleteMeasurementTitle;

  /// No description provided for @sureToDeleteMeasurementsTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete measurements?'**
  String get sureToDeleteMeasurementsTitle;

  /// No description provided for @isNotValidNumber.
  ///
  /// In en, this message translates to:
  /// **' is not a valid number'**
  String get isNotValidNumber;

  /// No description provided for @ignoreFilledValues.
  ///
  /// In en, this message translates to:
  /// **'All entered values will be deleted when leaving this location. Do you still want to leave?'**
  String get ignoreFilledValues;

  /// No description provided for @ignoreFilledValuesTitle.
  ///
  /// In en, this message translates to:
  /// **'Leave without saving?'**
  String get ignoreFilledValuesTitle;

  /// No description provided for @imageNotSupported.
  ///
  /// In en, this message translates to:
  /// **': this file is not supported. Only jpg, png and pdf are supported'**
  String get imageNotSupported;

  /// No description provided for @connectToFtpFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to connect to FTP-server'**
  String get connectToFtpFailed;

  /// No description provided for @authenticationError.
  ///
  /// In en, this message translates to:
  /// **'Authentication on FTP-server failed. Set a valid username and password, or extend your access session.'**
  String get authenticationError;

  /// No description provided for @unableToFindOnFtp.
  ///
  /// In en, this message translates to:
  /// **'Unable to find the file on FTP-server: '**
  String get unableToFindOnFtp;

  /// No description provided for @unableToFindPathOnFtp.
  ///
  /// In en, this message translates to:
  /// **'Unable to find path on FTP-server: '**
  String get unableToFindPathOnFtp;

  /// No description provided for @noHostnameDefined.
  ///
  /// In en, this message translates to:
  /// **'No hostname defined. Please assign a hostname in the settings'**
  String get noHostnameDefined;

  /// No description provided for @connected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get connected;

  /// No description provided for @chooseAFolder.
  ///
  /// In en, this message translates to:
  /// **'Choose a folder'**
  String get chooseAFolder;

  /// No description provided for @removePhotoTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove photo'**
  String get removePhotoTitle;

  /// No description provided for @editInputFields.
  ///
  /// In en, this message translates to:
  /// **'Edit input fields'**
  String get editInputFields;

  /// No description provided for @useStandardTime.
  ///
  /// In en, this message translates to:
  /// **'Use standard time'**
  String get useStandardTime;

  /// No description provided for @useStandardTimeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'When true, disable daylight saving time'**
  String get useStandardTimeSubtitle;

  /// No description provided for @wms.
  ///
  /// In en, this message translates to:
  /// **'WMS'**
  String get wms;

  /// No description provided for @addWms.
  ///
  /// In en, this message translates to:
  /// **'Add a WMS to the map'**
  String get addWms;

  /// No description provided for @wmsUrl.
  ///
  /// In en, this message translates to:
  /// **'WMS url'**
  String get wmsUrl;

  /// No description provided for @changeWmsUrl.
  ///
  /// In en, this message translates to:
  /// **'Change WMS url'**
  String get changeWmsUrl;

  /// No description provided for @wmsLayers.
  ///
  /// In en, this message translates to:
  /// **'WMS layers'**
  String get wmsLayers;

  /// No description provided for @changeWmsLayers.
  ///
  /// In en, this message translates to:
  /// **'Change WMS layers'**
  String get changeWmsLayers;

  /// No description provided for @ftp.
  ///
  /// In en, this message translates to:
  /// **'FTP'**
  String get ftp;

  /// No description provided for @hostname.
  ///
  /// In en, this message translates to:
  /// **'Hostname'**
  String get hostname;

  /// No description provided for @changeFtpHostname.
  ///
  /// In en, this message translates to:
  /// **'Change FTP hostname (use / to specify folders)'**
  String get changeFtpHostname;

  /// No description provided for @username.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get username;

  /// No description provided for @changeFtpUsername.
  ///
  /// In en, this message translates to:
  /// **'Change FTP username'**
  String get changeFtpUsername;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @changeFtpPassword.
  ///
  /// In en, this message translates to:
  /// **'Change FTP password'**
  String get changeFtpPassword;

  /// No description provided for @rootFolder.
  ///
  /// In en, this message translates to:
  /// **'Root folder'**
  String get rootFolder;

  /// No description provided for @changeFtpRoot.
  ///
  /// In en, this message translates to:
  /// **'Change FTP root (use / to separate folders)'**
  String get changeFtpRoot;

  /// No description provided for @addUserToMeasurements.
  ///
  /// In en, this message translates to:
  /// **'Add user to each measurement'**
  String get addUserToMeasurements;

  /// No description provided for @user.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get user;

  /// No description provided for @setUser.
  ///
  /// In en, this message translates to:
  /// **'Please provide your name'**
  String get setUser;

  /// No description provided for @userInputfield.
  ///
  /// In en, this message translates to:
  /// **'Name of inputfield for user'**
  String get userInputfield;

  /// No description provided for @changeUserInputfield.
  ///
  /// In en, this message translates to:
  /// **'Change name of inputfield for user'**
  String get changeUserInputfield;

  /// No description provided for @path.
  ///
  /// In en, this message translates to:
  /// **'Path'**
  String get path;

  /// No description provided for @onlyExportNewMeasurements.
  ///
  /// In en, this message translates to:
  /// **'Only export new measurements'**
  String get onlyExportNewMeasurements;

  /// No description provided for @uploadDataInstantly.
  ///
  /// In en, this message translates to:
  /// **'Upload measurements instantly'**
  String get uploadDataInstantly;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'Ok'**
  String get ok;

  /// No description provided for @input.
  ///
  /// In en, this message translates to:
  /// **'Input'**
  String get input;

  /// No description provided for @useFtps.
  ///
  /// In en, this message translates to:
  /// **'Use FTPS'**
  String get useFtps;

  /// No description provided for @useSftp.
  ///
  /// In en, this message translates to:
  /// **'Use SFTP'**
  String get useSftp;

  /// No description provided for @useImplicitFtps.
  ///
  /// In en, this message translates to:
  /// **'Use implicit FTPS'**
  String get useImplicitFtps;

  /// No description provided for @deleteInputField.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this input field?'**
  String get deleteInputField;

  /// No description provided for @deleteOption.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this option?'**
  String get deleteOption;

  /// No description provided for @inputFields.
  ///
  /// In en, this message translates to:
  /// **'Input fields'**
  String get inputFields;

  /// No description provided for @supplyInputFieldId.
  ///
  /// In en, this message translates to:
  /// **'Please supply the id of the input field.'**
  String get supplyInputFieldId;

  /// No description provided for @inputFieldIdExists.
  ///
  /// In en, this message translates to:
  /// **': this id already exists. Please enter another id for this input field.'**
  String get inputFieldIdExists;

  /// No description provided for @chooseId.
  ///
  /// In en, this message translates to:
  /// **'Choose id'**
  String get chooseId;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @anOptionalName.
  ///
  /// In en, this message translates to:
  /// **'An optional name'**
  String get anOptionalName;

  /// No description provided for @type.
  ///
  /// In en, this message translates to:
  /// **'type'**
  String get type;

  /// No description provided for @options.
  ///
  /// In en, this message translates to:
  /// **'Options'**
  String get options;

  /// No description provided for @tapToAddOptions.
  ///
  /// In en, this message translates to:
  /// **'Tap to add options'**
  String get tapToAddOptions;

  /// No description provided for @hint.
  ///
  /// In en, this message translates to:
  /// **'hint'**
  String get hint;

  /// No description provided for @anOptionalHint.
  ///
  /// In en, this message translates to:
  /// **'An optional hint'**
  String get anOptionalHint;

  /// No description provided for @newLocation.
  ///
  /// In en, this message translates to:
  /// **'New Location'**
  String get newLocation;

  /// No description provided for @specifyUniqueId.
  ///
  /// In en, this message translates to:
  /// **'Please specify a unique id'**
  String get specifyUniqueId;

  /// No description provided for @anOptionalGroup.
  ///
  /// In en, this message translates to:
  /// **'An optional group'**
  String get anOptionalGroup;

  /// No description provided for @group_optional.
  ///
  /// In en, this message translates to:
  /// **'Group (optional)'**
  String get group_optional;

  /// No description provided for @noGroupName.
  ///
  /// In en, this message translates to:
  /// **'Without a group'**
  String get noGroupName;

  /// No description provided for @inputfields_optional.
  ///
  /// In en, this message translates to:
  /// **'Input fields (optional)'**
  String get inputfields_optional;

  /// No description provided for @tapToAddInputFields.
  ///
  /// In en, this message translates to:
  /// **'Tap to add input fields'**
  String get tapToAddInputFields;

  /// No description provided for @selectInputFields.
  ///
  /// In en, this message translates to:
  /// **'Select input fields'**
  String get selectInputFields;

  /// No description provided for @specifyId.
  ///
  /// In en, this message translates to:
  /// **'Please specify an id'**
  String get specifyId;

  /// No description provided for @locationIdExists.
  ///
  /// In en, this message translates to:
  /// **': this id already exists. Please enter another id for this location.'**
  String get locationIdExists;

  /// No description provided for @takePicture.
  ///
  /// In en, this message translates to:
  /// **'Take a picture'**
  String get takePicture;

  /// No description provided for @photos.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get photos;

  /// No description provided for @resolution.
  ///
  /// In en, this message translates to:
  /// **'Resolution'**
  String get resolution;

  /// No description provided for @choosePhotoResolution.
  ///
  /// In en, this message translates to:
  /// **'Choose a resolution for photos'**
  String get choosePhotoResolution;

  /// No description provided for @photoResolutionLow.
  ///
  /// In en, this message translates to:
  /// **'Low (240p)'**
  String get photoResolutionLow;

  /// No description provided for @photoResolutionMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium (480p)'**
  String get photoResolutionMedium;

  /// No description provided for @photoResolutionHigh.
  ///
  /// In en, this message translates to:
  /// **'High (720p)'**
  String get photoResolutionHigh;

  /// No description provided for @photoResolutionVeryHigh.
  ///
  /// In en, this message translates to:
  /// **'Very high (1080p)'**
  String get photoResolutionVeryHigh;

  /// No description provided for @photoResolutionUltraHigh.
  ///
  /// In en, this message translates to:
  /// **'Ultra high (2160p)'**
  String get photoResolutionUltraHigh;

  /// No description provided for @photoResolutionMax.
  ///
  /// In en, this message translates to:
  /// **'Maximum'**
  String get photoResolutionMax;

  /// No description provided for @tapToTakePhoto.
  ///
  /// In en, this message translates to:
  /// **'Tik hier om een foto te maken'**
  String get tapToTakePhoto;

  /// No description provided for @n_sublocations.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 sublocation} other{{count} sublocations}}'**
  String n_sublocations(num count);

  /// No description provided for @default_value.
  ///
  /// In en, this message translates to:
  /// **'Default value'**
  String get default_value;

  /// No description provided for @removeValueFromId.
  ///
  /// In en, this message translates to:
  /// **'Do you want to remove {value} from the inputfield {id}?'**
  String removeValueFromId(String value, String id);

  /// No description provided for @removeDateTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove date'**
  String get removeDateTitle;

  /// No description provided for @isRequired.
  ///
  /// In en, this message translates to:
  /// **' is required'**
  String get isRequired;

  /// No description provided for @requiredInputField.
  ///
  /// In en, this message translates to:
  /// **'This is a required field'**
  String get requiredInputField;

  /// No description provided for @required.
  ///
  /// In en, this message translates to:
  /// **'required'**
  String get required;

  /// No description provided for @showPreviousAndNextLocation.
  ///
  /// In en, this message translates to:
  /// **'Buttons previous/next location'**
  String get showPreviousAndNextLocation;

  /// No description provided for @showSequenceNumber.
  ///
  /// In en, this message translates to:
  /// **'Show sequence number on location icons'**
  String get showSequenceNumber;

  /// No description provided for @properties.
  ///
  /// In en, this message translates to:
  /// **'Properties'**
  String get properties;

  /// No description provided for @value_is_lower_than_min.
  ///
  /// In en, this message translates to:
  /// **'The value of {inputfield} ({value}) is lower than the specified minimum value ({min_value}). Do you want to continue anyway?'**
  String value_is_lower_than_min(String inputfield, num value, num min_value);

  /// No description provided for @value_is_lower_than_min_title.
  ///
  /// In en, this message translates to:
  /// **'Value too low'**
  String get value_is_lower_than_min_title;

  /// No description provided for @value_is_higher_than_max.
  ///
  /// In en, this message translates to:
  /// **'The value of {inputfield} ({value}) is higher than the specified maximum value ({max_value}). Do you want to continue anyway?'**
  String value_is_higher_than_max(String inputfield, num value, num max_value);

  /// No description provided for @value_is_higher_than_max_title.
  ///
  /// In en, this message translates to:
  /// **'Value too high'**
  String get value_is_higher_than_max_title;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'nl'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'nl': return AppLocalizationsNl();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
