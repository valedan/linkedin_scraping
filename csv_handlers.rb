module CSVHandlers
  def create_row(row, headers)
    values = []
    headers.each do |header|
      values << row[header]
    end
    CSV::Row.new(headers, values)
  end

  def append_to_csv(file, row)

    f = CSV.open(file, "a+", headers: row.headers, encoding: 'windows-1252')
    encodings = row.collect{|k, v| v&.encoding}
    f << row
    f.close
  end

  def create_file(f)
    unless File.exist?(f)
      FileUtils.touch(f)
      csv = CSV.open(f, "w+")
      csv << @headers
      csv.close
    end
  end
end
