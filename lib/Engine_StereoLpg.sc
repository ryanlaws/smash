Engine_StereoLpg : CroneEngine {
  var <synth;
  var <buff;

  *new { arg context, doneCallback;
    ^super.new(context, doneCallback);
  }

  alloc {
    buff = Buffer.alloc(context.server, 480, 2);

    context.server.sync;

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
      var phasor, hacksig, lo, hi;

      // LAG
      noise = noise.lag(lag);
      gain = gain.lag(lag);
      resonance = resonance.lag(lag);
      leak = leak.lag(lag.max(0.1));
      hack = hack.lag(lag);

      hi = 87 * (1 - (resonance * 0.4));
      lo = 120 * (1.2 - ((1.1 - sharpness) ** 0.03));
      decay = (1 - sharpness) * 0.8 + 0.2 ** 1.7 * 2;
      volume = sharpness / 2 + 0.5;
      env = Env.perc(0.01, decay, volume, -6);
      env = EnvGen.kr(env, t_strike);

      freq = (env * hi + lo).midicps;

      side = side.max(-1).min(1).round + 1;
      side = Select.ar(side, sides);

      noise = Mix.ar(LFSaw.ar([hum, hum + 0.05], 0, noise/12))!2 +
        WhiteNoise.ar(noise/3*2!2);

      phasor = Phasor.ar(0, 0.1 / hack.max(0.00001), 0, 480);
      hacksig = BufRd.ar(2, buff, phasor, 0, 1) * hack;

      gated = DFM1.ar(hacksig + side + noise, freq, resonance, env ** 0.5 * gain).tanh;
      gated = gated * (env ** 0.5);
      leaked = (side / 2 + noise + hacksig) * leak;

      out = (hacksig * 0.7 + gated + leaked).tanh;
      LocalOut.ar(out);
      BufWr.ar(LocalIn.ar(2) * (1.0 - (1.0 - hack ** 2)), buff, phasor);
      out;

    }.play;

    this.addCommand("strike","f",{synth.set(\t_strike,1)});
    this.addCommand("sharpness","f",{|msg|synth.set(\sharpness,msg[1])});
    this.addCommand("side","f",{|msg|synth.set(\side,msg[1])});
    this.addCommand("leak","f",{|msg|synth.set(\leak,msg[1])});
    this.addCommand("noise","f",{|msg|synth.set(\noise,msg[1])});
    this.addCommand("hum","f",{|msg| synth.set(\hum,msg[1]) });
    this.addCommand("gain","f",{|msg|synth.set(\gain,msg[1])});
    this.addCommand("resonance","f",{|msg|synth.set(\resonance,msg[1])});
    this.addCommand("hack","f",{|msg|synth.set(\hack,msg[1])});
    this.addCommand("lag","f",{|msg|synth.set(\lag,msg[1])});
  }

  free {
    synth.free;
  }
}
