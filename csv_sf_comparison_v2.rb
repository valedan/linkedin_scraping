require './csv_handlers'
require 'csv'
require 'fileutils'

class CrossRef
  include CSVHandlers

  def initialize(input_dir, lin, sf)
    @input_dir = input_dir
    @lin_input = lin
    @sf_input = sf
    @output_file = "#{@input_dir}/bb_crossref.csv"
    @headers = get_headers(sf)
    create_file(@output_file)
    cross_ref
  end

  def cross_ref
    sf_data = CSV.read(@sf_input, headers: true)
    i = 0
    CSV.foreach(@lin_input, headers: true, encoding: 'windows-1252') do |lin_row|
      i += 1
      puts "lin row: #{i}"
      lin_email = lin_row['Email Address']&.downcase
      if lin_email.include?('@')
        sf_match = sf_data.find_index do |sf_row|
           sf_emails = [sf_row['Email']&.downcase, sf_row['Email 2']&.downcase, sf_row['Email 3']&.downcase]
           sf_emails.include?(lin_email)
          #lin_email == sf_row['Email']&.downcase
        end
        if sf_match
          append_to_csv(@output_file, splice_rows(sf_data[sf_match], lin_row))
        else
          append_to_csv(@output_file, convert_row(lin_row))
        end
      else
        puts "missing email"
      end
    end
  end

  def splice_rows(sf_row, lin_row)
    sf_row['Candidate Source'] = lin_row['Candidate Source']
    sf_row_ansi = CSV::Row.new(@headers, [])
    sf_row.each do |key, value|
      sf_row_ansi[key] = value&.encode('windows-1252', invalid: :replace, undef: :replace, replace: '#')
    end
    sf_row_ansi
  end

  def convert_row(lin_row)
    sf_row = CSV::Row.new(@headers, [])
    sf_row['Candidate Source'] = lin_row['Recruiter']
    sf_row['Email'] = lin_row['E-mail Address']
    sf_row['Account Name'] = 'Candidates'.encode('windows-1252')
    sf_row['Contact Record Type'] = 'Candidate'.encode('windows-1252')
    sf_row
  end

  def collect_emails(file)
    emails = []
    CSV.foreach(file, headers: true) do |row|
      emails << row['E-mail Address']
    end
    emails
  end

  def get_headers(file)
    CSV.open(file, headers: true, return_headers: true).shift.headers
  end

end

working_dir = './..'
crossref = CrossRef.new(working_dir, "#{working_dir}/bb.csv", "#{working_dir}/sf_ref.csv")
