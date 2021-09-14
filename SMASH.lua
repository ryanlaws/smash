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
FN = include('SMASH/lib/function') 

engine.name = "StereoLpg"

capturing = false
img_idx = 0

--[[
SCREEN CAPTURE
infinitedigits — 09/09/2021
i edited the script with this:
[8:33 AM]
-- define somewhere
imagei=0

-- inside redraw routine
_norns.screen_export_png(string.format("/dev/shm/image%04d.png",imagei)) imagei=imagei+1

-- then ffmpeged into a video:
ffmpeg -y -framerate 15 -pattern_type glob -i '*.png' -c:v libx264 -r 30 -pix_fmt yuv420p 1.mp4

-- then ffmpeged into a gif:
ffmpeg -i 1.mp4 out.gif

--]]

-- so require() can load stuff from dust
-- i.e. require('SMASH/lib/gfx')
-- I kinda like this, maybe I wanna use this

-- TODO
-- PRIORITY
-- - params
-- - - fix resonance (liiittle too loud)
-- - - - should baaarely self-osc (0.925) at max
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
seq_events = {}

function rerun()
  norns.script.load(norns.state.script)
end

function force_lattice_restart()
  spokes.phase = spokes.division * clk.ppqn * clk.meter
  --if spokes.phase > (spokes.division * ppm) then
  -- busted lattice code:
  --local ppm = clk.ppqn * clk.meter
  --spokes.phase = spokes.phase + 1
  --if spokes.phase > (spokes.division * ppm) then
  --  spokes.phase = spokes.phase - (spokes.division * ppm)
  --  spokes.action(clk.transport)
  --end
end

function init_events()
  print('initializing events')
  events = {
    strike     = FN.make_pub('strike'),
    play_start = FN.make_pub('play'),
    rec_start  = FN.make_pub('rec')
  }

  events.strike.sub(strike_engine)
end

function init_gfx()
  clock.run(function()
    while true do
      clock.sleep(1/15)
      redraw()
    end
  end)

  GFX.init()

  events.strike.sub(GFX.strike)
  events.play_start.sub(GFX.reset_seq)
  events.rec_start.sub(GFX.reset_seq)
end

function init()
  -- clock
  clk = lattice:new()
  spokes = clk:new_pattern{
    action = FN.noop,
    division = 1/48,
    enabled = true
  }
  clk:start()

  init_params()
  init_events()
  init_gfx()
  
  -- print(norns.state.script)
end

function init_params()
  params:add_group("SMASH",9)

  -- TODO: refactor. tooooo much boilerplate
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
    FN.param_value)
  params:set_action("smash_noise",
    function(noise)
      engine.noise(noise)
    end)

  params:add_control("smash_leak","leak",
    controlspec.new(0.0001,1,'exp',0.001,0.001,'drips',1/20),
    FN.param_value)
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
  if tick_pos == seq_events[next_event_pos][1] then
    events.strike.pub(seq_events[next_event_pos][2], true)
    last_event_pos = next_event_pos
    next_event_pos = next_event_pos % #seq_events + 1
  end
  tick_pos = (tick_pos + 1) % tick_length
end

function handle_rec_tick()
  tick_pos = tick_pos + 1
  tick_length = tick_length + 1
end


function disarm_recording()
  armed = false
  print('disarmed')
end

function start_recording()
  events.rec_start.pub()

  -- reset counters
  tick_pos = 0
  tick_length = 0
  last_event_pos = 0
  next_event_pos = 1

  -- clear seq_events
  seq_events = {}

  armed = false
  recording = true
  spokes.action = handle_rec_tick
  force_lattice_restart()
  print('started recording')
end

function stop_recording()
  print('stopped recording')
  while #seq_events > 0 and tick_length == seq_events[#seq_events][1] do
    print ('deleting event #'..#seq_events)
    table.remove(seq_events, #seq_events)
  end
  recording = false
end

function start_playing()
  tick_pos = 0
  last_event_pos = 0
  next_event_pos = 1
  print("started playing with "..#seq_events.." seq_events and "
    ..(tick_length or "(nil)").." tick length")

  -- totally gross but yikes, event queues or something
  events.play_start.pub()

  spokes.action = handle_play_tick
  force_lattice_restart()
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
  -- avoid multiple seq_events on a clock tick; they make no sense here
  if #seq_events == 0 or seq_events[#seq_events][1] ~= tick_pos then
    print('recording event @ '..tick_pos..' with value '..sharpness_value);
    seq_events[#seq_events + 1] = { tick_pos, sharpness_value }
  else
    print("ALREADY HAVE AN EVENT HERE, CRANK THE TICKS")
  end
end

function strike_engine(sharpness_value, from_seq)
  print('striking engine')
  engine.sharpness(sharpness_value)
  engine.strike(1) 
end

function play_it_safe()
  if #seq_events > 0 then
    start_playing()
  else
    spokes.action = FN.noop
  end
end

function redraw()
  leak = params:get('smash_leak')
  side = params:get("smash_side")
  speed = params:get('smash_ticks')

  GFX.up()
  GFX.draw_pos('l', last_event_pos, tick_pos)
  GFX.draw_noise()
  GFX.draw_gain()
  GFX.draw_leak(leak)
  GFX.draw_sharpness(sharpness, side)
  GFX.draw_strikes(side)
  --if #seq_events > 0 and not recording and not armed then
  if tick_pos then
    GFX.draw_seq(seq_events, last_event_pos, tick_pos, tick_length)
  end
  --end
  GFX.draw_status(recording, armed, #seq_events)
  GFX.draw_speed(speed)
  GFX.draw_pos('r', last_event_pos, tick_pos)
  GFX.down()

  -- infinitedigits capture technique
  -- (use ffmpeg to collate frames into GIF
  if capturing then
    _norns.screen_export_png(string.format("/dev/shm/image%04d.png",img_idx)) 
    img_idx=img_idx+1
  end
end

function key(k, z)
  if z ~= 1 then return end
  if k == 2 then 
    events.strike.pub(sharpness, from_seq)
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
      armed = false
      play_it_safe()
    else
      spokes.action = FN.noop
      armed = true
    end
  end
end

function cleanup()
  clk:destroy()
end
