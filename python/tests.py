import os
import fieldform

inputdir = "test_input"
output_dir = "test_output"
if not os.path.isdir(output_dir):
    os.makedirs(output_dir)
for name in ["test1", "test2"]:
    fname_csv = os.path.join(inputdir, f"{name}.csv")
    fname_json = os.path.join(output_dir, f"{name}.json")
    fieldform.location_file_from_fieldlogger(fname_csv, fname_json)
