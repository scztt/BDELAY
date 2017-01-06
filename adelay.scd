(
// Buffers - should be percussive
~buf1 = Buffer.read(s, "/Users/fsc/Documents/_sounds/zoom recordings/seth-hike-1/rock-throwing.WAV");
~buf2 = Buffer.read(s, "/Users/fsc/Documents/_sounds/zoom recordings/seth-hike-1/tree-rock-throw-surround.wav");
~buf3 = Buffer.read(s, "/Users/fsc/Documents/Untergang1.wav"); // 1.775
~buf4 = Buffer.read(s, "/Users/fsc/Documents/Untergang2.wav"); // 1.775
~buf5 = Buffer.read(s, "/Users/fsc/Documents/06-Falling the Same Way.aif"); // 1.916
~buf6 = Buffer.read(s, "/Users/fsc/Documents/04-Grey Cut Out.aif"); // 1.947
~buf7 = Buffer.read(s, "/Users/fsc/Documents/01-Confine.aif"); // 1.889
~buf8 = Buffer.read(s, "/Users/fsc/Documents/02-Remainder.aif"); // 1.905
~buf9 = Buffer.read(s, "/Users/fsc/Documents/03-Portal.aif"); // 1.880
)

(
Ndef(\source, {
	var sig, beatTrig, bass;
	var speed = \speed.kr(1, 10);


	// Input Buffer
	sig = (
		~buf2.ar(rate:2, trigger:1, startPos:40 * 44100, loop:1).clump(2).sum
		+ ~buf2.ar(rate:2, trigger:1, startPos:45 * 44100, loop:1).clump(2).sum
	);


	// Mic Input
	// sig = SoundIn.ar([0, 1]);


	// Krautrock delays on the input
	sig = Compander.ar(sig, sig, 0.5, 1, 1/10);
	sig = CombC.ar(sig, 1, speed * 1/8, 4, -6.dbamp) + CombC.ar(sig, 1, speed * 1/2, 4, mul: -2.dbamp);
	sig = (
		CombC.ar(sig * Decay.kr(Impulse.kr(speed.reciprocal * 4), 0.3, 0.2), 1, speed * 1/4, 4)
		+ CombC.ar(sig * Decay.kr(Impulse.kr(speed.reciprocal * 1), 0.6, 1), 1, speed * 1/1, 4)
	);
	sig = (sig * 0.1) + DelayC.ar(
		CombC.ar(sig * Decay.kr(Impulse.kr(speed.reciprocal * 2), 0.2), 1, speed * 1/2, 12),
		1, (1/4) + (1/64)
	);



	// HPF
	sig = HPF.ar(sig, 7000, 1.5);



	// Bass
	beatTrig = Env.perc(releaseTime:3).kr(gate:Impulse.kr(speed.reciprocal * 2));
	sig = sig + SinOsc.ar(beatTrig.linlin(0.01, 1, 1, 45), 0, 0.5 * beatTrig.linexp(0.1, 1, 0.001, 1)) * [1, 1];



	// Click pattern
	(
		sig
		+ Impulse.ar(speed * 8, 0, 0.4)
		+ Impulse.ar(speed * 4, 0, 0.5)
		+ Impulse.ar(speed * 0.25, 0, 1)
	)
});
)

Ndef(\source).clear;
Ndef(\source).play;
Ndef(\source).stop;


