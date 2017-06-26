class LunchRoulette
  class Lunch

    PREVIOUS_LUNCHES_HALF_LIFE = Config.previous_lunches_half_life
    
    attr_accessor :set_id, :group_id
    def initialize(set_id:, group_id:)
      @set_id = set_id
      @group_id = group_id
    end

    def equals(other_lunch)
      set_id == other_lunch.set_id && group_id = other_lunch.group_id
    end

    def previous_lunch_decay(prev_lunch)
      coeff = -1.0 * Math.log(2) / (PREVIOUS_LUNCHES_HALF_LIFE)
      Math.exp(coeff * (set_id - prev_lunch.set_id))
    end

    def to_s
      [set_id, group_id].join('-')
    end
  end
end
