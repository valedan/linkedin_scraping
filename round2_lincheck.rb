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
  '104.160.4.221',
'23.104.162.41',
'66.248.205.224',
'104.160.4.224',
'104.160.5.135',
'198.52.213.123',
'198.20.187.46',
'198.20.178.171',
'198.52.180.225',
'198.52.180.228'
            ]


$user_agents = ['Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/41.0.2227.1 Safari/537.36',
                'Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/41.0.2228.0 Safari/537.36',
                'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/42.0.2311.135 Safari/537.36 Edge/12.246',
                'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_3) AppleWebKit/537.75.14 (KHTML, like Gecko) Version/7.0.3 Safari/7046A194A',
               'Mozilla/5.0 (Windows NT 6.1; WOW64; rv:40.0) Gecko/20100101 Firefox/40.1',
               'Mozilla/5.0 (Windows NT 10.0) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/40.0.2214.93 Safari/537.36',
               'Mozilla/5.0 (Windows; U; MSIE 9.0; Windows NT 9.0; en-US)',
               'Mozilla/5.0 (compatible; MSIE 10.0; Windows NT 6.1; WOW64; Trident/6.0)',
               'Mozilla/5.0 (Windows NT 6.3; rv:36.0) Gecko/20100101 Firefox/36.0',
               'Mozilla/5.0 (X11; OpenBSD amd64; rv:28.0) Gecko/20100101 Firefox/28.0'
            ]

$headers = ["Contact ID", "First Name",	"Last Name",	"Employer Organization Name 1",
  	        "Employer 1 Title",	"Email",	"CV TR",	"Candidate Source",	"Candidate ID",
    	      "Account Name", "Linkedin Import Status", "Linkedin Profile"]

$index = $proxies.length - 1

puts "\n\n\n\n\n\n\nSCRAPER STARTING\n\n\n\n\n\n"

def main

  output_dir = "./../run3/profiles"
  log = "./../run3/lin_results.csv"
  input_csv = "./../run3/ddg_log.csv"
  create_file(log)
  total = %x(wc -l "#{input_csv}").split[0].to_i - 1
  puts "Length of input: #{total} rows.\n"
  count = 0
  start = 8522

  finish = 100000
  I18n.available_locales = [:en]
  previous_time = Time.now

  CSV.foreach(input_csv, headers: true) do |row|
    count += 1
    if $proxies.length == 0
      puts "proxies burned"
      puts count
      abort
    end
    begin
      original_row = row
      if count.between?(start, finish)
        puts "Time taken: #{Time.now - previous_time}"
        previous_time = Time.now
        puts "\n"
        puts "Input Row #{count}/#{total}"
        data_presence = 0
        if row["First Name"].strip != "" && !row["First Name"].nil?
          data_presence += 1
        end
        if row["Last Name"].strip != "" && !row["Last Name"].nil?
          data_presence += 1
        end
        if row["Employer Organization Name 1"].strip != "" && !row["Employer Organization Name 1"].nil?
          data_presence += 1
        end
        if row["Employer 1 Title"].strip != "" && !row["Employer 1 Title"].nil?
          data_presence += 1
        end
        if data_presence == 4 && !(row["Urls"].nil? || row["Urls"].strip == "" )
          correct_profile_url, correct_profile_page = check_urls(row["Urls"], row["First Name"], row["Last Name"],
                                                      row["Employer Organization Name 1"], row["Employer 1 Title"])
          if correct_profile_url.start_with?("http")
            puts "MATCH FOUND: #{correct_profile_url}"
            id = count
            output_file = File.new("#{output_dir}/#{id}.html", 'w+')
            output_file.write(correct_profile_page.body)
            output_file.close
            row["Linkedin Profile"] = correct_profile_url
            row["Linkedin Import Status"] = "Correct profile retreived"
            new_row = create_log_row(original_row, row)
            append_to_csv(log, new_row)
          else
            puts "NO MATCH FOUND"
            row["Linkedin Import Status"] = correct_profile_page
            new_row = create_log_row(original_row, row)
            append_to_csv(log, new_row)
          end
        elsif data_presence < 4
          row["Linkedin Import Status"] = "Data missing, no search attempted"
          new_row = create_log_row(original_row, row)
          append_to_csv(log, new_row)
        else
          new_row = create_log_row(original_row, row)
          append_to_csv(log, new_row)
        end
      end

    rescue Exception => msg
      puts "error in main"
      puts msg.backtrace
      abort
    end
  end
  puts "end of main"
