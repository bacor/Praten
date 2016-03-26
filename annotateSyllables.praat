## TO Done
# Move textgrid intervals to nearest zero crossing


## SETTINGS, OVERRIDEN BY FORM!

# # Directory that contains the stimuli sound files
# stimuliDirectory$ 	= "sounds/stimuli/"

# # Directory to write textgrid files to
# targetDirectory$ 	= "data/pitches/"

# # A tab separated file that contains data of all stimuli
# # It should contain the columns `stimulus_id`, `stimulus_filename`
# # and `stimulus_fulltext`
# stimuliDataFile$	= "data/simple_stimuli.csv"

# # Skip stimuli for which `stimulusId.TextGrid` exists in this folder
# # defaults to the target directory `(* target *)`
# skipFilesInDir$		= "*target*"

# # Filter for one language only
# lang$				= "EN"

# # Limit the number of stimuli shown
# limit 				= 50

# # Always create a new directory?
# forceNewDir			= 0

# The minimum duration a stimulus must have
minStimulusDur 		= 0.01 	

# File to log messages/errors to
log$ 				= "log.txt"
clearLog			= 1

# # Remove the sound and textgrid objects?
# removeSoundTextGrid = 0

# # OS dependent directory separator
# sep$				= "/" 



# Form for global script parameters
form Counting Syllables in Sound Utterances
	sentence Stimuli_directory sounds/stimuli
	sentence Target_directory data/pitches
	sentence Stimuli_data_file data/simple_stimuli.csv
	word Language EN
	integer Number_of_stimuli_to_rank 0 (= all)
	comment Advanced settings
	comment 
	sentence Skip_stimuli_in_directory *target*
	word Directory_seperator /
	boolean Force_new_target_directy 0
	boolean Remove_all_objects 1
endform

stimuliDirectory$ 	= stimuli_directory$
targetDirectory$ 	= target_directory$
stimuliDataFile$	= stimuli_data_file$
skipFilesInDir$		= skip_stimuli_in_directory$
lang$				= language$
limit 				= number_of_stimuli_to_rank
forceNewDir			= force_new_target_directy
removeSoundTextGrid = remove_all_objects
sep$				= directory_seperator$


#####################################################################
#####################################################################
#####################################################################

## INITIALIZE
# 

# If the target diretory exists, add a unique integer to get e.g. "target-4/"
if not fileReadable(targetDirectory$)
	createDirectory: targetDirectory$
elsif forceNewDir
	dirName$ 		= targetDirectory$ - $sep
	newDir$ 		= dirName$ + "-1"
	i 				= 1
	while fileReadable(newDir$) and i < 5
		newDir$		= dirName$ + "-" + string$ (i)
		i 			+= 1
	endwhile
	createDirectory: newDir$
	targetDirectory$ = newDir$
endif

# Defaults
if limit = 0
	limit = 99999
endif
skipFilesInDir$ 	= replace$(skipFilesInDir$, "*target*", targetDirectory$, 1)

# Add final slashes to directories
if skipFilesInDir$ <> ""
	skipFilesInDir$ = skipFilesInDir$ - sep$ + sep$
endif 
targetDirectory$ 	= targetDirectory$ - sep$ + sep$
stimuliDirectory$ 	= stimuliDirectory$ - sep$ + sep$

# Load stimuli data
allStimuli 			= Read Table from tab-separated file: stimuliDataFile$
stimuli				= Extract rows where column (text): "lang", "is equal to", lang$
select allStimuli
Remove


## WRITE LOG HEADER
#

line$ = ""
for i to 60
	line$ = line$ + "*"
endfor

if clearLog
	writeFileLine: log$, line$
else
	appendFileLine: log$, newline$, newline$, line$
endif
appendFileLine: log$, "* SYLLABLE ANNOTATIION ", newline$, "*"
appendFileLine: log$, "* Date & time:       ", date$()
appendFileLine: log$, "* Language:          ", lang$
appendFileLine: log$, "* Minimum duration:  ", string$(minStimulusDur), "s"
appendFileLine: log$, "* Stimuli data:      ", stimuliDataFile$
appendFileLine: log$, "* Stimuli directory: ", stimuliDirectory$
appendFileLine: log$, "* Target directory:  ", targetDirectory$
appendFileLine: log$, "* Skip files in:     ", skipFilesInDir$
appendFileLine: log$, line$, newline$

