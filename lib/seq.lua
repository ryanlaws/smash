local seq = {}
seq.armed = false
seq.recording = false
seq.events = {}

function seq.init()
  -- clock
  seq.clk = lattice:new()
  seq.spokes = seq.clk:new_pattern{
    action = FN.noop,
    division = 1/48,
    enabled = true
  }
  seq.clk:start()
end

function seq.force_lattice_restart()
  seq.spokes.phase = seq.spokes.division * seq.clk.ppqn * seq.clk.meter
end

function seq.handle_play_tick()
  if seq.tick_pos == seq.events[seq.next_event_pos][1] then
    -- events is a global :|
    events.strike.pub(seq.events[seq.next_event_pos][2], true)
    seq.last_event_pos = seq.next_event_pos
    seq.next_event_pos = seq.next_event_pos % #seq.events + 1
  end
  seq.tick_pos = (seq.tick_pos + 1) % seq.tick_length
end

function seq.handle_rec_tick()
  seq.tick_pos = seq.tick_pos + 1
  seq.tick_length = seq.tick_length + 1
end

function seq.start_recording()
    -- events is a global :|
  events.rec_start.pub()

  -- reset counters
  seq.tick_pos = 0
  seq.tick_length = 0
  seq.last_event_pos = 0
  seq.next_event_pos = 1

  -- clear seq.events
  seq.events = {}

  seq.armed = false
  seq.recording = true
  seq.spokes.action = seq.handle_rec_tick
  seq.force_lattice_restart()
  print('started recording')
end

function seq.stop_recording()
  print('stopped recording')
  while #seq.events > 0 and seq.tick_length == seq.events[#seq.events][1] do
    print ('deleting event #'..#seq.events)
    table.remove(seq.events, #seq.events)
  end
  seq.recording = false
end

function seq.start_playing()
  seq.tick_pos = 0
  seq.last_event_pos = 0
  seq.next_event_pos = 1
  print("started playing with "..#seq.events.." seq.events and "
    ..(seq.tick_length or "(nil)").." tick length")

    -- events is a global :|
  events.play_start.pub()

  seq.spokes.action = seq.handle_play_tick
  seq.force_lattice_restart()
end

function seq.play_it_safe()
  if #seq.events > 0 then
    seq.start_playing()
  else
    seq.spokes.action = FN.noop
  end
end

-- K3 handler (until K3 has other jobs)
function seq.change_status()
  if seq.recording then
    seq.stop_recording()
    seq.play_it_safe()
  elseif seq.armed then
    seq.armed = false
    seq.play_it_safe()
  else
    seq.spokes.action = FN.noop
    seq.armed = true
  end
end

function seq.record_event(sharpness_value)
  -- avoid multiple seq.events on a clock tick; they make no sense here
  if #seq.events == 0 or seq.events[#seq.events][1] ~= seq.tick_pos then
    print('recording event @ '..seq.tick_pos..' with value '..sharpness_value);
    seq.events[#seq.events + 1] = { seq.tick_pos, sharpness_value }
  else
    print("ALREADY HAVE AN EVENT HERE, CRANK THE TICKS")
  end
end

function seq.set_speed(new_speed)
  seq.spokes.division = 1/new_speed
end

return seq
