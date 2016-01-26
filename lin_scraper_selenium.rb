require 'rubygems'
require 'selenium-webdriver'
require 'headless'
require 'csv'

$proxies = {beijing_telco: {ip: '121.69.28.86', port: '8118'},
            us_hiw: {ip: '165.2.139.51', port: '80'},
            can_sas: {ip: '198.169.246.30', port: '80'},
            spain_tel: {ip: '195.140.157.138', port: '443'},
            china_mobile: {ip: '117.136.234.12', port: '80'}
            }

$user_agents = {mozilla_windows: "Mozilla/5.0 (Windows NT 6.1; WOW64; rv:40.0) Gecko/20100101 Firefox/40.1"}
$binghome_url = "http://global.bing.com/?FORM=HPCNEN&setmkt=en-us&setlang=en-us"


def main
  input_csv = "./LINSarahKelly.csv"
  output_dir = "./LINSarahKelly"
  profile = profile_setup("beijing_telco", "mozilla_windows")
  driver = driver_setup(profile)

  #puts "Page source is #{driver.page_source}"
  count = 0
  CSV.foreach(input_csv, headers: true) do |row|
    count += 1
    #cookie = false
    begin
      if count < 10
    #    if cookie == false
    #      driver.manage.add_cookie(name: 'SRCHD', value: 'AF=HPCNEN', path: '/', domain: 'bing.com')
    #      cookie = true
    #    end
        query = row["Search Query"]
        query.gsub!(/\?/, '')
        driver.get $binghome_url
        search_box = driver.find_element(name: "q")
        search_box.send_keys query
        search_box.submit
        puts "Page title is #{driver.title}"
      else
        break
      end
    rescue Exception => msg
      puts msg
    end
  end
  #puts "end of main"

  driver.quit
end

def profile_setup(proxy, user_agent)
  profile = Selenium::WebDriver::Firefox::Profile.new
  profile.proxy = set_proxy(profile, proxy)
  profile["general.useragent.override"] = set_useragent(profile, user_agent)
  profile["network.cookie.cookieBehavior"] = 2
  profile.add_extension("/home/dan/.mozilla/firefox/ggs3zxza.default/extensions/{d10d0bf8-f5b5-c8b4-a8b2-2b9879e08c5d}.xpi")
  profile["extensions.adblockplus.currentVersion"] = "2.7"
  return profile
end

def driver_setup(profile)
  driver = Selenium::WebDriver.for :firefox, :profile => profile
  driver.manage.window.resize_to(1300, 900)
  driver.manage.timeouts.implicit_wait = 2
  return driver
end

def set_proxy(profile, proxy_name)
  proxy_requested = $proxies["#{proxy_name}".to_sym]
  p "using proxy:  #{proxy_requested}"
  proxy = Selenium::WebDriver::Proxy.new(:http => "#{proxy_requested["ip".to_sym]}:#{proxy_requested["port".to_sym]}")
  return proxy
end

def set_useragent(profile, ua_name)
  ua_requested = $user_agents["#{ua_name}".to_sym]
  p "using UserAgent:  #{ua_requested}"
  return ua_requested
end

main
