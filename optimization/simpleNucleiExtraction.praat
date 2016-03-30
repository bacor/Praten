include ~/GitHub Projects/Praten/procedures/GetNuclei_Original.praat
include ~/GitHub Projects/Praten/procedures/GetNucleiSmooth.praat

soundName$ = selected$("Sound")
sound = selected("Sound")
@GetNuclei_Original: sound, 4, -25, 0.3
textgrid = selected("TextGrid")

select sound
@GetNucleiSmooth: sound, 4, 1.8, 0.2, -25, 0.3, 0
textgridSmooth = selected("TextGrid")

plus textgrid
mergedTextgrid = Merge
Rename: soundName$
Remove tier: 2
plus sound
View & Edit

selectObject: textgrid, textgridSmooth
Remove
