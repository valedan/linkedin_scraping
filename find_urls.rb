require 'rubygems'
require 'mechanize'
require 'csv'
require 'fileutils'


$headers = ["First Name",	"Last Name",	"Employer Organization Name 1",
  	        "Employer 1 Title",	"Email",	"CV TR",	"Candidate Source",	"Candidate ID",
    	      "Resume Last Updated",	"Account Name",	"Search Query", "Log", "Url"]

puts "\n\n\n\n\n\n\nSTARTING VALIDATION\n\n\n\n\n\n"

def main
  recruiter = 'SarahKelly'

  working_dir = "./../LIN#{recruiter}"
  input_csv = "#{working_dir}/success_log.csv"
  output_csv = "#{working_dir}/success_log_withurls.csv"
  create_files(output_csv)
  total = %x(wc -l "#{input_csv}").split[0].to_i
  puts "Length of input: #{total} rows.\n"
  count = 0
  start = 0
  finish = 100000

  CSV.foreach(input_csv, headers: true) do |row|
    count += 1
    begin
      if count.between?(start, finish)
        puts "\n"
        puts "Input Row #{count}/#{total}"
        filename = "#{row["Candidate ID"]}.html"
        file = File.read("#{working_dir}/#{filename}")
        page = Nokogiri::HTML(file)
        url = page.at_css("link[rel='canonical']")
        puts url['href']
        row["Url"] = url['href']
        append_to_csv(output_csv, row)
      elsif count > finish
        #row["Log"] = "Not attempted"
        #append_to_csv(fail_log, row)
        #break
      end
    rescue Exception => msg
      row["Log"] = msg
      #append_to_csv(fail_log, row)
      puts msg
    end
  end
end

def create_files(success_log)
  unless File.exist?(success_log)
    FileUtils.touch(success_log)
    csv = CSV.open(success_log, "w+")
    csv << $headers
    csv.close
  end
end

def append_to_csv(file, row)
  f = CSV.open(file, "a+", headers: row.headers)
  f << row
  f.close
end
main
