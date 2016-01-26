require 'rubygems'
require 'mechanize'
require 'csv'
require 'fileutils'


$headers = ["First Name",	"Last Name",	"Employer Organization Name 1",
  	        "Employer 1 Title",	"Email",	"CV TR",	"Candidate Source",	"Candidate ID",
    	      "Resume Last Updated",	"Account Name",	"Search Query", "Log", "Url"]

puts "\n\n\n\n\n\n\nSTARTING VALIDATION\n\n\n\n\n\n"

def main
  recruiter = 'MariaMurphy'

  working_dir = "./../LIN#{recruiter}"
  move_dir = "#{working_dir}/unvalidated_profiles"
  fail_log = "#{working_dir}/validated_fail_log.csv"
  success_log = "#{working_dir}/validated_success_log.csv"
  create_files(move_dir, fail_log, success_log)
  input_csv = "#{working_dir}/success_log.csv"
  total = %x(wc -l "#{input_csv}").split[0].to_i - 1
  puts "Length of input: #{total} rows.\n"
  count = 0
  start = 0
  finish = 100000
  invalids = 0

  CSV.foreach(input_csv, headers: true) do |row|
    count += 1
    begin

      if count.between?(start, finish)
        puts "\n"
        puts "Input Row #{count}/#{total}"
        filename = "#{row["Candidate ID"]}.html"
        file = File.read("#{working_dir}/#{filename}")
        page = Nokogiri::HTML(file)
        puts "checking #{row["Candidate ID"]}"

        correct_profile = validate_profile(page, row["First Name"], row["Last Name"],
                             row["Employer Organization Name 1"], row["Employer 1 Title"])
        if correct_profile
          puts "~~~~~~~~~~~ CORRECT PROFILE ~~~~~~~~~~~"
          append_to_csv(success_log, row)
        else
          puts '###########  WRONG PROFILE  ###########'
          append_to_csv(fail_log, row)
          FileUtils.mv("#{working_dir}/#{filename}", "#{move_dir}/#{filename}")
          invalids += 1
        end
      elsif count > finish
        #row["Log"] = "Not attempted"
        #append_to_csv(fail_log, row)
        #break
      end
    rescue Exception => msg
      row["Log"] = msg
      append_to_csv(fail_log, row)
      puts msg
    end
  end
  puts "Detected #{invalids} incorrect profiles"
  puts "end of main"
end

def create_files(move_dir, fail_log, success_log)
  unless Dir.exist?(move_dir)
    Dir.mkdir(move_dir)
  end
  unless File.exist?(fail_log)
    FileUtils.touch(fail_log)
    csv = CSV.open(fail_log, "w+")
    csv << $headers
    csv.close
  end
  unless File.exist?(success_log)
    FileUtils.touch(success_log)
    csv = CSV.open(success_log, "w+")
    csv << $headers
    csv.close
  end
end

def validate_profile(page, first_name, last_name, employer, title)
  full_name = "#{first_name} #{last_name}"
  profile_name = page.css("#name")
  #puts profile_name.text
  positions = page.css("#experience .positions .position")
  match = false
  positions.each do |position|
    profile_title = position.at_css("header .item-title a").text
    #puts "csv title: #{title}"

    #puts "Profile Title: #{profile_title}"
    profile_employer = position.at_css("header .item-subtitle").text
    #puts "csv emp: #{employer}"
    #puts "Profile Employer: #{profile_employer}"
    if profile_title.downcase.include?(title.downcase) && profile_employer.downcase.include?(employer.downcase)
      match = true
    end

  end
  return match
end

def append_to_csv(file, row)
  row["Log"] = "" if row.nil?
  f = CSV.open(file, "a+", headers: row.headers)
  f << row
  f.close
end
main
