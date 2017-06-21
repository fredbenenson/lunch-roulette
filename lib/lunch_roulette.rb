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
require 'sheet_fetcher'

class LunchRoulette

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

  def spin!
    lunchable_people = people.select(&:lunchable?)
    candidates = Set.new
    iterations = config.options[:iterations] || 1_000
    i = 0.0
    invalid_sets = 0
    if config.options[:verbose_output]
      puts "Generating #{config.options[:iterations]} sets..."
    end
    iterations.times do
      print "#{((i/iterations)*100).round(4)}% Done\r"
      i += 1
      l = LunchSet.new(lunchable_people)
      if l.valid?
        candidates << l
      else
        invalid_sets += 1
      end
    end

    if config.options[:verbose_output]
      puts "Invalid Sets: #{invalid_sets}"
      puts "Valid Sets: #{candidates.size}"
    end

    @results = {
      top: candidates.sort{|a,b| b.score <=> a.score }.first(config.options[:most_varied_sets].to_i),
    }
    # @all_valid_sets = candidates
  end

  protected

  def to_date(str)
    unless str.nil? || str.empty?
      Date.strptime(str, '%m/%d/%Y')
    end
  end

  def to_int_array(str)
    unless str.nil?
      str.split(',').map{|i| i.to_i }
    end
  end

  def people
    @people ||= SheetFetcher.fetch.map do |row|
      Person.new(
        name: row['name'], 
        email: row['email'], 
        start_date: to_date(row['start_date']),
        team: row['team'], 
        manager: row['manager'], 
        lunchable_default: row['lunchable_default'],
        lunchable_form: row['lunchable_form'], 
        lunchable_at: to_date(row['lunchable_at']), 
        previous_lunches: to_int_array(row['previous_lunches'])
      )
    end
    # CSV.foreach(@staff_csv, headers: true) do |row|
    #   staffer = Person.new(Hash[row])
    #   config.weights.keys.map{|f| config.maxes[f] = staffer.features[f] if staffer.features[f] > config.maxes[f].to_i }
    #   @staff << staffer
    # end
  end

end

l = LunchRoulette.new(ARGV)
results = l.spin!

o = LunchRoulette::Output.new(l.results, l.all_valid_sets)
o.get_results
o.get_stats_csv if o.config.options[:output_stats]

if l.results[:top].size > 0 || l.results[:bottom].size > 0
  o.get_new_staff_csv(l.staff)
else
  puts "No valid sets generated, sorry."
end