end

def create_log_row(original_row, row)
  new_row = CSV::Row.new($headers, [])
  new_row["Contact ID"] = original_row["Contact ID"]
  new_row["First Name"] = original_row["First Name"]
  new_row["Last Name"] = original_row["Last Name"]
  new_row["Employer Organization Name 1"] = original_row["Employer Organization Name 1"]
  new_row["Employer 1 Title"] = original_row["Employer 1 Title"]
  new_row["Email"] = original_row["Email"]
  new_row["CV TR"] = original_row["CV TR"]
  new_row["Candidate Source"] = original_row["Candidate Source"]
  new_row["Candidate ID"] = original_row["Candidate ID"]
  new_row["Account Name"] = original_row["Account Name"]
  new_row["Linkedin Import Status"] = row["Linkedin Import Status"]
  new_row["Linkedin Profile"] = row["Linkedin Profile"]
  return new_row
end

def check_urls(url_string, first_name, last_name, employer, title)
  urls = url_string.split("; ")
  emsg = "Profile could not be found"
  urls.each do |url|
    tries = 2
    begin
      delay_time = 20#/$proxies.length
      sleep(delay_time)
      agent = Mechanize.new
      if $index == $proxies.length - 1
        $index = 0
      else
        $index += 1
      end
    #  agent.set_proxy($proxies[$index], '80')
    #  agent.user_agent = $user_agents[$index]
    #  puts "IP: #{$proxies[$index]}"
    #  puts "UA: #{$user_agents[$index]}"
      page = agent.get(url)
      puts "checking #{url}"
      if validate_profile(page, first_name, last_name, employer, title) == true
        return [url, page]
      else
        puts "incorrect profile"
      end
    rescue Exception => e
      tries -= 1
      if e.to_s.start_with?("999")
        puts e
        puts "#{$proxies[$index]} burned, deleting"
        $proxies.delete_at($index)
        $user_agents.delete_at($index)
        $index -= 1
        if $proxies.length > 0
          retry
        else
          puts '############# ALL PROXIES BURNED ############'
          puts '################ ABORTING ##############'
          abort
        end
      elsif tries > 0
        puts "Error"
        puts e
        puts 'sleeping...'
        sleep(2)
        puts 'retrying'
        retry
      else
        puts "Error"
        puts e
        emsg = e
      end
    end
  end
  return ["Profile could not be found", emsg]
end


def delay(base, extra)
  prng = Random.new
  wait_time = base + prng.rand(extra)
  puts "sleeping"
  sleep(wait_time)
  puts "waking"
end

def create_file(f)
  unless File.exist?(f)
    FileUtils.touch(f)
    csv = CSV.open(f, "w+")
    csv << $headers
    csv.close
  end
end

### rewrite to include new sanitization logic ###
def validate_profile(page, first_name, last_name, employer, title)
  full_name = I18n.transliterate("#{first_name} #{last_name}").alnum
  return false unless page.at_css("#name")
  profile_name = I18n.transliterate(page.at_css("#name").text).alnum
  puts '############# ACCESS GRANTED ############'
  puts profile_name
  return false unless page.css("#experience .positions .position")
  positions = page.css("#experience .positions .position")
  match = false
  unless split_string_comp(profile_name, full_name) == true
    return match
  end
  positions.each do |position|
    begin
      if position.at_css("header .item-title a") && position.at_css("header .item-subtitle")
        profile_title = I18n.transliterate(position.at_css("header .item-title a").text).alnum
        profile_employer = I18n.transliterate(position.at_css("header .item-subtitle").text).alnum
        title = I18n.transliterate(title).alnum
        employer = I18n.transliterate(employer).alnum
        if split_string_comp(profile_title, title) && split_string_comp(profile_employer, employer)
          match = true
        end
      end
    rescue Exception => e
      puts e
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
