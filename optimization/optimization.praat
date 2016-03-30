# This script evaluates the getNucleiSmooth algorithm
# for all parameter settings in a settings.csv file.

start = 1
end = start + 1600
include ../procedures/GetNucleiSmooth.praat
include ../procedures/DumpAnalysis.praat

dir$ 		= "~/Github Projects/Praten/"
settings	= Read Table from comma-separated file: dir$ + "optimization/settings.csv"
numSettings = Get number of rows
trainIds 	= Read Table from comma-separated file: dir$ + "optimization/trainIds.csv"
numIds 		= Get number of rows
fileBase$   = dir$ + "optimization/results-I50/results-"

# Loop over all settings
for setting to numSettings
	if setting >= start and setting < end
		# Output file
		log$ 		= fileBase$ + string$(setting) + ".csv"
		header$ 	= "id,doubleNuclei,missingNuclei,emptyNuclei,numSyllables,numPeaks"
		writeFileLine: log$, header$
		
		select settings
		maxSmoothingDip		= Get value: setting, "maxSmoothingDip"
		minDipBefore		= Get value: setting, "minDipBefore"
		minDipAfter			= Get value: setting, "minDipAfter"
		silenceThreshold	= Get value: setting, "silenceThreshold"
		minPause			= Get value: setting, "minPause"
		
		# Evaluate all training samples
		for row to numIds
			select trainIds
			id$ 	= Get value: row, "stimulus_id"

			if fileReadable(dir$ + "sounds/stimuli/" + id$ + ".wav")

				sound 	= Read from file: dir$ + "sounds/stimuli/" + id$ + ".wav"
				
				#appendInfoLine: "Working on ", id$
				@GetNucleiSmooth: sound, maxSmoothingDip, minDipBefore, minDipAfter, silenceThreshold, minPause, 0
				
				# Create a textgrid with tier 1: syllables, 2: nuclei
				textgrid = selected("TextGrid")
				annotation 	= Read from file: dir$ + "data/pitches/" + id$ + ".TextGrid"
				syllables = Extract one tier: 1

				select textgrid
				Set tier name: 1, "New nuclei"
				nuclei = Extract one tier: 1

				# Create a textgrid with tier 1: syllables, 2: nuclei
				selectObject: syllables, nuclei
				newTextgrid = Merge

				@DumpAnalysis: newTextgrid, id$, log$

				selectObject: textgrid, nuclei, annotation, syllables, sound, newTextgrid
				Remove
			else
				writeFileLine: "log.txt", "Stimulus file could not be found, skipping "+id$
			endif
		endfor
	endif
endfor

selectObject: settings, trainIds
Remove