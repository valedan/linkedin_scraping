require 'rubygems'
require 'mechanize'
require 'csv'
require 'fileutils'

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

$headers = ["Timestamp", "Url", "Status"]


def main

  if ARGV[0].to_i.between?(1, 5)
    index = ARGV[0].to_i
  else
    abort
  end
  proxy = $proxies[index-1]
  ua = $user_agents[index-1]
  agent = Mechanize.new
  agent.set_proxy(proxy, '80')
  agent.user_agent = ua
  puts "IP: #{proxy}"
  puts "UA: #{ua}"

  working_dir = "./../proxy_stress"
  input = "#{working_dir}/#{index}.csv"
  log = "#{working_dir}/#{index}_log.csv"
  create_log(log)
  sleep_time = 20 + 10 * index

  CSV.foreach(input, headers: true) do |row|
    begin
      puts "sleeping for #{sleep_time}s"
      sleep(sleep_time)
      url = row["Url"]
      puts "fetching #{url}"
      page = agent.get(url)
      if page.at_css("#name").text
        puts '############# ACCESS GRANTED ############'
        status = 'Success'
        output_row = CSV::Row.new($headers, [Time.now, url, status])
        append_to_csv(log, output_row)
      else
        status = 'Failed (no name field found)'
        output_row = CSV::Row.new($headers, [Time.now, url, status])
        append_to_csv(log, output_row)
      end
    rescue Exception => msg
      status = msg
      output_row = CSV::Row.new($headers, [Time.now, url, status])
      append_to_csv(log, output_row)
      puts msg
    end
  end
end

def append_to_csv(file, row)
  f = CSV.open(file, "a+", headers: row.headers)
  f << row
  f.close
end

def create_log(log)

  unless File.exist?(log)
    FileUtils.touch(log)
    csv = CSV.open(log, "w+")
    csv << $headers
    csv.close
  end
end

main
