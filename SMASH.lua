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
seq = include('SMASH/lib/seq') 

engine.name = "StereoLpg"

capturing = false
img_idx = 0

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

sharpness = 0.5

function rerun()
  norns.script.load(norns.state.script)
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
  init_params()
  init_events()
  init_gfx()

  seq.init()
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
      seq.spokes.division = 1/new_speed
    end)
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

function strike_engine(sharpness_value, from_seq)
  print('striking engine')
  engine.sharpness(sharpness_value)
  engine.strike(1) 
end


function redraw()
  local leak = params:get('smash_leak')
  local side = params:get("smash_side")
  local speed = params:get('smash_ticks')

  GFX.up()
  GFX.draw_noise()
  GFX.draw_gain()
  GFX.draw_leak(leak)
  GFX.draw_sharpness(sharpness, side)
  GFX.draw_strikes(side)
  --if #seq.events > 0 and not recording and not armed then
  if seq.tick_pos then
    GFX.draw_seq(seq.events, seq.last_event_pos, seq.tick_pos, seq.tick_length)
  end
  --end
  GFX.draw_status(seq.recording, seq.armed, #seq.events)
  GFX.draw_speed(speed)
  GFX.draw_pos(seq.last_event_pos, seq.tick_pos)
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
    if seq.armed and not seq.recording then 
      seq.start_recording() 
    end
    if seq.recording then 
      seq.record_event(sharpness) 
    end
  elseif k == 3 then
    seq.change_status()
  end
end

function cleanup()
  seq.clk:destroy()
end
