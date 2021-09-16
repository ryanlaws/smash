Engine_StereoLpg : CroneEngine {
  var <synth;

  *new { arg context, doneCallback;
    ^super.new(context, doneCallback);
  }

  alloc {
    /* TODO
      * [ ] delay (influenced by strike times) - tiny buffer like a BBD
      * [ ] configurable min/max cutoff
      * [ ] configurable min/max decay
    */
    synth = { | t_strike=0, sharpness=1, side=0,
      leak=0.001, noise=0.001, hum=50, gain=1.05, 
      resonance=0.1, lag=0.1, hack=0|
      var ears = SoundIn.ar([0, 1]);
      var sides = [
        ears[[0,0]],
        ears[[0,1]],
        ears[[1,1]]
      ];

      var decay, volume, env, freq, gated, leaked, out;
      // LAG
      noise = noise.lag(lag);
      gain = gain.lag(lag);
      resonance = resonance.lag(lag);
      leak = leak.lag(lag.max(0.1));
      hack = hack.lag(lag);

      decay = (1 - sharpness) * 0.8 + 0.2 ** 2 * 1.5;
      volume = sharpness / 2 + 0.5;
      env = Env.perc(0.01, decay, volume, -6);
      env = EnvGen.kr(env, t_strike);

      freq = (env * 100 + 28).midicps;

      side = side.max(-1).min(1).round + 1;
      side = Select.ar(side, sides);

      noise = Mix.ar(LFSaw.ar([hum, hum + 0.05], 0, noise/12))!2 + 
        WhiteNoise.ar(noise/3*2!2);

      gated = DFM1.ar(side + noise, freq, resonance, env ** 0.5 * gain);
      gated = gated * (env ** 0.5);
      leaked = (side / 2 + noise) * leak;

      hack = DelayN.ar(LocalIn.ar(2), 1, hack * 0.2, hack.max(-0.99).min(0.99));

      out = (hack + gated + leaked).tanh;
      LocalOut.ar(out);
      out;
    }.play;

    this.addCommand("strike","f",{synth.set(\t_strike,1)});
    this.addCommand("sharpness","f",{|msg|synth.set(\sharpness,msg[1])});
    this.addCommand("side","f",{|msg|synth.set(\side,msg[1])});
    this.addCommand("leak","f",{|msg|synth.set(\leak,msg[1])});
    this.addCommand("noise","f",{|msg|synth.set(\noise,msg[1])});
    this.addCommand("hum","f",{|msg|
      msg.postln;
      synth.set(\hum,msg[1])
    });
    this.addCommand("gain","f",{|msg|synth.set(\gain,msg[1])});
    this.addCommand("resonance","f",{|msg|synth.set(\resonance,msg[1])});
    this.addCommand("hack","f",{|msg|synth.set(\hack,msg[1])});
    this.addCommand("lag","f",{|msg|synth.set(\lag,msg[1])});
  }

  free {
    synth.free;
  }
}
