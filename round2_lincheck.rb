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



$proxies = [
            '89.36.66.229',
            '91.235.142.232',
            '91.235.142.173',
            '91.235.142.146',
            '89.36.66.136'
            ]


$user_agents = ['Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/41.0.2227.1 Safari/537.36',
                'Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/41.0.2228.0 Safari/537.36',
                'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/42.0.2311.135 Safari/537.36 Edge/12.246',
                'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_3) AppleWebKit/537.75.14 (KHTML, like Gecko) Version/7.0.3 Safari/7046A194A',
               'Mozilla/5.0 (Windows NT 6.1; WOW64; rv:40.0) Gecko/20100101 Firefox/40.1'
            ]

$index = 4

$headers = ["First Name",	"Last Name",	"Employer Organization Name 1",
  	        "Employer 1 Title",	"Email",	"CV TR",	"Candidate Source",	"Candidate ID",
    	      "Resume Last Updated",	"Account Name",	"Search Query", "Log", "Url"]

puts "\n\n\n\n\n\n\nSCRAPER STARTING\n\n\n\n\n\n"
### re-do MariaMurphy from r2 fail log - validate uniqueness before parsing! ###
#recruiters = ['MaryBerry', 'NiamhBlack', 'LisaONeill', 'AlisonSmith', 'SheilaMcGrath']
def main#(recruiter)
  #puts recruiter
  recruiter = 'YuChun'
  output_dir = "./../LIN#{recruiter}/round2"
  fail_log = "#{output_dir}/fail_log.csv"
  success_log = "#{output_dir}/success_log.csv"
  create_files(output_dir, fail_log, success_log)
  input_csv = "./../LIN#{recruiter}/ddg_success_log.csv"
  total = %x(wc -l "#{input_csv}").split[0].to_i - 1
  puts "Length of input: #{total} rows.\n"
  count = 0
  start = 0

  finish = 10000
  I18n.available_locales = [:en]
  previous_time = Time.now

  CSV.foreach(input_csv, headers: true) do |row|
    count += 1

    begin

      if count.between?(start, finish)
        puts "Time taken: #{Time.now - previous_time}"
        previous_time = Time.now
        puts "\n"
        puts "Input Row #{count}/#{total}"


        correct_profile_url, correct_profile_page = check_urls(row["Url"], row["First Name"], row["Last Name"],
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
      end

    rescue Exception => msg
      row["Log"] = msg
      append_to_csv(fail_log, row)
      if msg.to_s.start_with?("999")
        puts '############# ACCESS DENIED ############'
        puts '################ ABORTING ##############'
        puts msg
        abort
      end
    end
  end
  puts "end of main"
end

def check_urls(url_string, first_name, last_name, employer, title)
  urls = url_string.split("; ")
  urls.each do |url|
    tries = 5
    begin
      delay(5.0, 1.0)
      agent = Mechanize.new
      if $index == 4
        $index = 0
      else
        $index += 1
      end
      agent.set_proxy($proxies[$index], '80')
      agent.user_agent = $user_agents[$index]
      puts "IP: #{$proxies[$index]}"
      puts "UA: #{$user_agents[$index]}"


      page = agent.get(url)
      puts "checking #{url}"
      if validate_profile(page, first_name, last_name, employer, title) == true
        return [url, page]
      else
        puts "incorrect profile"
      end
    rescue Exception => e
      tries -= 1
      if tries > 0
        puts "Error"
        puts e
        puts 'sleeping...'
        delay(5, 1.0)
        puts 'retrying'
        retry
      elsif
        e.to_s.start_with?("999")
        puts '############# ACCESS DENIED ############'
        puts '################ ABORTING ##############'
        puts e
        abort
      else
        puts "Error"
        puts e
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

# recruiters.each do |recruiter|
#   main(recruiter)
# end
main
