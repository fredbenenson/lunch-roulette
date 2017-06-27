class LunchRoulette
  class Survey

    SURVEY_YES = Config.config[:survey_yes]
    SURVEY_CURRENT_LAG = Config.config[:survey_current_lag]

    attr_accessor :email, :response, :date
    def initialize(email:, response:, date:)
      @email = email
      @response = response
      @date = date
    end

    def current?
      (Date.today - date).to_i <= SURVEY_CURRENT_LAG
    end

    def lunchable?
      response == SURVEY_YES
    end
  end
end
