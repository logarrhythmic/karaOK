# karalog
Aegisub KFX library

# Usage
Intended usage is loading into the karatemplater with a line like

    ln = _G.require "ln.kara" ln.init(tenv)

The variable ln will now be a table that contains the following functions:

# Functions

    ln.init(tenv_in)

Takes the tenv variable from the karaoke templater, to allow the library to directly read the current line and syllable and other such things.


    ln.line.tag(list)
 
Returns a string containing the first match found in the currently processed line for each of the tags listed in the list given as an argument. You can also call this with just a string defining one tag.


    ln.line.tags(list)
 
Same as above, but returns all matches for each tag. Useful for transforms.


    ln.line.c(n)
 
Returns a string containing either the color from the matching color tag in the line, or if that's not possible, the style's default color. n can be 1, 2, 3 or 4. Calling the function without an argument returns color 1.


    ln.line.a(n)
 
Same as c(n), but for alpha.


    ln.line.style_c(n)
    ln.line.style_a(n)
 
Same as the two above functions, but these just always give the style's default color.


    ln.tag.pos(alignment, anchorpoint, xoffset, yoffset, line_kara_mode)

Creates \an and \pos tags. Calling this without arguments will set \an to whatever is the style default, and set the position to where the text would normally be. Works 100% with pre-line, syl and char templates. For line templates, you want to set line_kara_mode to true to avoid having this create a pos tag for every single syllable. alignment is what this sets the \an tag to, anchorpoint is the alignment point the position is calculated by, and the offset values offset the position from the calculated position.

    ln.tag.move(xoff1, yoff1, time0, time1, alignment, anchorpoint, xoff0, yoff0, line_kara_mode)
	
Creates \an and \move tags. Calling this with only xoff1 and yoff1 defined will set \an to whatever is the style default, set the starting to where the text would normally be, and set the final position to that plus the offsets. The time arguments are the times put in the \move tag and work as you'd expect. Leaving them blank means they're not put in the tag. Works 100% with pre-line, syl and char templates. For line templates, you want to set line_kara_mode to true to avoid having this create a pos tag for every single syllable. alignment is what this sets the \an tag to, anchorpoint is the alignment point the position is calculated by, and the offset values offset the position from the calculated position.


    ln.color.byRGB(r,g,b)

Creates an ASS color value string for override tags. r, g and b are red, green and blue values between 0 and 255.


    ln.color.byHSL(h,s,l)

Creates an ASS color value string for override tags. h, s and l are hue, saturation and lightness values between 0 and 255.