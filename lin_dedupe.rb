require 'csv'

lin_csv = './LINDEC2015.csv'
output_csv = File.new("dec08_lin_dedupe3.csv", "w+")

emails = {}
priority_list = ["LINKarenMcHugh",
                 "LINSeanMurphy",
                 "LINLisaONeill",
                 "LINMariaMurphy",
                 "LINAlisonSmith",
                 "LINKarenDoyle",
                 "LINMikeBrown",
                 "LINJohnSmith",
                 "LINSheilaMcNeice",
                 "LINJennyDolan",
                 "LINSarahKelly",
                 "LINSheilaDempsey",
                 "LINNiamhBlack",
                 "LINNeasaWhite",
                 "LINMaryBerry",
                 "LINJingJing",
                 "LINLiWang",
                 "LINRuby",
                 "LINMyraKumar",
                 "LINEmily",
                 "LINYuChun"]

CSV.foreach(lin_csv, headers: true, return_headers: true, encoding: 'ISO-8859-1') {|row|
  unless row['E-mail Address'].nil?
    email = row['E-mail Address'].downcase
  end
  p $.
  if emails.has_key?(email)
    emails[email] << row
  else
    emails[email] = [row]
  end
}
emails.each {|emails_key, emails_value|
  recruiters = []
  #p "key: #{emails_key}"
  #p "value: #{emails_value}"
  emails_value.each {|row2|
    recruiters << row2['Recruiter']

  }
  p recruiters
  priority_recruiter = priority_list.find{|recruiter|
    recruiters.include?(recruiter)
  }
  emails_value.each {|row3|
    if row3['Recruiter'] == priority_recruiter
      output_csv << row3
    end
  }
}
