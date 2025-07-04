// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Dutch Flemish (`nl`).
class AppLocalizationsNl extends AppLocalizations {
  AppLocalizationsNl([String locale = 'nl']) : super(locale);

  @override
  String get map => 'Kaart';

  @override
  String get chooseMaptype => 'Kies een kaart-type';

  @override
  String get loadingMap => 'laad de kaart..';

  @override
  String get loading => 'Laden...';

  @override
  String get fieldForm => 'FieldForm';

  @override
  String get menu => 'Menu';

  @override
  String get addDataFromFile => 'Voeg data toe uit een bestand';

  @override
  String get shareData => 'Deel data';

  @override
  String get changeFtpFolder => 'Verander FTP Map';

  @override
  String get chooseGroups => 'Kies groepen';

  @override
  String get selectGroups => 'Selecteer groepen';

  @override
  String get selectAll => 'Selecteer alles';

  @override
  String get selectNone => 'Selecteer geen';

  @override
  String get deleteAllData => 'Verwijder data van telefoon';

  @override
  String get sureToDeleteData => 'Weet u zeker dat u alle data wilt verwijderen van uw telefoon?';

  @override
  String get unsentMeasurementsTitle => 'Eerst metingen versturen?';

  @override
  String get unsentMeasurements => 'Er zijn nog niet-verzonden metingen. Weet u zeker dat u alle date wilt verwijderen?';

  @override
  String get uploadUnsentMeasurements => 'Er zijn nog niet-verzonden metingen. Wilt u deze eerst uploaden? Zo niet, dan gaan ze verloren.';

  @override
  String get settings => 'Instellingen';

  @override
  String get markMeasuredLocations => 'Markeer bemeten locaties';

  @override
  String get doNotMarkMeasuredLocations => 'Markeer bemeten locaties niet';

  @override
  String withinIntervalDays(num interval) {
    return 'Binnen $interval dagen';
  }

  @override
  String get specifyInterval => 'Geef een ander aantal dagen op';

  @override
  String get other => 'Anders';

  @override
  String get markNotMeasured => 'Markeer locaties zonder metingen';

  @override
  String get addNewLocation => 'Voeg een nieuwe locatie toe';

  @override
  String get chooseSublocation => 'Kies een sublocatie';

  @override
  String get locsOrMeasTitle => 'Locaties of metingen';

  @override
  String get locsOrMeas => 'Bevat dit bestand locaties of metingen?';

  @override
  String get locations => 'Locaties';

  @override
  String get measurements => 'Metingen';

  @override
  String get removeExistingLocationsTitle => 'Importeren locaties verwijdert bestaande locaties';

  @override
  String get removeExistingLocations => 'Het importeren van nieuwe locaties zal alle bestaande locaties verwijderen. Wilt u doorgaan?';

  @override
  String get yes => 'Ja';

  @override
  String get no => 'Nee';

  @override
  String get importFailed => 'Importeren niet gelukt';

  @override
  String get csvNotImplemented => 'csv-locatie-bestanden worden (nog) niet ondersteund. Gebruik json-bestanden voor locatie-data.';

  @override
  String get unknownFileExtension => 'Onebekende bestands-extensie. Locatie-data moet in een json-bestand worden opgegeven.';

  @override
  String get syncCompleted => 'Synchronisatie voltooid';

  @override
  String get sendingMeasurements => 'Versturen van metingen';

  @override
  String get uploadMeasurementsFailed => 'Het lukt niet om metingen te versturen';

  @override
  String get retreivingFiles => 'Opvragen van lijst met bestanden';

  @override
  String get retreivedFiles => 'Lijst van bestanden ontvangen';

  @override
  String get downloading => 'Download ';

  @override
  String get downloadFailed => 'Het lukt niet om te downloaden: ';

  @override
  String get noDataToShare => 'Er is geen data om te versturen';

  @override
  String get uploadPhotoFailed => 'Het lukt niet om foto te versturen: ';

  @override
  String get done => 'Gereed';

