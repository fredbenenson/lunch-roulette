class LunchRoulette

  class Person

    TEAM_MAPPINGS = Config.team_mappings

    attr_accessor :name, :email, :start_date, :team, :manager, :lunchable_default, :lunches, :survey
    def initialize(name:, email:, start_date:, team:, manager: nil, lunchable_default: nil, lunches: nil, survey: nil)
      @name = name
      @email = email
      @start_date = start_date
      @team = team
      @manager = manager
      @lunchable_default = lunchable_default
      @lunches = lunches
      @survey = survey
    end

    def lunchable?
      if survey && (Date.today - survey.date).to_i < 30
        survey.response == 'Yep'
      else
        lunchable_default != 'FALSE'
      end
    end

    def days_here
      (Date.today - @start_date).to_i
    end

    def team_value
      TEAM_MAPPINGS[@team].to_i
    end

    def latest_lunch
      lunches.last
    end

    def previous_lunches
      lunches[0..-2]
    end

    def add_lunch(lunch)
      self.class.new(
        name: name,
        email: email,
        start_date: start_date,
        team: team,
        manager: manager,
        lunchable_default: lunchable_default,
        lunches: lunches + Array(lunch),
        survey: survey
      )
    end

    def to_row
      {
        'name' => name, 
        'email' => email, 
        'start_date' => start_date.strftime(PERSON_DATE_FORMAT), 
        'team' => team, 
        'manager' => manager, 
        'lunchable_default' => lunchable_default, 
        'lunches' => lunches.map(&:to_s).join(', ')
      }
    end

    def self.to_lunches(str)
      unless str.nil?
        str.split(',').map do |p| 
          ids = p.strip.split('-')
          Lunch.new(set_id: ids[0].to_i, group_id: ids[1].to_i)
        end
      else
        []
      end
    end
  end
end
