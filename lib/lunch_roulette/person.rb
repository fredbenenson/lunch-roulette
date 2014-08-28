class LunchRoulette
  class Person
    attr_accessor :name, :lunchable, :previous_lunches, :features, :team, :specialty, :user_id, :start_date, :table, :email
    def initialize(hash)
      @features = {}
      @lunchable = %w(true TRUE).include? hash['lunchable']
      @team = hash['team']
      @user_id = hash['user_id']
      @email = hash['email']
      @specialty = hash['specialty']
      @start_date = hash['start_date']
      @features['days_here'] = (Date.today - Date.strptime(@start_date, '%m/%d/%Y')).to_i
      @features['team'] = config.team_mappings[@team].to_i
      @features['specialty'] = config.specialty_mappings[@specialty].to_i
      @features['table'] = @table = hash['table'].to_i
      @name = hash['name']
      @previous_lunches = []
      if hash['previous_lunches']
        @previous_lunches = hash['previous_lunches'].split(',').map{|i| i.to_i }
        config.maxes['lunch_id'] = @previous_lunches.max if @previous_lunches && (@previous_lunches.max > config.maxes['lunch_id'].to_i)
        # Generate previous lunches to person mappings:
        @previous_lunches.map do |previous_lunch|
          config.previous_lunches[previous_lunch] ||= LunchGroup.new
          config.previous_lunches[previous_lunch].people = [config.previous_lunches[previous_lunch].people, self].flatten
        end
      end
    end

    def inspect
      s = @name
      if @specialty
        s += " (#{@team} - #{@specialty}"
      else
        s += " (#{@team}"
      end
      s += ", Table #{@table})"
      s
    end

    def config
      LunchRoulette::Config
    end

  end
end
