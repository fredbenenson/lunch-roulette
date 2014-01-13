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

class LunchRoulette

  attr_reader :results, :staff

  def initialize(*args)
    LunchRoulette::Config.new
    options = Hash.new
    options[:most_diverse_sets] = 1

    o = OptionParser.new do |o|
      o.banner = "Usage: ruby lunch_roulette_generator.rb staff.csv [OPTIONS]"
      o.on('-n', '--min-group-size N', 'Minimum Lunch Group Size (default 4)') {|n| options[:MIN_LUNCH_GROUP_SIZE] = n.to_i }
      o.on('-i', '--iterations I', 'Number of Iterations (default 1,000)') {|i| options[:ITERATIONS] = i.to_i }
      o.on('-m', '--most-diverse-sets M', 'Number of most diverse sets to generate (default 1)') {|i| options[:most_diverse_sets] = i.to_i }
      o.on('-l', '--least-diverse-sets L', 'Number of least diverse sets to generate (default 0)') {|i| options[:least_diverse_sets] = i.to_i }
      o.on('-v', '--verbose', 'Verbose output') { options[:verbose_output] = true }
      o.on('-d', '--dont-write', "Don't write to files") { options[:dont_write] = true }
      o.on('-h', '--help', 'Print this help') { puts o; exit }
      o.parse!
    end

    begin
      raise OptionParser::MissingArgument if not ARGV[0]
      @staff_csv = "#{ARGV[0]}"
    rescue OptionParser::MissingArgument, NameError
      if !ARGV[0]
        puts "Must specify staff.csv"
      else
        puts "Error attempting to load #{staff_csv}"
      end
      puts o
      exit 1
    end
    config.options = options
  end

  def config
    LunchRoulette::Config
  end

  def spin!
    compile_staff
    candidates = Set.new
    iterations = config.options[:ITERATIONS] || 1_000
    i = 0.0
    invalid_sets = 0
    if config.options[:verbose_output]
      puts "Generating #{iterations} sets..."
    end
    iterations.times do
      print "#{((i/iterations)*100).round(4)}% Done\r"
      i += 1
      l = LunchSet.new(@staff)
      if l.valid
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
      top: candidates.sort{|a,b| b.score <=> a.score }.first(config.options[:most_diverse_sets].to_i),
      bottom: candidates.sort{|a,b| a.score <=> b.score }.first(config.options[:least_diverse_sets].to_i)
    }
  end

  protected

  def compile_staff
    @staff = []
    CSV.foreach(@staff_csv, headers: true) do |row|
      staffer = Person.new(Hash[row])
      config.weights.keys.map{|f| config.maxes[f] = staffer.features[f] if staffer.features[f] > config.maxes[f].to_i }
      @staff << staffer
    end
  end

end

l = LunchRoulette.new(ARGV)
l.spin!

o = LunchRoulette::Output.new(l.results)
o.get_results

if l.results[:top].size > 0 || l.results[:bottom].size > 0
  o.get_new_staff_csv(l.staff)
else
  puts "No valid sets generated, sorry."
end

