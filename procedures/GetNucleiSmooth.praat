procedure GetNucleiSmooth: .sound, .maxSmoothingDip, .minDipBefore, .minDipAfter, .silenceThreshold, .minPause, .showPeaks
	
	# Load objects
	select .sound
	.pitch 	= To Pitch (ac): 0.02, 30, 5, "no", 0.03, 0.25, 0.01, 0.35, 0.25, 450
	select .sound
	.intensity = To Intensity: 100, 0, "yes"	
	
	# We want everything that has an intensity of `silenceThreshold`
	# below the 99% quantile (rather than below the maximum). So we 
	# calculate a new silence threshold `newSilenceThres` that is 
	# lowered by the difference between the max and the 99% quantile.
	.minIntensity 	= Get minimum: 0, 0, "Parabolic"
	.maxIntensity 	= Get maximum: 0, 0, "Parabolic"
	.q99Intensity 	= Get quantile: 0, 0, 0.99
	.newSilenceThres = .silenceThreshold - (.maxIntensity - .q99Intensity)
	.threshold 		= .maxIntensity + .newSilenceThres
	if .threshold < .minIntensity
		.threshold 	= .minIntensity
	endif
	
	# Textgrid with the following tiers
	# 1: nuclei, 2: filtered peaks, 3: all peaks; 4: silences
	.textgrid 		= To TextGrid (silences): .newSilenceThres, .minPause, 0.1, "silent", "sounding"
	Insert point tier: 1, "peaks"
	Insert point tier: 1, "filtered peaks"
	Insert point tier: 1, "nuclei"
	.soundingTierId	=	4

	select .intensity
	.peaks = To IntensityTier (peaks)
	.numPeaks = Get number of points
	.filteredPeaks		= Copy: "cleanPeaks"

	for .i to .numPeaks
		select .peaks
		.time = Get time from index: .i
		select .textgrid
		Insert point: 3, .time, string$(.i)
	endfor

	.i 					= 1
	.numRemovedPeaks	= 0
	while .i <= .numPeaks	
		
		# Check if current interval is sounding and has a pitch
		select .peaks	
		.curTime 		= Get time from index: .i
		.curIntensity 	= Get value at index: .i
		select .textgrid
		.index 			= Get interval at time: .soundingTierId, .curTime
		.label$ 		= Get label of interval: .soundingTierId, .index
		select .pitch
		.pitchValue		= Get value at time: .curTime, "Hertz", "Linear"
		
		if .label$ = "sounding" and .pitchValue <> undefined and .curIntensity > .threshold
			
			@SetDips: .peaks, .intensity, .i
			
			if dipAfter < .maxSmoothingDip
				# Compare this peak and the next. Remove the lowest one.
				select .peaks
				.index = .i + imin(curIntensity, nextIntensity) - 1
				select .filteredPeaks
				Remove point: .index - .numRemovedPeaks
				.numRemovedPeaks += 1
			endif
		else 
			select .filteredPeaks
			Remove point: .i - .numRemovedPeaks
			.numRemovedPeaks += 1
		endif

		.i += 1
	endwhile 
	
	# Identify nuclei
	select .filteredPeaks
	.numPeaks = Get number of points
	.i = 1
	while .i <= .numPeaks	
		
		@SetDips: .filteredPeaks, .intensity, .i
		
		if dipBefore > .minDipBefore and dipAfter > .minDipAfter
			select .textgrid
			Insert point: 1, curTime, string$('dipAfter:2')
		endif

		.i += 1
	endwhile 
	
	# Show all peaks in the textgrid?
	if .showPeaks
		# Add filtered peaks to textgrid
		select .filteredPeaks
		.numPeaks = Get number of points
		for .i to .numPeaks
			select .filteredPeaks
			.time = Get time from index: .i
			select .textgrid
			Insert point: 2, .time, string$(.i)
		endfor
	else
		select .textgrid
		Remove tier: 2
		Remove tier: 3
		Remove tier: 4
	endif

	selectObject: .pitch, .intensity, .peaks, .filteredPeaks
	Remove
	select .textgrid
endproc

# Set previous, current and next time and intensity
procedure SetDips: .peaks, .intensity, .i
	select .peaks
	if .i = 1
		select .intensity
		prevTime 			= Get time from frame number: 1
		prevIntensity 		= Get value in frame: 1
		select .peaks
	else		
		prevTime 		= Get time from index: .i - 1
		prevIntensity 	= Get value at index: .i - 1
	endif

	curTime 		= Get time from index: .i
	curIntensity 	= Get value at index: .i

	nextTime		= Get time from index: .i + 1
	nextIntensity 	= Get value at index: .i + 1
	
	if nextTime = undefined
		select .intensity
		.numFrames	= Get number of frames
		nextTime 	= Get time from frame number: .numFrames
		nextIntensity = Get value in frame: .numFrames
	endif

	select .intensity
	.valleyBefore	= Get minimum: prevTime, curTime, "Parabolic"
	.valleyAfter 	= Get minimum: curTime, nextTime, "Parabolic"
	dipBefore 		= abs(curIntensity - .valleyBefore)
	dipAfter 		= abs(curIntensity - .valleyAfter)
endproc