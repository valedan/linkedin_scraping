require 'rubygems'
require 'mechanize'
require 'csv'
require 'fileutils'
require 'date'

class NilClass
  def text
    return nil
  end
  def [](options = {})
    return nil
  end
  def css(options = {})
    return nil
  end
  def gsub(a, b)
    return nil
  end
  def at_css(options = {})
    return nil
  end
  def slice(a, b, options = {})
    return nil
  end
  def include?(a)
    return false
  end
end

# Compensation ts2__Compensation__c	JS2	Currency(16, 2)
# Contact ts2__Contact__c	JS2	Master-Detail(Contact)
# Employer ts2__Employer__c	JS2	Lookup(Account)
# Employer Name ts2__Name__c	JS2	Text(150)
# End Date ts2__Employment_End_Date__c	JS2	Date
# Job Title ts2__Job_Title__c	JS2	Text(75)
# Location ts2__Location__c	JS2	Text(255)
# Parsed ts2__Parsed__c	JS2	Checkbox
# Responsibilities ts2__Responsibilities__c	JS2	Long Text Area(10000)
# Salaried ts2__Salaried__c	JS2	Checkbox
# Start Date ts2__Employment_Start_Date__c	JS2	Date

$headers = ["Contact", "School Name", "Major", "Graduation Year"]

# recruiters = ['AlisonSmith', 'Emily', 'JennyDolan', 'JingJing',
#    'JohnSmith', 'KarenDoyle', 'KarenMcHugh', 'LisaONeill',
#    'LiWang', 'MariaMurphy', 'MaryBerry', 'MikeBrown', 'MyraKumar',
#    'NeasaWhite', 'NiamhBlack', 'SarahKelly', 'SeanMurphy',
#    'SheilaMcNeice', 'Ruby', 'SheilaDempsey', 'SheilaMcGrath',
#    'YuChun']

#recruiters = ['MariaMurphy', 'SeanMurphy', 'KarenMcHugh', 'JennyDolan', 'JohnSmith']

recruiters = ['SheilaMcNeice']

def main(recruiter)
  puts "Recruiter: #{recruiter}"

  target_dir = "./../LIN#{recruiter}"
  parsed_dir = "./../LIN#{recruiter}/parsed"
  parsed2_dir = "./../LIN#{recruiter}/parsed2"
  output_path = "./../LIN#{recruiter}/LIN#{recruiter}_education_history2.csv"
  success_log = "./../LIN#{recruiter}/id_lookup_success.csv"
  create_files(recruiter, output_path)
  count = 0
  output = CSV.open(output_path, "a+", headers: true)

  CSV.foreach(success_log, headers: true) do |input_row|
    count += 1
    puts "Input Row #{count}"
    candidate_id = input_row["Candidate ID"]
    contact_id = input_row["Contact ID"]
    target_file = "#{parsed_dir}/#{candidate_id}.html"
    if File.exist?(target_file)
      output_rows = parse_html(target_file, contact_id)
      output_rows.each do |output_row|
        output << output_row
      end
      FileUtils.mv(target_file, "#{target_dir}/parsed2/#{candidate_id}.html")
    else
      puts "File for #{candidate_id} NOT FOUND"
    end
  end

  output.close

end

def parse_html(file, contact_id)
  page = Nokogiri::HTML(File.read(file))
  rows = []

  schools = page.css("#education .schools .school")

  schools.each do |school|
    row = CSV::Row.new($headers, [], header_row: false)
    row["Contact"] = contact_id
    row["School Name"] = school.at_css(".item-title").text.slice(0, 149)
    row["Major"] = school.at_css(".item-subtitle").text.slice(0, 254)
    dstart = school.css(".date-range time")[0]
    dend = school.css(".date-range time")[1]
    if dend
      row["Graduation Year"] = dend.text.gsub(/\D/, '').slice(0, 74)
    else
      row["Graduation Year"] = dstart.text.gsub(/\D/, '').slice(0, 74)
    end
    rows << row
  end
  return rows
end

def format_date(input_date)
  if input_date.nil?
    return nil
  end
  begin
    date_arr = input_date.split(" ")
    if date_arr.length == 1
      output_date = Date.strptime(input_date, "%Y")
      return output_date.strftime("%Y-%m-%d")
    elsif date_arr.length == 2
      output_date = Date.strptime(input_date, "%B %Y")
      return output_date.strftime("%Y-%m-%d")
    else
      return nil
    end
  rescue
    if date_arr.length == 2
      return format_date(date_arr[1])
    else
      return nil
    end
  end
end

def create_files(recruiter, output_path)
  unless File.exist?(output_path)
    FileUtils.touch(output_path)
    csv = CSV.open(output_path, "w+")
    csv << $headers
    csv.close
  end

end

recruiters.each do |recruiter|
  main(recruiter)
end
