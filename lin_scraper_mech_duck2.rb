require 'rubygems'
require 'mechanize'
require 'csv'
require 'fileutils'

#                                   Urls?      Invalids
# AlisonSmith   - 450/682         - y          - 3
# Emily         - 59/177          - y          - 0
# JennyDolan    - 1167/2459       - y          - 10
# JingJing      - 1093/2540       - y          - 35
# JohnSmith     - 166/321         - y          - 6
# KarenDoyle    - 122/271         - y          - 1
# KarenMcHugh   - 1055/2549       - y          - 51
# LisaONeill    - 450/670         - y          - 2
# LiWang        - 23/37           - y          - 0
# MariaMurphy   - 1039/2197       - y          - 4
# MaryBerry     - 379/700         - y          - 2
# MikeBrown     - 84/109          - y          - 0
# MyraKumar     - 96/198          - y          - 0
# NeasaWhite    - 1532/3226       - y          - 11
# NiamhBlack    - 240/470         - y          - 2
# SarahKelly    - 593/958         - y          - 3
# SeanMurphy    - 1096/2311       - y          - 5
# SheilaMcNeice - 2112/4367       - y          - 81
# Ruby          - 617/1322        - y          - 1
# SheilaDempsey - 54/119          - y          - 1
# SheilaMcGrath - 151/388         - y          - 0
# YuChun        - 57/178          - y          - 0
# Total         - 12635/26249



$proxies = {beijing_telco: {ip: '121.69.28.86', port: '8118'},
            us_hiw: {ip: '165.2.139.51', port: '80'},
            can_sas: {ip: '198.169.246.30', port: '80'},
            spain_tel: {ip: '195.140.157.138', port: '443'},
            china_mobile: {ip: '117.136.234.12', port: '80'}
            }

$user_agents = {mozilla_windows: "Mozilla/5.0 (Windows NT 6.1; WOW64; rv:40.0) Gecko/20100101 Firefox/40.1",
                test_1: "Mozilla/5.0 (Windows; U; Windows NT 5.1; de; rv:1.9.2.3) Gecko/20100401 Firefox/3.6.3",
                google: "Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)"}

$headers = ["First Name",	"Last Name",	"Employer Organization Name 1",
  	        "Employer 1 Title",	"Email",	"CV TR",	"Candidate Source",	"Candidate ID",
    	      "Resume Last Updated",	"Account Name",	"Search Query", "Log", "Url"]

puts "\n\n\n\n\n\n\nSCRAPER STARTING\n\n\n\n\n\n"


def main
  recruiter = 'JohnSmith'

  #output_dir = "./../LIN#{recruiter}"
  #fail_log = "./../LIN#{recruiter}/fail_log.csv"
  #success_log = "./../LIN#{recruiter}/success_log.csv"
  #create_files(recruiter, fail_log, success_log)
  input_csv = "./../LIN#{recruiter}.csv"
  total = %x(wc -l "#{input_csv}").split[0].to_i
  puts "Length of input: #{total} rows.\n"
  count = 0
  start = 3
  finish = 10
  previous_time = Time.now
  # MyraKumar start: 184

  CSV.foreach(input_csv, headers: true) do |row|
    count += 1
    begin

      if count.between?(start, finish)
        puts "Time taken: #{Time.now - previous_time}"
        previous_time = Time.now
        delay(3.5, 1.0)
        puts "\n"
        puts "Input Row #{count}/#{total}"
        agent = Mechanize.new
        #agent = create_proxy(agent, $proxies.keys.sample)
        #agent = create_proxy(agent, 'beijing_telco')
        agent.user_agent = $user_agents["mozilla_windows".to_sym]
        query = create_query(row)
        query.gsub!(/\?/, '')
        puts query
        row["Search Query"] = query
        duck_page = agent.get('https://www.duckduckgo.com/html')
        search_form = duck_page.form_with(id: 'search_form_homepage')
        search_form.q = query
        results_page = agent.submit(search_form)
        #if no results found, results.length == 0 -> failure condition
        lin_url = find_match(results_page, row["First Name"], row["Last Name"],
                             row["Employer Organization Name 1"], row["Employer 1 Title"])
        if lin_url.start_with?("http")
          puts "MATCH FOUND: #{lin_url}"
          lin_url.gsub!(/https/, 'http')
          delay(5.0, 3.0)
          profile_page = agent.get(lin_url)
          correct_profile = validate_profile(profile_page, row["First Name"], row["Last Name"],
                               row["Employer Organization Name 1"], row["Employer 1 Title"])
        else
          puts "NO MATCH FOUND: #{lin_url}"
        #  row["Log"] = lin_url
        #  append_to_csv(fail_log, row)
        end
        # if correct_profile
        #   #save page and make success log
        #   id = row["Candidate ID"]
        #   output_file = File.new("#{output_dir}/#{id}.html", 'w+')
        #   output_file.write(profile_page.body)
        #   output_file.close
        #   row["Url"] = lin_url
        #   append_to_csv(success_log, row)
        # elsif correct_profile == false
        #   #break and make error log
        #   puts "INCORRECT PROFILE"
        #   row["Log"] = "Incorrect profile retrieved from search"
        #   append_to_csv(fail_log, row)
        # else
        #   puts "no valid linkedin url"
        # end
      elsif count > finish
        row["Log"] = "Not attempted"
        #append_to_csv(fail_log, row)
        #break
      end
    rescue Exception => msg
      row["Log"] = msg
      #append_to_csv(fail_log, row)
      if msg.to_s.start_with?("999")
        puts '############# ACCESS DENIED ############'
        puts "long sleep"
        delay(900, 1.0)
      end
      puts msg
    end
  end
  puts "end of main"
