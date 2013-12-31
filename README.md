Lunch Roulette
=====
Lunch Roulette is a command line tool for generating diverse lunch groups from a list of staff.

# Why #
**Sometimes you stumble upon your best ideas in conversation with someone completely outside our normal day to day routine**.

This is the inspiration behind Lunch Roulette -- an automated way to generate lunch groups with few people on the same teams or who share the same specialty.

You may be asking why put so much effort into a tool whose end results could be achieved manually (i.e., Why can't you just pick some groups of people to have lunch with each other?).

This task is surprisingly difficult, and particularly so when generating multiple sets of lunches over many weeks, and want lunch group choice to be dependent on more than mere randomness.

Another reason genearting lunch groups is difficult is because you must do so without replacement: by removing one person from a lunch group, you have to put them in another group, and that group may not be ideal in terms of diversity or other reasons. While surmountable for a handful of people this issue becomes increasingly complex when handling many lunch groups across dozens of people over the course of many outings.

Enter Lunch Roulette. This is the set of constraints the Lunch Roulette algorithm attempts to satisfy:

* Lunch groups should be maximally diverse (e.g. though not necessary, it is ideal if all people in a group should be from a different team)
* Be able to validate certain lunch sets (e.g. no set of lunches should ever be valid if two people with the same specialty should have lunch with each other, as chances are they see each other every day)
* Respect past lunches (e.g. if Fred, Lincoln and Sherry all had lunch together a week ago, they shouldn't ever have lunch together again)
* Have configurable mappings (e.g. the Product Management team is "close" to the Product Engineering team, so lunches between them should be discouraged)
* Use weights so that some things about people are more important than others when determining diversity (e.g. team matters a lot, seniority less so)
* Output to CSV files and console and provide visibility into each group's score

# How
Lunch Roulette creates a set of lunches containing all staff, where each group is maximally diverse given the staff's specialty, their department, and their seniority.

It does this thousands of times, and then ranks sets by their overall diversity: the set of lunch groups with highest total diversity wins.

For more insight into how Lunch Roulette calculates diversity per group, see the `calculate_group_score` in the `LunchGroup` class, or the Calculating Diversity section below.

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

The use of a CSV input as opposed to a database is to facilitate easy editing in a spreedsheet application (a shared Google Doc is recommended) without the need for migrations or further application bloat. This allows non-engineers to add new staff, collaborate, and add new columns if needed.

Accordingly, the date format of MM/DD/YYYY is specific to common spreadsheet programs like Google Docs and Excel.

The `previous_lunches` column contains a double quoted comma-delimited list of previous lunches each having their own ID. If no previous lunches have taken place, then ids will be generated automatically (see the *Output* section below for more info).

Currently, `user_id` isn't for anything inside Lunch Roulette, but it may be useful to keep track of staff with similar names and/or tie into an application.

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

Lunch Roulette expects, though doesn't need, all employees to have a team (Customer Service, Design, etc.), and some employees to have a specialty (Data, Legal), etc.

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

### Determining Mappings
The weights that Lunch Roulette uses to calculate team diversity are specified in the `config/weights_and_mappings.yml` file.

Team and specialty mappings effectively work as quantizers in the `Person` class, and if you add new features, you'll have to modify it accordingly.

For example, Customer Service may be culturally "closer" to the Communications team than the Engineering team. It is **highly** recommended that you tweak the above mappings to your individual use. Remember, the more you define similarity between teams and specialties the easier it is for Lunch Roulette to diversify your lunch groups.

Seniority is calculated by subtracting the day the employee started from today, so staff that start earliest have the highest seniority.

Not all staff are required to have values for all features. In particular, if each staff has a specialty, Lunch Roulette may have a difficult time creating valid lunch sets, so its recommended that no more than 30-40% have specialties.

## Previous Lunches & Validations ##
Before Lunch Roulette calculates a lunch group's diversity, the `LunchSet` class attempts to create a set of lunches that pass the validations specified in the class method `valid_set?`. For a staff of 48 people with a minimum group size of 4, a set would contain a dozen group lunches.

Out of the box, there are three validations Lunch Roulette requires for a set to be considered valid:

* The set cannot contain any group where 3 or more people have had lunch before
* The set cannot contain more than on executive (a dummy previous lunch with the id of 0 is used here)
* The set cannot contain anyone with the same specialty (remember, specialties are different than teams)

In most scenarios with at least one or two previous lunches, it is impossible to create a valid lunch set without at least one group having one pair of people who have had lunch before.

# Calculating Diversity #
Diversity is first within groups, and then across sets. The set with the highest diversity wins.

## Group Diversity ##
Once a valid lunch set is created Lunch Roulette determines the diversity of each group within the set thusly:

  1. Choose a feature
  2. Choose a person
  3. Normalize the value of that person's quantized feature value against the maximum of the entire staff

    **Example:** if Fred has been at the company 100 days, and the max anyone has been there is 400, his normalized seniority value is 0.25

  4. Do this for all people in the current group
  5. Find the standard deviation of these values

    **Example:** For values of 0.25, 0.125, 0.1, 0.9999, the standard deviation would be 0.4258687

  6. Multiply this value by the configured weight

    **Example:** 0.4258687 * 0.2, where 0.2 is the given weight for seniority

  7. Repeat this process for all features
  8. The group score is the average of these numbers (e.g. the product of the standard deviation of the features and the configured weight per feature)

The resulting average is a representation of the how different each member of a given group is from each other across all features and can be seen in the verbose output:

    Average Score: 0.1313
      Score Breakdown: {"floor"=>0.023935677693908454, "days_here"=>0.07567297816690133, "team"=>0.3773923687622737, "specialty"=>0.04827762594273528}

The higher the average, the more diverse the group.

## Set Diversity ##
Since all sets will have the same number of groups in them, we can simply sum the average scores across all the groups and arrive at a per-set score. This represents the average diversity across all groups within a set and is used to compare sets to each other.

# Output #
Unless instructed not to, Lunch Roulette will generate a new CSV in `data/output` each time it is run. The filenames are unique and based off MD5 hases of the people in each group of the set. If specified, Lunch Roulette will output the top N results and/or the bottom N results. This is useful for testing its efficacy: if the bottom sets don't seem as diverse as the top sets, then you know its working!

Lunch Roulette will also output a new staff CSV (prefixed `staff_` in `data/output`) complete with new lunch IDs per-staff so that the next time it is run, it will avoid generating similar lunch groups. It is recommended that you overwrite data/staff.csv with whatever version you end up going with.
# Tips

* Depending on your staff and the validations you choose to enforce, Lunch Roulette may generate only a couple dozen valid sets, so if you are getting poor results, consider relaxing (commenting out) some of the validations in `LunchSet`'s `valid_set?`
* Have some time? Try 100,000 iterations!

# Caveats #
The math Lunch Roulette is using is fundamentally pretty simple, and I am sure there are better ways for generating such diversity.

# TODO #
* Tests
* Decay previous lunches weight: if a lunch was a while ago, its OK that two or three people were in the same group
* Graduate from a CLI app to something web-based
