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

##
# Constructs a textgrid with all syllable nuclei
#
# This script is essentially a rewrite of the Praat script by  Nivja de Jong
# and Tom Wempe. 
#
# @author Bas Cornelissen
# @version 1.0
# @param Sound 		A sound object
# @param integer	(Optional) The silence threshold in dB. All points with 	
#					intensities below maxIntensity - silenceThreshold are 
#					considered silent. Default: -25dB
# @param integer	(Optional) The minimum dip in dB. Default: 2dB
# @param float 		(Optional) The minimum pause. Default: 0.3s
#
# @selects TextGrid A textgrid whose first tier contains the syllable nuclei.
#

procedure GetNuclei: .sound, .pitch0, .intensity0, .silenceThreshold, .minDip, .minPause

	# DEFAULT Pitch
	if .pitch0 = undefined
		select sound
		.pitch 	= To Pitch (ac): 0.02, 75, 15, "no", 0.03, 0.45, 0.01, 0.35, 0.14, 600
	else
		select .pitch0
		.pitch = Copy: "pitch"
	endif

	# DEFAULT intensity
	if .intensity0 = undefined
		select sound
		.intensity = To Intensity: 50, 0, "yes"	
	else
		select .intensity0
		.intensity = Copy: "intensity"
	endif
	
	# DEFAULT silenceThreshold
	if .silenceThreshold = undefined
		.silenceThreshold = -25
	endif

	# DEFAULT mindip
	if .minDip = undefined
		.minDip = 2
	endif

	# DEFAULT minPause
	if .minPause = undefined
		.minPause = 0.3
	endif


	## INITIALIZE
	#
	# Determine thresholds, maxima and create some objects we'll need

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

	# Get a textgrid with all silences (with newSilenceThres as threshold)
	.textgrid 		= To TextGrid (silences): .newSilenceThres, .minPause, 0.1, "silent", "sounding"

	# Collect the positions of the maxima
	select .intensity
	.matrix 		= Down to Matrix
	.intensitySound = To Sound (slice): 1
	.maximaPP 		= To PointProcess (extrema): "Left", "yes", "no", "Sinc70"
	.numMaxima 		= Get number of points
	for .i to .numMaxima
	   .maxima[.i] 	= Get time from index: .i
	endfor


	## FILTERING
	#
	# We now filter all maxima using three filters (see below) and collect
	# the positions (times) of the maxima that pass all three filters 
	# in the `peaks` array;
	#
	.peakCount = 0
	for .i to .numMaxima - 1

		# Shortcuts for the current and next maxima (peak candidates)
		.currentMax = .maxima[.i]
		.nextMax = .maxima[.i + 1]
		
		### Filter 1
		#
		# This filter checks if the intensity of the current maximum
		# exceeds the new silence threshold.

		select .intensitySound
		.intensityValue = Get value at time: .currentMax, "Cubic"

		if .intensityValue > .threshold

			### Filter 2
			# 
			# This filter checks if the next dip is deep enough. The dip
			# is the difference between the current intensity and the 
			# minimum intensity between this maximum and the next.

			select .intensity
			.curIntensity = Get value at time: .currentMax, "Cubic"
			.dip = Get minimum: .currentMax, .nextMax, "None"

			# appendInfoLine: newline$,abs(.curIntensity - .dip), ", ", .minDip
			if abs(.curIntensity - .dip) > .minDip
				# appendInfoLine: "ok"
				### Filter 3
				# 
				# This filter checks if the current maximum is in a sounding
				# interval (i.e. not silent) and whether it has a pitch.
				
				select .textgrid
				.interval = Get interval at time: 1, .currentMax
				.label$ = Get label of interval: 1, .interval

				select .pitch
				.pitchValue = Get value at time: .currentMax, "Hertz", "Linear"

				if .pitchValue <> undefined
					if .label$ = "sounding"

						### Done filtering
						#
						# Passed all filters, so this maximum is a valid peak
						
						.peakCount += 1
						.peaks[.peakCount] = .currentMax

					endif
				endif
				# End filter 3

			endif
			# End filter 2

		endif
		# End filter 1

	endfor


	## FINISHING
	#

	# Calculate time correction due to shift in time for Sound object versus
	# intensity object
	select .sound
	.soundDur 		= Get total duration
	select .intensity
	.intensSoundDur = Get total duration
	.timeCorrection = .soundDur / .intensSoundDur

	# Insert nuclei positions in TextGrid
	select .textgrid
	Insert point tier: 1, "nuclei"
	for .i to .peakCount
		.peak = .peaks[.i] * .timeCorrection
		Insert point: 1, .peak, string$ (.i)
	endfor
	Remove tier: 2

	# Clean up
	selectObject: .pitch, .intensity, .maximaPP, .intensitySound, .matrix
	Remove

	# Select the textgrid
	select .textgrid
	
endproc