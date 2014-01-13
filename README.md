Lunch Roulette
=====
Lunch Roulette is a command line tool for generating diverse lunch groups from a list of staff.

# Why #
**Sometimes you stumble upon your best ideas in conversation with someone completely outside our normal day to day routine**.

This is the inspiration behind Lunch Roulette -- an automated way to generate lunch groups with few people on the same teams or who share the same specialty.

You may be asking why put so much effort into a tool whose end results could be achieved manually (i.e., Why can't you just pick some groups of people to have lunch with each other?).

This task is surprisingly difficult, and particularly so when generating multiple sets of lunches over many weeks, and want lunch group choice to be dependent on more than mere randomness.

For more about this project, read this: TKTKTK

# Usage #
Lunch Roulette always requires a CSV file with staff features:

    ruby lib/lunch_roulette.rb data/staff.csv

Along with the various weights and and mappings, configurable options include the number of people per group, the number of iterations to perform, and the number of groups to output:

    Usage: ruby lunch_roulette_generator.rb staff.csv [OPTIONS]
        -n, --min-group-size N           Minimum Lunch Group Size (default 4)
        -i, --iterations I               Number of Iterations (default 1,000)
        -m, --most-diverse-sets M        Number of most diverse sets to generate (default 1)
        -l, --least-diverse-sets L       Number of least diverse sets to generate (default 0)
        -v, --verbose                    Verbose output
        -d, --dont-write                 Don't write to files
        -h, --help                       Print this help

# Input #
A sample staff dataset is provided in `data/staff.csv` (thanks to Namey for the names):

    user_id,name,start_date,floor,team,specialty,previous_lunches
    1,Lincoln Kruiboesch,06/18/2012,2,Communications,,"12,7"
    2,Sherill Assaf,09/10/2011,3,Product Manager,,"1,9"
    3,Don Greep,03/23/2013,1,Customer Service,,"6,3"
    4,Andera Levenson,10/12/2011,3,Operations,,"1,10"
    5,Fred Pickrell,07/21/2012,3,Customer Service,,"12,1"
    6,Felipe Graen,08/28/2009,3,Engineering,Backend,"5,13"
    7,Scott Swearengen,03/03/2011,2,Engineering,,"3,4"
    8,Ivory Sheward,08/17/2010,3,Outreach,Backend,"11,4"
    9,Mauricio Javis,08/25/2009,1,Customer Service,,"12,11"
    10,Maria Givhan,09/18/2011,3,Outreach,Backend,"11,9"

## Configuration ##
### Mappings ###
At the minimum, Lunch Roulette needs to know how different individual features are from each other. This is achieved by hardcoding a one dimensional mapping in `config/mappings_and_weights.yml`:

    team_mappings:
      Customer Service: 0
      Communications: 5
      Outreach: 15
      Operations: 30
      Product Manager: 40
      Design: 60
      Engineering: 90
      Executive: 150
    specialty_mappings:
      Backend: -20
      Data: -10
      Frontend: -15
      Mobile: 5
      Finance: 0
      Legal: 40

### Weights ###
You should also specify the weights of each feature as a real value. This allows Lunch Roulette to weight some features as being more important than others when calculating lunch group diversity. In the supplied configuration, team is weighted as 0.9, and is therefore the most important factor in determining whether a lunch group is diverse.

    weights:
      floor: 0.1
      days_here: 0.2
      team: 0.9
      specialty: 0.1

It's not strictly necessary to keep the weights between 0 and 1, but doing so can keep scores more comprehensible.

Finally you can specify the default minimum number of people per lunch group:

    min_lunch_group_size: 4

When the number of total staff is not wholly divisible by this number, Lunch Roulette randomly assigns remaining staff to groups.

For example, if a staff was comprised of 21 people, and the mimimum group size was 4, Lunch Roulette would create four groups of four people, and one group of five people.

# Output #
Unless instructed not to, Lunch Roulette will generate a new CSV in `data/output` each time it is run. The filenames are unique and based off MD5 hases of the people in each group of the set. If specified, Lunch Roulette will output the top N results and/or the bottom N results. This is useful for testing its efficacy: if the bottom sets don't seem as diverse as the top sets, then you know its working!

Lunch Roulette will also output a new staff CSV (prefixed `staff_` in `data/output`) complete with new lunch IDs per-staff so that the next time it is run, it will avoid generating similar lunch groups. It is recommended that you overwrite data/staff.csv with whatever version you end up going with.

# Tips

* Depending on your staff and the validations you choose to enforce, Lunch Roulette may generate only a couple dozen valid sets, so if you are getting poor results, consider relaxing (commenting out) some of the validations in `LunchSet`'s `valid_set?`
* Have some time? Try 100,000 iterations!

# TODO #
* Tests
* Decay previous lunches weight: if a lunch was a while ago, its OK that two or three people were in the same group
* Graduate from a CLI app to something web-based
