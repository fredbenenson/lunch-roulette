class LunchRoulette
  class LunchSet

    attr_accessor :people, :groups #, :previous_lunch_stats, :previous_lunches

    def initialize(people)
      @people = people
      @groups = generate_groups
      # @previous_lunches = {}
      # previous_lunch_stats
      # @valid = valid_set?
    end

    def config
      LunchRoulette::Config
    end

    def inspect
      @groups.map.with_index{|group, index| "Group #{index + 1}: #{group.inspect}"}
    end

    #For CSV naming purposes
    def name
      Digest::MD5.hexdigest inspect.to_s
    end

    def score
      @score ||= @groups.map(&:score).sum
    end

    def generate_groups
      group_count = people.length / config.min_lunch_group_size
      groups = []
      people.shuffle.each_with_index do |person, i|
        group_index = i % group_count
        groups[group_index] = Array(groups[group_index]) << person
      end
      groups.map{|g| LunchGroup.new(g)}
    end

    # def generate_groups
    #   groups = []
    #   min_lunch_group_size = config.min_lunch_group_size
    #   until lunchers.empty?
    #     # First check whether we have enough people to create a new group
    #     if lunchers.size < min_lunch_group_size
    #       # If we don't have enough people to do a new group
    #       lunchers.size.times do
    #         # Randomly pick a group to put them in
    #         random_group = (rand groups.size)
    #         groups[random_group] = LunchGroup.new([groups[random_group].people, lunchers.pop].flatten)
    #       end
    #     else
    #       # If we do have enough people to create a new group
    #       # Pick our minimum number of people and throw them in a group
    #       group = LunchGroup.new(lunchers.pop(min_lunch_group_size))
    #       groups << group
    #     end
    #   end
    #   groups.map.with_index{|g, i| g.id = config.maxes['lunch_id'].to_i + i + 1 }
    #   groups
    # end

    # For each group, find how many people have had lunch with each other previously
    # in groups of 2, 3, ... etc.
    # def previous_lunch_stats
    #   config.match_thresholds.each do |match_threshold|
    #     @groups.each do |group|
    #       @previous_lunches[match_threshold] ||= 0
    #       @previous_lunches[match_threshold] += [group.previous_lunches[match_threshold]].flatten.compact.size
    #     end
    #   end
    # end

    def valid?
      groups.map(&:valid?).all?
    end
    #   # @valid = true
    #   # Are there any groups that are individually too low-scoring to allow?
    #   groups.each do |group|
    #     @valid = false if group.score < config.min_group_score
    #   end
    #   # Are there any groups that have already been deemed invalid?
    #   groups.each do |group|
    #     if !group.valid
    #       @valid = false
    #     end
    #   end
    #   @valid
    # end

  end
end
