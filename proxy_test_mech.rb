require 'rubygems'
require 'mechanize'

$proxies = {beijing_telco: {ip: '121.69.28.86', port: '8118'},
            us_hiw: {ip: '165.2.139.51', port: '80'},
            can_sas: {ip: '198.169.246.30', port: '80'},
            spain_tel: {ip: '195.140.157.138', port: '443'},
            china_mobile: {ip: '117.136.234.12', port: '80'},
            limeproxy_test: {ip: '190.112.203.13', port: '1212'}
            }

$user_agents = {mozilla_windows: "Mozilla/5.0 (Windows NT 6.1; WOW64; rv:40.0) Gecko/20100101 Firefox/40.1"}


def create_proxy(agent, proxy_name)
  proxy_requested = $proxies["#{proxy_name}".to_sym]
  p "using proxy:  #{proxy_requested}"
  agent.set_proxy(proxy_requested["ip".to_sym], proxy_requested["port".to_sym])
  return agent
end

jobcontax_url = "http://www.jobcontax.com/about"
lintest_url = "https://ie.linkedin.com/in/aaron-o-regan-86365444"
linhome_url = "http://www.linkedin.com"
whatsmyip_url = "http://www.whatsmyip.org/"

agent = Mechanize.new
#agent = create_proxy(agent, $proxies.keys.sample)
agent = create_proxy(agent, 'limeproxy_test')

agent.user_agent = $user_agents["mozilla_windows".to_sym]
page = agent.get 'http://www.whatsmyip.org/'

puts "Page title is #{page.title}"
pp "Page source is #{page.body}"
