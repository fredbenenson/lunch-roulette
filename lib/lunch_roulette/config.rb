class LunchRoulette
  class Config
    def self.config
      @@config ||= YAML::load(File.open('config/config.yml'))
    end

    def self.spreadsheet_url
      config['spreadsheet_url']
    end

    def self.spreadsheet_id
      config['spreadsheet_id']
    end

    def self.people_range
      config['people_range']
    end

    def self.people_old_range
      config['people_old_range']
    end

    def self.survey_range
      config['survey_range']
    end

    def self.person_date_format
      config['person_date_format']
    end

    def self.survey_date_format
      config['survey_date_format']
    end

    def self.file_date_format
      config['file_date_format']
    end

    def self.tenure_weight
      config['tenure_weight']
    end

    def self.team_weight
      config['team_weight']
    end

    def self.manager_weight
      config['manager_weight']
    end

    def self.colleague_weight
      config['colleague_weight']
    end

    def self.previous_lunches_weight
      config['previous_lunches_weight']
    end

    def self.previous_lunches_half_life
      config['previous_lunches_half_life']
    end

    def self.team_mappings
      config['team_mappings']
    end

    def self.iterations
      config['iterations']
    end

    def self.min_group_size
      config['min_group_size']
    end

    def self.max_group_score
      config['max_group_score']
    end

    def self.options=(o)
      @@options = o
    end

    def self.options
      @@options
    end
  end
end
