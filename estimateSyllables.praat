# Silence threshold in dB. 
# This "determines the maximum silence intensity value in dB with
# respect to the maximum intensity. So everything with intensity
# below max_intensity - silenceThreshold is considered to be silent.
silenceThreshold= -25
minDip 			= 2
showText 		= 1
minPause 		= 0.3


# Read the sound file and get the intensity
sound 			= Read from file: "sounds/deutsch-context.wav"
soundDur 		= Get total duration
pitch 			= To Pitch (ac)... 0.02 30 4 no 0.03 0.25 0.01 0.35 0.25 450
select sound
intensity 		= To Intensity: 50, 0, "yes"

# We want everything that has an intensity of `silenceThreshold`
# below the 99% quantile (rather than below the maximum). So we 
# calculate a new silence threshold `newSilenceThres` that is 
# lowered by the difference between the max and the 99% quantile.

minIntensity 	= Get minimum: 0, 0, "Parabolic"
maxIntensity 	= Get maximum: 0, 0, "Parabolic"
q99Intensity 	= Get quantile: 0, 0, 0.99
newSilenceThres = silenceThreshold - (maxIntensity - q99Intensity)
threshold 		= maxIntensity + newSilenceThres
if threshold < minIntensity
	threshold 	= minIntensity
endif

# Get a textgrid with all silences (with newSilenceThres as threshold)
textgrid 		= To TextGrid (silences): newSilenceThres, minPause, 0.1, "silent", "sounding"

# Collect the positions of the maxima
select intensity
matrix 			= Down to Matrix
intensitySound 	= To Sound (slice): 1
intensSoundDur 	= Get total duration
maximaPP 		= To PointProcess (extrema): "Left", "yes", "no", "Sinc70"
numMaxima 		= Get number of points
for i to numMaxima
   maxima[i] 	= Get time from index: i
endfor


################
# FILTERS!
# We now filter all maxima using three filters (see below) and collect
# the positions (times) of the maxima that pass all three filters 
# in the `peaks` array;
#
peakCount = 0
for i to numMaxima - 1

	# Shortcuts for the current and next maxima (peak candidates)
	currentMax = maxima[i]
	nextMax = maxima[i + 1]
	
	################
	# Start Filter 1.
	# This filter checks if the intensity of the current maximum
	# exceeds the new silence threshold.
	select intensitySound
	intensityValue = Get value at time: currentMax, "Cubic"

	# Filter 1: Is this point not silent?
	if intensityValue > threshold

		################
		# Start Filter 2
		# This filter checks if the next dip is deep enough. The dip
		# is the difference between the current intensity and the 
		# minimum intensity between this maximum and the next.
		#
		select intensity
		curIntensity = Get value at time: currentMax, "Cubic"
		dip = Get minimum: currentMax, nextMax, "None"

		# Filter 2: is the dip deep enough?
		if abs(curIntensity - dip) > minDip

			################
			# Start Filter 3
			# This filter checks if the current maximum is in a sounding
			# interval (i.e. not silent) and whether it has a pitch.
			#
			select textgrid
			interval = Get interval at time: 1, currentMax
			label$ = Get label of interval: 1, interval

			select pitch
			pitchValue = Get value at time: currentMax, "Hertz", "Linear"

			# Filter 3: is the pitch defined and the interval not silent?
			if pitchValue <> undefined
				if label$ = "sounding"

					################
					# Passed all filters
					# This maximum passed all filters and is a valid peak
					#
					peakCount += 1
					peaks[peakCount] = currentMax

				endif
			endif
			# End filter 3

		endif
		# End filter 2

	endif
	# End filter 1

endfor
# End filter


# calculate time correction due to shift in time for Sound object versus
# intensity object
timeCorrection = soundDur / intensSoundDur

# Insert nuclei positions in TextGrid
if showText > 0
	select textgrid
	Insert point tier: 1, "nuclei"

	for i to peakCount
		peak = peaks[i] * timeCorrection
		Insert point: 1, peak, string$ (i)
	endfor
endif

select intensitySound
minimaPP 	= To PointProcess (extrema): "Left", "no", "yes", "Sinc70"

select textgrid
nuclei = Extract one tier: 1

select textgrid
Insert interval tier: 1, "syllables"

select pitch
pitchPP 		= To PointProcess
voicedUnvoiced 	= To TextGrid (vuv): 0.02, 0.01
numIntervals 	= Get number of intervals: 1

for i to numIntervals

	select voicedUnvoiced
	label$ 		= Get label of interval: 1, i
	
	# We only consider intervals that are voiced (V)
	if label$ = "V"
		
		# Find current interval boundaries
		intervalStart 	= Get starting point: 1, i
		intervalEnd 	= Get end point: 1, i
		
		# Adjust them to nearest zero crossing 
		select sound
		intervalStart 	= Get nearest zero crossing: 1, intervalStart
		intervalEnd 	= Get nearest zero crossing: 1, intervalEnd

		# Insert the interval boundaries in the textgrid
		select textgrid
		Insert boundary: 1, intervalStart
		Insert boundary: 1, intervalEnd

		# Extract the nuclei in this interval
		select nuclei
		intervalNuclei 	= Extract part: intervalStart, intervalEnd, "yes"
		numNuclei 		= Get number of points: 1
		
		# If there's only one, we're done...
		if numNuclei = 1
			select textgrid
			intervalId = Get high interval at time: 1, intervalStart
			Set interval text: 1, intervalId, "syllable"

		# ... Otherwise, we have to break up the current interval 
		# between every two successive nuclei. We do that by searching
		# for the point of minimum intensity between all successive nuclei.
		elsif numNuclei > 1
			for j to numNuclei - 1

				select intervalNuclei
				curNucleus 		= Get time of point: 1, j
				nextNucleus 	= Get time of point: 1, j + 1

 				select minimaPP
				firstMinimum 	= Get high index: curNucleus
				lastMinimum 	= Get low index: nextNucleus
				
				# `minMinimum` is the index of the minimum with the 
				# lowest intensity of all minima between curNucleus and 
				# nextNucleus. If there's only one minimum, just take 
				# the first and only as the `minMinimum`.... 
				minMinimum 		= firstMinimum
				
				# ... otherwise, we look for the minimal one.
				if firstMinimum <> lastMinimum
					index = firstMinimum
					repeat
						select minimaPP
						time = Get time from index: index
						select intensitySound
						mins[index] = Get value at time: time, "Cubic"

						if mins[index] < mins[minMinimum]
							minMinimum = index
						endif

						index += 1
					until index > lastMinimum
				endif

				# Insert another boundary in the interval at the
				# lowest minimum we just determined.
				select minimaPP
				boundary = Get time from index: minMinimum
				
				select textgrid
				Insert boundary: 1, boundary
				intervalId = Get low interval at time: 1, boundary
				Set interval text: 1, intervalId, "syllable"

			endfor

			# Fix text in the last interval
			intervalId = Get low interval at time: 1, intervalEnd
			Set interval text: 1, intervalId, "syllable"
		endif

		# Reset
		select intervalNuclei
		Remove

	endif
endfor

# Number all the syllables
select textgrid
numIntervals = Get number of intervals: 1
for i to numIntervals
	label$ = Get label of interval: 1, i
	if label$ = "syllable"
		Set interval text: 1, i, string$ (i)
	endif
endfor

# Remove the tier with silence/sounding
Remove tier: 3

# Clean up
selectObject: maximaPP, minimaPP, matrix, pitch, intensity, intensitySound, pitchPP, voicedUnvoiced, nuclei
Remove
