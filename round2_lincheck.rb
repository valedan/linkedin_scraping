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
#
# AlisonSmith   -
# Emily         -
# JennyDolan    -
# JingJing      -
# JohnSmith     -
# KarenDoyle    -
# KarenMcHugh   -
# LisaONeill    -
# LiWang        -
# MariaMurphy   -
# MaryBerry     -
# MikeBrown     -
# MyraKumar     -
# NeasaWhite    -
# NiamhBlack    -
# SarahKelly    -
# SeanMurphy    -
# SheilaMcNeice -
# Ruby          -
# SheilaDempsey -
# SheilaMcGrath -
# YuChun        -
# Total         -



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
  recruiter = 'MariaMurphy'

  output_dir = "./../LIN#{recruiter}/round2"
  fail_log = "#{output_dir}/fail_log2.csv"
  success_log = "#{output_dir}/success_log.csv"
  create_files(output_dir, fail_log, success_log)
  input_csv = "./../LIN#{recruiter}/ddg_success_log.csv"
  total = %x(wc -l "#{input_csv}").split[0].to_i - 1
  puts "Length of input: #{total} rows.\n"
  count = 0
  start = 1055
  finish = 10000
  I18n.available_locales = [:en]
  previous_time = Time.now

  CSV.foreach(input_csv, headers: true) do |row|
    count += 1
    begin

      if count.between?(start, finish)
        puts "Time taken: #{Time.now - previous_time}"
        previous_time = Time.now
        #delay(3.5, 1.0)
        puts "\n"
        puts "Input Row #{count}/#{total}"
        agent = Mechanize.new
        #agent = create_proxy(agent, $proxies.keys.sample)
        #agent = create_proxy(agent, 'beijing_telco')
        agent.user_agent = $user_agents["mozilla_windows".to_sym]
        correct_profile_url, correct_profile_page = check_urls(row["Url"], agent, row["First Name"], row["Last Name"],
                                                    row["Employer Organization Name 1"], row["Employer 1 Title"])
        if correct_profile_url.start_with?("http")
          puts "MATCH FOUND: #{correct_profile_url}"
          id = row["Candidate ID"]
          output_file = File.new("#{output_dir}/#{id}.html", 'w+')
          output_file.write(correct_profile_page.body)
          output_file.close
          row["Url"] = correct_profile_url
          append_to_csv(success_log, row)
        else
          puts "NO MATCH FOUND"
          row["Log"] = correct_profile_page
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
    begin
      delay(8.0, 3.0)
      page = agent.get(url)
      puts "checking #{url}"
      if validate_profile(page, first_name, last_name, employer, title) == true
        return [url, page]
      else
        puts "incorrect profile"
      end
    rescue Exception => e
      puts "problem fetching/validating page"
      puts e
      if e.to_s.start_with?("999")
        puts '############# ACCESS DENIED ############'
        puts "long sleep"
        delay(900, 1.0)
      end
    end
  end
  return ["no matches found", "no matches found"]
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

### rewrite to include new sanitization logic ###
def validate_profile(page, first_name, last_name, employer, title)
  full_name = I18n.transliterate("#{first_name} #{last_name}").alnum
  profile_name = I18n.transliterate(page.at_css("#name").text).alnum
  puts '############# ACCESS GRANTED ############'
  puts profile_name
  positions = page.css("#experience .positions .position")
  match = false
  unless split_string_comp(profile_name, full_name) == true
    return match
  end
  positions.each do |position|
    if position.at_css("header .item-title a") && position.at_css("header .item-subtitle")
      profile_title = I18n.transliterate(position.at_css("header .item-title a").text).alnum
      profile_employer = I18n.transliterate(position.at_css("header .item-subtitle").text).alnum
      title = I18n.transliterate(title).alnum
      employer = I18n.transliterate(employer).alnum
      if split_string_comp(profile_title, title) && split_string_comp(profile_employer, employer)
        match = true
      end
    end
  end
  return match
end

def split_string_comp(observed_string, canon_string)
  canon_array = canon_string.downcase.split(" ")
  observed_array = observed_string.downcase.split(" ")
  match = true
  canon_array.each do |chunk|
    unless observed_array.include?(chunk)
      match = false
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
