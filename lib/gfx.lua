local g = {
  leaks = {},
  ripples = {},
  event_last_pos = 0,
  add_ripple_q = FN.make_q(),
  menu_level = 0,
  sharpness = 0.5,
  lag_str = '.',
  lag_pos = 0,
  hack_font = 64,
  hack_font_size = 8,
  hack_text = '',
  hack_counter = 0
}

-- some methods stolen/adapted from 
-- northern-information/athenaeum/lib/graphics.lua

-- | helpers | --
function g.text(x, y, s, l, right)
  g.safe_level(l)
  screen.move(x, y)
  if right then
    screen.text_right(s)
  else
    screen.text(s)
  end
  screen.stroke()
end

function g.shadow_text(x, y, s, l, pos)
  if not s or s == '' then return end
  local t = (pos == 'right') and screen.text_right 
    or (pos == 'center') and screen.text_center 
    or screen.text

  -- shadow
  screen.level(0)
  screen.move(x - 1, y) t(s)
  screen.move(x + 1, y) t(s)
  screen.move(x, y - 1) t(s)                
  screen.move(x, y + 1) t(s)
  screen.stroke()

  g.safe_level(l)
  screen.move(x, y)
  t(s)
  screen.stroke()
end

function g.circle(x, y, r, l, filled)
  screen.level(math.floor(l) or 15)
  screen.circle(x, y, r)
  if filled then 
    screen.fill()
  else
    screen.stroke()
  end
end

function g.safe_level(l)
  screen.level(type(l) == 'number' and 
    math.min(math.max(math.floor(l), 0), 15) or 
    15)
end

function g.line(x1, y1, x2, y2, l)
  g.safe_level(l)
  screen.move(x1, y1)
  screen.line(x2, y2)
  screen.stroke()
end

function g.dots(size) -- more a string helper really
  local str = '.'
  while string.len(str) < size do
    str = str .. '.'
  end
  return str
end