end

def create_query(row)
  name = "#{row["First Name"]} #{row["Last Name"]}"
  employer = "#{row["Employer Organization Name 1"]}"
  title = "#{row["Employer 1 Title"]}"
  query = "#{name} #{employer} #{title}"
end

def delay(base, extra)
  prng = Random.new
  wait_time = base + prng.rand(extra)
  puts "sleeping"
  sleep(wait_time)
  puts "waking"
end

def create_files(recruiter, fail_log, success_log)
  dir_name = "./../LIN#{recruiter}"
  unless Dir.exist?(dir_name)
    Dir.mkdir(dir_name)
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
  puts '############# ACCESS GRANTED ############'
  puts profile_name.text
  positions = page.css("#experience .positions .position")
  match = false
  positions.each do |position|
    profile_title = position.at_css("header .item-title a").text
    #puts "csv title: #{title}"

    puts "Profile Title: #{profile_title}"
    profile_employer = position.at_css("header .item-subtitle").text
    #puts "csv emp: #{employer}"
    puts "Profile Employer: #{profile_employer}"
    if profile_title.downcase.include?(title.downcase) && profile_employer.downcase.include?(employer.downcase)
      puts "CORRECT PROFILE"
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

def find_match(page, first_name, last_name, employer, title)
  match = nil
  #puts page.head
  #puts page.body
  full_name = "#{first_name} #{last_name}"
  results = page.css("#links .results_links_deep")
  #puts results
  #puts "results url: #{page.uri}"
  #puts "number of results: #{results.length}"
  puts "Full Name: #{full_name}"
  if employer.nil? || title.nil?
    return "ERR: Nil field"
  end
  results.each do |result|
    url_text = result.css("a.large").text
    url = result.at_css('a.large')['href']    # results in exception if less that 1 full page of results and match not found
  #  puts "url text: #{url_text}"
    paragraph = result.css("div.snippet").text
  #  puts "paragraph: #{paragraph}"
    match_found = true
    bio = "#{paragraph}"
    short_title = title.split
    short_title = "#{short_title[0]} #{short_title[1]}"
  #  puts "short title: #{short_title}"
    short_employer = employer.split
    short_employer = "#{short_employer[0]}"
  #  puts "short employer: #{short_employer}"
    if url.include?("/dir/")
      match_found = false
    end
    unless url.include?("/in/") || url.include?("/pub/")
      match_found = false
    end
    unless url_text.downcase.include?(full_name.downcase) && url_text.include?("LinkedIn")
      match_found = false
    end
    unless bio.downcase.include?(short_title.downcase)
      match_found = false
    end
    unless bio.downcase.include?(short_employer.downcase)
      match_found = false
    end
    if match_found
      return url
    end

  end
  return "No match found"
end

def create_proxy(agent, proxy_name)
  proxy_requested = $proxies["#{proxy_name}".to_sym]
  p "using proxy:  #{proxy_requested}"
  agent.set_proxy(proxy_requested["ip".to_sym], proxy_requested["port".to_sym])
  return agent
end

main
