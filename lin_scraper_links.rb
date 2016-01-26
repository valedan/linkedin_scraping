require 'rubygems'
require 'mechanize'
require 'csv'
require 'fileutils'

$proxies = {beijing_telco: {ip: '121.69.28.86', port: '8118'},
            us_hiw: {ip: '165.2.139.51', port: '80'},
            can_sas: {ip: '198.169.246.30', port: '80'},
            spain_tel: {ip: '195.140.157.138', port: '443'},
            china_mobile: {ip: '117.136.234.12', port: '80'}
            }

$user_agents = {mozilla_windows: "Mozilla/5.0 (Windows NT 6.1; WOW64; rv:40.0) Gecko/20100101 Firefox/40.1",
                test_1: "Mozilla/5.0 (Windows; U; Windows NT 5.1; de; rv:1.9.2.3) Gecko/20100401 Firefox/3.6.3",
                google: "Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)"}

puts "\n\n\n\n\n\n\nSCRAPER STARTING\n\n\n\n\n\n"


def main
  recruiter = 'MariaMurphy'

  output_dir = "./../LIN#{recruiter}"
  fail_log = "./../LIN#{recruiter}/fail_log3.csv"
  success_log = "./../LIN#{recruiter}/success_log.csv"
  create_files(recruiter, fail_log, success_log)
  #input_csv = "./../LIN#{recruiter}.csv"
  input_csv = "./../LIN#{recruiter}/fail_log2.csv"

  count = 0
  CSV.foreach(input_csv, headers: true) do |row|
    count += 1
    begin
      if count < 10000
        prng = Random.new
        wait_time = 4.0 + prng.rand(4.0)
        puts "Input Row #{count}"
        puts 'sleeping'
        sleep(wait_time)
        puts 'waking'
        agent = Mechanize.new
        #agent = create_proxy(agent, $proxies.keys.sample)
        #agent = create_proxy(agent, 'spain_tel')
        agent.user_agent = $user_agents["mozilla_windows".to_sym]
        #query = create_query(row)
        #query.gsub!(/\?/, '')
        #puts query
        #duck_page = agent.get('https://www.duckduckgo.com/html')
        #search_form = duck_page.form_with(id: 'search_form_homepage')
        #search_form.q = query
        #results_page = agent.submit(search_form)
        #if no results found, results.length == 0 -> failure condition
        lin_url = row["Url"]
        if lin_url.start_with?("http")
          puts "MATCH FOUND: #{lin_url}"
          lin_url.gsub!(/https/, 'http')
          profile_page = agent.get(lin_url)
          correct_profile = validate_profile(profile_page, row["First Name"], row["Last Name"],
                               row["Employer Organization Name 1"], row["Employer 1 Title"])
        else
          puts "NO MATCH FOUND: #{lin_url}"
          row["Log"] = lin_url
          append_to_csv(fail_log, row)
        end
        if correct_profile
          #save page and make success log
          id = row["Candidate ID"]
          output_file = File.new("#{output_dir}/#{id}.html", 'w+')
          output_file.write(profile_page.body)
          output_file.close
          row["Url"] = lin_url
          append_to_csv(success_log, row)
        elsif correct_profile == false
          #break and make error log
          puts "INCORRECT PROFILE"
          row["Log"] = "Incorrect profile retrieved from Bing"
          append_to_csv(fail_log, row)
        else
          puts "no valid linkedin url"
        end
      else
        row["Log"] = "Not attempted"
        append_to_csv(fail_log, row)
        #break
      end
    rescue Exception => msg
      row["Log"] = msg
      append_to_csv(fail_log, row)
      if msg.to_s.start_with?("999")
        puts '############# ACCESS DENIED ############'
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


def create_files(recruiter, fail_log, success_log)
  dir_name = "./../LIN#{recruiter}"
  unless Dir.exist?(dir_name)
    Dir.mkdir(dir_name)
  end

  unless File.exist?(fail_log)
    FileUtils.touch(fail_log)
  end
  unless File.exist?(success_log)
    FileUtils.touch(success_log)
  end
end

def validate_profile(page, first_name, last_name, employer, title)
  full_name = "#{first_name} #{last_name}"
  profile_name = page.css("#name")
  puts '############# ACCESS GRANTED ############'
  puts profile_name.text
  positions = page.css("#experience .positions")
  match = false
  positions.each do |position|
    profile_title = position.css("header .item-title a").text
    #puts "csv title: #{title}"

    puts "Profile Title: #{profile_title}"
    profile_employer = position.css("header .item-subtitle").text
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
    url = result.at_css('a.large')['href']
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
