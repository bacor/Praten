##
# Manipulate the pitch of a section of a sound object.
# Note that it actually changes the original sound object!
#
# @param sound  sound object 
# @param start  float   Starting of the interval (s) that will be manipulated
# @param end    float   End of the interval (s)
# @param newPitch   integer Target pitch
# @param timeStep   float   Timestep used in the manipulation
#
procedure ManipulatePitch: .sound, .start, .end, .newPitch, .timeStep

    # Select/create sound, extraction, manipulation and pitch objects
    select .sound
    .name$      = selected$("Sound")
    .extract    = Extract part: .start, .end, "rectangular", 1, "no"
    .manipulation = To Manipulation: .timeStep, 75, 600
    .pitch      = Extract pitch tier

    # Replace pitch points with new pitch
    .numPoints  = Get number of points
    for .i to .numPoints
        .value  = Get value at index: .i
        .time   = Get time from index: .i
        Remove point: .i
        Add point: .time, .newPitch
    endfor

    # Get resynthesis and change original sound
    plus .manipulation
    Replace pitch tier
    select .manipulation
    .resynth = Get resynthesis (overlap-add)
    Rename: "resynth"
    select .sound
    Formula (part): .start, .end, 1, 1, "Sound_resynth(x-.start)"

    # Clean up
    selectObject: .extract, .pitch, .manipulation, .resynth
    Remove

endproc