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
engine.name = "StereoLpg"

-- TODO
-- - config knob behaviors
-- - graphix... 
-- - - on strike... something indicating sharpness
-- - - on strike... something indicating sharpness
-- - - 

armed = false
recording = false
sharpness = 0.5
seq_speed = 48
events = {}

function noop() end

function rerun()
  norns.script.load(norns.state.script)
end

function r()
  rerun()
end

function init_events()
  print('initializing events')
end

function set_seq_speed(new_speed)
  spokes.division = 1/new_speed
end

function init()
  -- Just Clock Things
  clock.internal.set_tempo(120)
  clock.set_source("internal")

  lettuce = lattice:new()
  spokes = lettuce:new_pattern{
    action = play_next_event,
    division = 1/seq_speed,
    enabled = true
  }
  lettuce:start()

  set_seq_speed(seq_speed)

  init_params()
  
  -- print(norns.state.script)
end

function init_params()
  params:add_group("SMASH",6)

  -- (id, name, controlspec, formatter)
  params:add_control("smash_reso","resonance",
  -- (minval, maxval, warp, step, default, units, quantum, wrap)
    controlspec.new(0,1,'lin',0.05,0.2,'pewpew',0.05/1))
  params:set_action("smash_reso",function(ouchie_wawa)
    engine.resonance(ouchie_wawa)
  end)

  params:add_control("smash_gain","gain",
    controlspec.new(0.2,20,'exp',0.05,1,'OUCH',1/50))
  params:set_action("smash_gain",function(huge_gains_bro)
    engine.gain(huge_gains_bro)
  end)

  params:add_control("smash_noise","noise",
    controlspec.new(0,1,'exp',0.001,0.001,'kiss',1/100))
  params:set_action("smash_noise",function(hz)
    engine.noise(hz)
  end)

  params:add_control("smash_leak","leak",
    controlspec.new(0,1,'exp',0.001,0.001,'drips',1/100))
  params:set_action("smash_leak",function(hz)
    engine.leak(hz)
  end)

  params:add_option("smash_hum","hum",{"50Hz","60Hz"},1)
  params:set_action("smash_hum",function(i)
    engine.hum(({50,60})[i])
  end)

  params:add_option("smash_side","ears",{"left","both","right"},2)
  params:set_action("smash_side",function(i)
    print ("side "..i)
    engine.side(i - 2)
  end)
end

function handle_play_tick()
  if tick_pos == events[event_pos][1] then
    -- print(event_pos, tick_pos, tick_length)
    strike(events[event_pos][2])
    event_pos = event_pos % #events + 1
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
  -- reset counters
  tick_pos = 0
  tick_length = 0
  event_pos = 1

  -- clear events
  events = {}

  -- set clock to medium position 
  -- I'm not super set on this
  -- seems reasonable atm tho
  -- SPEED IT UP SLOW IT DOWN
  seq_speed = 48

  armed = false
  recording = true
  spokes.action = handle_rec_tick
  print('started recording')
end

function stop_recording()
  print('stopped recording')
  recording = false
end

function start_playing()
  spokes.action = handle_play_tick
  tick_pos = 0
  event_pos = 1
  print("started playing with "..#events.." events and "
    ..(tick_length or "(nil)").." tick length")
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
    sharpness = math.min(math.max(sharpness + (d / 10), 0), 1)
    engine.sharpness(sharpness)
    print (sharpness)
  elseif e == 3 then
    seq_speed = math.min(math.max(seq_speed + d, 12), 96)
    set_seq_speed(seq_speed)
  end
end

function record_event(sharpness_value)
  print('recording event @ '..tick_pos..' with value '..sharpness_value);
  events[#events + 1] = { tick_pos, sharpness_value }
end

function strike(sharpness_value)
  engine.sharpness(sharpness_value)
  engine.strike(1) 
end

function play_it_safe()
  if #events > 0 then
    start_playing()
  else
    detach()
  end
end

function key(k, z)
  if z ~= 1 then return end
  if k == 2 then 
    strike(sharpness)
    if armed and not recording then start_recording() end
    if recording then record_event(sharpness) end
  elseif k == 3 then
    if recording then
      stop_recording()
      play_it_safe()
    else
      if armed then
        disarm_recording()
        play_it_safe()
      else
        stop_playing()
        arm_recording()
      end
    end
  end
end

function cleanup()
  lettuce:destroy()
end
