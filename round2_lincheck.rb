require 'rubygems'
require 'mechanize'
require 'csv'
require 'fileutils'
require 'i18n'

class String
  def alnum
    return self.gsub(/[^\p{Alnum}\p{Space}]/u, ' ')
  end
end


# AlisonSmith - 450/682
# Emily - 59/177
# JennyDolan - 1167/2459
# JingJing - 1093/2540
# JohnSmith - 166/321
# KarenDoyle - 122/271
# KarenMcHugh - 1055/2549
# LisaONeill - 450/670
# LiWang - 23/37
# MariaMurphy - 1039/2197
# MaryBerry - 379/700
# MikeBrown - 84/109
# MyraKumar - 90/198
# NeasaWhite - 1532/3226
# NiamhBlack - 240/470
# SarahKelly - 593/958
# SeanMurphy - 1096/2311
# SheilaMcNeice - 2112/4367
# Ruby - 0/1322
# SheilaDempsey - 54/119
# SheilaMcGrath - 151/388
# YuChun - 0/178
# Total - 10327



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

$correct_profile_page = nil

puts "\n\n\n\n\n\n\nSCRAPER STARTING\n\n\n\n\n\n"

def main
  recruiter = 'MaryBerry'

  output_dir = "./../LIN#{recruiter}/round2"
  fail_log = "#{output_dir}/fail_log.csv"
  success_log = "#{output_dir}/success_log.csv"
  create_files(output_dir, fail_log, success_log)
  input_csv = "./../LIN#{recruiter}/ddg_success_log.csv"
  total = %x(wc -l "#{input_csv}").split[0].to_i
  puts "Length of input: #{total} rows.\n"
  count = 0
  start = 0
  finish = 10000
  previous_time = Time.now

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
        correct_profile = check_urls(row["Url"], agent, row["First Name"], row["Last Name"],
                             row["Employer Organization Name 1"], row["Employer 1 Title"])
        if correct_profile.start_with?("http")
          puts "MATCH FOUND: #{correct_profile}"
          id = row["Candidate ID"]
          output_file = File.new("#{output_dir}/#{id}.html", 'w+')
          output_file.write($correct_profile_page.body)
          output_file.close
          row["Url"] = correct_profile
          append_to_csv(success_log, row)
        else
          puts "NO MATCH FOUND"
          row["Log"] = correct_profile
          append_to_csv(fail_log, row)
        end

      elsif count > finish
        #row["Log"] = "Not attempted"
        #append_to_csv(fail_log, row)
        #break
      end
    rescue Exception => msg
      row["Log"] = msg
      append_to_csv(fail_log, row)
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

def check_urls(url_string, agent, first_name, last_name, employer, title)
  urls = url_string.split("; ")
  urls.each do |url|
    delay(5.0, 3.0)
    page = agent.get(url)
    puts "checking #{url}"
    if validate_profile(page, first_name, last_name, employer, title)
      $correct_profile_page = page
      return url
    else
      puts "incorrect profile"
    end
  end
  return "no matches found"
end


def delay(base, extra)
  prng = Random.new
  wait_time = base + prng.rand(extra)
  puts "sleeping"
  sleep(wait_time)
  puts "waking"
end

def create_files(dir_name, fail_log, success_log)
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

def create_proxy(agent, proxy_name)
  proxy_requested = $proxies["#{proxy_name}".to_sym]
  p "using proxy:  #{proxy_requested}"
  agent.set_proxy(proxy_requested["ip".to_sym], proxy_requested["port".to_sym])
  return agent
end

main
