procedure GetNucleiSmooth: .sound, .maxSmoothingDip, .minDipBefore, .minDipAfter, .silenceThreshold, .minPause, .showPeaks
	
	# Load objects
	select .sound
	.pitch = To Pitch (ac): 0, 30, 4, "no", 0.03, 0.25, 0.01, 0.35, 0.25, 450
	select .sound
	.intensity = To Intensity: 50, 0, "yes"	
	
	# We want everything that has an intensity of `silenceThreshold`
	# below the 99% quantile (rather than below the maximum). So we 
	# calculate a new silence threshold `newSilenceThres` that is 
	# lowered by the difference between the max and the 99% quantile.
	.minIntensity = Get minimum: 0, 0, "Parabolic"
	.maxIntensity = Get maximum: 0, 0, "Parabolic"
	.q99Intensity = Get quantile: 0, 0, 0.99
	.newSilenceThres = .silenceThreshold - (.maxIntensity - .q99Intensity)
	.threshold = .maxIntensity + .newSilenceThres
	if .threshold < .minIntensity
		.threshold 	= .minIntensity
	endif
	
	# Textgrid with the following tiers
	# 1: nuclei, 2: filtered peaks, 3: all peaks; 4: silences
	.textgrid = To TextGrid (silences): .newSilenceThres, .minPause, 0.1, "silent", "sounding"
	Insert point tier: 1, "peaks"
	Insert point tier: 1, "filtered peaks"
	Insert point tier: 1, "nuclei"
	.soundingTierId	= 4
	
	# Get all peak candidates
	# Always include the very first frame.
	select .intensity
	.firstValue = Get value in frame: 1
	.firstTime = Get time from frame number: 1
	.peaks = To IntensityTier (peaks)
	Add point: .firstTime, .firstValue
	.numPeaks = Get number of points
	
	# Fill textgrid tier with all peak positions
	for .i to .numPeaks
		select .peaks
		.time = Get time from index: .i
		select .textgrid
		Insert point: 3, .time, string$(.i)
	endfor

	.i = 1
	while .i <= .numPeaks

		# Set intensities, times and dips
		@SetDips: .peaks, .intensity, .i
		.remove = 0

		# Check if current interval is sounding and has a pitch
		select .textgrid
		.index = Get interval at time: .soundingTierId, curTime
		.label$ = Get label of interval: .soundingTierId, .index
		select .pitch
		.pitchValue	= Get value at time: curTime, "Hertz", "Linear"
		
		# Filter the peaks and only keep serious candidates
		if .label$ = "sounding" and curIntensity > .threshold and .pitchValue <> undefined
			if dipAfter < .maxSmoothingDip
				# Compare this peak and the next. Remove the lowest one.
				.index = .i + imin(curIntensity, nextIntensity) - 1
				.remove = .index
			endif
		else 
			.remove = .i
		endif
		
		# Remove the point to be removed
		if .remove <> 0  and .remove <= .numPeaks
			select .peaks
			Remove point: .remove
			.numPeaks = Get number of points
		else
			.i += 1
		endif
	endwhile 
	
	# Put all nuclei in yet another textgrid tier
	.numNuclei = 1
	for .i to .numPeaks	
		
		@SetDips: .peaks, .intensity, .i
		
		if dipBefore > .minDipBefore and dipAfter > .minDipAfter
			select .textgrid
			Insert point: 1, curTime, string$(.numNuclei)
			.numNuclei += 1
		endif
		
		# Show the filtered peaks in the textgrid?
		if .showPeaks
			select .peaks
			.time = Get time from index: .i
			select .textgrid
			Insert point: 2, .time, string$('dipBefore:1') + ","+ string$('dipAfter:1')
		endif
	endfor 
	
	if .showPeaks = 0
		select .textgrid
		Remove tier: 2
		Remove tier: 3
		Remove tier: 4
	endif

	selectObject: .pitch, .intensity, .peaks
	Remove
	select .textgrid
endproc


# Set previous, current and next time and intensity
procedure SetDips: .peaks, .intensity, .i
	select .peaks
	if .i = 1
		select .intensity
		prevTime = Get time from frame number: 1
		select .peaks
	else		
		prevTime = Get time from index: .i - 1
	endif
	
	select .peaks
	curTime = Get time from index: .i
	curIntensity = Get value at index: .i

	nextTime = Get time from index: .i + 1
	nextIntensity = Get value at index: .i + 1
	
	if nextTime = undefined
		select .intensity
		.numFrames = Get number of frames
		nextTime = Get time from frame number: .numFrames
		nextIntensity = Get value in frame: .numFrames
	endif

	select .intensity
	.firstTime = Get time from frame number: 1
	.valleyBefore = Get minimum: prevTime, curTime, "Parabolic"
	.valleyAfter = Get minimum: curTime, nextTime, "Parabolic"

	# Pretend that at the beginning, there is always
	# a point with mean intensity
	if prevTime < .firstTime + 0.01
		.mean = Get mean: 0, 0, "energy"
		.valleyBefore = min(.valleyBefore, .mean)
	endif

	dipBefore = abs(curIntensity - .valleyBefore)
	dipAfter = abs(curIntensity - .valleyAfter)
endproc