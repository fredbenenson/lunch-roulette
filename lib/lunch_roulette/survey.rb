class LunchRoulette
  class Survey

    SURVEY_CURRENT_LAG = Config.config[:survey_current_lag]

    attr_accessor :email, :lunchable, :date
    def initialize(email:, lunchable:, date:)
      @email = email
      @lunchable = lunchable
      @date = date
    end

    def current?
      (Date.today - date).to_i <= SURVEY_CURRENT_LAG
    end
  end
end
