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

-- LATER 
-- - implement tick length
-- - do that rhythm trigger thing wm wanted I guess
-- - overdub
-- - crow (env? trig? gate?)

-- | standard lifecycle stuff | --
function init()
  init_events()
  init_gfx()

  cfg.init()
  seq.init()
end

function cleanup()
  seq.clk:destroy()
end

function redraw()
  GFX.redraw(sharpness, seq, meta, 
    { cfg.e2options, cfg.e3options }, 
    params:get("smash_e2"), params:get("smash_e3"))

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

function strike_engine(ctrl, value, from_seq)
  print('striking engine')

  if from_seq then
    set_ctrl(ctrl, value)
  end

  if ctrl == 'sharpness' then
    engine.sharpness(value)
  elseif ctrl == 'resonance' then
    engine.resonance(value)
  elseif ctrl == 'noise' then
    engine.noise(value)
  elseif ctrl == 'side' then
    engine.side(value - 2)
  elseif ctrl == 'h4ck' then
    engine.hack(value)
  end

  engine.strike(1) 
end


-- | specific init(s) | --
function init_events()
  print('initializing events')
  events = {
    strike     = FN.make_pub('strike'),
    play_start = FN.make_pub('play'),
    rec_start  = FN.make_pub('rec'),
    speed_set  = FN.make_pub('set speed'),
    sharpness_set  = FN.make_pub('set sharpness')
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
function change_ctrl(ctrl, d)
  print('ctrl "'..ctrl..'" changed by '..d)

  -- recordable
  -- TODO: set recorded param + value
  if ctrl == 'sharpness' then
    sharpness = math.min(math.max(sharpness + (d / 10), 0.1), 1)
    GFX.sharpness = sharpness
    engine.sharpness(sharpness)
  elseif ctrl == 'resonance' then
    params:delta('smash_reso', d)
  elseif ctrl == 'noise' then
    params:delta('smash_noise', d)
  elseif ctrl == 'side' then
    params:delta('smash_side', d)
  elseif ctrl == 'h4ck' then
    params:delta('smash_hack', d)

  -- non-recordable
  elseif ctrl == 'seq speed' then
    params:delta('smash_ticks', d)
  elseif ctrl == 'seq length' then
    print('seq len not implemented')
  elseif ctrl == 'leak' then
    params:delta('smash_leak', d)
  elseif ctrl == 'lag' then
    params:delta('smash_lag', d)
  elseif ctrl == 'gain' then
    params:delta('smash_gain', d)
  end
end

function set_ctrl(ctrl, value)
  print('ctrl "'..ctrl..'" set to '..value)

  -- recordable
  -- TODO: set recorded param + value
  if ctrl == 'sharpness' then
    sharpness = value
    GFX.sharpness = sharpness
    --engine.sharpness(sharpness)
    -- engine.sharpness(sharpness)
  elseif ctrl == 'resonance' then
    params:set('smash_reso', value)
  elseif ctrl == 'noise' then
    params:set('smash_noise', value)
  elseif ctrl == 'side' then
    params:set('smash_side', value)
  elseif ctrl == 'h4ck' then
    params:set('smash_hack', value)
  end
end

function ctrl_value(ctrl)
  if ctrl == 'sharpness' then
    return sharpness
  elseif ctrl == 'resonance' then
    return params:get('smash_reso')
  elseif ctrl == 'noise' then
    return params:get('smash_noise')
  elseif ctrl == 'side' then
    return params:get('smash_side')
  elseif ctrl == 'h4ck' then
    return params:get('smash_hack')
  end
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
      local ctrl = cfg.e2options[params:get('smash_e2')]
      events.strike.pub(ctrl, ctrl_value(ctrl), from_seq)
      if seq.armed and not seq.recording then 
        seq.start_recording() 
      end
      if seq.recording then 
        seq.record_event(ctrl, ctrl_value(ctrl)) 
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
      params:delta('smash_e2', math.min(math.max(-1, d), 1))
    else
      change_ctrl(cfg.e2options[params:get('smash_e2')], d)
    end
  elseif e == 3 then
    if meta then
      params:delta('smash_e3', math.min(math.max(-1, d), 1))
    else
      change_ctrl(cfg.e3options[params:get('smash_e3')], d)
    end
  end
end
