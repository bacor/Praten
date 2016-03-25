###########################################################################
#                                                                         #
#  Praat Script Syllable Nuclei                                           #
#  Copyright (C) 2008  Nivja de Jong and Ton Wempe                        #
#                                                                         #
#    This program is free software: you can redistribute it and/or modify #
#    it under the terms of the GNU General Public License as published by #
#    the Free Software Foundation, either version 3 of the License, or    #
#    (at your option) any later version.                                  #
#                                                                         #
#    This program is distributed in the hope that it will be useful,      #
#    but WITHOUT ANY WARRANTY; without even the implied warranty of       #
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the        #
#    GNU General Public License for more details.                         #
#                                                                         #
#    You should have received a copy of the GNU General Public License    #
#    along with this program.  If not, see http://www.gnu.org/licenses/   #
#                                                                         #
###########################################################################
#
# Modified 2010.09.17 by Hugo Quené, Ingrid Persoon, & Nivja de Jong 
# Overview of changes: 
# + change threshold-calculator: rather than using median, use the almost maximum
#   minus 25dB. (25 dB is in line with the standard setting to detect silence
#   in the "To TextGrid (silences)" function.
#   Almost maximum (.99 quantile) is used rather than maximum to avoid using
#   irrelevant non-speech sound-bursts.
# + add silence-information to calculate articulation rate and ASD (average syllable
#   duration.
#   NB: speech rate = number of syllables / total time
#       articulation rate = number of syllables / phonation time
# + remove max number of syllable nuclei
# + refer to objects by unique identifier, not by name
# + keep track of all created intermediate objects, select these explicitly, 
#   then Remove
# + provide summary output in Info window
# + do not save TextGrid-file but leave it in Object-window for inspection
#   (if requested in startup-form)
# + allow Sound to have starting time different from zero
#   for Sound objects created with Extract (preserve times)
# + programming of checking loop for mindip adjusted
#   in the orig version, precedingtime was not modified if the peak was rejected !!
#   var precedingtime and precedingint renamed to currenttime and currentint
#
####
#
# + bug fixed concerning summing total pause, feb 28th 2011
#
###########################################################################
#
# Modified 2016.03.25 by Bas Cornelissen (bascornelissen.nl)
# Overview of changes
# +	Rewrote the script in the (what I believe to be) latest Praat syntax
# + Renamed nearly all variables to increase readibility and naming consistency
# + Changed the logic of the script. Instead of iterating over all peak 
#	candidates multiple time to apply the different filters, this script
#	loops over all maxima once, checks for each of those maxima if they 
# 	pass all three filters and if so, stores those peaks. 
#	Also, I changed the order of certain blocks of code to improve readability.
# +	Added more detailed comments
#
###########################################################################


## This script counts the syllables of all sound utterances in a directory
# NB unstressed syllables are sometimes overlooked
# NB filter sounds that are quite noisy beforehand
# NB use Silence threshold (dB) = -25 (or -20?)
# NB use Minimum dip between peaks (dB) = between 2-4 (you can first try;
#                                                      For clean and filtered: 4)

# Form for global script parameters
form Counting Syllables in Sound Utterances
	real Silence_threshold_(dB) -25
	real Minimum_dip_between_peaks_(dB) 2
	real Minimum_pause_duration_(s) 0.3
	boolean Keep_Soundfiles_and_Textgrids yes
	sentence directory /Users/Bas/Github Projects/Praten/sounds
endform

# Use more convenient variable names
silenceThreshold= silence_threshold
minDip 			= minimum_dip_between_peaks 
showText 		= keep_Soundfiles_and_Textgrids
minPause 		= minimum_pause_duration

# Print information about quantities
# writeInfoLine: newline$, "QUANTITIES AND UNITS"
appendInfoLine: "Duration (duration): seconds"
appendInfoLine: "Phonation time (phon. time): seconds"
appendInfoLine: "Speech rate (sp. rate): # syll / duration"
appendInfoLine: "Articulation rate (art. rate): # syll / phonation time"
appendInfoLine: "ASD: speakingtime/nsyll", newline$

# Print a table header
appendInfoLine: "SOUNDNAME, # SYLL, # PAUSE, DURATION, PHON. TIME, SP. RATE, ART. RATE, ASD"
appendInfoLine: "——————————————————————————————————————————————————————————————————————————"

# Loop over all .wav files in the directory
fileList 			= Create Strings as file list: "fileList", directory$ + "/*.wav"
numberOfFiles 		= Get number of strings
for file to numberOfFiles

	# Get sound, pitch and intensity objects
	select fileList
	fileName$ 		= Get string: file
	fileName$		= directory$ + "/" + fileName$
	sound 			= Read from file: fileName$
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
	maximaObject 	= To PointProcess (extrema): "Left", "yes", "no", "Sinc70"
	numMaxima 		= Get number of points
	for i to numMaxima
	   maxima[i] 	= Get time from index: i
	endfor

	################
	# FILTERING
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

	# Insert voiced peaks in TextGrid
	if showText > 0
		select textgrid
		Insert point tier: 1, "syllables"

		for i to peakCount
			peak = peaks[i] * timeCorrection
			Insert point: 1, peak, string$ (i)
		endfor
	endif

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

	speakingRate 	= peakCount / soundDur
	articulationRate= peakCount / soundingDur
	npause 			= numPauses - 1
	asd 			= soundingDur / peakCount

	select sound
	soundname$ = selected$("Sound")

	# Print results
	appendInfo: 	soundname$, ", ", peakCount, ", ", npause, ", ", 'soundDur:2'
	appendInfo: 	", ", 'soundingDur:2', ", ", 'speakingRate:2', ", "
	appendInfoLine: 'articulationRate:2', ", ", 'asd:3'

	# Clean up
	select maximaObject
	plus matrix
	plus pitch
	plus intensity
	plus intensitySound
	plus silenceTier
	plus silenceTable
	Remove

endfor
# End loop over all files in directory