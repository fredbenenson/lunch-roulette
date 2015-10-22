class LunchRoulette
  class LunchGroup

    attr_accessor :people, :score, :valid, :previous_lunches, :scores, :id

    def initialize(chosen_people = [])
      @config = config
      @people = chosen_people
      @previous_lunches = {}
      find_previous_lunches
      # Calculate the penalty factor for recent repeated subgroups
      previous_lunches_factor = calculate_previous_lunches_factor
      # Calculate the average variance across all features for all members.
      # Since some groups will have 1 or 2 more people than others, we can't use sum
      @scores = Hash.new
      calculate_group_score
      @score = previous_lunches_factor * scores.values.sum / people.size.to_f
      @scores['previous_lunches_factor'] = previous_lunches_factor
      @valid = true
    end

    def config
      LunchRoulette::Config
    end

    def inspect
      @people.map{|p| p.inspect }.join(", ")
    end

    def emails
      @people.map{|p| p.email }.join(", ")
    end

    protected

    def calculate_group_score
      # Scores are normalized to the maximum value of all staff, then we get the standard deviation
      # This is later averaged across all the features of the group, so that groups with higher variance
      # will have a higher average. The averages of each group in a set is then summed to determine the
      # overall variance of the set.
      h = features.map do |feature|
        s = @people.map do |person|
          person.features[feature] / config.maxes[feature].to_f
        end.standard_deviation
        [feature, s * config.weights[feature]]
      end
      @scores = Hash[*h.flatten]
    end

    def calculate_previous_lunches_factor
      factor = 1.0
      max_lunch_id = @config.maxes['lunch_id'].to_i
      return factor if @previous_lunches.nil?
      @previous_lunches.each do |threshold, previous_lunches_above_threshold|
        previous_lunches_above_threshold.each do |previous_lunch_id|
          time = (max_lunch_id - previous_lunch_id).to_f
          factor *= (1.0 - Math.exp(-1.0 * (time / config.time_decay_constant) ** 2))
        end
      end
      factor
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

