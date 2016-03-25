##
# Concatenates 
procedure Concat .blank .name$
   
   .sound   = selected("Sound")
   
   select .blank
   .blank1  = Copy: "blank1"
   
   select .sound
   .soundTmp = Copy: "soundTmp"

   select .blank
   .blank2 = Copy: "blank2"


   plus .blank1
   plus .sndTemp
   .concatenation = Concatenate
   Rename: .name$

   select .blank1
   plus .blank2
   plus .sndTemp
   Remove

   select .concatenation

endproc