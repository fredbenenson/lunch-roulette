class LunchRoulette
  class Output

    def initialize(results)
      @results = results
    end

    def get_results
      @results.map do |type, result|
        result.map.with_index do |set, set_index|

          if config.options[:dont_write]
            file = "/dev/null"
          else
            file = "data/output/#{set.score.round(4)}_#{type}_#{set.name}.csv"
          end

          CSV.open(file, "w") do |csv|
            puts "#{type.capitalize} Set Candidate: #{set_index + 1}\n\n" if config.options[:verbose_output]
            csv << ['score', *config.match_thresholds]
            set.groups.each.with_index do |group, group_index|
              s = config.match_thresholds.map{|m| group.previous_lunches[m].to_a.join("\t") }
              o = "Group #{group_index + 1} of #{group.people.size} people: "
              o << group.inspect
              o << "\n\tEmails: #{group.emails}"
              o << "\n\tSum Score: #{group.sum_score.round(4)}"
              o << "\n\tScore Breakdown:#{group.scores}"
              o << "\n\n"
              puts o if config.options[:verbose_output]
              csv << [group.sum_score, *s, group.inspect].flatten
            end
            o =  "Set #{set_index + 1} total score: #{set.score}, previous lunch matches: #{set.previous_lunch_stats.inspect}\n"
            puts "File written to: #{file}\n" unless config.options[:dont_write]
            o += "~~~"
            puts o if config.options[:verbose_output]
            csv << ["SUM: #{set.score}", *set.previous_lunches.values]
          end
        end
      end
    end

    def get_new_staff_csv(staff)
      winning_set = @results[:top].first
      person_lunch_mappings = Hash[*winning_set.groups.map{|g| g.people.map{|person| [person.user_id, g.id] } }.flatten ]

      if config.options[:dont_write]
        file = "/dev/null"
      else
        file = "data/output/staff_#{winning_set.score.round(4)}_#{winning_set.name}.csv"
      end
      CSV.open(file, "w") do |csv|
        csv << %w(user_id email name start_date table team specialty previous_lunches)
        staff.each do |luncher|
          o = [ luncher.user_id, luncher.email, luncher.name, luncher.start_date, luncher.table, luncher.team, luncher.specialty, [luncher.previous_lunches, person_lunch_mappings[luncher.user_id]].flatten.join(",") ]
          puts o.join("\t") if config.options[:verbose_output]
          csv << o
        end
        puts "Staff file written to: #{file}\n" unless config.options[:dont_write]
      end
    end

    def config
      LunchRoulette::Config
    end

  end
end
