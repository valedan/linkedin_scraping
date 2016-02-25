require 'csv'
require 'fileutils'




input_dir = './../run3/input'
lin_csv = "#{input_dir}/merged.csv"
sf_csv = "#{input_dir}/sf_ref2.csv"
lin_emails = []

sf_data = CSV.read(sf_csv, headers: true, return_headers: true)
sf_headers = sf_data.headers
$headers = sf_headers

def create_file(f)
  unless File.exist?(f)
    FileUtils.touch(f)
    csv = CSV.open(f, "w+")
    csv << $headers
    csv.close
  end
end

output_csv = "#{input_dir}/cross_ref.csv"

create_file(output_csv)

def append_to_csv(file, row)
  tries = 6
  begin
    f = CSV.open(file, "a+")
    f << row
    f.close
  rescue Exception => e
    if tries > 0
      puts "UNABLE TO WRITE TO #{file}"
      sleep(10)
      retry
    else
      puts e
      f.close
      abort
    end
  end
end


CSV.foreach(lin_csv, headers: true) do |lin_row|
  email = lin_row['E-mail Address']
  lin_emails << email
end

lin_data = CSV.read(lin_csv, headers: true, return_headers: true)
lin_data.delete(0)
sf_index = 0

CSV.foreach(sf_csv, headers: true, return_headers: true) do |sf_row|
  sf_index += 1
  puts "sf: #{sf_index}"
  sf_emails = []
  sf_emails << sf_row['Email'] if sf_row['Email']
  sf_emails << sf_row['Email 2'] if sf_row['Email 2']
  sf_emails << sf_row['Email 3'] if sf_row['Email 3']
  #puts sf_emails

  target_lin_row_num = lin_emails.find_index do |lin_email|
    sf_emails.include?(lin_email)
  end
  if target_lin_row_num
    sf_row['Candidate Source'] = lin_data[target_lin_row_num]['Recruiter']
    unless lin_data[target_lin_row_num]['First Name'].nil?
      sf_row['First Name'] = lin_data[target_lin_row_num]['First Name']
    end
    unless lin_data[target_lin_row_num]['Last Name'].nil?
      sf_row['Last Name'] = lin_data[target_lin_row_num]['Last Name']
    end
    unless lin_data[target_lin_row_num]['Company'].nil?
      sf_row['Employer Organization Name 1'] = lin_data[target_lin_row_num]['Company']
    end
    unless lin_data[target_lin_row_num]['Job Title'].nil?
      sf_row['Employer 1 Title'] = lin_data[target_lin_row_num]['Job Title']
    end
    lin_data.delete(target_lin_row_num)
    lin_emails.delete_at(target_lin_row_num)
    append_to_csv(output_csv, sf_row)
  end
end

lin_index = 0
lin_data.each do |lin_row|
  lin_index += 1
  puts "lin: #{lin_index}"
  new_sf_row = CSV::Row.new(sf_headers, [])
  new_sf_row['Candidate Source'] = lin_row['Recruiter']
  new_sf_row['First Name'] = lin_row['First Name']
  new_sf_row['Last Name'] = lin_row['Last Name']
  new_sf_row['Email'] = lin_row['E-mail Address']
  new_sf_row['Employer Organization Name 1'] = lin_row['Company']
  new_sf_row['Employer 1 Title'] = lin_row['Job Title']
  new_sf_row['Account Name'] = 'Candidates'
  append_to_csv(output_csv, new_sf_row)
end
