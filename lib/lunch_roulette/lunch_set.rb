class LunchRoulette
  class LunchSet

    attr_accessor :people, :groups

    def initialize(people)
      @people = people
      @groups = generate_groups
    end

    def config
      LunchRoulette::Config
    end

    def inspect
      groups.map.with_index{|group, index| "Group #{index + 1}: #{group.inspect}"}
    end

    def score
      @score ||= groups.map(&:score).sum
    end

    def id
      @id ||= people.flat_map(&:previous_lunches).map(&:set_id).max + 1
    end

    def generate_groups
      group_count = people.length / config.min_lunch_group_size
      groups = []
      people.shuffle.each_with_index do |person, i|
        group_index = i % group_count
        groups[group_index] = Array(groups[group_index]) << person
      end
      groups.map.with_index do |g, i| 
        LunchGroup.new(
          people: g, 
          lunch: Lunch.new(set_id: id, group_id: i)
        )
      end
    end

    def new_lunches
      groups.flat_map do |g|
        g.people.map{|p| p.add_lunch(g.lunch)}
      end
    end

    def print_scores
      puts "Overall score: #{score}"
      groups.each(&:print_scores)
    end

    def valid?
      groups.map(&:valid?).all?
    end
  end
end
