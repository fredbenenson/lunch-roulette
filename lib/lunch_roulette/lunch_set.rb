class LunchRoulette
  class LunchSet

    MIN_GROUP_SIZE = Config.min_group_size

    attr_accessor :id, :groups

    def initialize(id:, groups:)
      @id = id
      @groups = groups
    end

    def self.generate(people)
      set_id = people.flat_map(&:lunches).map(&:set_id).max + 1
      groups = generate_groups(set_id: set_id, people: people)
      new(id: set_id, groups: groups)
    end

    def self.generate_groups(set_id:, people:)
      group_count = people.length / MIN_GROUP_SIZE
      groups = []
      people.shuffle.each_with_index do |person, i|
        group_index = i % group_count
        groups[group_index] = Array(groups[group_index]) << person
      end
      groups.map.with_index do |g, i| 
        LunchGroup.new(
          id: i + 1,
          people: g.map{|p| p.add_lunch(Lunch.new(set_id: set_id, group_id: i + 1))}
        )
      end
    end

    def people
      @people ||= groups.flat_map(&:people)
    end

    def score
      @score ||= groups.map(&:score).sum
    end

    def valid?
      @valid ||= groups.map(&:valid?).all?
    end

    def inspect_scores
      ["Winning set's savory score: #{score}", groups.map(&:inspect_scores)].join("\n ")
    end

    def inspect_emails
      ["Gastronomical group emails:", groups.map(&:inspect_emails)].join("\n ")
    end
  end
end
