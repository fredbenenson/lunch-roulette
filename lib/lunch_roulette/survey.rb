class LunchRoulette
  class Survey
    attr_accessor :email, :response, :date
    def initialize(email:, response:, date:)
      @email = email
      @response = response
      @date = date
    end
  end
end
