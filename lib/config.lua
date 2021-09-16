local c = {
  e2options = {"sharpness","resonance","noise","side","h4ck"},
  e3options = {"seq speed","seq length","leak","lag", "gain"}
}

function c.init()
  params:add_group("SMASH", 11)
  -- TODO: refactor. tooooo much boilerplate
  params:add_control("smash_reso","resonance",
    controlspec.new(0,1,'lin',0.05,0.2,'pewpew',0.05/1))
  params:set_action("smash_reso",
    function(reso)
      engine.resonance(reso)
    end)

  params:add_control("smash_noise","noise",
    controlspec.new(0.0001,1,'exp',0.001,0.001,'kiss',1/20),
    FN.param_value)
  params:set_action("smash_noise",
    function(noise)
      engine.noise(noise)
    end)

  params:add_option("smash_side","ears",{"left","both","right"},2)
  params:set_action("smash_side",
    function(i)
      print ("side "..i)
      engine.side(i - 2)
    end)

  params:add_control("smash_hack","h4ck",
    controlspec.new(0.0,0.95,'lin',0.05,0.0,'',0.05))
  params:set_action("smash_hack",
    function(hack)
      engine.hack(hack)
    end)

  params:add_separator()

  params:add_control("smash_ticks", "ticks",
    controlspec.new(1,96,'lin',1,48,'',1/96))
  params:set_action("smash_ticks", events.speed_set.pub)

  params:add_control("smash_leak","leak",
    controlspec.new(0.0001,1,'exp',0.001,0.001,'drips',1/20),
    FN.param_value)
  params:set_action("smash_leak",
    function(leak)
      engine.leak(leak)
    end)

  params:add_control("smash_lag","lag",
    controlspec.new(0.0,2.00,'lin',0.05,0.1,'s',1/40))
  params:set_action("smash_lag",
    function(lag)
      engine.lag(lag)
    end)

  params:add_control("smash_gain","gain",
    controlspec.new(0.2,20,'exp',0.05,1,'OUCH',1/50))
  params:set_action("smash_gain",
    function(gain)
      engine.gain(gain)
    end)

  params:add_separator()

  params:add_option("smash_hum","hum",{"50Hz","60Hz"},1)
  params:set_action("smash_hum",
    function(i)
      engine.hum(({50,60})[i])
    end)

  params:add_separator() -- encoders

  params:add_option("smash_e2","E2",c.e2options,1)
  params:add_option("smash_e3","E3",c.e3options,1)
end

return c
