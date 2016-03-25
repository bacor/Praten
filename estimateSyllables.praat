# Includes
include procedures/NucleiToSyllables.praat
include procedures/GetNuclei.praat
include procedures/ManipulatePitch.praat

# The sound file
sound = Read from file: "sounds/demo.wav"

# Get all nuclei
@GetNuclei: sound, undefined, undefined, undefined
textgrid = selected("TextGrid")

# Estimate the syllables from the nuclei
@NucleiToSyllables: sound, textgrid, undefined, undefined, undefined

selectObject: sound, textgrid
View & Edit

#######################################################



# newPitch = 200
# manipTimeStep= 0.001
# extraBlank = 0

# for i to numIntervals
# 	select textgrid
# 	label$ = Get label of interval: 1, i
# 	if label$ <> ""

# 		start = Get starting point: 1, i
# 		end = Get end point: 1, i

# 		select pitch
# 		mean = Get mean: start, end, "Hertz"

# 		select sound
# 		manipulation = Copy: "manipulation"
# 		@ManipulatePitch: manipulation, start, end, mean, manipTimeStep

# 	endif
# endfor

# @ManipulatePitch(snd, timeStart, timeEnd, newPitch)

# select snd
# Formula (part): timeStart, timeEnd, 1, 1, "Sound_resynth(x-timeStart)"

# select Sound resynth
# if extraBlank > 0
#   plus blank
# endif
# Remove

# select tg
# tg= Copy: name$

# select snd
# plus tg
# View & Edit

# exit


# procedure Concat .blank .name$
#    .snd= selected("Sound")
#    select .blank
#    .blank1= Copy: "blank1"
#    select .snd
#    .sndTemp= Copy: "sndTemp"
#    select .blank
#    .blank2= Copy: "blank2"
#    plus .blank1
#    plus .sndTemp
#    .c= Concatenate
#    Rename: .name$

#    select .blank1
#    plus .blank2
#    plus .sndTemp
#    Remove

#    select .c

# endproc