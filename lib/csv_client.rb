class CsvClient
  def self.read_csv(file)
    rows = []
    CSV.foreach(file, headers: true) do |row|
      rows << Hash[row]
    end
    rows
  end

  def self.write_csv(file, rows)
    header = rows.first.keys
    CSV.open(file, "w") do |csv|
      csv << header
      rows.each do |row|
        csv << header.map{|k| row[k]}
      end
    end
  end
end
