require 'csv'
require 'fileutils'


$headers = ["First Name",	"Last Name",	"Company",
  	        "Job Title",	"E-mail Address",	"Recruiter"]

def append_to_csv(file, row)
  f = CSV.open(file, "a+", headers: row.headers)
  f << row
  f.close
end

def create_file(f)
  unless File.exist?(f)
    FileUtils.touch(f)
    csv = CSV.open(f, "w+")
    csv << $headers
    csv.close
  end
end

$emails = {}
target_dir = './../run3/input'
create_file("#{target_dir}/merged.csv")

recruiter_list = ["LINKarenMcHugh",
                 "LINSeanMurphy",
                 "LINLisaONeill",
                 "LINMariaMurphy",
                 "LINAlisonSmith",
                 "LINKarenDoyle",
                 "LINMikeBrown",
                 "LINJohnSmith",
                 "LINSheilaMcNeice",
                 "LINJennyDolan",
                 "LINSarahKelly",
                 "LINSheilaDempsey",
                 "LINSheilaMcGrath",
                 "LINNiamhBlack",
                 "LINNeasaWhite",
                 "LINMaryBerry",
                 "LINJingJing",
                 "LINLiWang",
                 "LINRuby",
                 "LINMyraKumar",
                 "LINEmily",
                 "LINYuChun"]

recruiter_list.each do |recruiter|
  count = 0
  input_csv = "#{target_dir}/#{recruiter}.csv"
  begin
    CSV.foreach(input_csv, headers: true, encoding: 'windows-1252') do |row|
      count += 1
      puts "compiling email list -> #{recruiter} -> #{count}"
      row["Recruiter"] = recruiter
      unless row['E-mail Address'].nil?
        email = row['E-mail Address'].downcase
      end
      if $emails.has_key?(email)
        $emails[email] << row
      else
        $emails[email] = [row]
      end
    end
  rescue Exception => e
    puts e
  end
end

i = 0
$emails.each {|emails_key, emails_value|
  i += 1
  puts "deduping -> #{i} -> #{emails_key}"
  recruiters = []
  emails_value.each {|row2|
    recruiters << row2['Recruiter']
  }
  priority_recruiter = recruiter_list.find{|recruiter|
    recruiters.include?(recruiter)
  }
  puts "recruiters: #{recruiters} -> selecting: #{priority_recruiter}"
  emails_value.each {|row3|
    if row3['Recruiter'] == priority_recruiter
      output_row = CSV::Row.new($headers, [row3["First Name"].encode('utf-8', 'windows-1252'),
      	row3["Last Name"].encode('utf-8', 'windows-1252'), row3["Company"].encode('utf-8', 'windows-1252'),
         row3["Job Title"].encode('utf-8', 'windows-1252'), row3["E-mail Address"].encode('utf-8', 'windows-1252'),
         	row3["Recruiter"].encode('utf-8', 'windows-1252')])
      append_to_csv("#{target_dir}/merged.csv", output_row)
    end
  }
}
