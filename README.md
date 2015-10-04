# karalog
Aegisub KFX library

# Usage
Intended usage is loading into the karatemplater with a line like

    ln = _G.require "ln.kara" ln.init(tenv)

The variable ln will now be a table that contains the following functions:

# Functions

    ln.init(tenv_in)

Takes the tenv variable from the karaoke templater, to allow the library to directly read the current line and syllable and other such things.


    ln.chari()

Returns the current character index, works on char templates too.


    ln.syltime(p)

Returns syl.start_time + syl.duration*p, or syl.start_time if p is not provided.

## line table - info about the line and tags within it

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


    ln.line.buffers(startmin, endmin)
 
Returns 2 values, the length of empty syllables at the start and end of the line. If these are smaller than startmin/endmin, startmin/endmin is returned instead. Useful for fade effects and the like.


	ln.line.len_stripped()
	ln.line.len()
	ln.line.len_raw()
	
Each returns the unicode character length of line.text_stripped, line.text and line.text_raw respectively. Pointless unless you have kanji in your kara.

## tag table - tag generation and handling

    ln.tag.pos(alignment, anchorpoint, xoffset, yoffset, line_kara_mode)

Creates \an and \pos tags. Calling this without arguments will set \an to whatever is the style default, and set the position to where the text would normally be. Works 100% with pre-line, syl and char templates. For line templates, you want to set line_kara_mode to true to avoid having this create a pos tag for every single syllable. alignment is what this sets the \an tag to, anchorpoint is the alignment point the position is calculated by, and the offset values offset the position from the calculated position.


    ln.tag.move(xoff1, yoff1, time0, time1, alignment, anchorpoint, xoff0, yoff0, line_kara_mode)
	
Creates \an and \move tags. Calling this with only xoff1 and yoff1 defined will set \an to whatever is the style default, set the starting to where the text would normally be, and set the final position to that plus the offsets. The time arguments are the times put in the \move tag and work as you'd expect. Leaving them blank means they're not put in the tag. Works 100% with pre-line, syl and char templates. For line templates, you want to set line_kara_mode to true to avoid having this create a pos tag for every single syllable. alignment is what this sets the \an tag to, anchorpoint is the alignment point the position is calculated by, and the offset values offset the position from the calculated position.

	
	ln.tag.t(a1, a2, a3, a4)
	
Creates a transform tag, works exactly like simply writing out the transform tag in the templater like \(!a1!,!a2!,!a3!,!a4!) - except it rounds the times to a sane precision. Putting in fewer variables works the same way as a transform tag too. Useful because you don't have to write as many exclamation points.


	ln.tag.parse_transform(tag)
	
Returns the start time, end time, acceleration and transformed tags of a transform tag.


	ln.tag.mod_transform(tag, starttime_mod, endtime_mod, accel_mod, tags_mod)
	
Makes changes to a transform tag and returns it. 
starttime_mod, endtime_mod and accel_mod are strings that work like this:
	<symbol><number>
Symbol can be -, + or =. + and - add the number to and substract the number from the original value. = sets the value to the number, and so does just inputting a number without a prefix.
tag_mod works like this:
	<symbol><string>
Symbol can once again be -, + or =. + adds the string to the tag string, - deletes all instances of the string from the tag string, and = or no prefix sets the tag string.


## color table - fancy fairy magic

    ln.color.byRGB(r,g,b)

Creates an ASS color value string for override tags. r, g and b are red, green and blue values between 0 and 255.


    ln.color.byHSL(h,s,l)

Creates an ASS color value string for override tags. h, s and l are hue, saturation and lightness values between 0 and 255. The values are in this range to be consistent with Aegisub's color picker.


    ln.color.lumaHSL(h,s,l)

Creates an ASS color value string for override tags. h, s and l are hue, saturation and luma values between 0 and 255. The values are in this range to be consistent with Aegisub's color picker.
This differs from the normal HSL function by preserving perceived brightness of the color between different hues. The human eye sees green as much brighter than blue, for example. TV.709 values are used.


    ln.color.rgb.get(string)
	ln.color.rgb.add(string,r,g,b)
	ln.color.hsl.get(string)
	ln.color.hsl.add(string,h,s,l)
	
These return either the three RGB or HSL values, and the add functions add the values you give to the numbers that are returned. HSL handles hue correctly, all values are kept within the 0-255 limits.

## math table

	ln.math.clamp(value, min, max)

Returns min if value is below min, max if value is over max, or value otherwise. Useful for keeping a value within bounds.


	ln.math.modloop(value, min, max)

Returns a value that has been moved to the specified range by substracting or adding the range's width to it enough times - for example 5.6,0,1 would return 5.6-5x1=0.6, and 7,40,52 would return 7+3x12=43. As a more practical example, modloop(789,-180,180) will get you 69 which can be used to keep angles in a nice range.