require 'rubygems'
require 'selenium-webdriver'
# require 'headless'

$proxies = {beijing_telco: {ip: '121.69.28.86', port: '8118'},
            us_hiw: {ip: '165.2.139.51', port: '80'},
            can_sas: {ip: '198.169.246.30', port: '80'},
            spain_tel: {ip: '195.140.157.138', port: '443'},
            china_mobile: {ip: '117.136.234.12', port: '80'},
            limeproxy_test: {ip: '190.112.203.13', port: '1212'}
            }

def create_proxy(proxy_name)
  proxy_requested = $proxies["#{proxy_name}".to_sym]
  p proxy_requested
  proxy = Selenium::WebDriver::Proxy.new(:http => "#{proxy_requested["ip".to_sym]}:#{proxy_requested["port".to_sym]}")
end

profile = Selenium::WebDriver::Firefox::Profile.new
proxy = create_proxy("limeproxy_test")
profile.proxy = proxy
mozilla_windows_ua = "Mozilla/5.0 (Windows NT 6.1; WOW64; rv:40.0) Gecko/20100101 Firefox/40.1"
profile["general.useragent.override"] = mozilla_windows_ua
profile["network.cookie.cookieBehavior"] = 2
profile.add_extension("/home/dan/.mozilla/firefox/ggs3zxza.default/extensions/{d10d0bf8-f5b5-c8b4-a8b2-2b9879e08c5d}.xpi")
profile["extensions.adblockplus.currentVersion"] = "2.7"

jobcontax_url = "http://www.jobcontax.com"
lintest_url = "https://ie.linkedin.com/in/aaron-o-regan-86365444"
linhome_url = "http://www.linkedin.com"
whatsmyip_url = "http://www.whatsmyip.org/"
driver = Selenium::WebDriver.for :firefox, :profile => profile
driver.manage.window.resize_to(1300, 900)
driver.manage.timeouts.implicit_wait = 20
#10.times do
   driver.get "whatsmyip_url"
#end

puts "Page title is #{driver.title}"
puts "Page source is #{driver.page_source}"


driver.quit
