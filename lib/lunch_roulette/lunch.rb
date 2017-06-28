class LunchRoulette
  class Lunch
    attr_accessor :set_id, :group_id
    def initialize(set_id:, group_id:)
      @set_id = set_id
      @group_id = group_id
    end

    def eql?(other_lunch)
      set_id == other_lunch.set_id && group_id == other_lunch.group_id
    end

    def to_s
      [set_id, group_id].join('-')
    end

    def self.from_s(str)
      ids = str.split('-')
      new(set_id: ids[0].to_i, group_id: ids[1].to_i)
    end
  end
end
