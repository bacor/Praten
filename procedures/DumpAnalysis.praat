
procedure DumpAnalysis: .textgrid, .id$, .log$
	# Indices of nuclei and syllables
	.n 				= 2
	.s 				= 1

	# EVALUATE
	select .textgrid
	.doubleNuclei 	= 0
	.missingNuclei 	= 0
	.emptyNuclei	= 0
	.numPeaks 		= Get number of points: .n

	if .numPeaks = 0 
		.numIntervals = Get number of intervals: .s
		.missingNuclei = .numIntervals
	else 
		for .i to .numPeaks
			.time = Get time of point: .n, .i
			.interval = Get interval at time: .s, .time
			if .i > 1
				if .interval = .prevInterval
					.doubleNuclei += 1
				endif
			endif
			.prevInterval = .interval
		endfor
		
		.lastPeak = Get time of point: .n, .numPeaks
		.numIntervals = Get number of intervals: .s
		.numSyllables = 0
		for .i to .numIntervals
			.label$ = Get label of interval: .s, .i
			.start = Get starting point: .s, .i
			.end = Get end point: .s, .i
			
			if .start < .lastPeak
				.nucleus = Get high index from time: .n, .start
				.time = Get time of point: .n, .nucleus
				if .label$ <> ""
					.numSyllables += 1
					if .time > .end 
						.missingNuclei += 1
					endif
				else
					if .time < .end
						.emptyNuclei += 1
					endif
				endif
			else
				if .label$ <> "" 
					.missingNuclei += 1
				endif
			endif
		endfor
	endif
	
	.out$ =  .id$ + "," + string$(.doubleNuclei) + "," + string$(.missingNuclei)
	.out$ = .out$ + "," + string$(.emptyNuclei)  + "," + string$(.numSyllables)
	.out$ = .out$ + "," + string$(.numPeaks)
	appendFileLine: .log$, .out$
endproc