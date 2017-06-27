class LunchRoulette

  class Person

    TEAM_MAPPINGS = Config.config[:team_mappings]
    LUNCHABLE_FALSE = Config.config[:lunchable_false]

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
      survey ? survey.lunchable? : lunchable_default
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
  end
end
