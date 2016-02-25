require 'rubygems'
require 'mechanize'
require 'csv'
require 'fileutils'
require 'i18n'
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

class String
  def alnum
    return self.gsub(/[^\p{Alnum}\p{Space}]/u, ' ')
  end
end

$user_agents = {mozilla_windows: "Mozilla/5.0 (Windows NT 6.1; WOW64; rv:40.0) Gecko/20100101 Firefox/40.1"}

$headers = ["First Name",	"Last Name",	"Employer Organization Name 1",
  	        "Employer 1 Title",	"Email",	"CV TR",	"Candidate Source",	"Candidate ID",
    	      "Resume Last Updated",	"Account Name",	"Search Query", "Log", "Url"]

puts "\n\n\n\n\n\n\nDUCK SCRAPER STARTING\n\n\n\n\n\n"

def main
  recruiter = 'YuChun'
  puts recruiter

  output_dir = "./../LIN#{recruiter}"
  fail_log = "./../LIN#{recruiter}/ddg_fail_log.csv"
  success_log = "./../LIN#{recruiter}/ddg_success_log.csv"
  create_files(recruiter, fail_log, success_log)
  input_csv = "#{output_dir}/rebase_success.csv"
  total = %x(wc -l "#{input_csv}").split[0].to_i - 1
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
        delay(5.5, 1.0)
        puts "\n"
        puts "Input Row #{count}/#{total}"
        agent = Mechanize.new
        agent.user_agent = $user_agents["mozilla_windows".to_sym]
        #need to sanitize data before constructing query
        I18n.available_locales = [:en]
        row["First Name"].gsub!(row["Email"], ' ')
        row["Last Name"].gsub!(row["Email"], ' ')
        row["First Name"] = I18n.transliterate(row["First Name"]).alnum
        row["Last Name"]  = I18n.transliterate(row["Last Name"]).alnum
        row["Employer Organization Name 1"]  = I18n.transliterate(row["Employer Organization Name 1"]).alnum
        row["Employer 1 Title"]  = I18n.transliterate(row["Employer 1 Title"]).alnum
        query = create_query(row)
        query.gsub!(/\?/, '')
        puts query
        row["Search Query"] = query
        duck_page = agent.get('https://www.duckduckgo.com/html')
        search_form = duck_page.form_with(id: 'search_form_homepage')
        search_form.q = query
        results_page = agent.submit(search_form)
        #expect lin_urls to be array of strings
        lin_urls = aggregate_urls(results_page, row["First Name"], row["Last Name"],
                             row["Employer Organization Name 1"], row["Employer 1 Title"])
        if lin_urls.class == Array && lin_urls.length > 0
          row["Url"] = lin_urls.join("; ")
          row["Log"] = nil
          puts "#{lin_urls.length} results found"
          append_to_csv(success_log, row)
        elsif lin_urls.class == Array && lin_urls.length == 0
          row["Log"] = "No results found"
          append_to_csv(fail_log, row)
        elsif lin_urls.class == String
          row["Log"] = lin_urls
          append_to_csv(fail_log, row)
        else
          row["Log"] = "invalid return type from aggregate function"
          append_to_csv(fail_log, row)
        end
        puts row["Log"]
      elsif count > finish
        #row["Log"] = "Not attempted"
        #append_to_csv(fail_log, row)
        #break
      end
    rescue Exception => msg
      row["Log"] = msg
      append_to_csv(fail_log, row)
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

def append_to_csv(file, row)
  f = CSV.open(file, "a+", headers: row.headers)
  f << row
  f.close
end



def aggregate_urls(page, first_name, last_name, employer, title)
  full_name = "#{first_name} #{last_name}"
  results = page.css("#links .results_links_deep")
  good_matches = []
  okay_matches = []
  puts "number of results: #{results.length}"
  if employer.nil? || title.nil?
    return "ERR: Nil field"
  end
  results.each do |result|

    if result.at_css("a.large")
      url_text = I18n.transliterate(result.css("a.large").text).alnum
      url = result.at_css('a.large')['href']
      paragraph = result.css("div.snippet").text
      valid_url = true
      bio = I18n.transliterate("#{paragraph}").alnum
      short_title = title.split
      short_title = "#{short_title[0]}"
      short_title += " #{short_title[1]}" if short_title[1]
      short_employer = employer.split
      short_employer = "#{short_employer[0]}"

      if result.css("a.large").text.include?("profiles | LinkedIn")
        valid_url = false
      end
      unless url.include?("linkedin")
        valid_url = false
      end
      unless url.include?("/in/") || url.include?("/pub/")
        valid_url = false
      end
      if name_check(url_text, full_name) && valid_url
        valid_url = "okay"
      end
      if valid_url == "okay" && bio.downcase.include?(short_title.downcase) && bio.downcase.include?(short_employer.downcase)
        valid_url = "good"
      end
      if valid_url == "good"
        good_matches << url
      elsif valid_url == "okay"
        okay_matches << url
      end
    end

  end
  matches = good_matches.concat(okay_matches)
  return matches
end

def name_check(lin_name, csv_name)
  csv_array = csv_name.downcase.split(" ")
  lin_array = lin_name.downcase.split(" ")
  match = true
  csv_array.each do |chunk|
    unless lin_array.include?(chunk)
      match = false
    end
  end
  return match
end


main
