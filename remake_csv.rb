require 'csv'
require 'fileutils'

def create_files(success_log)
  unless File.exist?(success_log)
    FileUtils.touch(success_log)
    csv = CSV.open(success_log, "w+")
    csv.close
  end
end

def append_to_csv(file, row)
  f = CSV.open(file, "a+", headers: row.headers)
  f << row
  f.close
end

recruiter = 'NeasaWhite'
working_dir = "./../LIN#{recruiter}"
input_csv = "#{working_dir}/id_lookup_success.csv"
#input_table = CSV.read(input_csv, headers: true)
output_csv = "./../LIN#{recruiter}/id_lookup_success_reencode.csv"
#headers = data_table.headers
create_files(output_csv)
count = 1
CSV.foreach(input_csv, headers: true) do |row|
  puts count
  append_to_csv(output_csv, row)
  count += 1
end
