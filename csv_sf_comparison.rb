require 'csv'
require 'fileutils'




input_dir = './..'
lin_csv = "#{input_dir}/bb.csv"
sf_csv = "#{input_dir}/sf_ref.csv"
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

output_csv = "#{input_dir}/bb_sf_crossref3.csv"

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
  email = lin_row['Email Address']
  lin_emails << email&.downcase
end

lin_data = CSV.read(lin_csv, headers: true, return_headers: true)
lin_data.delete(0)
sf_index = 0

CSV.foreach(sf_csv, headers: true, return_headers: true) do |sf_row|
  sf_index += 1
  puts "sf: #{sf_index}"
  sf_emails = []
  sf_emails << sf_row['Email']&.downcase if sf_row['Email']
  sf_emails << sf_row['Email 2']&.downcase if sf_row['Email 2']
  sf_emails << sf_row['Email 3']&.downcase if sf_row['Email 3']
  #puts sf_emails

  target_lin_row_num = lin_emails.find_index do |lin_email|
    sf_emails.include?(lin_email)
  end
  if target_lin_row_num
    sf_row['Candidate Source'] = lin_data[target_lin_row_num]['Candidate Source']
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
  new_sf_row['Candidate Source'] = lin_row['Candidate Source']
  new_sf_row['Email'] = lin_row['Email Address']
  new_sf_row['Account Name'] = 'Candidates'
  new_sf_row['Contact Record Type'] = 'Candidate'
  append_to_csv(output_csv, new_sf_row)
end
