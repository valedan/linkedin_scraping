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
# Spec: for each row in success log, look for a file with that id. if found, parse file
#       and generate new row to add to output csv and move file into parsed folder

# First Name                                Text(40)
# Last Name                                 Text(80)
# Title                                     Text(128)
# Email                                     Email
# Contact Country                           Picklist(send sean lin list)
# Contact LIN Sector                        Text(100)(Unique Case Insensitive)
# Text Resume                               Long Text Area(32000)
# Employer 1 Title                          Long Text Area(32000)
# Employer Organization Name 1              Text Area(255)
# Employer 1 Start Date                     Date
# Employer 1 End Date                       Date
# Employer 1 Location                       Text Area(255)
# Employer 1 Description                    Long Text Area(32000)
# License or Certification Name 1           Text Area(255)
# License or Certification Credential Type  Text Area(255)
# Education School 1                        Text(125)
# Education Degree Name 1                   Text Area(255)
# Languages                                 Text(100)
# LinkedIn Profile                          URL(255)
# Candidate ID                              Auto Number
# Candidate Source                          Lookup(Source)

#Salesforce required date format: yyyy-mm-dd

# LIN date possibilities: Experience - Month yyyy (Month optional)
# =>                      Education - yyyy


# recruiters = ['AlisonSmith', 'Emily', 'JingJing',
#    'KarenDoyle', 'LisaONeill',
#    'LiWang', 'MikeBrown', 'MyraKumar',
#    'NeasaWhite', 'NiamhBlack', 'MaryBerry', 'SarahKelly',
#    'SheilaMcNeice', 'Ruby', 'SheilaDempsey', 'SheilaMcGrath',
#    'YuChun']

recruiters = ['YuChun']

$headers = ["First Name", "Last Name", "Email", "LinkedIn Profile", "Candidate ID",
            "Candidate Source", "Title", "Contact Country", "Contact LIN Sector",
            "Employer 1 Title", "Employer Organization Name 1", "Employer 1 Start Date",
            "Employer 1 End Date", "Employer 1 Location", "Employer 1 Description",
            "Employer 2 Title", "Employer Organization Name 2", "Employer 2 Start Date",
            "Employer 2 End Date", "Employer 2 Location", "Employer 2 Description",
            "Employer 3 Title", "Employer Organization Name 3", "Employer 3 Start Date",
            "Employer 3 End Date", "Employer 3 Location", "Employer 3 Description",
            "License or Certification Name 1", "License or Certification Name 2",
            "License or Certification Credential Type", "Education School 1",
            "Education Degree Name 1", "Education Degree Date 1",
            "Education School 2", "Education Degree Name 2",
            "Education Degree Date 2", "Text Resume"]

def main(recruiter)
  puts recruiter

  target_dir = "./../LIN#{recruiter}/round2"
  parsed_dir = "./../LIN#{recruiter}/round2/parsed"
  FileUtils.mkdir(parsed_dir) unless Dir.exist?(parsed_dir)
  output_path = "./../LIN#{recruiter}/round2/LIN#{recruiter}.csv"
  success_log = "./../LIN#{recruiter}/round2/success_log.csv"
  create_files(recruiter, output_path)
  total = %x(wc -l "#{success_log}").split[0].to_i - 1
  puts "Length of input: #{total} rows.\n"
  count = 0
  output = CSV.open(output_path, "a+", headers: true)

  CSV.foreach(success_log, headers: true) do |input_row|
    count += 1
    puts "Input Row #{count}/#{total}"
    candidate_id = input_row["Candidate ID"]
    target_file = "#{target_dir}/#{candidate_id}.html"
    if File.exist?(target_file)
      #puts "File for #{candidate_id} exists"
      output_row = parse_html(target_file, input_row)
      output << output_row
      FileUtils.mv(target_file, "#{target_dir}/parsed/#{candidate_id}.html")

    else
      puts "File for #{candidate_id} NOT FOUND"
    end
  end

  output.close

end

