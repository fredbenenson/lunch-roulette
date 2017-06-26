$:.push "./lib"

require 'csv'
require 'optparse'
require 'yaml'
require 'set'
require 'digest'

require 'lunch_roulette/config'
require 'lunch_roulette/enumerable_extension'
require 'lunch_roulette/lunch'
require 'lunch_roulette/lunch_set'
require 'lunch_roulette/lunch_group'
require 'lunch_roulette/person'
require 'lunch_roulette/survey'
require 'input_output'
require 'sheets_client'

class LunchRoulette

  SPREADSHEET_ID = Config.spreadsheet_id
  SPREADSHEET_URL = Config.spreadsheet_url
  PEOPLE_RANGE = Config.people_range
  PEOPLE_OLD_RANGE = Config.people_old_range
  SURVEY_RANGE = Config.survey_range

  SURVEY_DATE_FORMAT = Config.survey_date_format
  PERSON_DATE_FORMAT = Config.person_date_format
  FILE_DATE_FORMAT = Config.file_date_format

  ITERATIONS = Config.iterations

  TIME_NOW = DateTime.now
  PEOPLE_OLD_FILE = "data/output/people_old_#{TIME_NOW.strftime(FILE_DATE_FORMAT)}.csv"
  PEOPLE_FILE = "data/output/people_#{TIME_NOW.strftime(FILE_DATE_FORMAT)}.csv"

  def initialize(*args)
    options = Hash.new

    o = OptionParser.new do |o|
      o.banner = "Usage: ruby lunch_roulette.rb [OPTIONS]"
      o.on('-f', '--file F', 'Read data from CSV') { |f| options[:file] = f.to_s }
      o.on('-d', '--dont-write', "Don't write to files or update spreadsheets") { options[:dont_write] = true }
      o.on('-h', '--help', 'Print this help') { puts o; exit }
      o.parse!
    end

    Config.options = options
  end

  def run!
    begin
      puts "Consuming delicious data:"
      lunchable_people, unlunchable_people = people.partition(&:lunchable?)

      puts "Cooking #{ITERATIONS} scrumptious sets:"
      lunch_set = spin(lunchable_people, ITERATIONS)

      puts "#{lunch_set.inspect_scores}"
      puts "#{lunch_set.inspect_emails}"

      unless Config.options[:dont_write]
        puts "Catering flavorful files:"
        people_old_rows = people.sort_by(&:start_date).map(&:to_row)
        people_rows = (lunch_set.people + unlunchable_people).sort_by(&:start_date).map(&:to_row)

        puts " Writing previous people file to: #{PEOPLE_OLD_FILE}"
        InputOutput.write_csv(PEOPLE_OLD_FILE, people_old_rows)

        puts " Writing new people file to: #{PEOPLE_FILE}"
        InputOutput.write_csv(PEOPLE_FILE, people_rows)

        puts " Updating previous people sheet at: #{SPREADSHEET_URL}"
        SheetsClient.update(SPREADSHEET_ID, PEOPLE_OLD_RANGE, people_old_rows)

        puts " Updating new people sheet at: #{SPREADSHEET_URL}"
        SheetsClient.update(SPREADSHEET_ID, PEOPLE_RANGE, people_rows)
      end
    rescue Exception => e
      puts e.message
    end
  end

  protected

  def spin(people, iterations)
    i = 0
    valid_sets = 0
    winner = iterations.times.reduce(nil) do |accum|
      i += 1
      new_set = LunchSet.new(people)
      valid_sets += 1 if new_set.valid?
      print " Valid sets found: #{valid_sets}. Percent complete: #{((100.0*i/iterations)).round(4)}%\r"

      if new_set.valid? && (accum.nil? || new_set.score < accum.score)
        new_set
      else
        accum
      end
    end
    puts "\n"
    raise "No valid lunch sets found!" if winner.nil? 
    winner
  end

  def people
    @people ||= 
      if Config.options[:file]
        puts " Reading people file from: #{Config.options[:file]}"
        InputOutput.read_csv(Config.options[:file])
      else
        puts " Downloading people sheet from: #{SPREADSHEET_URL}"
        SheetsClient.get(SPREADSHEET_ID, PEOPLE_RANGE)
      end.map do |p|
        Person.new(
          name: p['name'], 
          email: p['email'], 
          start_date: DateTime.strptime(p['start_date'], PERSON_DATE_FORMAT),
          team: p['team'], 
          manager: p['manager'], 
          lunchable_default: p['lunchable_default'],
          lunches: Person.to_lunches(p['lunches']),
          survey: surveys.
            select{|s| s.email == p['email']}.
            sort_by(&:date).
            reverse.
            first
        )
      end
  end

  def surveys
    @surveys ||= 
      if Config.options[:file]
        []
      else
        puts " Downloading surveys sheet from: #{SPREADSHEET_URL}"
        SheetsClient.get(SPREADSHEET_ID, SURVEY_RANGE)
      end.map do |s|
        Survey.new(
          email: s['email'], 
          response: s['response'], 
          date: DateTime.strptime(s['date'], SURVEY_DATE_FORMAT)
        )
      end
  end
end

LunchRoulette.new(ARGV).run!
