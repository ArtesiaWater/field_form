import pandas as pd
from pyproj import Proj, transform, CRS
import os
import ftplib


def read_locations(fname, out=None):
    """Read a FieldLogger location file, and add its contents to a dictionary."""
    if out is None:
        out = {}

    is_inputfield = False
    is_group = False
    is_location = False

    inputfields = []
    groups = []
    locations = []
    with open(fname) as f:
        line = f.readline().strip()
        while line != "":
            splt = line.split(";")
            if (
                not is_inputfield
                and not is_group
                and not is_location
                and "INPUTTYPE" in splt
            ):
                # this is the inputfield header
                is_inputfield = True
                is_group = False
                is_location = False
                header_inputfields = splt
            elif (
                not is_group
                and not is_location
                and "GROUP" in splt
                and "SUBNAME" not in splt
            ):
                # this is the group header
                is_inputfield = False
                is_group = True
                is_location = False
                header_groups = splt
            elif not is_location and "SUBNAME" in splt:
                # this is the location header
                is_inputfield = False
                is_group = False
                is_location = True
                header_locations = splt
            else:
                if not is_inputfield and not is_group and not is_location:
                    # the line is probably a setting at the beginning of the file
                    if len(splt) > 1:
                        if "settings" not in out:
                            out["settings"] = {}
                        out["settings"][splt[0]] = splt[1]
                elif is_inputfield:
                    inputfields.append(splt)
                elif is_group:
                    groups.append(splt)
                elif is_location:
                    locations.append(splt)
            line = f.readline().strip()

    if len(inputfields) > 0:
        df = pd.DataFrame(inputfields, columns=header_inputfields)
        df.set_index("NAME", inplace=True)
        if "inputfields" in out:
            out["inputfields"] = update_and_append(out["inputfields"], df)
        else:
            out["inputfields"] = df

    if len(groups) > 0:
        df = pd.DataFrame(groups, columns=header_groups)
        df.set_index("GROUP", inplace=True)
        if "groups" in out:
            out["groups"] = update_and_append(out["groups"], df)
        else:
            out["groups"] = df

    if len(locations) > 0:
        df = pd.DataFrame(locations, columns=header_locations)
        if "XCOOR" in df.columns and "YCOOR" in df.columns:
            # transform coordinets to lat and lon
            df["LON"], df["LAT"] = rd2wgs(df["XCOOR"].values, df["YCOOR"].values)
            df = df.drop(["XCOOR", "YCOOR"], axis=1)
        else:
            df = df.astype({"LAT": "float", "LON": "float"})
        df.set_index("SUBNAME", inplace=True)
        if "locations" in out:
            out["locations"] = update_and_append(out["locations"], df)
        else:
            out["locations"] = df

    return out


def rd2wgs(x, y):
    """Calculate longitude and latitude from x and y in rd-coordinates"""
    lat, lon = transform(Proj(CRS("epsg:28992")), Proj(CRS("epsg:4326")), x, y)
    return lon, lat


def write_locations(locs, fname):
    """write a FieldLogger location file, from a dictionary of data"""
    with open(fname, "w", newline="\n") as f:
        if "settings" in locs:
            for key in locs["settings"]:
                f.write("{};{}\n".format(key, locs["settings"][key]))
        if "inputfields" in locs:
            locs["inputfields"].to_csv(f, sep=";")
        if "groups" in locs:
            locs["groups"].to_csv(f, sep=";")
        if "locations" in locs:
            locs["locations"].to_csv(f, sep=";")


def read_measurements(fname, meas=None):
    """read a FieldLogger measurement file, and add its contents to a DataFrame"""
    try:
        df = pd.read_csv(fname, delimiter=";").set_index(
            ["LOCATION", "DATE", "TIME", "TYPE"]
        )
    except pd.errors.EmptyDataError:
        print("No data in {}".format(fname))
        return meas
    if meas is None or meas.empty:
        return df
    else:
        # drop duplicate indexes in df2 (to avoid Exception: cannot handle a non-unique multi-index!)
        df = df.loc[~df.index.duplicated(keep="last")]
        return update_and_append(meas, df)


def write_measurements(df, fname):
    """write a FieldLogger meassurement file, from a DataFrame"""
    df.to_csv(fname, sep=";")


def update_and_append(df, df2, sort=False):
    """Update DataFrame df by values in df2 and append new rows"""
    # first update values at matching index/column labels
    df.update(df2)
    # then also add new rows
    df = df.append(df2.loc[df2.index.difference(df.index)], sort=sort)
    return df


def clean_fieldlogger_ftp(ftp_serv, ftp_user, ftp_pass, ftp_path, change_ftp=True):
    """This method reads, combines writes and deletes Fieldlogger files to an ftp-server"""

    # log into the ftp-server
    ftp = ftplib.FTP(ftp_serv)
    ftp.login(ftp_user, ftp_pass)

    # Go to the right path
    ftp.cwd(ftp_path)

    # download files from ftp-server
    files = []
    ftp.dir(files.append)

    # get a unique pathname to store the files from the ftp-server
    i = 1
    today = pd.Timestamp("today").strftime("%Y%m%d")
    pathname = "files_{}_{}".format(today, i)
    while os.path.isdir(pathname):
        i = i + 1
        pathname = "files_{}_{}".format(today, i)
    os.makedirs(pathname)

    for file in files:
        filename = file.split()[-1]
        if filename.startswith("locations") or filename.startswith("measurements"):
            print("Download {}".format(filename))
            fname = os.path.join(pathname, filename)
            ftp.retrbinary("RETR " + filename, open(fname, "wb").write)

    # the next step can take a while, so log out from the ftp
    ftp.quit()

    # read the files and combine the data
    locs = {}
    meas = pd.DataFrame()
    location_files = []
    measurement_files = []
    files = sorted(os.listdir(pathname))
    for file in files:
        fname = os.path.join(pathname, file)
        if file.startswith("locations"):
            print("Import locations from {}".format(file))
            locs = read_locations(fname, locs)
            location_files.append(file)
        elif file.startswith("measurements"):
            print("Import measurements from {}".format(file))
            meas = read_measurements(fname, meas)
            measurement_files.append(file)

    if change_ftp:
        # log back into the ftp-server again
        ftp = ftplib.FTP(ftp_serv)
        ftp.login(ftp_user, ftp_pass)

        # Go to the right path
        ftp.cwd(ftp_path)

    # write locations to a temporary file and send this to the ftp-server
    if len(location_files) > 0:
        print("Write new locations in {} to ftp".format(location_files[-1]))
        write_locations(locs, location_files[-1])
        if change_ftp:
            with open(location_files[-1], "rb") as file:
                ftp.storbinary("STOR " + location_files[-1], file)
            os.remove(location_files[-1])

    # write measurements to a temporary file and send this to the ftp-server
    if len(measurement_files) > 0:
        print("Write new measurements in {} to ftp".format(measurement_files[-1]))
        write_measurements(meas, measurement_files[-1])
        if change_ftp:
            with open(measurement_files[-1], "rb") as file:
                ftp.storbinary("STOR " + measurement_files[-1], file)
            os.remove(measurement_files[-1])

    # delete existing location- and measurement-files on ftp server
    if change_ftp:
        for file in location_files[:-1]:
            print("Delete imported file {} from ftp-server".format(file))
            ftp.delete(file)
        for file in measurement_files[:-1]:
            print("Delete imported file {} from ftp-server".format(file))
            ftp.delete(file)

    # log out from the ftp
    if change_ftp:
        ftp.quit()
    print("FTP cleaner fieldlogger completed")
