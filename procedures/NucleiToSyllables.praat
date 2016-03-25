##
# Detects syllable intervals using the syllable nucleus positions
#
# This algorithm crucially relies on the positions of the syllable nuclei, 
# but is otherwise very straightforward:
#
#	1.	Select all voiced intervals
#	2. 	For every voiced interval, check if it contains multiple nuclei
#		2a. If not, done.
#		2b. If yes, then cut the interval at the deepest intensity minimum
#			between all successive nuclei in the interval.
#
# You can use default arguments for this procedure by passing `undefined`
# instead of a parameter.
#
# @author Bas Cornelissen (bascornelissen.nl)
# @version 1.0
# @licence Creative Commons Attribution-NonCommercial-ShareAlike 4.0
# @param Sound 		The sound objects
# @param TextGrid 	A textgrid whose first tier is a point tier containing
#					the syllable nuclei
# @param Pitch 		(Optional)
# @param Intenstiy 	(Optional)
#

procedure NucleiToSyllables: .sound, .textgrid, .pitch0, .intensity0

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


	## INITIALIZATION
	#
	# Set up textgrid tiers, get minima, voiced/unvoiced grids ets.
	select .intensity
	.matrix = Down to Matrix
	.intensitySound = To Sound (slice): 1

	select .textgrid
	.nuclei = Extract one tier: 1

	select .textgrid
	Insert interval tier: 1, "syllables"

	select .intensitySound
	.minimaPP = To PointProcess (extrema): "Left", "no", "yes", "Sinc70"

	select .pitch
	.pitchPP = To PointProcess
	.voicedUnvoiced = To TextGrid (vuv): 0.02, 0.01
	.numIntervals = Get number of intervals: 1


	## FINETUNE INTERVALS 
	#
	# The voiced intervals serve as our starting point. All voiced intervals 
	# are added as syllables, but some will in fact consist of multiple 
	# syllables. We try to detect if that's the case by looking at the 
	# syllable nuclei. If there are multiple nuclei within one voiced interval
	# we cut the interval at the deepest minimum between every two successive
	# nuclei. The resulting subintervals all become syllables. 

	for .i to .numIntervals

		select .voicedUnvoiced
		.label$ 			= Get label of interval: 1, .i
		
		# We only consider intervals that are voiced (V)
		if .label$ = "V"
			
			# Find current interval boundaries
			.intervalStart 	= Get starting point: 1, .i
			.intervalEnd 	= Get end point: 1, .i
			
			# Adjust them to nearest zero crossing 
			select .sound
			.intervalStart 	= Get nearest zero crossing: 1, .intervalStart
			.intervalEnd 	= Get nearest zero crossing: 1, .intervalEnd

			# Insert the interval boundaries in the textgrid
			# Note that we thus also allow syllables without a nucleus!
			# select .textgrid
			# Insert boundary: 1, .intervalStart
			# Insert boundary: 1, .intervalEnd
			# select .textgrid
			# .intervalId = Get high interval at time: 1, .intervalStart
			# Set interval text: 1, .intervalId, "syllable"

			# Extract the nuclei in this interval
			select .nuclei
			.intervalNuclei = Extract part: .intervalStart, .intervalEnd, "yes"
			.numNuclei 		= Get number of points: 1

			if .numNuclei >= 1
				select .textgrid
				Insert boundary: 1, .intervalStart
				Insert boundary: 1, .intervalEnd
				select .textgrid
				.intervalId = Get high interval at time: 1, .intervalStart
				Set interval text: 1, .intervalId, "syllable"
			endif
			
			# If there are multiple nuclei, we break up the current interval 
			# between every two successive nuclei. We do that by searching
			# for the point of minimum intensity between all successive nuclei.
			if .numNuclei > 1
				for .j to .numNuclei - 1

					select .intervalNuclei
					.curNucleus 		= Get time of point: 1, .j
					.nextNucleus 	= Get time of point: 1, .j + 1

	 				select .minimaPP
					.firstMinimum 	= Get high index: .curNucleus
					.lastMinimum 	= Get low index: .nextNucleus
					
					# `minMinimum` is the index of the minimum with the 
					# lowest intensity of all minima between curNucleus and 
					# nextNucleus. If there's only one minimum, just take 
					# the first and only as the `minMinimum`.... 
					.minMinimum 	= .firstMinimum
					
					# ... otherwise, we look for the minimal one.
					if .firstMinimum <> .lastMinimum
						.index = .firstMinimum
						repeat
							select .minimaPP
							.time = Get time from index: .index
							select .intensitySound
							.mins[.index] = Get value at time: .time, "Cubic"

							if .mins[.index] < .mins[.minMinimum]
								.minMinimum = .index
							endif

							.index += 1
						until .index > .lastMinimum
					endif

					# Insert another boundary in the interval at the
					# lowest minimum we just determined.
					select .minimaPP
					.boundary = Get time from index: .minMinimum
					
					select .textgrid
					Insert boundary: 1, .boundary
					.intervalId = Get low interval at time: 1, .boundary
					Set interval text: 1, .intervalId, "syllable"

				endfor

				# Fix text in the last interval
				.intervalId = Get low interval at time: 1, .intervalEnd
				Set interval text: 1, .intervalId, "syllable"
			endif

			# Reset
			select .intervalNuclei
			Remove

		endif
	endfor


	## WRAPPING UP
	# 
	# Number the syllables and remove useless tiers and objects. Done!

	# Number all the syllables
	select .textgrid
	.numIntervals = Get number of intervals: 1
	.syllableCount = 0
	for .i to .numIntervals
		.label$ = Get label of interval: 1, .i
		if .label$ = "syllable"
			.syllableCount += 1
			Set interval text: 1, .i, string$ (.syllableCount)
		endif
	endfor

	# Clean up
	# Remove tier: 2
	selectObject: .minimaPP, .pitch, .pitchPP, .voicedUnvoiced, .matrix, .intensity, .intensitySound, .nuclei
	Remove

endproc