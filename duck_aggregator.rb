require 'rubygems'
require 'mechanize'
require 'csv'
require 'fileutils'
require 'i18n'

$proxies = [
            '89.36.66.229',
            '91.235.142.232',
            '91.235.142.173',
            '91.235.142.146',
            '89.36.66.136',
            '172.245.226.181',
            '107.172.227.43',
            '172.245.226.188',
            '155.94.234.119',
            '204.44.77.43'
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

class String
  def alnum
    return self.gsub(/[^\p{Alnum}\p{Space}]/u, ' ')
  end
end


$headers = ["Contact ID", "First Name",	"Last Name",	"Employer Organization Name 1",
  	        "Employer 1 Title",	"Email",	"CV TR",	"Candidate Source",	"Candidate ID",
    	      "Account Name",	"Search Query", "Linkedin Import Status", "Urls"]

$index = $proxies.length - 1


puts "\n\n\n\n\n\n\nDUCK SCRAPER STARTING\n\n\n\n\n\n"

def main
  input_csv = './../run3/cross_ref.csv'
  log = "./../run3/ddg_log.csv"
  create_file(log)
  total = %x(wc -l "#{input_csv}").split[0].to_i - 1
  puts "Length of input: #{total} rows.\n"
  count = 0
  start = 2351
  finish = 100000
  previous_time = Time.now

  CSV.foreach(input_csv, headers: true) do |row|
    count += 1
    tries = 10
    begin
      if count.between?(start, finish) && row['CV TR'] != '1'
        original_row = row
        puts "Time taken: #{Time.now - previous_time}"
        previous_time = Time.now
        puts "\n"
        puts "Input Row #{count}/#{total}"
        I18n.available_locales = [:en]
        row["First Name"].gsub!(row["Email"], ' ')
        row["Last Name"].gsub!(row["Email"], ' ')
        row["First Name"] = I18n.transliterate(row["First Name"]).alnum
        row["Last Name"]  = I18n.transliterate(row["Last Name"]).alnum
        row["Employer Organization Name 1"]  = I18n.transliterate(row["Employer Organization Name 1"]).alnum
        row["Employer 1 Title"]  = I18n.transliterate(row["Employer 1 Title"]).alnum
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
        puts "data presence: #{data_presence}"

        if data_presence > 2
          delay_time = 11 - $proxies.length
          sleep(delay_time)
          agent = Mechanize.new
          if $index == $proxies.length - 1
            $index = 0
          else
            $index += 1
          end
          agent.set_proxy($proxies[$index], '80')
          agent.user_agent = $user_agents[$index]
          puts "IP: #{$proxies[$index]}"
          puts "UA: #{$user_agents[$index]}"
          #need to sanitize data before constructing query
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
        else
          row["Linkedin Import Status"] = "Data missing, no search attempted"
          new_row = create_log_row(original_row, row)
          append_to_csv(log, new_row)
        end
        if lin_urls.class == Array && lin_urls.length > 0
          row["Urls"] = lin_urls.join("; ")
          row["Linkedin Import Status"] = "Success"
          puts "#{lin_urls.length} results found"
          new_row = create_log_row(original_row, row)
          append_to_csv(log, new_row)
        elsif lin_urls.class == Array && lin_urls.length == 0
          row["Linkedin Import Status"] = "No DDG results found"
          new_row = create_log_row(original_row, row)
          append_to_csv(log, new_row)
        elsif lin_urls.class == String
          row["Linkedin Import Status"] = lin_urls
          new_row = create_log_row(original_row, row)
          append_to_csv(log, new_row)
        end
        puts row["Linkedin Import Status"]
      end
    rescue Exception => msg
      tries -= 1
      if tries > 0
        puts msg
        puts 'retrying'
        retry
      else
        row["Linkedin Import Status"] = msg
        new_row = create_log_row(original_row, row)
        append_to_csv(log, new_row)
        puts msg
      end
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
  new_row["Search Query"] = row["Search Query"]
  new_row["Linkedin Import Status"] = row["Linkedin Import Status"]
  new_row["Urls"] = row["Urls"]
  return new_row
end

def create_query(row)
  name = "#{row["First Name"].strip} #{row["Last Name"].strip}"
  employer = "#{row["Employer Organization Name 1"].strip}"
  title = "#{row["Employer 1 Title"].strip}"
  query = "linkedin #{name} #{employer} #{title}"
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

def append_to_csv(file, row)
  f = CSV.open(file, "a+")
  f << row
  f.close
end



def aggregate_urls(page, first_name, last_name, employer, title)
  full_name = "#{first_name} #{last_name}"
  if page.css("#links .results_links_deep")
    results = page.css("#links .results_links_deep")
  else
    return "No DDG results found"
  end
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
      paragraph = result.css("div.snippet").text || ""
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
