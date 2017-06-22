$:.push "./lib"

require 'csv'
require 'optparse'
require 'yaml'
require 'set'
require 'digest'

require 'lunch_roulette/config'
require 'lunch_roulette/enumerable_extension'
require 'lunch_roulette/lunch_set'
require 'lunch_roulette/lunch_group'
require 'lunch_roulette/person'
require 'lunch_roulette/output'
require 'sheets_client'

class LunchRoulette

  # https://docs.google.com/spreadsheets/d/1cUx7UEk-_AHPWynJDF-1ye9laoPDsElyjNbN9e8JK4g/edit
  SPREADSHEET_ID = '1cUx7UEk-_AHPWynJDF-1ye9laoPDsElyjNbN9e8JK4g'
  PEOPLE_RANGE = 'Staff test!A:F'
  LUNCH_GROUPS_RANGE = 'Lunch groups!A:B'
  LUNCH_GROUPS_OLD_RANGE = 'Lunch groups old!A:B'
  SURVEY_RANGE = 'Survey responses!A:C'

  attr_reader :results, :people, :all_valid_sets

  def initialize(*args)
    LunchRoulette::Config.new
    options = Hash.new
    options[:most_varied_sets] = 1

    o = OptionParser.new do |o|
      o.banner = "Usage: ruby lunch_roulette_generator.rb staff.csv [OPTIONS]"
      o.on('-f', '--staff-csv', 'Staff csv') {|f| options[:staff_csv] = f }
      o.on('-n', '--min-group-size N', 'Minimum Lunch Group Size (default 4)') {|n| options[:min_lunch_group_size] = n.to_i }
      o.on('-i', '--iterations I', 'Number of Iterations (default 1,000)') {|i| options[:iterations] = i.to_i }
      o.on('-v', '--verbose', 'Verbose output') { options[:verbose_output] = true }
      o.on('-d', '--dont-write', "Don't write to files") { options[:dont_write] = true }
      o.on('-h', '--help', 'Print this help') { puts o; exit }
      o.parse!
    end

    config.options = options
  end

  def config
    LunchRoulette::Config
  end

  def run!
    lunchable_people, unlunchable_people = people.partition(&:lunchable?)
    begin
      new_lunch_set = spin(lunchable_people)
      new_lunch_set.print_scores
      output_lunch_groups(new_lunch_set.new_lunches + unlunchable_people)
      send_emails(new_lunch_set)
    rescue Exception => e
      puts e.message
    end
  end

  protected

  def spin(people)
    candidates = []
    iterations = config.options[:iterations] || 1000
    i = 0.0
    puts "Generating #{config.options[:iterations]} sets..."
    iterations.times do
      print "#{((i/iterations)*100).round(4)}% Done, #{candidates.length} valid sets found\r"
      i += 1
      l = LunchSet.new(people)
      candidates << l if l.valid?
    end
    raise "No valid lunch sets found!" if candidates.empty? 
    puts "Invalid Sets: #{iterations - candidates.size}"
    puts "Valid Sets: #{candidates.size}"

    candidates.sort_by(&:score).first
  end

  def people
    @people ||= people_data.map do |person|
      lunch_groups = lunch_groups_data.
        select{|g| g['email'] == person['email']}.
        first.to_h
      survey = survey_data.
        select{|s| s['email'] == person['email']}.
        sort_by{|s| to_date(s['date'])}.
        reverse.
        first.to_h
      Person.new(
        name: person['name'], 
        email: person['email'], 
        start_date: to_date(person['start_date']),
        team: person['team'], 
        manager: person['manager'], 
        lunchable_default: person['lunchable_default'],
        lunchable_survey_response: survey['response'], 
        lunchable_survey_date: to_date(survey['date']), 
        previous_lunches: to_previous_lunches(lunch_groups['previous_lunches'])
      )
    end
  end

  def people_raw_data
    @people_raw_data ||= SheetsClient.get(SPREADSHEET_ID, PEOPLE_RANGE)
  end

  def lunch_groups_raw_data
    @lunch_groups_raw_data ||= SheetsClient.get(SPREADSHEET_ID, LUNCH_GROUPS_RANGE)
  end

  def survey_raw_data
    @survey_raw_data ||= SheetsClient.get(SPREADSHEET_ID, SURVEY_RANGE)
  end

  def people_data
    @people_data ||= data_hash(people_raw_data)
  end

  def lunch_groups_data
    @lunch_groups_data ||= data_hash(lunch_groups_raw_data)
  end

  def survey_data
    @survey_data ||= data_hash(survey_raw_data)
  end

  def data_hash(raw_data, headers: nil)
    data = raw_data[1..-1]
    data.map do |row|
      (headers || raw_data[0]).zip(row).to_h
    end
  end

  def to_date(str)
    unless str.nil? || str.empty?
      Date.strptime(str, '%m/%d/%Y')
    end
  end

  def to_previous_lunches(str)
    unless str.nil?
      str.split(',').map do |p| 
        ids = p.strip.split('-')
        Lunch.new(set_id: ids[0].to_i, group_id: ids[1].to_i)
      end
    else
      []
    end
  end

  def send_emails(lunch_set)
    lunch_set.groups.each_with_index do |group, i|
      puts "Group #{i + 1}: #{group.emails}"
    end
  end

  def output_lunch_groups(people)
    data = people.
      sort_by{|p| p.previous_lunches.length}.
      reverse.
      map do |p|
        [p.email, p.previous_lunches.map(&:to_str).join(', ')]
      end    
    headers = ['email', 'previous_lunches']
    write_csv(lunch_groups_file, data, headers)
    puts "Lunch groups file written to: #{lunch_groups_file}\n"

    # SheetsClient.update(SPREADSHEET_ID, LUNCH_GROUPS_OLD_RANGE, lunch_groups_raw_data)
    # SheetsClient.update(SPREADSHEET_ID, LUNCH_GROUPS_RANGE, data, headers: headers)
  end

  def lunch_groups_file
    @lunch_groups_file ||= "data/output/lunch_groups_#{DateTime.now.to_s}.csv"
  end

  def write_csv(file, data, headers)
    CSV.open(file, "w") do |csv|
      csv << headers
      data.each do |row|
        csv << row
      end
    end
  end
end

LunchRoulette.new(ARGV).run!
