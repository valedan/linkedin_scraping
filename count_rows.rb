require 'csv'
require 'fileutils'

recruiters = ['AlisonSmith', 'Emily', 'JennyDolan', 'JingJing',
   'JohnSmith', 'KarenDoyle', 'KarenMcHugh', 'LisaONeill',
   'LiWang', 'MariaMurphy', 'MaryBerry', 'MikeBrown', 'MyraKumar',
   'NeasaWhite', 'NiamhBlack', 'SarahKelly', 'SeanMurphy',
   'SheilaMcNeice', 'Ruby', 'SheilaDempsey', 'SheilaMcGrath',
   'YuChun']
$total = 0
$output = {}

def main(recruiter)

  working_dir = "./../LIN#{recruiter}"
  if $file
    input_csv = "#{working_dir}/#{$file}"
  else
    input_csv = "#{working_dir}/LIN#{recruiter}.csv"
  end

  if File.exist?(input_csv)
    input_table = CSV.read(input_csv, headers: true)
    count = input_table.count
    $total += count
    $output[recruiter] = count
    #puts "#{recruiter}: #{count}"
  end
end

if ARGV[0]
  $file = ARGV[0]
end

recruiters.each do |recruiter|
  main(recruiter)
end
$output = $output.sort_by{|key, value| value}
$output.reverse!
$output.each do |key, value|
  skey = "#{key}"
  sval = "#{value}"
  puts "#{sprintf("%-20s", key)}: #{value}"
end
puts "#{sprintf("%-20s", "Total")}: #{$total}"
