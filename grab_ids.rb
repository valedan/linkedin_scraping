# SPEC:
#       - Given a data csv with a Candidate ID field and an assortment of data
#       - AND a lookup csv with Candidate ID's and Contact ID's
#       - For each row of the data csv, find the row in the lookup csv with the corresponding CandID
#       - AND add the Contact ID to that row of the data csv.

require 'csv'
require 'fileutils'
recruiters = ['AlisonSmith', 'Emily','JingJing',
   'KarenDoyle', 'LisaONeill',
   'LiWang', 'MaryBerry', 'MikeBrown', 'MyraKumar',
   'NeasaWhite', 'NiamhBlack', 'SarahKelly',
   'SheilaMcNeice', 'Ruby', 'SheilaDempsey', 'SheilaMcGrath',
   'YuChun']


def main(recruiter)
  puts "Recruiter: #{recruiter}"


  output_dir = "./../LIN#{recruiter}/round2"
  fail_log = "./../LIN#{recruiter}/round2/id_lookup_fail.csv"
  success_log = "./../LIN#{recruiter}/round2/id_lookup_success.csv"
  data_csv = "#{output_dir}/LIN#{recruiter}.csv"
  lookup_csv = "./../sf_id_lookup.csv"
  data_table = CSV.read(data_csv, headers: true)
  lookup_table = CSV.read(lookup_csv, headers: true)
  headers = data_table.headers
  headers.push("Contact ID") unless headers.include?("Contact ID")
  create_files(headers, fail_log, success_log)

  count = 0

  data_table.each do |row|
    begin
      count += 1
      puts "#{recruiter}: #{count}"
      cand_id = row["Candidate ID"]
      match = lookup_table.find do |lookup_row|
        lookup_row["Candidate ID"] == cand_id
      end
      row["Contact ID"] = match["Contact ID"]
      if match
        append_to_csv(success_log, row)
        puts "Match found"
      else
        append_to_csv(fail_log, row)
        puts '############## NO MATCH FOUND ##############'
      end
    rescue Exception => msg
        append_to_csv(fail_log, row)
        puts msg
    end
  end
end

def create_files(headers, fail_log, success_log)
  unless File.exist?(fail_log)
    FileUtils.touch(fail_log)
    csv = CSV.open(fail_log, "w+")
    csv << headers
    csv.close
  end
  unless File.exist?(success_log)
    FileUtils.touch(success_log)
    csv = CSV.open(success_log, "w+")
    csv << headers
    csv.close
  end
end

def append_to_csv(file, row)
  f = CSV.open(file, "a+", headers: row.headers)
  f << row
  f.close
end

recruiters.each do |recruiter|
  main(recruiter)
end
