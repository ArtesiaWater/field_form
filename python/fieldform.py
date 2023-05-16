import json
import fieldlogger


def write_location_file(data, fname):
    """
    Write a FieldForm location file (.json)

    Parameters
    ----------
    data : dict
        The data that needs to be written to the location-file. This dictionary can have
        the keys 'settings', 'inputfields', 'groups' and/or 'locations'.
    fname : str
        The path to the new location-file (.json).

    Returns
    -------
    None.

    """
    with open(fname, "w") as outfile:
        json.dump(data, outfile, indent=2)


def location_file_from_fieldlogger(fname_csv, fname_json, return_data=False):
    """
    Write a FieldForm location file (.json) from a FieldLogger location file (.csv)

    Parameters
    ----------
    fname_csv : str or dict
        The path to the FieldForm location-file (csv).
    fname_json : str
        The path to the new location-file (.json).
    return_data : bool, optional
        Retrun the data as a dictionary. The default is False.

    Returns
    -------
    data : dict
        A dictionary with location-data, only retured when return_data is False.

    """
    if isinstance(fname_csv, dict):
        locs = fname_csv
    else:
        locs = fieldlogger.read_locations(fname_csv)

    # %% start with an empty dictionary
    data = {}

    # %% settings
    # just copy settings
    # (not all are supported in FieldForm, see https://github.com/ArtesiaWater/field_form)
    if "settings" in locs:
        data["settings"] = locs["settings"]
        # some settings have been renamed:
        translate_settings = {
            "ftp_download_hostname": "ftp_hostname",
            "ftp_download_path": "ftp_path",
            "ftp_download_username": "ftp_username",
            "ftp_download_password": "ftp_password",
        }
        drop_settings = [
            "ftp_upload_hostname",
            "ftp_upload_path",
            "ftp_upload_username",
            "ftp_upload_password",
        ]
        for fl_setting, ff_setting in translate_settings.items():
            if fl_setting in data["settings"]:
                data["settings"][ff_setting] = data["settings"][fl_setting]
                drop_settings.append(fl_setting)

        for fl_setting in drop_settings:
            if fl_setting in data["settings"]:
                data["settings"].pop(fl_setting)

    # %% inputfields
    if "inputfields" in locs:
        # locs['inputfields'].T.to_dict()
        inputfields = {}
        for id, inputfield in locs["inputfields"].iterrows():
            inputfields[id] = {}
            if "INPUTTYPE" in inputfield:
                inputfields[id]["type"] = inputfield["INPUTTYPE"]
            if "HINT" in inputfield:
                if "INPUTTYPE" in inputfield and inputfield["INPUTTYPE"] == "choice":
                    inputfields[id]["options"] = inputfield["HINT"].split("|")
                inputfields[id]["hint"] = inputfield["HINT"]
        data["inputfields"] = inputfields

    # %% groups
    if "groups" in locs:
        # locs['groups'].T.to_dict()
        groups = {}
        for id, group in locs["groups"].iterrows():
            groups[id] = {}
            if "COLOR" in group:
                groups[id]["color"] = group["COLOR"]
        data["groups"] = groups

    # %% locations
    if "locations" in locs:
        # locs['groups'].T.to_dict()
        locations = {}
        for id, location in locs["locations"].iterrows():
            if "NAME" not in location:
                raise (Exception("Only locations with sublocations supported"))

            # if needed, add the location
            if location["NAME"] not in locations:
                locations[location["NAME"]] = {}
                if "LAT" in location:
                    locations[location["NAME"]]["lat"] = location["LAT"]
                if "LON" in location:
                    locations[location["NAME"]]["lon"] = location["LON"]
                if "COLOR" in location:
                    locations[location["NAME"]]["color"] = location["COLOR"]
                if "GROUP" in location:
                    locations[location["NAME"]]["group"] = location["GROUP"]
                locations[location["NAME"]]["sublocations"] = {}

            # add sublocation
            subloc = {}
            if "INPUTFIELD" in location:
                subloc["inputfields"] = location["INPUTFIELD"].split("|")
            locations[location["NAME"]]["sublocations"][id] = subloc
        data["locations"] = locations

    # %% return data if requested
    if return_data:
        return data

    # %% write dictionary to json
    write_location_file(data, fname_json)
