-- TODO
-- - - 
-- - sequencer w/ tempo adj
-- - - k3 = toggle play/rec
-- - - switch to rec, wait for first tap
-- - - (if nothing rec, leave seq alone = doubles as stop btn)
-- - - switch to play, immediately start playback
-- - params
-- - config knob behaviors
-- - graphix... 
-- - - on strike... something indicating sharpness
-- - - on strike... something indicating sharpness
-- - - 
engine.name = "StereoLpg"

armed = false
recording = false
sharpness = 0.5

function rerun()
  norns.script.load(norns.state.script)
end

function r()
  rerun()
end

function init()
  print(norns.state.script)
end

function start_recording()
  print('started recording')
  -- clear events
  -- reset counters
  recording = true
end


function enc(e, d)
  if e == 2 then
    sharpness = math.min(math.max(sharpness + (d / 10), 0), 1)
    engine.sharpness(sharpness)
    print (sharpness)
  end
  -- print("enc", e, d)
end

function record_event()
  -- get time
  -- get params
  -- add to table
end

function strike()
  engine.sharpness(sharpness)
  engine.strike(1) 
end

function start_playback()
  print('started playback')
  -- hook timer to event playback callback
  -- start clock
end

function key(k, z)
  if z ~= 1 then return end
  if k == 2 then 
    strike()
    if armed and not recording then start_recording() end
    if recording then record_event() end
  elseif k == 3 then
    if not armed and not recording then 
      print('armed')
      armed = true
    elseif recording then
      print('stopped recording')
      recording = false
      armed = false
    end
  end
end

function cleanup()
  -- engine.free()
end
