class LunchRoulette
  class LunchGroup

    MAX_GROUP_SCORE = Config.config[:max_group_score]
    MAX_MANAGER_SCORE = Config.config[:max_manager_score]
    MAX_PREVIOUS_LUNCHES_SCORE = Config.config[:max_previous_lunches_score]

    TENURE_WEIGHT = Config.config[:tenure_weight]
    TEAM_WEIGHT = Config.config[:team_weight]
    MANAGER_WEIGHT = Config.config[:manager_weight]
    COLLEAGUE_WEIGHT = Config.config[:colleague_weight]
    PREVIOUS_LUNCHES_WEIGHT = Config.config[:previous_lunches_weight]
    PREVIOUS_LUNCHES_HALF_LIFE = Config.config[:previous_lunches_half_life]

    attr_accessor :id, :people

    def initialize(id:, people:)
      @id = id
      @people = people
    end

    def emails
      people.map(&:email)
    end

    def valid?
      # score <= MAX_GROUP_SCORE &&
        manager_score < MAX_MANAGER_SCORE &&
        previous_lunches_score < MAX_PREVIOUS_LUNCHES_SCORE
    end

    def score
      TENURE_WEIGHT * tenure_score +
        TEAM_WEIGHT * team_score +
        MANAGER_WEIGHT * manager_score + 
        COLLEAGUE_WEIGHT * colleague_score + 
        PREVIOUS_LUNCHES_WEIGHT * previous_lunches_score
    end

    def tenure_score
      100.0 / (1 + people.map(&:days_here).standard_deviation)
    end

    def team_score
      10.0 / (1 + people.map(&:team_value).standard_deviation)
    end
    
    def manager_score
      names = people.map(&:name)
      managers = people.map(&:manager)
      overlap = names & managers
      managers.count{|m| overlap.include?(m)}
    end

    def colleague_score
      managers = people.map(&:manager).compact
      managers.uniq.reduce(0) do |sum, manager|
        count = managers.count(manager)
        sum + (count - 1) ** 2
      end
    end

    def previous_lunches_score
      previous_lunches = people.flat_map(&:previous_lunches)
      latest_lunch = people.first.latest_lunch

      previous_lunches.uniq(&:to_s).reduce(0) do |sum, prev_lunch|
        count = previous_lunches.count{|p| prev_lunch.eql?(p)}
        sum + (count - 1) ** 2 * previous_lunch_weight(prev_lunch, latest_lunch)
      end
    end

    def previous_lunch_weight(prev_lunch, new_lunch)
      coeff = -1.0 * Math.log(2) / (PREVIOUS_LUNCHES_HALF_LIFE)
      Math.exp(coeff * (new_lunch.set_id - prev_lunch.set_id - 1))
    end

    def inspect
      "Group #{id}: " + people.map(&:name).join(', ')
    end

    def inspect_previous_groups
      previous_groups = Hash.new([])
      people.each do |p|
        p.previous_lunches.each do |l|
          previous_groups[l.to_s] += [p.name]
        end
      end
      previous_groups.
        select{|k, v| v.length > 1}.
        sort_by{|k, v| Lunch.from_s(k).set_id}.
        reverse.
        map{|k, v| "#{k}: [" + v.join(', ') + ']'}.
        join(', ')
    end

    def inspect_scores
      "Group #{id}: " + 
      "score #{score.round(3)} ("+
        "tenure #{tenure_score.round(3)}, " +
        "teams #{team_score.round(3)}, " +
        "managers #{manager_score.round(3)}, " +
        "colleagues #{colleague_score.round(3)}, " +
        "previous_lunches #{previous_lunches_score.round(3)})"
    end

    def inspect_emails
      "Group #{id}: " + emails.join(', ')
    end
  end
end
