#find cases where a single sf contact has multiple lin profiles

require 'csv'
require 'fileutils'


input_dir = './../run3'
lin_csv = "#{input_dir}/merged.csv"
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

output_csv = "#{input_dir}/lin_dupes.csv"

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
  email = lin_row['E-mail Address'].downcase
  lin_emails << email
end

sf_index = 0

CSV.foreach(sf_csv, headers: true, return_headers: true) do |sf_row|
  sf_index += 1
  puts "sf: #{sf_index}"
  sf_emails = []
  sf_emails << sf_row['Email'].downcase if sf_row['Email']
  sf_emails << sf_row['Email 2'].downcase if sf_row['Email 2']
  sf_emails << sf_row['Email 3'].downcase if sf_row['Email 3']
#  puts sf_emails
  lin_profiles = 0
  sf_emails.each do |sf_email|
    if sf_email.include?("@") && lin_emails.include?(sf_email)
    #  puts "match found for #{sf_email}"
      lin_profiles += 1
    end
  end
  if lin_profiles > 1
  #  puts "#{lin_profiles} - appended"
    append_to_csv(output_csv, sf_row)
  end
end
