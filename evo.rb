require 'sinatra'
#require "sinatra/reloader"

WIDTH = 100
HEIGHT = 30
JUNGLE = [45,10,10,10]
PLANT_ENERGY = 80
$plants = Hash.new
REPRODUCTION_ENERGY = 200
Animal = Struct.new(:x, :y, :energy, :dir, :genes)
Point = Struct.new :x, :y
DEFAULT= "#3a75c4"
HI_LO = "#800c7b"
LO_HI = "#e40045"

def randomPlant (left, top, width, height)
  x = (left + rand(WIDTH)) % WIDTH
  y = (top + rand(HEIGHT)) % HEIGHT
  pos = Point.new(x,y)
  $plants[pos] = true
end

def addPlants ()
  randomPlant(45,10,10,10);
  randomPlant(0,0,WIDTH,HEIGHT)
end

def randomGenes ()
  lst = Array.new
  for i in 0..7
    lst.push(rand(10))
  end
  return lst
end

#modifies x and y fields
def move (animal)
  dir = animal.dir
  x = animal.x
  y = animal.y
  if (dir >= 2 && dir < 5)
    animal.x = (x + 1) % WIDTH
  elsif (dir == 1 || dir == 5)
    animal.x = x % WIDTH
  else
    animal.x = (x - 1) % WIDTH
  end
  if (dir >= 0 && dir < 3)
    animal.y = (y - 1) % HEIGHT
  elsif (dir >= 4 || dir < 7)
    animal.y = (y + 1) % HEIGHT
  else
    animal.y = y % HEIGHT
  end
  animal.energy = animal.energy - 1
end

def turn (animal)
  x = rand(1..animal.genes.inject{|sum,x| sum + x})
  total = 0
  for i in animal.genes
    xnu = animal.x - i
    if (xnu < 0)
      break
    else
      total = 1 + total
    end
  end
  animal.dir = (animal.dir + total) % x
end

def eat (animal)
  pos = Point.new(animal.x, animal.y)
  if ($plants[pos])
    $plants.delete(pos)
    animal.energy += PLANT_ENERGY
  end
end

#pushes new animal on $animals if energy level are above 200
def reproduce (animal)
  e = animal.energy
  if (animal.energy >= REPRODUCTION_ENERGY)
    animal.energy = animal.energy << -1
    animalNu = animal.clone
    genesNu = animal.genes.clone
    mutation = rand(8)
    genesNu[mutation] = [1, (animalNu.genes[mutation] + rand(3) - 1)].max
    animalNu.genes = genesNu
    $animals.push(animalNu)
  end
end

$animals = [Animal.new((WIDTH << -1),(HEIGHT << -1),1000,0,randomGenes())]

def updateWorld ()
  counter = 0
  $animals.each do |animal|
    if (animal.energy <= 0)
      $animals.delete_at(counter)
    end
    counter = counter+1
  end
  size = $animals.length - 1
  for a in 0..size
    turn($animals[a])
    move($animals[a])
    eat($animals[a])
    reproduce($animals[a])
  end
  addPlants()
end

class DrawWorld
  def each
    yield "<body>"
    yield "<table>"
    for x in 0..WIDTH
      yield "<col width='20px'/>"
    end
    for x in 0..WIDTH
      if (x == 0)
        yield "<tr>"
      end
      yield "<td>-</td>"
    end
    yield "</tr>"
    for y in 0..HEIGHT
      yield "<tr><td>|</td>"
      for x in 0..WIDTH
        found_anim = false
        found_plant = false
        for a in $animals
          if (a.x == x && a.y == y)
            if (a.genes[0] < 5 && a.genes[7] > 5)
              yield "<td><span style=color:#{LO_HI}>M</span></td>"
            elsif (a.genes[0] > 5 && a.genes[7] < 5)
              yield "<td><span style=color:#{HI_LO}>M</span></td>"
            else
              yield "<td><span style=color:#{DEFAULT}>M</span></td>"
            end
            found_anim = true
            break;
          end
        end
        if (!found_anim)
          $plants.each{|key,val| 
            if (key[:x] == x && key[:y] == y)
              found_plant = true
              yield "<td><span style=color:green>*</span></td>"
            end
          }
        end
        if (!found_anim && !found_plant)
          yield "<td>&nbsp;</td>"
          found_anim = false
          found_plant = false
        end
      end
      yield "<td>|</td></tr>"
    end
    yield "<tr>"
    for x in 0..WIDTH
      yield "<td>-</td>"
    end
    yield "</tr></table>"
    yield "<table border=1>"
    yield "<tr><td colspan=5>#{$animals.length} Animals</td></tr>"
    yield "<tr><th>x</th><th>y</th><th>energy</th><th>dir</th><th>genes</th></tr>"
    $animals.each do |animal|
      yield "<tr><td>#{animal.x}</td><td>#{animal.y}</td><td>#{animal.energy}</td><td>#{animal.dir}</td><td>#{animal.genes}</td></tr>"
    end
    yield "</table>"
    yield "</body>"
  end
end

get '/' do 
  days = params[:days].to_i
  if (days == 0)
    days = 100
  end
  for i in 0..days
    updateWorld()
  end
  DrawWorld.new
end