(
Ndef(\adelay, {
	var input;
	var resons, tuning;
	var freqs, bws, amps, delays, feeds, feedsAmp;
	var pitchTrig;
	var bpm = 1, buf, bufRate;
	var beatTrig;
	var patternSize, bigDelay, smallDelay;
	var sig, eqSigs, bass, beat, noise, blip, chord;

	input = InFeedback.ar(Ndef(\source).bus, 2);
	pitchTrig = Coyote.kr(input.sum);
	// pitchTrig.poll(pitchTrig);

	tuning = 40.collect {
		|i|
		var root = \root.kr(40);
		// root = Latch.kr(root, pitchTrig + Impulse.kr(0));
		// root = root + ((root < 1) * 400);
		//
		// Scale.majorPentatonic.degreeToFreq(i, root, 0);
		Scale.minorPentatonic.degreeToFreq(i, root, 0);
		// Scale.indian.degreeToFreq(i, root, 0);
	};
	tuning = 16.collect {
		|i|
		var start, jump, trig, index, starts, jumps;
		var retrig = \t_notes.kr(0);

		starts = \noteStarts.kr([0, 3, 7, 0, 3, 7]);
		jumps = \noteJumps.kr([0, 2, 5, 8, 12, 16]);

		trig = PulseDivider.kr(pitchTrig, 5 + 5.rand, 16.rand) + retrig;

		//start = Select.kr(TRand.kr(0, starts.size - 1, trig), starts);
		start = Select.kr(Stepper.kr(trig, 1, 0, starts.size - 1, 1, starts.size.rand), starts);
		jump = Select.kr(TRand.kr(0, jumps.size - 1, trig), jumps);

		index = Latch.kr((start + jump) % tuning.size(), trig);
		Select.kr(index, tuning);

		// Select.kr(TRand.kr(0, 16, PulseDivider.kr(pitchTrig, 12)), tuning)
	};
	tuning.poll(1/10);

	freqs = tuning;
	freqs = freqs.collect { |f| f * SinOsc.ar(Rand(6, 12), 1.0.rand, \detune.kr(0.005), 1) };
	freqs = freqs.lag(\freqLag.kr(0.01));

	input = input * \inputAmpDB.kr(6).dbamp;
	// input = input + LPF.ar(GrayNoise.ar(1), 60, 0.2 * SinOsc.ar(1 / 60));

	patternSize = \patternSize.kr(32);

	beatTrig = Decay2.kr(PulseDivider.kr(pitchTrig, patternSize, 0), 0.005, 14);
	bass = SinOsc.ar(beatTrig.linlin(0, 1, 2, 40), 0, beatTrig);

	beatTrig = Env.perc(0.01, 8, curve:-16).kr(gate:PulseDivider.kr(pitchTrig > 0, patternSize, patternSize / 2));
	// beatTrig = Env.perc(3, 0.01, curve:-`16).kr(gate:PulseDivider.kr(pitchTrig > 0, patternSize, patternSize / 2));
	noise = HPF.ar(WhiteNoise.ar() * beatTrig.linexp(0.01, 1, 0.0001, 1), beatTrig.linexp(0.00001, 1, 7000, 1000));

	beatTrig = Decay2.kr(PulseDivider.kr(pitchTrig, patternSize / 2, patternSize / 4), 0.001, 12);
	blip = LPF.ar(Impulse.ar(beatTrig.lincurve(0, 1, 0.5, \blipSpeed.kr(30), 4), 0, beatTrig), 12000, 8);
	blip = Pan2.ar(blip, LFNoise2.kr(beatTrig.linlin(0, 1, 10, 0.1), mul:0.7));

	beatTrig = PulseDivider.kr(pitchTrig, patternSize / 8, 1 * patternSize / 8);
	beatTrig = beatTrig * (TRand.kr(0, 10, beatTrig) > 6);
	beatTrig = Env.perc(0.01, 4, curve:-8).kr(gate:beatTrig);
	chord = LPF.ar(LFSaw.ar(freqs[0..6], beatTrig), beatTrig.linlin(0, 1, 300, 12000), mul:1/6).sum;
	chord = Pan2.ar(chord, TRand.kr(-0.6, 0.6, beatTrig > 0.01).lag(0.3));

	sig = (
		(\inputAmp.kr(1) * input)
		+ (\bassAmp.kr(0) * bass)
		+ (\noiseAmp.kr(0) * noise)
		+ (\chordAmp.kr(0) * chord)
		+ (\blipAmp.kr(0) * blip)
	);

	bws = Amplitude.kr(sig.sum).lagud(0.01, 8);
	bws = bws.lincurve(0.4, 2.0, \bwMin.kr(1 / 1000, 10), \bwMax.kr(1 / 5, 10), \bwCurve.kr(1));
	bws = bws ! freqs.size;

	amps = freqs.size.collect { TRand.kr(0.0, 1.0, pitchTrig).pow(Decay.kr(pitchTrig, 5).linlin(0, 1, 1, 2)).lag(0.01) };

	// DELAYS
	bigDelay = \bigDelay.kr(1.0);
	smallDelay = \smallDelay.kr(1/32);
	delays = freqs.size.collect {
		[
			// DELAY 1
			TRand.kr(0, 4, pitchTrig).round(bigDelay) + bigDelay,
			// DELAY 2
			TRand.kr(0, 2, pitchTrig).round(smallDelay) + smallDelay
		]
	};
	delays = delays * bpm;

	// COMPRESS
	// (RunningMax.kr(Amplitude.kr(sig.sum / 2), Impulse.kr(1/5))).poll(1, label:"before");
	sig = Compander.ar(sig, sig.sum / 2, 0.25, 1, 1/10);
	// (RunningMax.kr(Amplitude.kr(sig.sum / 2), Impulse.kr(1/5))).poll(1, label:"after ");

	// FEEDBACK
	feeds = \feed.kr(1.0) * LocalIn.ar(freqs.size * 2).clump(2);
	feeds = feeds + (feeds.sum * 0.02);
	feedsAmp = Amplitude.kr(sig.flatten.sum + feeds.flatten.sum, 0.2, 6);
	feedsAmp = feedsAmp.linlin(0, 0.5, 0, 0.5) + feedsAmp.lincurve(0.5, 1.0, 0, 0.2, -4) + feedsAmp.lincurve(1.0, 1.2, 0, -0.8, -4);

	feeds = feeds * feedsAmp;

	eqSigs = List();

	eqSigs = [freqs, bws, amps, delays, feeds].flop.collect {
		|eq|
		var freq, bw, amp, delay, feed, feedSig, eqSig;
		var sawLevel;
		#freq, bw, amp, delay, feed = eq;

		feed = Rotate2.ar(feed[0], feed[1], Rand(-0.1, 0.1));
		feed = XFade2.ar(
			DelayC.ar(feed, 4.0, delay[0], 1),
			DelayC.ar(feed, 4.0, delay[1]
				// * Decay.kr(pitchTrig > 0, 4).linexp(0, 1, 1, 2)
				,
				0.8
			),
			SinOsc.ar(1/12, 1.0.rand, 0.6)
		);
		// feed = BLowPass4.ar(feed, min(20000, freq * 6), freq / 100);
		feed = BLowPass4.ar(feed, 16000);

		eqSig = [1, 2, 3, 4, 6, 8].sum {
			|mult, i|
			mult = mult + (Rand(-1, 1) * (\eqPartialDetune.kr(0.01)));
			BBandPass.ar(sig, freq * mult, bw, amp * 2 * i.linexp(0.001, 6, 1, \eqPartialAmp.kr(0.2)));
		};
		eqSig = LeakDC.ar(eqSig + feed);

		// eqSig = (eqSig + LPF.ar(eqSig * LFSaw.ar(freq, 0.5, 1), Decay2.kr(pitchTrig, 0.5, 12).lincurve(0, 1, 100, 6000, -4)));
		// eqSig = (eqSig + LPF.ar(eqSig * LFPulse.ar(freq), Decay2.kr(pitchTrig, 0.5, 12).lincurve(0, 1, 100, 5000, -4)));
		sawLevel = \sawLevel.kr(0.3);
		eqSig = (
			eqSig
			+ LPF.ar(
				eqSig * Saw.ar(freq, sawLevel),
				Decay2.kr(pitchTrig, 0.5, 12).lincurve(
					0, 1,
					sawLevel.linlin(0, 1, 20, 100), sawLevel.linlin(0, 1, 100, 8000),
					-4
				)
			)
		);

		eqSig.assertChannels(2);
	};

	eqSigs.assertChannels(16, 2);
	sig = eqSigs.sum;

	LocalOut.ar(eqSigs.flatten);
	sig * 0.dbamp;

}).play;
)