  @override
  String get previousMeasurements => 'Voorgaande metingen:';

  @override
  String sureToDeleteMeasurement(String value, String id) {
    return 'Weet u zeker dat u de meting $value van het type $id wilt verwijderen?';
  }

  @override
  String sureToDeleteMeasurementsAt(String datetime) {
    return 'Weet u zeker dat u de metingen op $datetime wilt verwijderen?';
  }

  @override
  String get sureToDeleteMeasurementTitle => 'Verwijder meting?';

  @override
  String get sureToDeleteMeasurementsTitle => 'Verwijder metingen?';

  @override
  String get isNotValidNumber => ' is geen geldig getal';

  @override
  String get ignoreFilledValues => 'Alle ingevulde waarden worden verwijderd wanneer u deze locatie verlaat. Wilt u nog steeds weggaan?';

  @override
  String get ignoreFilledValuesTitle => 'Weggaan zonder op te slaan?';

  @override
  String get imageNotSupported => ': dit bestand wordt niet ondersteund. Alleen jpg, png en pdf worden ondersteund';

  @override
  String get connectToFtpFailed => 'Het lukt niet om met de FTP-server te verbinden';

  @override
  String get authenticationError => 'Er is een authenticatie-fout opgetreden met de FTP-server. Voer een geldige gebruikersnaam en wachtwoord in, of verleng uw toegangsessie.';

  @override
  String get unableToFindOnFtp => 'Kan het bestand niet vinden op de FTP-server: ';

  @override
  String get unableToFindPathOnFtp => 'Kan de map niet vinden op de FTP-server: ';

  @override
  String get noHostnameDefined => 'Geen hostnaam opgegeven. Geef aub een hostname op in de instellingen.';

  @override
  String get connected => 'Verbonden';

  @override
  String get chooseAFolder => 'Kies een map';

  @override
  String get removePhotoTitle => 'Verwijder foto';

  @override
  String get editInputFields => 'Pas invoervelden aan';

  @override
  String get useStandardTime => 'Gebruik wintertijd';

  @override
  String get useStandardTimeSubtitle => 'Wanneer aan gebruik ook in de zomer de wintertijd';

  @override
  String get wms => 'WMS';

  @override
  String get addWms => 'Voeg een WMS-laag toe aan de kaart';

  @override
  String get wmsUrl => 'WMS url';

  @override
  String get changeWmsUrl => 'Verander WMS url';

  @override
  String get wmsLayers => 'WMS lagen';

  @override
  String get changeWmsLayers => 'Verander WMS lagen';

  @override
  String get ftp => 'FTP';

  @override
  String get hostname => 'Hostnaam';

  @override
  String get changeFtpHostname => 'Verander FTP hostnaam (gebruik / om mappen op te geven)';

  @override
  String get username => 'Gebruikersnaam';

  @override
  String get changeFtpUsername => 'Verander FTP gebruikersnaam';

  @override
  String get password => 'Wachtwoord';

  @override
  String get changeFtpPassword => 'Verander FTP wachtwoord';

  @override
  String get rootFolder => 'Hoofdmap';

  @override
  String get changeFtpRoot => 'Verander hoofdmap (gebruik / om mappen te scheiden)';

  @override
  String get addUserToMeasurements => 'Voeg gebruiker toe aan elke meting';

  @override
  String get user => 'Gebruiker';

  @override
  String get setUser => 'Geef uw naam op';

  @override
  String get userInputfield => 'Naam van invoerveld voor gebruiker';

  @override
  String get changeUserInputfield => 'Verander naam van invoerveld voor gebruiker';

  @override
  String get path => 'Pad';

  @override
  String get onlyExportNewMeasurements => 'Exporteer alleen nieuwe metingen';

  @override
  String get uploadDataInstantly => 'Upload metingen direct';

  @override
  String get cancel => 'Annuleer';

  @override
  String get ok => 'Ok';

  @override
  String get input => 'Invoer';

  @override
  String get useFtps => 'Gebruik FTPS';

