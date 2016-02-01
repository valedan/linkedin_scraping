# SPEC:
#       - Given a data csv with a Candidate ID field and an assortment of data
#       - AND a lookup csv with Candidate ID's and Contact ID's
#       - For each row of the data csv, find the row in the lookup csv with the corresponding CandID
#       - AND add the Contact ID to that row of the data csv.

require 'csv'
require 'fileutils'
# recruiters = ['AlisonSmith', 'Emily', 'JennyDolan', 'JingJing',
#    'JohnSmith', 'KarenDoyle', 'KarenMcHugh', 'LisaONeill',
#    'LiWang', 'MariaMurphy', 'MikeBrown', 'MyraKumar',
#    'NeasaWhite', 'NiamhBlack', 'MaryBerry', 'SarahKelly', 'SeanMurphy',
#    'SheilaMcNeice', 'Ruby', 'SheilaDempsey', 'SheilaMcGrath',
#    'YuChun']
recruiters = ['SeanMurphy', 'SheilaMcNeice', 'Ruby', 'SheilaDempsey', 'SheilaMcGrath',
'YuChun']

lookup_csv = "./../jan27_salesforce_lin_update2.csv"
$lookup_table = CSV.read(lookup_csv, headers: true, encoding: 'windows-1252')



def main(recruiter)
  puts "Recruiter: #{recruiter}"


  output_dir = "./../LIN#{recruiter}"
  fail_log = "./../LIN#{recruiter}/rebase_fail.csv"
  success_log = "./../LIN#{recruiter}/rebase_success.csv"
  data_csv = "#{output_dir}/fail_log.csv"
  data_table = CSV.read(data_csv, headers: true)
  headers = data_table.headers
  create_files(headers, fail_log, success_log)

  count = 0

  data_table.each do |row|
    begin
      count += 1
      puts "#{recruiter}: #{count}"
      email = row["Email"]
      master_row = $lookup_table.find do |lookup_row|
        lookup_row["Email"] == email
      end
      if master_row
        row["First Name"] = master_row["First Name"].encode('utf-8', 'windows-1252') if master_row["First Name"]
        row["Last Name"] = master_row["Last Name"].encode('utf-8', 'windows-1252') if master_row["Last Name"]
        row["Employer Organization Name 1"] = master_row["Employer Organization Name 1"].encode('utf-8', 'windows-1252') if master_row["Employer Organization Name 1"]
        row["Employer 1 Title"] = master_row["Employer 1 Title"].encode('utf-8', 'windows-1252') if master_row["Employer 1 Title"]
        append_to_csv(success_log, row)
        #puts "Match found"
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
