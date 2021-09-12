-- Stack = include('SMASH/lib/stack')

local g = {}
-- TODO
--
-- some methods stolen from 
-- northern-information/athenaeum/lib/graphics.lua

local circle_size = 1
local circle_size_dir = 2
local circle_size_max = 40

g.leaks = {}
local leak_buffer
local leak_frame_index = 0
local leak_counter = 0

local strike_sharpness = nil
local strike_level = nil

local event_last_pos = 0
g.event_ripples = {}

function g.text(x, y, s, l)
  screen.level(l or 15)
  screen.move(x, y)
  screen.text(s)
  screen.stroke()
end

function g.circle(x, y, r, l)
  screen.level(math.floor(l) or 15)
  screen.circle(x, y, r)
  screen.stroke()
end

function g.up()
  screen.clear()
end

function g.down()
  screen.update()
end

function g.draw_strikes()
  if strike_sharpness == nil then 
    return 
  end

  g.draw_eyes(strike_sharpness, strike_level, false)

  strike_level = math.floor(strike_level * ((1 - strike_sharpness) ^ 3))
  if strike_level < 1 then 
    strike_sharpness = nil
  end
end

function g.draw_eye(pos, size, level, is_open)
  is_open = is_open ~= false
  if is_open then
    g.circle(pos, 32, size, level)
  else
    g.line(pos, 32 - size, pos, 32 + size, level)
  end
end

function g.draw_eyes(sharpness, level, draw_shut)
  sharpness = math.floor(sharpness * 10)
  radius = math.ceil((sharpness ^ 2) / 3.8) 
  side = params:get("smash_side")
  l_open = side < 3
  r_open = side > 1

  if l_open or draw_shut then
    g.draw_eye(66 - (sharpness * 3), radius, level, l_open)
  end

  if r_open or draw_shut then
    g.draw_eye(62 + (sharpness * 3), radius, level, r_open)
  end
end

function g.draw_sharpness(sharpness)
  local level = (sharpness < 0.4) and (5 - (sharpness * 10)) or 1
  g.draw_eyes(sharpness, level, true)
end

function g.line(x1, y1, x2, y2, l)
  screen.level(l or 15)
  screen.move(x1, y1)
  screen.line(x2, y2)
  screen.stroke()
end

-- seq events
function g.draw_seq(events, event_pos, tick_pos, tick_length)
  radians = (tick_pos / tick_length - 0.25) * 2 * math.pi
  screen.level(8)
  screen.pixel(
    math.floor(math.cos(radians) * 32 + 64),
    math.floor(math.sin(radians) * 32 + 32)
  )
  screen.fill()
  while event_pos ~= event_last_pos do
    print("attempting to add a ripple")
    event_last_pos = (event_last_pos ~= nil) and (event_last_pos % #events + 1) or 1
    --print("adding ripple at "..(#event_ripples+1)..": "..event_poast
    g.event_ripples[#g.event_ripples+1] = {
      pos=event_last_pos,
      size=1
    }
    -- start drawing the event(s) 
  end

  g.remove = {}
  for i = 1,#g.event_ripples do
    r = g.event_ripples[i]
    radians = (events[r.pos][1] / tick_length) * 2 * math.pi
    g.circle(
      math.floor(math.cos(radians) * 32 + 64),
      math.floor(math.sin(radians) * 32 + 32),
      r.size,
      5 - r.size
    )
    r.size = r.size + 1
    if r.size > 4 then
      g.remove[#g.remove+1] = i
    end
-- - n-gon connecting circle points ("rays"?)
-- - points light up on playback
  end

  while #g.remove > 0 do
    -- print("attempting to remove a ripple")
    table.remove(g.remove, #g.remove)
  end
end

function g.draw_tempo()
-- - plain ol' number good here
-- - love that TT font
end

function add_new_leak()
  g.leaks[#g.leaks + 1] = {
    x = math.random(128),
    y = math.random(64),
    level = math.random(1, 8)
  }
end

function g.draw_leak(leak)
-- - was thinking rain drops
  leak_counter = leak_counter + 1
  local leak_chance = leak ^ (1/6)
  leak_chance = math.floor(leak_chance // 0.01)
  leak_chance = math.random(0, leak_chance)
  --print('taking a leak' .. leak_chance)
  if leak_counter > 0 and leak_counter % 20 == 0 then
    -- print('last new leak '..leak_counter..' frames ago')
  end
  if leak_chance > 29.8 and leak_chance < 100 then
    -- print('new leak after '..leak_counter..' frames')
    add_new_leak()
    leak_counter = 0
  end

  removes = {}

  for i = 1,#g.leaks do
    screen.level(g.leaks[i].level)
    screen.pixel(g.leaks[i].x, g.leaks[i].y)
    screen.fill()

    delta_y = math.floor((math.random() * 1.32) ^ 5)
    g.leaks[i].y = g.leaks[i].y + delta_y
    if delta_y > 0 or math.random() > 0.6 then
      g.leaks[i].level = g.leaks[i].level - 1
    end

    if g.leaks[i].level < 1 then
      removes[#removes + 1] = i
    end
  end

  for i = #removes,1,-1 do
    table.remove(g.leaks, removes[i])
  end
end

function g.draw_noise()
-- - something indicating "floor"
-- - maybe a dirty line thru the middle
-- - gets brighter as it gets louder
end

function g.draw_gain()
-- - something that gets painfully bright
-- - maybe should influence leak gfx too
end

function g.draw_stupid_circle()
  g.circle(64, 32, circle_size, 3)

  circle_size = (circle_size + circle_size_dir)
  if circle_size > circle_size_max or circle_size <= 0 then 
    circle_size_dir = 0 - circle_size_dir
  end
end

-- special events
function g.create_strike(sharpness)
  strike_sharpness = sharpness
  strike_level = 15
end

return g
