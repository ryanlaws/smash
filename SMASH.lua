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

-- might be cool to require() these but that caches until restart :|
FN = include('SMASH/lib/function') 
GFX = include('SMASH/lib/gfx')
seq = include('SMASH/lib/seq') 
cfg = include('SMASH/lib/config') 

engine.name = "StereoLpg"

-- PNG stuff
capturing = false
img_idx = 0
-- end PNG stuff

sharpness = 0.5 -- should maybe be a param


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
-- NOT PRIORITY (after UI done maybe
-- - centralize globals (params, clock, etc.)
-- - config knob behaviors
-- - - what does this even mean? like assign E2/E3?
-- - do that rhythm trigger thing wm wanted I guess
-- - overdub
-- - crow (env? trig? gate?)

function rerun()
  norns.script.load(norns.state.script)
end

function init_events()
  print('initializing events')
  events = {
    strike     = FN.make_pub('strike'),
    play_start = FN.make_pub('play'),
    rec_start  = FN.make_pub('rec'),
    speed_set  = FN.make_pub('set speed')
  }

  events.strike.sub(strike_engine)
  events.speed_set.sub(seq.set_speed)
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
  init_events()
  init_gfx()

  cfg.init()
  seq.init()
  -- print(norns.state.script)
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
  GFX.redraw(sharpness, seq)

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