# Count errors
numErrors = 0

## LOOP OVER STIMULI
#

select stimuli
numberOfStimuli 	= Get number of rows
numberAdjusted 		= 0
for i to numberOfStimuli
	if numberAdjusted < limit 

		select stimuli
		stimulusId$		= Get value: i, "stimulus_id"
		fullText$ 		= Get value: i, "stimulus_fulltext"
		fileName$ 		= Get value: i, "stimulus_filename"	
		fileLoc$		= stimuliDirectory$ + fileName$

		textGridName$ 	= stimulusId$ + ".TextGrid"
		textGridFile$ 	= targetDirectory$ + textGridName$

		if fileReadable( skipFilesInDir$ + textGridName$)
			@LogMessage: stimulusId$, "Skipping..."

		elsif fileReadable (fileLoc$)
			sound 			= Read from file: fileLoc$
			soundDur 		= Get total duration
			
			if soundDur > minStimulusDur

				pitch 		= To Pitch (ac): 0.02, 75, 15, "no", 0.03, 0.45, 0.01, 0.35, 0.14, 600
				select sound
				intensity 	= To Intensity: 50, 0, "yes"

				# Get all nuclei
				@GetNuclei: sound, pitch, intensity, undefined, 2, undefined
				textgrid 	= selected("TextGrid")

				# Estimate the syllables from the nuclei
				@NucleiToSyllables: sound, textgrid, pitch, intensity

				# Back up the nuclei and automatically detected syllable boundaries
				select textgrid 
				Rename: stimulusId$
				autoSyllables = Extract one tier: 1
				Set tier name: 1, "auto syllables"

				select textgrid 
				nuclei = Extract one tier: 2
	 			select textgrid 
	 			Remove tier: 2

				# Insert a tier with the fulltext
				Insert interval tier: 2, "fulltext"
				Set interval text: 2, 1, fullText$

				selectObject: sound, textgrid
				View & Edit

				beginPause: "Adjust syllable boundaries"
				    comment: "Adjust the syllable boundaries of stimulus "+stimulusId$
				    comment: "Note: Valid syllables should contain some text (anything but nothing)"
				    comment: "Please do not change other objects"
				endPause: "Continue with the next stimulus", 1

				# Insert the original syllable boundaries and save
				selectObject: textgrid, nuclei, autoSyllables
				newTextgrid = Merge
				Rename: stimulusId$
				Save as text file: textGridFile$
				@LogMessage: stimulusId$, "Pitch file stored: " + textGridFile$

				numberAdjusted += 1

				# Clean up
				selectObject: autoSyllables, nuclei, pitch, intensity, textgrid
				if removeSoundTextGrid
					plus sound
					plus newTextgrid
				endif
				Remove

			else 
				@LogError: stimulusId$, "Stimulus too short: " + string$('soundDur:4') +"s"
			endif

		else 
			@LogError: stimulusId$, "Stimulus file not readable: " + fileLoc$
		endif

	endif
endfor

beginPause: "Done"
    comment: "Done! You have checked " + string$(numberAdjusted) + " stimuli"
    if numErrors > 0
    	comment: "Check the log: " + string$(numErrors) + " errors occured"
    endif
endPause: "Finish", 1

# Clean up
selectObject: stimuli
Remove

appendFileLine: log$, newline$, "** " + string$(numErrors) + " errors occured"+newline$


#####################################################################
#####################################################################
#####################################################################


include procedures/NucleiToSyllables.praat
include procedures/GetNuclei.praat

procedure LogError: .stimulusId$, .message$
	appendFileLine: log$, "*  ", .stimulusId$, tab$, .message$
	numErrors += 1
endproc

procedure LogMessage: .stimulusId$, .message$
	appendFileLine: log$, "   ", .stimulusId$, tab$, .message$
endproc