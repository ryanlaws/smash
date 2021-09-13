--    * **  S  M  A  S  H  ** * 
--     stereo LPG + sequencer
--  fun for primates of all ages
--
-- K2 = SMASH ..........................................  
-- ................................ K3 = arm/play
-- E2 = sharpness ..............................
-- ....................................... E3 = tempo

lattice = require('lattice')
tabutil = require('tabutil')
-- GFX = require('SMASH/lib/gfx') -- always require() - easy to move later
GFX = include('SMASH/lib/gfx') -- lol but it won't update then :|

engine.name = "StereoLpg"

-- so require() can load stuff from dust
-- i.e. require('SMASH/lib/gfx')
-- I kinda like this, maybe I wanna use this

-- TODO
-- PRIORITY
-- - params
-- - - add sharpness
-- - - fix formatters
-- - - - JUST LOOKIT norns formatter api-docs/code
-- - - fix resonance (liiittle too loud)
-- - - - should baaarely self-osc (0.925) at max
-- - - add tempo (should just be, like, 20-300 BPM or w/e)
-- - synth
-- - - bring min freq down a bit
-- - - bring max decay up a bit
-- - - bring min decay down a bit
-- - etc.
-- - - tweak sharpness
-- - - - vol vs. cutoff decay
-- - - - cutoff amount
-- - - - consider slew
-- - - - consider faster -> more open "screaming" a la 303
-- - - refactor clock to use ACTUAL BPM
-- - - move seq stuff to own module
-- NOT PRIORITY (after UI done maybe
-- - config knob behaviors
-- - - what does this even mean? like assign E2/E3?
-- - do that rhythm trigger thing wm wanted I guess
-- - overdub
-- - crow (env? trig? gate?)

armed = false
recording = false
sharpness = 0.5
events = {}


function noop() end

function identity(x) return x  end

function to_string(x) return '' .. (x ~= nil and x or 'nil')  end

function param_value(x) 
  return x:get()
end

function rerun()
  norns.script.load(norns.state.script)
end

function r()
  rerun()
end

function init_events()
  print('initializing events')
end


function init_gfx()
  clock.run(function()
    while true do
      clock.sleep(1/15)
      redraw()
    end
  end)
  GFX.init()
end

function init()
  -- Just Clock Things
  -- update: LEAVE CLOCK ALONE!!
  --clock.internal.set_tempo(120)
  --clock.set_source("internal")

  lettuce = lattice:new()
  spokes = lettuce:new_pattern{
    action = noop,
    division = 1/48,
    enabled = true
  }
  lettuce:start()

  init_params()
  init_gfx()
  
  -- print(norns.state.script)
end

function init_params()
  params:add_group("SMASH",9)

  params:add_control("smash_reso","resonance",
    controlspec.new(0,1,'lin',0.05,0.2,'pewpew',0.05/1))
  params:set_action("smash_reso",
    function(reso)
      engine.resonance(reso)
    end)

  params:add_control("smash_gain","gain",
    controlspec.new(0.2,20,'exp',0.05,1,'OUCH',1/50))
  params:set_action("smash_gain",
    function(gain)
      engine.gain(gain)
    end)

  params:add_separator()

  params:add_control("smash_noise","noise",
    controlspec.new(0.0001,1,'exp',0.001,0.001,'kiss',1/20),
    param_value)
  params:set_action("smash_noise",
    function(noise)
      engine.noise(noise)
    end)

  params:add_control("smash_leak","leak",
    controlspec.new(0.0001,1,'exp',0.001,0.001,'drips',1/20),
    param_value)
  params:set_action("smash_leak",
    function(leak)
      engine.leak(leak)
    end)

  params:add_option("smash_hum","hum",{"50Hz","60Hz"},1)
  params:set_action("smash_hum",
    function(i)
      engine.hum(({50,60})[i])
    end)

  params:add_separator()

  params:add_option("smash_side","ears",{"left","both","right"},2)
  params:set_action("smash_side",
    function(i)
      print ("side "..i)
      engine.side(i - 2)
    end)

  params:add_control("smash_ticks", "ticks",
    controlspec.new(1,96,'lin',1,48,'',1/96))
  params:set_action("smash_ticks", 
    function (new_speed)
      spokes.division = 1/new_speed
    end)
end

function handle_play_tick()
  if type(tick_pos) ~= "number" then
    print("about to explode because tick_pos is a ".. type(tick_pos))
  end
  -- there's a bug here that happens when the event tick pos > tick length
  -- may need to mitigate elsewhere for simplicity
  if tick_pos == events[next_event_pos][1] then
    -- print(next_event_pos, tick_pos, tick_length)
    strike(events[next_event_pos][2])
    last_event_pos = next_event_pos
    next_event_pos = next_event_pos % #events + 1
  end
  tick_pos = (tick_pos + 1) % tick_length
end

function handle_rec_tick()
  tick_pos = tick_pos + 1
  tick_length = tick_length + 1
end

function arm_recording()
  armed = true
  print('armed')
end

function disarm_recording()
  armed = false
  print('disarmed')
end

function start_recording()
  -- dirty
  GFX.reset_seq()

  -- reset counters
  tick_pos = 0
  tick_length = 0
  last_event_pos = 0
  next_event_pos = 1


  -- clear events
  events = {}

  -- set clock to medium position 
  -- I'm not super set on this
  -- seems reasonable atm tho
  -- SPEED IT UP SLOW IT DOWN

  armed = false
  recording = true
  spokes.action = handle_rec_tick
  print('started recording')
end

function stop_recording()
  print('stopped recording')
  while #events > 0 and tick_length == events[#events][1] do
    print ('deleting event #'..#events)
    table.remove(events, #events)
  end
  recording = false
end

function start_playing()
  spokes.action = handle_play_tick
  tick_pos = 0
  last_event_pos = 0
  next_event_pos = 1
  print("started playing with "..#events.." events and "
    ..(tick_length or "(nil)").." tick length")

  -- totally gross but yikes, event queues or something
  GFX.reset_seq()
end

function stop_playing()
  print('stopped playing')
  spokes.action = noop
end

function detach()
  print('detaching handlers')
  spokes.action = noop
end

function enc(e, d)
  if e == 2 then
    sharpness = math.min(math.max(sharpness + (d / 10), 0.1), 1)
    engine.sharpness(sharpness)
    print (sharpness)
  elseif e == 3 then
    params:delta('smash_ticks', d)
  end
end

function record_event(sharpness_value)
  -- avoid multiple events on a clock tick; they make no sense here
  if #events == 0 or events[#events][1] ~= tick_pos then
    print('recording event @ '..tick_pos..' with value '..sharpness_value);
    events[#events + 1] = { tick_pos, sharpness_value }
  else
    print("ALREADY HAVE AN EVENT HERE, CRANK THE TICKS")
  end
end

function strike(sharpness_value)
  engine.sharpness(sharpness_value)
  engine.strike(1) 
  GFX.create_strike(sharpness_value)
end

function play_it_safe()
  if #events > 0 then
    start_playing()
  else
    detach()
  end
end

function redraw()
  leak = params:get('smash_leak')
  side = params:get("smash_side")
  speed = params:get('smash_ticks')

  GFX.up()
  GFX.draw_noise()
  GFX.draw_gain()
  GFX.draw_leak(leak)
  GFX.draw_sharpness(sharpness, side)
  GFX.draw_strikes(side)
  --if #events > 0 and not recording and not armed then
  if tick_pos then
    GFX.draw_seq(events, last_event_pos, tick_pos, tick_length)
  end
  --end
  GFX.draw_status(recording, armed, #events)
  GFX.draw_speed(speed)
  GFX.down()
end

function key(k, z)
  if z ~= 1 then return end
  if k == 2 then 
    strike(sharpness)
    if armed and not recording then 
      start_recording() 
    end
    if recording then 
      record_event(sharpness) 
    end
  elseif k == 3 then
    if recording then
      stop_recording()
      play_it_safe()
    elseif armed then
      disarm_recording()
      play_it_safe()
    else
      stop_playing()
      arm_recording()
    end
  end
end

function cleanup()
  lettuce:destroy()
end
