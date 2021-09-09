-- TODO
-- - sequencer w/ tempo adj
-- - params
-- - config knob behaviors
engine.name = "StereoLpg"

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

function enc(e, d)
  if e == 2 then
    sharpness = math.min(math.max(sharpness + (d / 10), 0), 1)
    engine.sharpness(sharpness)
    print (sharpness)
  end
  -- print("enc", e, d)
end

function strike ()
  engine.sharpness(sharpness)
  engine.strike(1) 
end

function key(k, z)
  if k == 2 and z == 1 then 
    strike()
  end
end
