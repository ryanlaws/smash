-- TODO
-- strike... 
-- sharpness
-- - (circle?)
-- seq events
-- - n-gon connecting circle points ("rays"?)
-- - points light up on playback
-- tempo
-- - plain ol' number good here
-- - love that TT font
-- leak
-- - was thinking actual rain drops
-- noise
-- - something indicating "floor"
-- - maybe a dirty line thru the middle
-- - gets brighter as it gets louder
-- gain
-- - something that gets painfully bright
-- - maybe should influence leak gfx too
--
-- some methods stolen from 
-- northern-information/athenaeum/lib/graphics.lua

local poopcounter = 0
local circle_size = 1
local circle_size_dir = 2
local circle_size_max = 40

local g = {}

function g.text(x, y, s, l)
  screen.level(l or 15)
  screen.move(x, y)
  screen.text(s)
  screen.stroke()
end

function g.circle(x, y, r, l)
  screen.level(l or 15)
  screen.circle(x, y, r)
  --screen.fill()
  screen.stroke()
end

function g.up()
  screen.clear()
end

function g.down()
  screen.update()
end

-- this is maybe not a "lib"
function g.redraw () 
  g.up()
  g.circle(64, 32, circle_size, 3)
  g.text(poopcounter, 8, 'poop', poopcounter % 15)
  g.down()

  poopcounter = (poopcounter + 1) % 48
  circle_size = (circle_size + circle_size_dir)
  if circle_size > circle_size_max or circle_size <= 0 then 
    circle_size_dir = 0 - circle_size_dir
  end
end

return g