// \source settings
Ndef(\source).fadeTime = 10;
Ndef(\source).set(\speed, 1);
Ndef(\source).play();


// \adelay settings
Ndef(\adelay).play;

Ndef(\adelay).fadeTime = 10;

Ndef(\adelay).set(\root, 40);

Ndef(\adelay).set(\feed, 1);
Ndef(\adelay).set(\bigDelay, 1);
Ndef(\adelay).set(\smallDelay, 1/16);

Ndef(\adelay).set(\eqPartialAmp, 0.8);
Ndef(\adelay).set(\eqPartialDetune, 0.001);

Ndef(\adelay).set(\detune, 0.001);
Ndef(\adelay).set(\freqLag, 0.00);

// Bandwidth min and max = should stay fractional, between 1/1 and 1/3000 or so
(
Ndef(\adelay).set(\bwMin, 1 / 1);
Ndef(\adelay).set(\bwMax, 1 / 2000);
Ndef(\adelay).set(\bwCurve, 4); // -30 .. 30
)

// Reversed...
(
Ndef(\adelay).set(\bwMin, 1 / 10);
Ndef(\adelay).set(\bwMax, 1 / 100.5);
Ndef(\adelay).set(\bwCurve, -5); // -30 .. 30
)

Ndef(\adelay).set(\sawLevel, 0.0);

// notes are indexed on pentatonic scale, where index is noteJump + noteStart, each chosen randomly in rotation
// minorPentatonic
(
Ndef(\adelay).setn(\noteJumps, [0, 12, 24, 5, 12, 24]);
Ndef(\adelay).setn(\noteStarts, [0, 3, 5, 7, 7, 14 ]);
)

(
Ndef(\adelay).set(\root, 40);
Ndef(\adelay).setn(\noteJumps, [0, 12, 24, 0, 12, 24]);
Ndef(\adelay).setn(\noteStarts, [0, 1, 1, 3, 4, 1]);
)

(
Ndef(\adelay).set(\root, 20);
Ndef(\adelay).setn(\noteJumps, [0, 0, 0, 15, 6, 10]);
Ndef(\adelay).setn(\noteStarts, [0, 1, 1, 5, 5, 6]);
)

Ndef(\adelay).set(\patternSize, 128);

(
Ndef(\adelay).set(\inputAmp, 1);
Ndef(\adelay).set(\bassAmp, 0.2);
Ndef(\adelay).set(\noiseAmp, 0.7);
Ndef(\adelay).set(\blipAmp, 0.5);
Ndef(\adelay).set(\blipSpeed, 40);
Ndef(\adelay).set(\chordAmp, 0.2);
)

(
// solo one....
Ndef(\adelay).set(\inputAmp, 1);
Ndef(\adelay).set(\bassAmp, 0);
Ndef(\adelay).set(\noiseAmp, 0);
Ndef(\adelay).set(\blipAmp, 0);
Ndef(\adelay).set(\chordAmp, 0);
)