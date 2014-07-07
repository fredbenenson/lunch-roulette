require 'rails'
require 'CSV'

teams = ["Community Support", "Communications", "Community", "Operations", "Product Manager", "Design", "Engineering"]
specialties = ["Frontend", "Backend", "Data", "Finance", "Human Resources", "Legal", "Mobile" ]
staff = ["Lincoln Kruiboesch", "Sherill Assaf", "Don Greep", "Andera Levenson", "Fred Pickrell", "Felipe Graen", "Scott Swearengen", "Ivory Sheward", "Mauricio Javis", "Maria Givhan", "Rolande Russer", "Cornelius Samrov", "Domitila Keliipaakaua", "Keneth Fliger", "Mickie Robyn", "Margeret Sofer", "Lashandra Kallevig", "Sherron Nealley", "DeAndra Szpak", "Ethan Kuzara", "Damion Gibala", "Parker Derwin", "Roscoe Pyeatt", "Mara Maria", "Ines Jubilee", "Leandro Mittlestadt", "Letty Swarner", "Nakita Allbritten", "Eggimann Tarone", "Stepanie Palevic", "Ramiro Buckmeon", "Valrie Kleftogiannis", "Tenisha Sandate", "Dian Cham", "Carolina Credo", "Colin Rigoni", "Lorrine Langanke", "Suzi Savannah", "Michaela Barella", "Yuriko Rodefer", "Jerald Wolanin", "Idella Siem", "Edra Weisiger", "Collen Molton", "Orlando Horgan", "Scot Collons", "Deshawn Meinhardt", "Brittani Baccus", "Jerrie Covarrubias", "Ina Larde", "Loyd Donofrio", "Jani McGlothian", "Samuel Janis", "Susan Young", "Jennifer Baker", "William Wood", "Elizabeth Diaz", "Helen Ward", "Campbell Russell", "David Graham", "Ruth Bryant", "Patricia Thompson", "Patricia Ford", "Tony Reuteler", "Michaele Zahm", "Florencio Montogomery", "Terese Delung"]

DATE_RANGE = (Date.parse("2009-04-29")..Date.today).to_a
FLOOR_RANGE = (1..4).to_a
PREVIOUS_LUNCHES = (1..staff.size/4).to_a

CSV.open("data/new_staff.csv", "w") do |csv|
  csv << %w(user_id name start_date floor team specialty previous_lunches)
  staff.each.with_index do |luncher, index|
    specialty = rand < 0.33333 ? specialties.sample(1) : [nil]
    csv << [ index + 1, luncher, DATE_RANGE.sample(1).first.strftime('%m/%d/%Y'), *FLOOR_RANGE.sample(1), *teams.sample(1), *specialty, PREVIOUS_LUNCHES.sample(2).join(",")]
  end
end




