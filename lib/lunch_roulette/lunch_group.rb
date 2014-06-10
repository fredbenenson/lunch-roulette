class LunchRoulette
  class LunchGroup

    attr_accessor :people, :sum_score, :valid, :previous_lunches, :scores, :id

    def initialize(chosen_people = [])
      @config = config
      @people = chosen_people
      @scores = Hash.new
      # Calculate the average diversity across all features for all members.
      # Since some groups will have 1 or 2 more people than others, we can't use sum
      @sum_score = calculate_group_score.values.sum
      @valid = true
      @previous_lunches = {}
      find_previous_lunches
    end

    def config
      LunchRoulette::Config
    end

    def inspect
      @people.map{|p| p.inspect }.join(",\n")
    end

    def emails
      @people.map{|p| p.email }.join(", ")
    end

    protected

    def calculate_group_score
      # Scores are normalized to the maximum value of all staff, then we get the standard deviation
      # This is later averaged across all the features of the group, so that groups with higher diversity
      # will have a higher average. The averages of each group in a set is then summed to determine the
      # overall diversity of the set.
      h = features.map do |feature|
        s = @people.map do |person|
          person.features[feature] / config.maxes[feature].to_f
        end.standard_deviation
        [feature, s * config.weights[feature]]
      end
      @scores = Hash[*h.flatten]
    end

    def features
      config.weights.keys
    end

    # Find the group's previous lunches if there are any.
    def find_previous_lunches
      @people.each do |person|
        if person.previous_lunches
          person.previous_lunches.map do |previous_lunch|
            @config.match_thresholds.map do |match_threshold|
              if ((@config.previous_lunches[previous_lunch].people - [person]) & @people).size >= (match_threshold - 1)
                @previous_lunches[match_threshold] ||= Set.new
                @previous_lunches[match_threshold] << previous_lunch
              end
            end
          end
        end
      end
    end
  end
end

