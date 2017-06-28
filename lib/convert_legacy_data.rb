require 'csv'
require 'set'

IN_CSV = 'data/people_legacy.csv'
OUT_CSV = 'data/people_converted.csv'
ID_FIELD = 'email'
LEGACY_LUNCHES_FIELD = 'previous_lunches'
LUNCHES_FIELD = 'lunches'

def read_people
  people = []
  CSV.foreach(IN_CSV, headers: true) do |row|
    people << Hash[row].merge(legacy_lunches: String(row[LEGACY_LUNCHES_FIELD]).split(',').map(&:to_i))
  end
  people
end

def lunch_groups(people)
  lunches = Hash.new([])
  people.each do |p|
    p[:legacy_lunches].each do |l|
      lunches[l] += [p[ID_FIELD]]
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
    p_set_groups = p[:legacy_lunches].map do |l|
      set_groups[l]
    end
    p.merge(
      lunches: p_set_groups,
      LUNCHES_FIELD => p_set_groups.map{|l| "#{l[:set]}-#{l[:group]}"}.join(', ')
    )
  end.sort_by{|p| p[:lunches].length}.reverse
end

def valid?(people_set_groups)
  people_set_groups.map do |p|
    sets = p[:lunches].map{|l| l[:set]}
    sets.uniq == sets
  end.all?
end

def write_csv(people_set_groups)
  header = people_set_groups.first.keys.reject{|k| [:legacy_lunches, :lunches].include?(k)}
  CSV.open(OUT_CSV, "w") do |csv|
    csv << header
    people_set_groups.each do |row|
      csv << header.map{|k| row[k]}
    end
  end
end

people = read_people
set_groups = set_groups(lunch_sets(lunch_groups(people)))
people_set_groups = people_set_groups(people, set_groups)

if valid?(people_set_groups)
  write_csv(people_set_groups) 
  puts "File written to #{OUT_CSV}"
else
  puts "Conversion was invalid"
end
