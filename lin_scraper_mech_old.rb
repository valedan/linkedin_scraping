require 'rubygems'
require 'mechanize'
require 'csv'

$proxies = {beijing_telco: {ip: '121.69.28.86', port: '8118'},
            us_hiw: {ip: '165.2.139.51', port: '80'},
            can_sas: {ip: '198.169.246.30', port: '80'},
            spain_tel: {ip: '195.140.157.138', port: '443'},
            china_mobile: {ip: '117.136.234.12', port: '80'}
            }

$user_agents = {mozilla_windows: "Mozilla/5.0 (Windows NT 6.1; WOW64; rv:40.0) Gecko/20100101 Firefox/40.1",
                test_1: "Mozilla/5.0 (Windows; U; Windows NT 5.1; de; rv:1.9.2.3) Gecko/20100401 Firefox/3.6.3",
                google: "Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)"}
$binghome_url = "http://global.bing.com/?FORM=HPCNEN&setmkt=en-us&setlang=en-us"

puts "\n\n\n\n\n\n\nSCRAPER STARTING\n\n\n\n\n\n"


def main
  recruiter = 'LisaONeill'
  success_log = CSV.open("./../LIN#{recruiter}/success_log.csv", "a+",
                         headers: true, write_headers: true)
  fail_log = CSV.open("./../LIN#{recruiter}/fail_log.csv", "a+",
                         headers: true, write_headers: true)

  input_csv = "./../LIN#{recruiter}.csv"
  #input_csv = "./../LIN#{recruiter}/fail_log.csv"
  output_dir = "./../LIN#{recruiter}"

  count = 0
  CSV.foreach(input_csv, headers: true) do |row|
    count += 1
    begin
      if count < 5
        prng = Random.new
        wait_time = 4.0 + prng.rand(2.0)
        puts "Input Row #{count}"
        puts 'sleeping'
        sleep(wait_time)
        puts 'waking'
        agent = Mechanize.new
        #agent = create_proxy(agent, $proxies.keys.sample)
        #agent = create_proxy(agent, 'can_sas')
        agent.user_agent = $user_agents["mozilla_windows".to_sym]
        query = row["Search Query"]
        query.gsub!(/\?/, '')
        bing_page = agent.get('http://www.bing.com')
        search_form = bing_page.form_with(id: 'sb_form')
        search_form.q = query
        results_page = agent.submit(search_form)
        #if no results found, results.length == 0 -> failure condition
        lin_url = find_match(results_page, row["First Name"], row["Last Name"],
                             row["Employer Organization Name 1"], row["Employer 1 Title"])
        if lin_url.start_with?("http")
          puts "MATCH FOUND: #{lin_url}"
          lin_url.gsub!(/https/, 'http')
          profile_page = agent.get(lin_url)
          correct_profile = validate_profile(profile_page, row["First Name"], row["Last Name"],
                               row["Employer Organization Name 1"], row["Employer 1 Title"])
        else
          puts "NO MATCH FOUND: #{lin_url}"
          row["Log"] = lin_url
          fail_log << row
        end
        if correct_profile
          #save page and make success log
          id = row["Candidate ID"]
          output_file = File.new("#{output_dir}/#{id}.html", 'w+')
          output_file.write(profile_page.body)
          output_file.close
          success_log << row
        elsif correct_profile == false
          #break and make error log
          puts "INCORRECT PROFILE"
          row["Log"] = "Incorrect profile retrieved from Bing"
          fail_log << row
        else
          puts "no valid linkedin url"
        end
      else
        row["Log"] = "Not attempted"
        fail_log << row
        #break
      end
    rescue Exception => msg
      row["Log"] = msg
      fail_log << row
      if msg.to_s.start_with?("999")
        puts '############# ACCESS DENIED ############'
      end
      puts msg
    end
  end
  #puts "end of main"
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
    puts "Profile Title: #{profile_title}"
    profile_employer = position.css("header .item-subtitle").text
    puts "Profile Employer: #{profile_employer}"
    if profile_title.include?(title) && profile_employer.include?(employer)
      puts "CORRECT PROFILE"
      match = true
    else
      puts "WRONG PROFILE"
    end

  end
  return match
end

def find_match(page, first_name, last_name, employer, title)
  match = nil
  full_name = "#{first_name} #{last_name}"
  results = page.css("ol#b_results li.b_algo")
  puts "Full Name: #{full_name}"
  if employer.nil? || title.nil?
    return "ERR: Nil field"
  end
  results.each do |result|
    url_text = result.css("a").text
    fact_row = result.css("ul.b_factrownosep").text
    fact_row.sub!(/\d+\+? CONNECTIONS/, '')
    paragraph = result.css("div.b_caption p").text
    match_found = true
    bio = "#{fact_row} #{paragraph}"
    short_title = title.split
    short_title = "#{short_title[0]} #{short_title[1]}"
    short_employer = employer.split
    short_employer = "#{short_employer[0]}"
    if url_text.downcase.include?(full_name.downcase)
    else
      match_found = false
    end

    if bio.downcase.include?(short_title.downcase)
    else
      match_found = false
    end

    if bio.downcase.include?(short_employer.downcase)
    else
      match_found = false
    end
    if match_found
      return result.at_css('a')['href']
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
