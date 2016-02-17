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

$headers = ["Contact", "Employer Name", "Job Title", "Start Date", "End Date", "Location"]

# recruiters = ['AlisonSmith', 'Emily', 'JennyDolan', 'JingJing',
#    'JohnSmith', 'KarenDoyle', 'KarenMcHugh', 'LisaONeill',
#    'LiWang', 'MariaMurphy', 'MaryBerry', 'MikeBrown', 'MyraKumar',
#    'NeasaWhite', 'NiamhBlack', 'SarahKelly', 'SeanMurphy',
#    'SheilaMcNeice', 'Ruby', 'SheilaDempsey', 'SheilaMcGrath',
#    'YuChun']

recruiters = ['SheilaMcNeice']

def main(recruiter)
  puts "Recruiter: #{recruiter}"

  target_dir = "./../LIN#{recruiter}"
  parsed_dir = "./../LIN#{recruiter}/parsed"
  parsed2_dir = "./../LIN#{recruiter}/parsed2"
  FileUtils.mkdir(parsed2_dir) unless Dir.exist?(parsed2_dir)
  output_path = "./../LIN#{recruiter}/LIN#{recruiter}_employment_history_2.csv"
  success_log = "./../LIN#{recruiter}/id_lookup_success2.csv"
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

  positions = page.css("#experience .positions .position")

  positions.each do |position|
    row = CSV::Row.new($headers, [], header_row: false)
    row["Contact"] = contact_id

    row["Job Title"] = position.at_css(".item-title").text.slice(0, 74)
    row["Employer Name"] = position.at_css(".item-subtitle").text.slice(0, 149)
    jstart = position.css(".date-range time")[0]
    jend = position.css(".date-range time")[1]
    row["Start Date"] = format_date(jstart.text)
    row["End Date"] = format_date(jend.text)
    row["Location"] = position.at_css(".location").text.slice(0, 254)
    rows << row
  end


  # text_resume += "\n\nEDUCATION\n" if schools.length > 0
  # schools.each do |school|
  #   stitle = school.at_css(".item-title")
  #   sdegree = school.at_css(".item-subtitle")
  #   sdates = school.at_css(".date-range")
  #   sdesc = school.at_css(".description")
  #   sdesc.css('br').each{|br| br.replace "\n"} if sdesc
  #   text_resume += "\n#{stitle.text}\n" if stitle
  #   text_resume += " - #{sdegree.text}\n" if sdegree.text.length > 0
  #   text_resume += "#{sdates.text}\n" if sdates
  #   text_resume += "#{sdesc.text}\n" if sdesc
  # end


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
