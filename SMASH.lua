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
meta = false

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

-- | standard lifecycle stuff | --
function init()
  init_events()
  init_gfx()

  cfg.init()
  seq.init()
  -- print(norns.state.script)
end

function cleanup()
  seq.clk:destroy()
end

function redraw()
  GFX.redraw(sharpness, seq, meta)

  -- infinitedigits capture technique
  -- (use ffmpeg to collate frames into GIF
  if capturing then
    _norns.screen_export_png(string.format("/dev/shm/image%04d.png",img_idx)) 
    img_idx=img_idx+1
  end
end


-- | helpers | --
function rerun()
  norns.script.load(norns.state.script)
end

function strike_engine(sharpness_value, from_seq)
  print('striking engine')
  engine.sharpness(sharpness_value)
  engine.strike(1) 
end


-- | specific init(s) | --
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


-- | controls | --
function key(k, z)
  if k == 1 then
    meta = z == 1 and true or false
    print('meta '..(meta and 'true' or 'false')) -- lol this feels wrong
  elseif z ~= 1 then 
    return 
  end

  if k == 2 then 
    if meta then
    else
      events.strike.pub(sharpness, from_seq)
      if seq.armed and not seq.recording then 
        seq.start_recording() 
      end
      if seq.recording then 
        seq.record_event(sharpness) 
      end
    end
  elseif k == 3 then
    if meta then
    else
      seq.change_status()
    end
  end
end

function enc(e, d)
  if e == 2 then
    if meta then
    else
      sharpness = math.min(math.max(sharpness + (d / 10), 0.1), 1)
      engine.sharpness(sharpness)
      print (sharpness)
    end
  elseif e == 3 then
    if meta then
    else
      params:delta('smash_ticks', d)
    end
  end
end
