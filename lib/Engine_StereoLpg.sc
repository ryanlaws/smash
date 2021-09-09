Engine_StereoLpg : CroneEngine {
  var sound;

  *new { arg context, doneCallback;
    ^super.new(context, doneCallback);
  }

  alloc {
    /* TODO
      gain + tanh
      line noise + volume
      hum : 50Hz/60Hz, volume, detune (level + det)
      delay (influenced by strike times) - tiny buffer like a BBD
      configurable min/max cutoff
      configurable min/max decay
      slews
    */
    var sound = { | t_strike=0, sharpness=1, side=0 |
      var ears = SoundIn.ar([0, 1]);
      var sides = [
        ears[[0,0]],
        ears[[0,1]],
        ears[[1,1]]
      ];

      var decay = (1 - sharpness) ** 3 + 0.01;
      var volume = sharpness / 2 + 0.5;
      var env = EnvGen.kr(Env.perc(0.01, decay), t_strike, volume);
      var freq;

      side = side.max(-1).min(1).round + 1;
      side = Select.ar(side, sides);

      // this might break it if DFM doesn't exist
      freq = (env * 120 + 15).midicps;
      side = DFM1.ar(side, freq, 0.1);

      side * volume * env;
    }.play;

    this.addCommand("strike",    "f", {      sound.set(\t_strike,      1 ) });
    this.addCommand("sharpness", "f", {|msg| sound.set(\sharpness, msg[1]) });
    this.addCommand("side",      "f", {|msg| sound.set(\side,      msg[1]) });
  }

  free {
    sound.free;
  }
}
