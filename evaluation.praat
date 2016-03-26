# Includes
include procedures/NucleiToSyllables.praat
include procedures/GetNuclei.praat


directory$ = "sounds/stimuli/"

# Write general header
writeInfoLine: "stimulus_id,num_syllables"

# Loop over all .wav files in the directory
directory$ 			= directory$ - "/" + "/"
fileList 			= Create Strings as file list: "fileList", directory$ + "*.wav"
numberOfFiles 		= Get number of strings

for file to numberOfFiles
	# if file > 300
	# 	exit
	# endif

	select fileList
	fileName$ 		= Get string: file
	id$ 			= fileName$ - ".wav"

	sound 			= Read from file: directory$ + fileName$
	soundDur 		= Get total duration
	
	if soundDur > 0.1
	# if id$ = "UvA0014"

		pitch 			= To Pitch (ac): 0.02, 75, 15, "no", 0.03, 0.45, 0.01, 0.35, 0.14, 600
		select sound
		intensity 		= To Intensity: 50, 0, "yes"

		# Get all nuclei
		@GetNuclei: sound, pitch, intensity, undefined, 2, undefined
		textgrid = selected("TextGrid")

		# Estimate the syllables from the nuclei
		@NucleiToSyllables: sound, textgrid, pitch, intensity

		# Count the number of syllables
		select textgrid
		numSyllables 	= Count intervals where: 1, "is not equal to", ""
		appendInfoLine: id$, ",", numSyllables

		selectObject: pitch, intensity, textgrid
		Remove

	endif

	select sound
	Remove

endfor