  @override
  String get useSftp => 'Gebruik SFTP';

  @override
  String get useImplicitFtps => 'Gebruik impliciete FTPS';

  @override
  String get deleteInputField => 'Weet u zeker dat u dit invoerveld wilt verwijderen?';

  @override
  String get deleteOption => 'Weet u zeker dat u deze optie wilt verwijderen?';

  @override
  String get inputFields => 'Invoervelden';

  @override
  String get supplyInputFieldId => 'Geef aub de id van het invoerveld op.';

  @override
  String get inputFieldIdExists => ': dit id bestaat al. Vul aub een ander id in voor dit invoerveld.';

  @override
  String get chooseId => 'Kies id';

  @override
  String get name => 'Naam';

  @override
  String get anOptionalName => 'Een optionele naam';

  @override
  String get type => 'type';

  @override
  String get options => 'Opties';

  @override
  String get tapToAddOptions => 'Tik om opties toe te voegen';

  @override
  String get hint => 'hint';

  @override
  String get anOptionalHint => 'Een optionele hint';

  @override
  String get newLocation => 'Nieuwe locatie';

  @override
  String get specifyUniqueId => 'Vul aub een unieke id in';

  @override
  String get anOptionalGroup => 'Een optionele groep';

  @override
  String get group_optional => 'Groep (optioneel)';

  @override
  String get noGroupName => 'Zonder groep';

  @override
  String get inputfields_optional => 'Invoervelden (optioneel)';

  @override
  String get tapToAddInputFields => 'Tik om invoervelden toe te voegen';

  @override
  String get selectInputFields => 'Selecteer invoervelden';

  @override
  String get specifyId => 'Vul aub een id in';

  @override
  String get locationIdExists => ': dit id bestaat al. Vul aub een ander id in voor deze locatie.';

  @override
  String get takePicture => 'Neem een foto';

  @override
  String get photos => 'Foto\'s';

  @override
  String get resolution => 'Resolutie';

  @override
  String get choosePhotoResolution => 'Kies een resolutie van foto\'s';

  @override
  String get photoResolutionLow => 'Laag (240p)';

  @override
  String get photoResolutionMedium => 'Gemiddeld (480p)';

  @override
  String get photoResolutionHigh => 'Hoog (720p)';

  @override
  String get photoResolutionVeryHigh => 'Heel hoog (1080p)';

  @override
  String get photoResolutionUltraHigh => 'Zeer hoog (2160p)';

  @override
  String get photoResolutionMax => 'Maximaal';

  @override
  String get tapToTakePhoto => 'Tik hier om een foto te maken';

  @override
  String n_sublocations(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sublocaties',
      one: '1 sublocatie',
    );
    return '$_temp0';
  }

  @override
  String get default_value => 'Standaard waarde';

  @override
  String removeValueFromId(String value, String id) {
    return 'Wilt u $value verwijderen van het invoerveld $id?';
  }

  @override
  String get removeDateTitle => 'Verwijder datum';

  @override
  String get isRequired => ' is verplicht';

  @override
  String get requiredInputField => 'Dit is een verplicht veld';

  @override
  String get required => 'verplicht';

  @override
  String get showPreviousAndNextLocation => 'Knoppen vorige/volgende locatie';

  @override
  String get showSequenceNumber => 'Geef volgnummer op locaties weer';

  @override
  String get properties => 'Eigenschappen';

  @override
  String value_is_lower_than_min(String inputfield, num value, num min_value) {
    return 'De waarde van $inputfield ($value) is lager dan de opgegeven minimale waarde ($min_value). Wilt u toch doorgaan?';
  }

  @override
  String get value_is_lower_than_min_title => 'Waarde te laag';

  @override
  String value_is_higher_than_max(String inputfield, num value, num max_value) {
    return 'De waarde van $inputfield ($value) is hoger dan de opgegeven maximale waarde ($max_value). Wilt u toch doorgaan?';
  }

  @override
  String get value_is_higher_than_max_title => 'Waarde te hoog';
}
