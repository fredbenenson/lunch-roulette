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

  SPREADSHEET_ID = Config.config[:spreadsheet_id]
  SPREADSHEET_URL = Config.config[:spreadsheet_url]
  PEOPLE_RANGE = Config.config[:people_range]
  PEOPLE_OLD_RANGE = Config.config[:people_old_range]
  SURVEY_RANGE = Config.config[:survey_range]

  SURVEY_DATE_FORMAT = Config.config[:survey_date_format]
  PERSON_DATE_FORMAT = Config.config[:person_date_format]
  FILE_DATE_FORMAT = Config.config[:file_date_format]

  LUNCHABLE_TRUE = Config.config[:lunchable_true]

  ITERATIONS = Config.config[:iterations]

  TIME_NOW = DateTime.now
  PEOPLE_INPUT_FILE = Config.config[:people_input_file]
  PEOPLE_OUTPUT_FILE = Config.config[:people_output_file].split('.csv').first + '_' + TIME_NOW.strftime(FILE_DATE_FORMAT).to_s + '.csv'

  def initialize(*args)
    options = Hash.new

    o = OptionParser.new do |o|
      o.banner = "Usage: ruby lunch_roulette.rb [OPTIONS]"
      o.on('-f', '--file F', 'Read data from provided CSV') { |f| options[:file] = f.to_s }
      o.on('-o', '--offline', "Offline mode: read and write CSV data locally; default read location is #{PEOPLE_INPUT_FILE}") { options[:offline] = true }
      o.on('-i', '--iterations I', "Iterations, default #{ITERATIONS}") { |i| options[:iterations] = i.to_i }
      o.on('-h', '--help', 'Print this help') { puts o; exit }
      o.parse!
    end

    Config.options = options
  end

  def run!
    begin
      puts "🥑  Devouring delicious data:"
      lunchable_people, unlunchable_people = people.partition(&:lunchable?)

      puts "🥒  Slicing up #{Config.options[:iterations] || ITERATIONS} scrumptious sets:"
      unless lunch_set = spin(lunchable_people, Config.options[:iterations] || ITERATIONS)
        puts "🔪  No lunch sets made the cut!"
        return
      end
      puts "🍇  We have a winner! Set ##{lunch_set.id} is born, with #{lunch_set.groups.size} great groups"

      puts "🐓  Plating palatable previous groups:\n#{lunch_set.inspect_previous_groups}"
      puts "🌮  Sautéing savory scores:\n#{lunch_set.inspect_scores}"
      puts "🍕  Grilling gastronomical group emails:\n#{lunch_set.inspect_emails}"

      puts "🍦  Flash-freezing flavorful files:"
      people_old_rows = people.sort_by(&:start_date).map(&:to_row)
      people_rows = (lunch_set.people + unlunchable_people).sort_by(&:start_date).map(&:to_row)

      puts "Writing new people file to: #{PEOPLE_OUTPUT_FILE}"
      InputOutput.write_csv(PEOPLE_OUTPUT_FILE, people_rows)

      unless Config.options[:offline]
        puts "Updating previous people sheet at: #{SPREADSHEET_URL}"
        SheetsClient.update(SPREADSHEET_ID, PEOPLE_OLD_RANGE, people_old_rows)

        puts "Updating new people sheet at: #{SPREADSHEET_URL}"
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
    winner = iterations.times.reduce(nil) do |leader|
      new_set = LunchSet.generate(people)
      valid_sets += 1 if new_set.valid?
      print "#{valid_sets == 0 ? '🐄' : '🍔'}  Valid sets found: #{valid_sets}. Percent complete: #{((100.0 * (i += 1) / iterations)).round(4)}%\r"

      [leader, new_set].compact.select(&:valid?).min_by(&:score)
    end.tap{puts "\n"}
  end

  def people
    @people ||= 
      if Config.options[:file] || Config.options[:offline]
        puts "Reading people file from: #{Config.options[:file] || PEOPLE_INPUT_FILE}"
        InputOutput.read_csv(Config.options[:file] || PEOPLE_INPUT_FILE)
      else
        puts "Downloading people sheet from: #{SPREADSHEET_URL}"
        SheetsClient.get(SPREADSHEET_ID, PEOPLE_RANGE)
      end.map do |p|
        Person.new(
          name: p['name'], 
          email: p['email'], 
          start_date: DateTime.strptime(p['start_date'], PERSON_DATE_FORMAT),
          team: p['team'], 
          manager: p['manager'] && p['manager'].empty? ? nil : p['manager'], 
          lunchable_default: p['lunchable_default'] == LUNCHABLE_TRUE,
          lunches: String(p['lunches']).split(',').map{|s| Lunch.from_s(s)},
          survey: surveys.
            select(&:current?).
            select{|s| s.email == p['email']}.
            sort_by(&:date).
            reverse.
            first
        )
      end
  end

  def surveys
    @surveys ||= 
      if Config.options[:file] || Config.options[:offline]
        []
      else
        puts "Downloading surveys sheet from: #{SPREADSHEET_URL}"
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