-- | main loop | -- 
function g.redraw(sharpness, seq, meta, menu_items, e2option, e3option)
  -- params is global. feels a little dirty
  -- I think params is an OK global tho
  local leak = params:get('smash_leak')
  local side = params:get("smash_side")
  local speed = params:get('smash_ticks')
  local lag = params:get("smash_lag")
  local hack = params:get("smash_hack")

  screen.clear()
  
  g.draw_noise()
  g.draw_gain()
  g.draw_leak(leak)
  g.draw_sharpness(sharpness, side)
  g.draw_strikes(side)

  -- all this seq stuff is kinda tacky, maybe clean up
  -- what would Sandi Metz call this? inappropriate intimacy?

  if seq.tick_pos then
    g.draw_seq(seq.events, seq.last_event_pos, seq.tick_pos, seq.tick_length)
  end

  g.draw_hack(hack)
  g.draw_lag(lag)

  g.draw_status(seq.recording, seq.armed, #seq.events)
  g.draw_speed(speed)

  g.draw_menu(meta, menu_items, e2option, e3option)

  screen.update()
end


-- | components | -- 
function g.draw_strikes(side)
  if g.strike_sharpness == nil then 
    return 
  end

  g.draw_ears(g.strike_sharpness, g.strike_level, side)

  g.strike_level = math.floor(g.strike_level * ((1 - g.strike_sharpness) ^ 3))
  if g.strike_level < 1 then 
    g.strike_sharpness = nil
  end
end

function g.draw_ear(pos, size, level)
  local resonance = params:get('smash_reso')
  g.circle(pos, 32, size, level)
  x1, x2 = pos + math.random(-1, 2), pos + math.random(-1, 2)
  g.line(x1, 32 - (resonance * 32), x2, 32 + (resonance * 32), level)
  g.line(x1, 32 - (resonance * 32), x2, 32 + (resonance * 32), level)
end

function g.draw_ears(sharpness, level, side)
  sharpness = math.floor(sharpness * 10)
  radius = math.ceil((sharpness ^ 2) / 3.8) 

  l_open = side < 3
  r_open = side > 1

  if side < 3 then
    g.draw_ear(66 - (sharpness * 3), radius, level)
  end

  if side > 1 then
    g.draw_ear(62 + (sharpness * 3), radius, level)
  end
end

function g.draw_sharpness(sharpness, side)
  local level = (sharpness < 0.4) and (5 - (sharpness * 10)) or 1
  g.draw_ears(sharpness, level, side)
end

function g.draw_needle(tick_pos, tick_length)
  radians = (tick_pos / tick_length - 0.25) * 2 * math.pi
  g.circle(
    math.floor(math.cos(radians) * 32 + 64),
    math.floor(math.sin(radians) * 32 + 32),
    1, 8, true)
end

function g.reset_seq()
  print('(gfx) seq reset')
  g.event_last_pos = 0
end

function g.add_event_ripple()
  g.add_ripple_q.nq(function (pos, len)
    pos = (pos + len - 1) % len / len
    g.ripples[#g.ripples+1] = { pos=pos, size=1, level=math.random(6, 10) }
  end)
end

function g.draw_event_ripple(ripple)
  radians = (ripple.pos - 0.25) * 2 * math.pi
  g.circle(
    math.floor(math.cos(radians) * 32 + 64),
    math.floor(math.sin(radians) * 32 + 32),
    ripple.size,
    ripple.level
  )
  ripple.size = ripple.size + math.random(1,3)
  ripple.level = ripple.level - math.random(1,2)
end

function g.draw_ngon(events, tick_length, last_index)
  if events == nil or #events < 2 then
    return -- that's a nah!
  end

  screen.level(last_index == 1 and 5 or 1)
  screen.move(64, 1)

  for i=2,#events do
    radians = (events[i][1] / tick_length - 0.25) * 2 * math.pi
    x = math.floor(math.cos(radians) * 32 + 64)
    y = math.floor(math.sin(radians) * 32 + 32)
    screen.line(x, y)
    screen.stroke()
    screen.move(x, y)
    screen.level(last_index == i and 5 or 1)
  end

  screen.line(64, 1)
  screen.stroke()
end

function g.draw_ripples()
  while #g.ripples > 10 do
    table.remove(g.ripples,1)
  end

  g.remove = {}
  for i = 1,#g.ripples do
    g.draw_event_ripple(g.ripples[i])
    if g.ripples[i].size > 10 then
      g.remove[#g.remove+1] = i
    end
  end

  for i = #g.remove, 1, -1 do
    table.remove(g.ripples, g.remove[i])
  end
end

function g.draw_seq(events, event_pos, tick_pos, tick_length)
  g.draw_ngon(events, tick_length, g.event_last_pos)
  g.draw_needle(tick_pos - 1, tick_length)

  while event_pos ~= g.event_last_pos do
    g.event_last_pos = (g.event_last_pos ~= nil) and (g.event_last_pos % #events + 1) or 1
  end

  g.add_ripple_q.fire(tick_pos, tick_length)

  g.draw_ripples()
end

function g.init()
  screen.aa(0)
  screen.font_face(2)
  screen.font_size(16)
end

function g.draw_status(recording, armed, event_count)
  if not armed and not recording and event_count == 0 then
    -- nothing happened yet
  elseif armed then
    g.circle(10, 56, 4, 8, false)
  elseif recording then
    g.circle(10, 56, 4, 8, true)
  elseif event_count > 0 then
    screen.level(8)
    screen.move(6, 52)
    screen.line(15, 56)
    screen.line(6, 60)
    screen.fill()
  end
  screen.stroke()
end

function g.draw_speed(speed)
  screen.font_face(2)
  screen.font_size(16)

  g.shadow_text(124, 60, speed, 8, 'right')
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
  if g.chance(leak) then
    g.add_new_leak()
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
  max_noise = 1
  if noise >= 0.1 then max_noise = 2 end
  if noise >= 0.2 then max_noise = 3 end
  if noise >= 0.3 then max_noise = 5 end
  if noise >= 0.5 then max_noise = 9 end
  if noise >= 0.8 then max_noise = 15 end

  for i=1,256 do
    noise_str = noise_str .. string.char(g.chance(noise) and math.random(1, max_noise) or 0)
  end

  screen.poke(1, 32, 128, 2, noise_str)
end

function g.draw_gain()
  g.safe_level(params:get('smash_gain') * 5)
  screen.rect(1, 1, 127, 63)
  screen.stroke()

  g.safe_level(params:get('smash_gain'))
  screen.rect(2, 2, 125, 61)
  screen.stroke()
end

function g.strike(ctrl, value, from_seq)
  if ctrl == 'sharpness' then
    g.strike_sharpness = value
  else
    g.strike_sharpness = g.sharpness
  end
  g.strike_level = 15

  if from_seq then
    g.add_event_ripple() -- too clockwise at fast speeds. need event pos
  end
end

function g.draw_menu(meta, menu_items, e2option, e3option) 
  if not meta then
    if g.menu_level == 0 then 
      return 
    else
      g.menu_level = math.max(g.menu_level - 1, 0) 
    end
  elseif meta and g.menu_level < 5 then
    g.menu_level = math.min(g.menu_level + 2, 5) 
  end

  screen.font_face(1)
  screen.font_size(8)

  for i = 1, #menu_items[1] do
    g.shadow_text(4, 8 * (i - 1) + 8, menu_items[1][i], 
      (i == e2option) and 15 or 4 * g.menu_level / 5)
  end

  for i = 1, #menu_items[2] do
    g.shadow_text(124, 8 * (i - 1) + 8, menu_items[2][i], 
      (i == e3option) and 15 or 4 * g.menu_level / 5, 'right')
  end
end

function g.draw_hack(hack)
  --if hack == 0 then return end
  local hack_digit
  if g.hack_counter == 0 then
    g.hack_text = ''
    for i = 1, 11 do
      hack_digit = math.random(0, math.ceil(hack / 0.95 * 15))
      if hack_digit == 1 then
        g.hack_text = g.hack_text .. "I"
      elseif hack_digit > 15 then
        g.hack_text = g.hack_text .. "X"
      else
        g.hack_text = g.hack_text .. string.format('%x', hack_digit)
      end
    end
  end
  screen.font_face(g.hack_font)
  screen.font_size(g.hack_font_size)
  g.shadow_text(63, 61, g.hack_text, 1, 'center')
  g.hack_counter = (g.hack_counter + 1) % 2
end

function g.draw_lag(lag)
  screen.font_face(2)
  screen.font_size(8)

  local max_dots = 43

  local lagged = ((g.lag_pos + max_dots - 1 - math.ceil(lag * 10)) % max_dots) + 1
  g.shadow_text(64, 56, g.dots(lagged), 3, 'center')
  g.shadow_text(64, 58, g.dots(g.lag_pos), 15, 'center')

  g.lag_pos = g.lag_pos % max_dots + 1
end

return g
