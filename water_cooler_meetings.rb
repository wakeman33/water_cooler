require 'json'
require 'digest'

class WaterCoolerRand
  def initialize(people_count)
    @r = Random.new
    @people_count = people_count
    @rand_max = @people_count * @r.rand(100)
    @index =  @r.rand(@rand_max) % @people_count
  end

  def get_index(people_count)
    offset = @r.rand(@rand_max)
    @index = (@index + offset) % people_count
    @index
  end
end

people = JSON.parse(File.new("./coworkers.json").read)
completed_groups = JSON.parse(File.new("./completed_groups.json").read)
$wc_rand = WaterCoolerRand.new(people.count)

def grab_group(people)
  group = []

  while group.count != 3 do
    index = $wc_rand.get_index(people.count)

    # Skip person if they should not be included
    next unless people[index]['include']

    unless group.include?(people[index])
      group.push(people[index])
    end
  end

  # Sorting Items so that it is always the same order for correct SHA1
  group.sort {|x,y| x['name'] <=> y['name']}
end

def remove_group(group, people)
  group.each do |person|
    people.delete(person)
  end
end

def output_groups(groups)
  count = 1
  f = File.new('./water_cooler_groups', 'w')
  groups.each do |group|
    f.puts("Group #{count}")
    group.each do |person|
      f.puts(person['name'])
    end
    f.write("\n\n")
    count += 1
  end
end

list_of_groups = []
retry_limit = 0
while (!people.empty? && retry_limit < 20) do 
  if people.count < 3
    puts "PUSHING LEFTOVERS"
    list_of_groups.push(people)
    break
  end
  group = grab_group(people)
  group_hash = Digest::SHA1.hexdigest(group.join)
  if completed_groups.include?(group_hash)
    retry_limit += 1
    next
  else
    retry_limit = 0
  end
  list_of_groups.push(group)
  remove_group(group, people)
  completed_groups.push(group_hash)
end

output_groups(list_of_groups)

File.open("./completed_groups.json", 'w') do |f|
  f.write(JSON.pretty_generate(completed_groups))
end
