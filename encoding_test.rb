require 'csv'
# recruiters = ['AlisonSmith', 'Emily', 'JennyDolan', 'JingJing',
#    'JohnSmith', 'KarenDoyle', 'KarenMcHugh', 'LisaONeill',
#    'LiWang', 'MariaMurphy', 'MaryBerry', 'MikeBrown', 'MyraKumar',
#    'NeasaWhite', 'NiamhBlack', 'SarahKelly', 'SeanMurphy',
#    'SheilaMcNeice', 'Ruby', 'SheilaDempsey', 'SheilaMcGrath',
#    'YuChun']
recruiters = ['MaryBerry']


def main(recruiter)
  puts "Recruiter: #{recruiter}"
  output_dir = "./../LIN#{recruiter}"
  data_csv = "#{output_dir}/rebase_success2.csv"

  data_table = CSV.read(data_csv, headers: true, encoding: 'UTF-8')
  count = 0
  data_table.each do |row|
    count += 1
    first = row["First Name"]
    last = row["Last Name"]
    email = row["Email"]
    puts "#{count}: #{first} -> #{last} -> #{email}"
  end
end

recruiters.each do |recruiter|
  main(recruiter)
end
