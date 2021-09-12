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
  g.safe_level(l)
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

  g.draw_ears(strike_sharpness, strike_level, false)

  strike_level = math.floor(strike_level * ((1 - strike_sharpness) ^ 3))
  if strike_level < 1 then 
    strike_sharpness = nil
  end
end

function g.draw_ear(pos, size, level)
  g.circle(pos, 33, size, level)
end

function g.draw_ears(sharpness, level, draw_shut)
  sharpness = math.floor(sharpness * 10)
  radius = math.ceil((sharpness ^ 2) / 3.8) 

  -- this is really not this thing's responsibility
  side = params:get("smash_side")

  l_open = side < 3
  r_open = side > 1

  if side < 3 then
    g.draw_ear(66 - (sharpness * 3), radius, level)
  end

  if side > 1 then
    g.draw_ear(62 + (sharpness * 3), radius, level)
  end
end

function g.draw_sharpness(sharpness)
  local level = (sharpness < 0.4) and (5 - (sharpness * 10)) or 1
  g.draw_ears(sharpness, level, true)
end

function g.safe_level(l)
  screen.level(type(l) == 'number' and math.floor(l) or 15)
end

function g.line(x1, y1, x2, y2, l)
  g.safe_level(l)
  screen.move(x1, y1)
  screen.line(x2, y2)
  screen.stroke()
end

function g.draw_needle(tick_pos, tick_length)
  radians = (tick_pos / tick_length - 0.25) * 2 * math.pi
  screen.level(8)
  screen.pixel(
    math.floor(math.cos(radians) * 32 + 64),
    math.floor(math.sin(radians) * 32 + 32)
  )
  screen.fill()
end

function g.restart_seq()
  print('seq restarted')
  event_last_pos = 0
end

function g.add_event_ripple(pos)
  g.event_ripples[#g.event_ripples+1] = { pos=event_last_pos, size=1 }
end

function g.draw_event_ripple(ripple)
  radians = (events[ripple.pos][1] / tick_length - 0.25) * 2 * math.pi
  g.circle(
    math.floor(math.cos(radians) * 32 + 64),
    math.floor(math.sin(radians) * 32 + 32),
    ripple.size,
    5 - ripple.size
  )
  -- existing stuff here
  ripple.size = ripple.size + 1
end

function g.draw_seq(events, event_pos, tick_pos, tick_length)
  g.draw_needle(tick_pos, tick_length)

  -- catch up
  while event_pos ~= event_last_pos do
    --print("catching up to "..event_pos.." from "..event_last_pos.."...")
    event_last_pos = (event_last_pos ~= nil) and (event_last_pos % #events + 1) or 1
    g.add_event_ripple(event_last_pos)
  end

  g.remove = {}
  for i = 1,#g.event_ripples do
    g.draw_event_ripple(g.event_ripples[i])
-- - n-gon connecting circle points ("rays"?)
    if g.event_ripples[i].size > 4 then
      g.remove[#g.remove+1] = i
    end
  end

  for i = #g.remove, 1, -1 do
    -- print("attempting to remove a ripple")
    table.remove(g.event_ripples, g.remove[i])
    --print("removed ripple "..#g.event_ripples)
  end
end

function g.draw_tempo()
-- - plain ol' number good here
-- - love that TT font
end

function g.add_new_leak()
  g.leaks[#g.leaks + 1] = {
    x = math.random(128),
    y = math.random(64),
    level = math.random(1, 8)
  }
end

-- collapse values from 0.001 - 1 to scaled random boolean 
function g.chance(x)
  x = x ^ (1/6)
  x = math.floor(x // 0.01)
  x = math.random(0, x)
  return x > 29.8 and x < 100
end

function g.draw_leak(leak)
  leak_counter = leak_counter + 1
  if g.chance(leak) then
    g.add_new_leak()
    leak_counter = 0
  end

  removes = {}

  for i = 1,#g.leaks do
    g.safe_level(g.leaks[i].level)
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
  noise = params:get("smash_noise")
  noise_str = ''

  for i=1,256 do
    noise_str = noise_str .. string.char(g.chance(noise) and math.random(1, 2) or 0)
  end

  screen.poke(1, 32, 128, 2, noise_str)
end

function g.draw_gain()
-- - something that gets painfully bright
-- - maybe should influence leak gfx too
end

-- special events
function g.create_strike(sharpness)
  strike_sharpness = sharpness
  strike_level = 15
end

return g
