class LunchRoulette
  class Config

    def initialize
      @@config = YAML::load(File.open('config/mappings_and_weights.yml'))
    end

    def self.tenure_weight
      @@config['tenure_weight']
    end

    def self.team_weight
      @@config['team_weight']
    end

    def self.manager_weight
      @@config['manager_weight']
    end

    def self.colleague_weight
      @@config['colleague_weight']
    end

    def self.previous_lunches_weight
      @@config['previous_lunches_weight']
    end

    def self.previous_lunches_half_life
      @@config['previous_lunches_half_life']
    end

    def self.min_lunch_group_size
      @@config['min_lunch_group_size']
    end

    def self.max_group_score
      @@config['max_group_score']
    end

    def self.team_mappings
      @@config['team_mappings']
    end

    def self.options=(o)
      @@options = o
    end

    def self.options
      @@options
    end
  end
end