def parse_html(file, input_row)
  page = Nokogiri::HTML(File.read(file))
  row = CSV::Row.new($headers, [], header_row: false)
  name = page.at_css("#name").text.split
  email = input_row["Email"]
  lin_profile = input_row["Url"]
  cand_id = input_row["Candidate ID"]
  cand_source = input_row["Candidate Source"]
  title = page.at_css(".headline.title").text
  country = page.at_css("#demographics .locality").text
  sector = page.at_css("#demographics .descriptor:not(.adr)").text

  positions = page.css("#experience .positions .position")
  e1_title = positions[0].at_css(".item-title").text
  e1_org = positions[0].at_css(".item-subtitle").text
  e1_start = positions[0].css(".date-range time")[0].text
  e1_end = positions[0].css(".date-range time")[1].text
  e1_loc = positions[0].at_css(".location").text
  e1_desc = positions[0].at_css(".description").text
  e2_title = positions[1].at_css(".item-title").text
  e2_org = positions[1].at_css(".item-subtitle").text
  e2_start = positions[1].css(".date-range time")[0].text
  e2_end = positions[1].css(".date-range time")[1].text
  e2_loc = positions[1].at_css(".location").text
  e2_desc = positions[1].at_css(".description").text
  e3_title = positions[2].at_css(".item-title").text
  e3_org = positions[2].at_css(".item-subtitle").text
  e3_start = positions[2].css(".date-range time")[0].text
  e3_end = positions[2].css(".date-range time")[1].text
  e3_loc = positions[2].at_css(".location").text
  e3_desc = positions[2].at_css(".description").text

  certs = page.css(".certifications .certification")
  c1_name = certs[0].at_css(".item-title").text
  c2_name = certs[1].at_css(".item-title").text
  c_type  = certs[0].at_css(".item-subtitle").text

  schools = page.css("#education .schools .school")
  s1_name = schools[0].at_css(".item-title").text
  s2_name = schools[1].at_css(".item-title").text
  s1_start = schools[0].css(".date-range time")[0].text
  s2_start = schools[1].css(".date-range time")[0].text
  s1_end = schools[0].css(".date-range time")[1].text
  s2_end = schools[1].css(".date-range time")[1].text
  s1_degree = schools[0].at_css(".item-subtitle").text
  s2_degree = schools[1].at_css(".item-subtitle").text

  summary = page.at_css("#summary .description")
  summary.css('br').each{|br| br.replace "\n"} if summary

  text_resume = "\n\n***IMPORTED FROM LINKEDIN***\n#{lin_profile}\n\n"
  text_resume += name.join(" ")
  text_resume += "\n#{email}"
  text_resume += "\nTitle: #{title}" if title
  text_resume += "\nLocation: #{country}" if country
  text_resume += "\nSector: #{sector}" if sector
  text_resume += "\n\nSUMMARY\n#{summary.text}" if summary
  text_resume += "\n\nEXPERIENCE\n" if positions.length > 0
  positions.each do |position|
    jtitle = position.at_css(".item-title")
    jcompany = position.at_css(".item-subtitle")
    jdates = position.at_css(".date-range")
    jlocation = position.at_css(".location")
    jdesc = position.at_css(".description")
    jdesc.css('br').each{|br| br.replace "\n"} if jdesc
    text_resume += "\n#{jtitle.text}\n" if jtitle
    text_resume += " - #{jcompany.text}\n" if jcompany.text.length > 0
    text_resume += "#{jdates.text}\n" if jdates
    text_resume += "#{jlocation.text}\n" if jlocation
    text_resume += "#{jdesc.text}\n" if jdesc
  end
  text_resume += "\n\nEDUCATION\n" if schools.length > 0
  schools.each do |school|
    stitle = school.at_css(".item-title")
    sdegree = school.at_css(".item-subtitle")
    sdates = school.at_css(".date-range")
    sdesc = school.at_css(".description")
    sdesc.css('br').each{|br| br.replace "\n"} if sdesc
    text_resume += "\n#{stitle.text}\n" if stitle
    text_resume += " - #{sdegree.text}\n" if sdegree.text.length > 0
    text_resume += "#{sdates.text}\n" if sdates
    text_resume += "#{sdesc.text}\n" if sdesc
  end
  text_resume  += "\n\nCERTIFICATIONS\n" if certs.length > 0
  certs.each do |cert|
    ctitle = cert.at_css(".item-title")
    csub = cert.at_css(".item-subtitle")
    cdates = cert.at_css(".date-range")
    text_resume += "\n#{ctitle.text}\n" if ctitle
    text_resume += "#{csub.text}\n" if csub
    text_resume += "#{cdates.text}\n" if cdates
  end
  interests = page.css("#interests .pills .interest")
  text_resume += "\nINTERESTS\n" if interests.length > 0
  ints = []
  interests.each do |interest|
    int = interest.at_css(".wrap").text
    if int
      ints << int unless (int == "See less") || (int.match(/See \d+\+/))
    end
  end
  text_resume += "#{ints.join(", ")}\n\n"
  skills = page.css("#skills .pills .skill")
  text_resume += "\n\nSKILLS\n" if skills.length > 0
  sks = []
  skills.each do |skill|
    sk = skill.at_css(".wrap").text
    if sk
      sks << sk unless (sk == "See less") || (sk.match(/See \d+\+/))
    end
  end
  text_resume += "#{sks.join(", ")}\n\n"
  languages = page.css("#languages .language")
  text_resume += "\n\nLANGUAGES\n" if languages.length > 0
  langs = []
  languages.each do |language|
    lang = language.at_css(".name").text
    prof = language.at_css(".proficiency")
    lang += " (#{prof.text})" if prof && prof.text.length > 0
    langs << lang if lang
  end
  text_resume += "#{langs.join(", ")}\n\n"
  projects = page.css("#projects .project")
  text_resume += "\n\nPROJECTS\n" if projects.length > 0
  projects.each do |project|
    ptitle = project.at_css(".item-title")
    pdates = project.at_css(".date-range")
    pdesc = project.at_css(".description")
    pdesc.css('br').each{|br| br.replace "\n"} if pdesc
    pcont = project.at_css(".contributors")
    text_resume += "\n#{ptitle.text}\n" if ptitle
    text_resume += "#{pdates.text}\n" if pdates
    text_resume += "#{pdesc.text}\n" if pdesc
    text_resume += "#{pcont.text}\n " if pcont
  end
  pubs = page.css("#publications .publication")
  text_resume += "\n\nPUBLICATIONS\n" if pubs.length > 0
  pubs.each do |pub|
    pubtitle = pub.at_css(".item-title")
    pubsub = pub.at_css(".item-subtitle")
    pubdates = pub.at_css(".date-range")
    pubdesc = pub.at_css(".description")
    pubdesc.css('br').each{|br| br.replace "\n"} if pubdesc
    pubcont = pub.at_css(".contributors")
    text_resume += "\n#{pubtitle.text}\n" if pubtitle
    text_resume += "#{pubsub.text}\n" if pubsub
    text_resume += "#{pubdates.text}\n" if pubdates
    text_resume += "#{pubdesc.text}\n" if pubdesc
    text_resume += "#{pubcont.text}\n" if pubcont
  end
  vols = page.css("#volunteering .position")
  text_resume += "\n\nVOLUNTEERING\n" if vols.length > 0
  vols.each do |vol|
    voltitle = vol.at_css(".item-title")
    volsub = vol.at_css(".item-subtitle")
    voldates = vol.at_css(".date-range")
    voldesc = vol.at_css(".description")
    voldesc.css('br').each{|br| br.replace "\n"} if voldesc
    volcause = vol.at_css(".cause")
    text_resume += "\n#{voltitle.text}\n" if voltitle
    text_resume += "#{volsub.text}\n" if volsub
    text_resume += "#{voldates.text}\n" if voldates
    text_resume += "Cause: #{volcause.text}\n" if volcause
    text_resume += "#{voldesc.text}\n" if voldesc
  end
  orgs = page.css("#organizations li")
  text_resume += "\n\nORGANIZATIONS\n" if orgs.length > 0
  orgs.each do |org|
    orgtitle = org.at_css(".item-title")
    orgsub = org.at_css(".item-subtitle")
    orgdates = org.at_css(".date-range")
    orgdesc = org.at_css(".description")
    orgdesc.css('br').each{|br| br.replace "\n"} if orgdesc
    text_resume += "\n#{orgtitle.text}\n" if orgtitle
    text_resume += "#{orgsub.text}\n" if orgsub
    text_resume += "#{orgdates.text}\n" if orgdates
    text_resume += "#{orgdesc.text}\n" if orgdesc
  end
  pats = page.css("#patents .patent")
  text_resume += "\n\nPATENTS\n" if pats.length > 0
  pats.each do |pat|
    pattitle = pat.at_css(".item-title")
    patsub = pat.at_css(".item-subtitle")
    patdates = pat.at_css(".date-range")
    patdesc = pat.at_css(".description")
    patdesc.css('br').each{|br| br.replace "\n"} if patdesc
    patcont = pat.at_css(".contributors")
    text_resume += "\n#{pattitle.text}\n" if pattitle
    text_resume += "#{patsub.text}\n" if patsub
    text_resume += "#{patdates.text}\n" if patdates
    text_resume += "#{patdesc.text}\n" if patdesc
    text_resume += "#{patcont.text}\n" if patcont
  end
  awards = page.css("#awards .award")
  text_resume += "\n\nAWARDS\n" if awards.length > 0
  awards.each do |award|
    atitle = award.at_css(".item-title")
    asub = award.at_css(".item-subtitle")
    adates = award.at_css(".date-range")
    adesc = award.at_css(".description")
    adesc.css('br').each{|br| br.replace "\n"} if adesc
    text_resume += "\n#{atitle.text}\n" if atitle
    text_resume += "#{asub.text}\n" if asub
    text_resume += "#{adates.text}\n" if adates
    text_resume += "#{adesc.text}\n" if adesc
  end
  courses = page.css("#courses li")
  text_resume += "\n\nCOURSES\n" if courses.length > 0
  courses.each do |course|
    coutitle = course.at_css(".item-title")
    coulist = course.at_css(".courses-list")
    text_resume += "\n#{coutitle.text}\n" if coutitle
    text_resume += "#{coulist.text}\n" if coulist
  end




  row["First Name"] = name[0].slice(0, 39)
  row["Last Name"] = name[1..-1].join(" ").slice(0, 79)
  row["Email"] = email
  row["Candidate ID"] = cand_id
  row["Candidate Source"] = cand_source
  row["Title"] = title.slice(0, 127)
  row["Contact Country"] = country
  row["Contact LIN Sector"] = sector.slice(0, 99)
  row["Employer 1 Title"] = e1_title.slice(0, 31999)
  row["Employer Organization Name 1"] = e1_org.slice(0, 254)
  row["Employer 1 Start Date"] = format_date(e1_start) #format
  row["Employer 1 End Date"] = format_date(e1_end) #format
  row["Employer 1 Location"] = e1_loc.slice(0, 254)
  row["Employer 1 Description"] = e1_desc.slice(0, 31999)
  row["Employer 2 Title"] = e2_title.slice(0, 31999)
  row["Employer Organization Name 2"] = e2_org.slice(0, 254)
  row["Employer 2 Start Date"] = format_date(e2_start) #format
  row["Employer 2 End Date"] = format_date(e2_end) #format
  row["Employer 2 Location"] = e2_loc.slice(0, 254)
  row["Employer 2 Description"] = e2_desc.slice(0, 31999)
  row["Employer 3 Title"] = e3_title.slice(0, 31999)
  row["Employer Organization Name 3"] = e3_org.slice(0, 254)
  row["Employer 3 Start Date"] = format_date(e3_start) #format
  row["Employer 3 End Date"] = format_date(e3_end) #format
  row["Employer 3 Location"] = e3_loc.slice(0, 254)
  row["Employer 3 Description"] = e3_desc.slice(0, 31999)
  row["License or Certification Name 1"] = c1_name.slice(0, 254)
  row["License or Certification Name 2"] = c2_name.slice(0, 254)
  row["License or Certification Credential Type"] = c_type.slice(0, 254)
  row["Education School 1"] = s1_name.slice(0, 124)
  row["Education Degree Name 1"] = s1_degree.slice(0, 254)
  row["Education Degree Date 1"] = format_date(s1_end)
  row["Education School 2"] = s2_name.slice(0, 124)
  row["Education Degree Name 2"] = s2_degree.slice(0, 254)
  row["Education Degree Date 2"] = format_date(s2_end)
  row["Text Resume"] = text_resume.slice(0, 31999)
  row["LinkedIn Profile"] = lin_profile.slice(0, 254)

  return row
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
  dir_name = "./../LIN#{recruiter}"

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
