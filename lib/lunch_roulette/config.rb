class LunchRoulette
  class Config
    def self.config
      @@config ||= YAML::load(File.open('config/config.yml')).
        map{|k, v| [k.to_sym, v]}.to_h
    end

    def self.options=(o)
      @@options = o
    end

    def self.options
      @@options
    end
  end
end
