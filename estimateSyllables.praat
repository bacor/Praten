# Includes
include procedures/NucleiToSyllables.praat
include procedures/GetNuclei.praat
include procedures/ManipulatePitch.praat

# The sound file
sound = Read from file: "sounds/AT0032-context.wav"
pitch = To Pitch (ac): 0.02, 75, 15, "no", 0.03, 0.45, 0.01, 0.35, 0.14, 600
select sound
intensity = To Intensity: 50, 0, "yes"	

# Get all nuclei
@GetNuclei: sound, pitch, intensity, undefined, 2, undefined
textgrid = selected("TextGrid")

# Estimate the syllables from the nuclei
@NucleiToSyllables: sound, textgrid, pitch, intensity

selectObject: sound, textgrid
View & Edit


## MANIPULATE
# 
# This clearly doesn't work yet. But that was to be expected.
# --> A weighted sum would be much better. 

# select sound
# original = Copy: "Original"

# select textgrid
# numIntervals = Get number of intervals: 1

# for i to numIntervals
# 	select textgrid
# 	label$ = Get label of interval: 1, i
# 	if label$ <> ""

# 		start = Get starting point: 1, i
# 		end = Get end point: 1, i

# 		select pitch
# 		mean = Get mean: start, end, "Hertz"

# 		@ManipulatePitch: sound, start, end, mean, 0.001

# 	endif
# endfor


selectObject: pitch, intensity
Remove