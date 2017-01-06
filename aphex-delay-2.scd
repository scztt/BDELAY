~buf1 = Buffer.read(s, "/Users/fsc/Documents/_sounds/zoom recordings/seth-hike-1/rock-throwing.WAV");
~buf2 = Buffer.read(s, "/Users/fsc/Documents/_sounds/zoom recordings/seth-hike-1/tree-rock-throw-surround.wav");
~buf3 = Buffer.read(s, "/Users/fsc/Documents/Untergang1.wav"); // 1.775
~buf4 = Buffer.read(s, "/Users/fsc/Documents/Untergang2.wav"); // 1.775
~buf5 = Buffer.read(s, "/Users/fsc/Documents/06-Falling the Same Way.aif"); // 1.916
~buf6 = Buffer.read(s, "/Users/fsc/Documents/04-Grey Cut Out.aif"); // 1.947
~buf7 = Buffer.read(s, "/Users/fsc/Documents/01-Confine.aif"); // 1.889
~buf8 = Buffer.read(s, "/Users/fsc/Documents/02-Remainder.aif"); // 1.905
~buf9 = Buffer.read(s, "/Users/fsc/Documents/03-Portal.aif"); // 1.880


(
Ndef(\test, {
	var input;
	var resons, tuning;
	var freqs, bws, amps, delays, feeds, feedsAmp;
	var sig, eqSigs, pitchTrig, beatTrig;
	var bpm = 1.905;

	// input = PlayBuf.ar(4, ~buf0.bufnum, rate:1, loop:1);
	// input = input[0..1] + input[2..3];
	// input = PlayBuf.ar(2, ~buf1.bufnum, rate:1, loop:1);
	input = PlayBuf.ar(2, ~buf1.bufnum, rate:0.5, trigger:1, startPos:130 * 44100, loop:1)
	+ PlayBuf.ar(2, ~buf1.bufnum, rate:1, trigger:1, startPos:20 * 44100, loop:1)
	+ PlayBuf.ar(2, ~buf1.bufnum, rate:1, trigger:1, startPos:45 * 44100, loop:1);

	input = input + SinOsc.ar(Decay2.ar(Impulse.ar(1/4), 0.01, 6).lincurve(0, 1, 10, 60, 1), 0, 0.1);
	input = input * 4.dbamp;

	pitchTrig = Coyote.kr(input.sum);

	beatTrig = Decay2.ar(Impulse.ar(1 / 8), 0.005, 4);
	// input = input + SinOsc.ar(beatTrig.linlin(0, 1, 2, 65), 0, beatTrig * 0.5);

	tuning = 64.collect {
		|i|
		Scale.minorPentatonic.degreeToFreq(i, \root.kr(20), 0);
		// Scale.partch_o3.degreeToFreq(i, \root.kr(10), 0);
	};
	tuning = 16.collect {
		|i|
		var start, jump, trig;
		trig = PulseDivider.kr(pitchTrig, 10 + 15.rand);
		start = TRand.kr(0, 2, trig) * 2;
		jump = Select.kr(TRand.kr(0, 2, trig), [1, 1, 1, 3, 5]);
		Select.kr((start + (jump * i)) % tuning.size, tuning);
		//Select.kr(TRand.kr(0, 16, PulseDivider.kr(pitchTrig, 12)), tuning)
	};

	freqs = tuning.collect { |f| f * SinOsc.ar(Rand(1, 0.5), 1.0.rand, 0.01, 1) };
	//bws = (\bandwidth.kr(0.01) * Decay.kr(pitchTrig, 2).linexp(0, 1, 1, 30)) ! freqs.size;
	//bws = (\bandwidth.kr(1 / 2000) * Amplitude.kr(input).lagud(0.001, 1).lincurve(0, 1, 1, 600, 4)) ! freqs.size;
	bws = Amplitude.kr(input.sum).lagud(0.01, 12).lincurve(0.1, 1.0, 1 / 300, 1 / 40, 3) ! freqs.size;
	bws[0].reciprocal.poll;

	amps = freqs.size.collect { TRand.kr(0.0, 1.0, pitchTrig).pow(2).lag(0.3) };
	delays = freqs.size.collect {
		[
			6.0.rand.round(1/2) + (1/2),
			TRand.kr(0, 1.0, pitchTrig).round(1/8) + (1/8)
		]
	};
	delays = delays * bpm;

	feeds = \feed.kr(2) * LocalIn.ar(freqs.size * 2).clump(2);
	feeds = feeds + (feeds.sum * 0.02);
	feedsAmp = Amplitude.kr(input.flatten.sum + feeds.flatten.sum, 0.2, 6);
	feedsAmp = feedsAmp.linlin(0, 0.5, 0, 0.5) + feedsAmp.lincurve(0.5, 1.0, 0, 0.2, -4)
	+ feedsAmp.lincurve(1.0, 1.2, 0, -0.8, -4);
	//feeds = Compander.ar(feeds, input.sum + feeds.sum, 0.2, 1, 1/10, 0.1, 12);
	feeds = feeds * feedsAmp;

	eqSigs = List();

	eqSigs = [freqs, bws, amps, delays, feeds].flop.collect {
		|eq|
		var freq, bw, amp, delay, feed, feedSig, eqSig;
		#freq, bw, amp, delay, feed = eq;

		feed = Rotate2.ar(feed[0], feed[1], Rand(-0.1, 0.1));
		feed = XFade2.ar(
			DelayC.ar(feed, 4.0, delay[0], 1),
			DelayC.ar(feed, 4.0, delay[1]
				// * Decay.kr(pitchTrig > 0, 4).linexp(0, 1, 1, 2)
				,
				0.5
			),
			SinOsc.ar(1/12, 1.0.rand, 0.6)
		);
		feed = BLowPass4.ar(feed, min(20000, freq * 6), freq/10);
		// feed = BLowPass4.ar(feed, 18000);

		eqSig = [1, 2, 3, 4, 5, 6].sum {
			|mult, i|
			mult = mult + Rand(-0.05, 0.05);
			BBandPass.ar(input, freq * mult, bw, amp * 2 * i.linexp(0, 6, 1, 0.6));
		};
		eqSig = LeakDC.ar(eqSig + feed);
		eqSig = (eqSig + (eqSig * LPF.ar(LFSaw.ar(freq), Decay2.kr(pitchTrig, 0.1, 12).linlin(0, 1, 1000, 4000))));

		eqSig.assertChannels(2);
	};

	eqSigs.assertChannels(16, 2);
	sig = eqSigs.sum;

	LocalOut.ar(eqSigs.flatten);
	sig * 16.dbamp;

}).play;
)

Ndef(\test).fadeTime = 20;
Ndef(\test).set(\root, 45);
