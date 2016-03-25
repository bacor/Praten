# printline soundname, nsyll, npause, dur (s), phonationtime (s), speechrate (nsyll/dur), articulation rate (nsyll / phonationtime), ASD (speakingtime/nsyll)

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

## Collect the positions of the maxima
select intensity
matrix 			= Down to Matrix
intensitySound 	= To Sound (slice): 1
intensitySoundDur = Get total duration
maxima 			= To PointProcess (extrema): "Left", "yes", "no", "Sinc70"
numMaxima 		= Get number of points
for i to numMaxima
   maximaPositions[i] = Get time from index: i
endfor

## FILTER NON-SILENT PEAKS
# Now collect all maxima whose value (amplitude?) exceeds the 
# silence threshold (w.r.t. 99 quantile) in an array. 
# These are candidate peaks.
select intensitySound
numPeaks = 0
for i to numMaxima
	value = Get value at time: maximaPositions[i], "Cubic"
	if value > threshold
		numPeaks += 1
		peakIntensities[numPeaks] = value
		peakPositions[numPeaks] = maximaPositions[i]
	endif
endfor

## FILTER DEEP DIPPING PEAKS
# Filter the candidate peaks. Only keep the peaks for which the
# preceding (or succeeding?) dip in intensity is greater than minDip
select intensity
numValidPeaks 		= 0
for i to numPeaks - 1
	curPosition 	= peakPositions[i]
	curIntensity 	= Get value at time: curPosition, "Cubic"
	nextPos 		= peakPositions[i + 1]
	dip 			= Get minimum: curPosition, nextPos, "None"

	if abs(curIntensity - dip) > minDip
		numValidPeaks += 1
		validPeakPositions[numValidPeaks] = curPosition
	endif
endfor

## FILTER VOICED PEAKS
# Look for only voiced parts
select sound
pitch = To Pitch (ac)... 0.02 30 4 no 0.03 0.25 0.01 0.35 0.25 450
numVoicedPeaks = 0
for i to numValidPeaks
	pos = validPeakPositions[i]

	select textgrid
	interval = Get interval at time: 1, pos
	label$ = Get label of interval: 1, interval

	select pitch
	value = Get value at time: pos, "Hertz", "Linear"
	if value <> undefined
		if label$ = "sounding"
			numVoicedPeaks += 1
			voicedPeakPositions[numVoicedPeaks] = validPeakPositions[i]
		endif
	endif
endfor


# calculate time correction due to shift in time for Sound object versus
# intensity object
timeCorrection = soundDur / intensitySoundDur

# Insert voiced peaks in TextGrid
if showText > 0
	select textgrid
	Insert point tier: 1, "syllables"

	for i to numVoicedPeaks
		pos = voicedPeakPositions[i] * timeCorrection
		Insert point: 1, pos, string$ (i)
	endfor
endif


# Clean up
select maxima
plus matrix
plus pitch
plus intensity
plus intensitySound
Remove

## Total sounding duration
# Calculate the duration of the speech `soundingDur`.
# That is: add the duration of all non-silent, but sounding parts.
select textgrid
silenceTier 	= Extract tier: 2
silenceTable 	= Down to TableOfReal: "sounding"
numPauses 		= Get number of rows
soundingDur 	= 0
for i to numPauses
	beginSound 	= Get value: i, 1
	endSound 	= Get value: i, 2
	soundingDur += endSound - beginSound
endfor

# Clean up
select silenceTier
plus silenceTable
Remove

speakingRate 	= numVoicedPeaks / soundDur
articulationRate= numVoicedPeaks / soundingDur
npause 			= numPauses - 1
asd 			= soundingDur / numVoicedPeaks

select sound
soundname$ = selected$("Sound")
printline 'soundname$', 'numVoicedPeaks', 'npause', 'soundDur:2', 'soundingDur:2', 'speakingRate:2', 'articulationRate:2', 'asd:3'



