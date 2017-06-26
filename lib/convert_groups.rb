require 'csv'
require 'set'

IN_CSV = 'data/people_legacy.csv'
OUT_CSV = 'data/people.csv'

def read_people
  people = []
  CSV.foreach(IN_CSV, headers: true) do |row|
    person = Hash[row]
    people << {
      name: person['name'], 
      email: person['email'], 
      start_date: person['start_date'],
      team: person['team'],
      manager: person['manager'],
      lunchable_default: person['lunchable'],
      lunches: parse_lunches(person['previous_lunches'])}
  end
  people
end

def parse_lunches(str)
  unless str.nil?
    str.split(',').map(&:to_i)
  else
    []
  end
end

def lunch_groups(people)
  lunches = Hash.new([])
  people.each do |p|
    p[:lunches].each do |l|
      lunches[l] += [p[:email]]
    end
  end
  lunches.sort_by{|l| l[0]}
end

def lunch_sets(lunch_groups)
  current_set = 1
  person_max_set = Hash.new(0)
  sets = Hash.new(Set.new)
  lunch_groups.each do |g|
    max_set = g[1].map{|person| person_max_set[person]}.max
    current_set += 1 if max_set >= current_set
    g[1].each{|person| person_max_set[person] = current_set}
    sets[current_set] += [g[0]]
  end
  sets
end

def set_groups(lunch_sets)
  lunch_sets.flat_map do |s|
    i = 0
    s[1].sort.map do |g|
      i += 1
      [g, {set: s[0], group: i}]
    end
  end.to_h
end

def people_set_groups(people, set_groups)
  people.map do |p|
    p_set_groups = p[:lunches].map do |l|
      set_groups[l]
    end
    p.merge({lunches: p_set_groups})
  end.sort_by{|p| p[:lunches].length}.reverse
end

def valid?(people_set_groups)
  people_set_groups.map do |p|
    sets = p[:lunches].map{|l| l[:set]}
    sets.uniq == sets
  end.all?
end

def write_csv(people_set_groups)
  CSV.open(OUT_CSV, "w") do |csv|
    csv << ['name', 'email', 'start_date', 'team', 'manager', 'lunchable_default', 'lunches']
    people_set_groups.each do |row|
      csv << [row[:name], row[:email], row[:start_date], row[:team], row[:manager], row[:lunchable_default], row[:lunches].map{|l| "#{l[:set]}-#{l[:group]}"}.join(', ')]
    end
  end
end

people = read_people
puts people.inspect
set_groups = set_groups(lunch_sets(lunch_groups(people)))
people_set_groups = people_set_groups(people, set_groups)

if valid?(people_set_groups)
  write_csv(people_set_groups) 
  puts "File written to #{OUT_CSV}"
else
  puts "Conversion was invalid"
end
