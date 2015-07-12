# karalog
Aegisub KFX library

# Usage
Intended usage is loading into the karatemplater with a line like

    ln = _G.require "ln.kara" ln.init(tenv)

The variable ln will now be a table that contains the following functions:

# Functions

    init(tenv_in)

Takes the tenv variable from the karaoke templater, to allow the library to directly read the current line and syllable and other such things.


    line.tags(list)
 
Returns a string containing the first match found in the currently processed line for each of the tags listed in the list given as an argument. You can also call this with just a string defining one tag.


    line.c(n)
 
Returns a string containing either the color from the matching color tag in the line, or if that's not possible, the style's default color. n can be 1, 2, 3 or 4. Calling the function without a variable returns color 1.


    line.a(n)
 
Same as c(n), but for alpha.


    line.style_c(n)
    line.style_a(n)
 
Same as the two above functions, but these just always give the style's default color.