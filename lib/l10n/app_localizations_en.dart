// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get map => 'Map';

  @override
  String get chooseMaptype => 'Choose a maptype';

  @override
  String get loadingMap => 'loading map..';

  @override
  String get loading => 'Loading...';

  @override
  String get fieldForm => 'FieldForm';

  @override
  String get menu => 'Menu';

  @override
  String get addDataFromFile => 'Add data from file';

  @override
  String get shareData => 'Share data';

  @override
  String get changeFtpFolder => 'Change FTP Folder';

  @override
  String get chooseGroups => 'Choose groups';

  @override
  String get selectGroups => 'Select groups';

  @override
  String get selectAll => 'Select all';

  @override
  String get selectNone => 'Select none';

  @override
  String get deleteAllData => 'Delete data from phone';

  @override
  String get sureToDeleteData => 'Are you sure you wish to delete all data from your phone?';

  @override
  String get unsentMeasurementsTitle => 'First send measurements?';

  @override
  String get unsentMeasurements => 'There are still unsent measurements. Are you really sure you want to delete all data?';

  @override
  String get uploadUnsentMeasurements => 'There are unsent measurements. Do you want to upload these first? Otherwise they will be lost.';

  @override
  String get settings => 'Settings';

  @override
  String get markMeasuredLocations => 'Mark measured locations';

  @override
  String get doNotMarkMeasuredLocations => 'Do not mark measured locations';

  @override
  String withinIntervalDays(num interval) {
    return 'Within $interval days';
  }

  @override
  String get specifyInterval => 'Specify a different number of days';

  @override
  String get other => 'Other';

  @override
  String get markNotMeasured => 'Mark locations without measurements';

  @override
  String get addNewLocation => 'Add a new location';

  @override
  String get chooseSublocation => 'Choose a sublocation';

  @override
  String get locsOrMeasTitle => 'Locations or measurements';

  @override
  String get locsOrMeas => 'Does this file contain locations or measurements?';

  @override
  String get locations => 'Locations';

  @override
  String get measurements => 'Measurements';

  @override
  String get removeExistingLocationsTitle => 'Import of locations removes existing locations';

  @override
  String get removeExistingLocations => 'Importing new locations will remove all existing locations. Do you want to continue?';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get importFailed => 'Import failed';

  @override
  String get csvNotImplemented => 'csv-location files not implemented (yet). Use json-files for location-data';

  @override
  String get unknownFileExtension => 'Unknown file-extension. Location-data has to be supplied in a json-file.';

  @override
  String get syncCompleted => 'Synchronisation complete';

  @override
  String get sendingMeasurements => 'Sending measurements';

  @override
  String get uploadMeasurementsFailed => 'Unable to upload measurements';

  @override
  String get retreivingFiles => 'Requesting file list';

  @override
  String get retreivedFiles => 'Retrieved file list';

  @override
  String get downloading => 'Downloading ';

  @override
  String get downloadFailed => 'Unable to download ';

  @override
  String get noDataToShare => 'There is no data to share';

  @override
  String get uploadPhotoFailed => 'Unable to upload photo: ';

  @override
  String get done => 'Done';

  @override
  String get previousMeasurements => 'Previous measurements:';

  @override
  String sureToDeleteMeasurement(String value, String id) {
    return 'Are you sure you want to delete $value of type $id?';
  }

  @override
  String sureToDeleteMeasurementsAt(String datetime) {
    return 'Are you sure you want to delete the measurements at $datetime?';
  }

  @override
  String get sureToDeleteMeasurementTitle => 'Delete measurement?';

  @override
  String get sureToDeleteMeasurementsTitle => 'Delete measurements?';

  @override
  String get isNotValidNumber => ' is not a valid number';

  @override
  String get ignoreFilledValues => 'All entered values will be deleted when leaving this location. Do you still want to leave?';

  @override
  String get ignoreFilledValuesTitle => 'Leave without saving?';

  @override
  String get imageNotSupported => ': this file is not supported. Only jpg, png and pdf are supported';

  @override
  String get connectToFtpFailed => 'Unable to connect to FTP-server';

  @override
  String get authenticationError => 'Authentication on FTP-server failed. Set a valid username and password, or extend your access session.';

  @override
  String get unableToFindOnFtp => 'Unable to find the file on FTP-server: ';

  @override
  String get unableToFindPathOnFtp => 'Unable to find path on FTP-server: ';

  @override
  String get noHostnameDefined => 'No hostname defined. Please assign a hostname in the settings';

  @override
  String get connected => 'Connected';

  @override
  String get chooseAFolder => 'Choose a folder';

  @override
  String get removePhotoTitle => 'Remove photo';

  @override
  String get editInputFields => 'Edit input fields';

  @override
  String get useStandardTime => 'Use standard time';

  @override
  String get useStandardTimeSubtitle => 'When true, disable daylight saving time';

  @override
  String get wms => 'WMS';

  @override
  String get addWms => 'Add a WMS to the map';

  @override
  String get wmsUrl => 'WMS url';

  @override
  String get changeWmsUrl => 'Change WMS url';

  @override
  String get wmsLayers => 'WMS layers';

  @override
  String get changeWmsLayers => 'Change WMS layers';

  @override
  String get ftp => 'FTP';

  @override
  String get hostname => 'Hostname';

  @override
  String get changeFtpHostname => 'Change FTP hostname (use / to specify folders)';

  @override
  String get username => 'Username';

  @override
  String get changeFtpUsername => 'Change FTP username';

  @override
  String get password => 'Password';

  @override
  String get changeFtpPassword => 'Change FTP password';

  @override
  String get rootFolder => 'Root folder';

  @override
  String get changeFtpRoot => 'Change FTP root (use / to separate folders)';

  @override
  String get addUserToMeasurements => 'Add user to each measurement';

  @override
  String get user => 'User';

  @override
  String get setUser => 'Please provide your name';

  @override
  String get userInputfield => 'Name of inputfield for user';

  @override
  String get changeUserInputfield => 'Change name of inputfield for user';

  @override
  String get path => 'Path';

  @override
  String get onlyExportNewMeasurements => 'Only export new measurements';

  @override
  String get uploadDataInstantly => 'Upload measurements instantly';

  @override
  String get cancel => 'Cancel';

  @override
  String get ok => 'Ok';

  @override
  String get input => 'Input';

  @override
  String get useFtps => 'Use FTPS';

  @override
  String get useSftp => 'Use SFTP';

  @override
  String get useImplicitFtps => 'Use implicit FTPS';

  @override
  String get deleteInputField => 'Are you sure you want to delete this input field?';

  @override
  String get deleteOption => 'Are you sure you want to delete this option?';

  @override
  String get inputFields => 'Input fields';

  @override
  String get supplyInputFieldId => 'Please supply the id of the input field.';

  @override
  String get inputFieldIdExists => ': this id already exists. Please enter another id for this input field.';

  @override
  String get chooseId => 'Choose id';

  @override
  String get name => 'Name';

  @override
  String get anOptionalName => 'An optional name';

  @override
  String get type => 'type';

  @override
  String get options => 'Options';

  @override
  String get tapToAddOptions => 'Tap to add options';

  @override
  String get hint => 'hint';

  @override
  String get anOptionalHint => 'An optional hint';

  @override
  String get newLocation => 'New Location';

  @override
  String get specifyUniqueId => 'Please specify a unique id';

  @override
  String get anOptionalGroup => 'An optional group';

  @override
  String get group_optional => 'Group (optional)';

  @override
  String get noGroupName => 'Without a group';

  @override
  String get inputfields_optional => 'Input fields (optional)';

  @override
  String get tapToAddInputFields => 'Tap to add input fields';

  @override
  String get selectInputFields => 'Select input fields';

  @override
  String get specifyId => 'Please specify an id';

  @override
  String get locationIdExists => ': this id already exists. Please enter another id for this location.';

  @override
  String get takePicture => 'Take a picture';

  @override
  String get photos => 'Photos';

  @override
  String get resolution => 'Resolution';

  @override
  String get choosePhotoResolution => 'Choose a resolution for photos';

  @override
  String get photoResolutionLow => 'Low (240p)';

  @override
  String get photoResolutionMedium => 'Medium (480p)';

  @override
  String get photoResolutionHigh => 'High (720p)';

  @override
  String get photoResolutionVeryHigh => 'Very high (1080p)';

  @override
  String get photoResolutionUltraHigh => 'Ultra high (2160p)';

  @override
  String get photoResolutionMax => 'Maximum';

  @override
  String get tapToTakePhoto => 'Tik hier om een foto te maken';

  @override
  String n_sublocations(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sublocations',
      one: '1 sublocation',
    );
    return '$_temp0';
  }

  @override
  String get default_value => 'Default value';

  @override
  String removeValueFromId(String value, String id) {
    return 'Do you want to remove $value from the inputfield $id?';
  }

  @override
  String get removeDateTitle => 'Remove date';

  @override
  String get isRequired => ' is required';

  @override
  String get requiredInputField => 'This is a required field';

  @override
  String get required => 'required';

  @override
  String get showPreviousAndNextLocation => 'Buttons previous/next location';

  @override
  String get showSequenceNumber => 'Show sequence number on location icons';

  @override
  String get properties => 'Properties';

  @override
  String value_is_lower_than_min(String inputfield, num value, num min_value) {
    return 'The value of $inputfield ($value) is lower than the specified minimum value ($min_value). Do you want to continue anyway?';
  }

  @override
  String get value_is_lower_than_min_title => 'Value too low';

  @override
  String value_is_higher_than_max(String inputfield, num value, num max_value) {
    return 'The value of $inputfield ($value) is higher than the specified maximum value ($max_value). Do you want to continue anyway?';
  }

  @override
  String get value_is_higher_than_max_title => 'Value too high';
}
