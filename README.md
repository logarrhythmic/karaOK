# karaOK
Normal Aegisub kara templater usage: messy code written across dozens of template and code lines without linebreaks

Usage with karaOK: same horribly messy templates but at least there's less of it

Basically, you probably want to use this only as an example of how to start making your own external libraries for use with the Aegisub karaoke templater, but do whatever you feel like. There's some useful stuff here if you can make any sense of my garbage code

# Usage
Intended usage is loading into the karatemplater with a `code once` line like

    ln = _G.require "ln.kara"; ln.init(tenv)

The variable ```ln``` will now be a table that contains the following functions:

# Functions

**General usage note: Arguments can be left out by passing `nil` in their place, or by passing fewer than the full number of arguments to leave arguments out at the end of the list.**

Note: parts of this will be out of date or outright incorrect. I'm no longer using any of this actively, so tell me if you need something fixed.

---

    ln.init(tenv_in)

Takes the ```tenv``` variable from the karaoke templater, to allow the library to directly read the current line and syllable and other such things. Also sets shorthands for a few functions. For example, instead of using ```!ln.syltime(0.3)!``` you can use ```!st(0.3)!```. **This should be called in a `code once` line right after `ln = _G.require "ln.kara"` to ensure that functions work properly.** 

---

    shorthand only: set(var, val)
    
Sets variable ```var``` in the templater environment to value ```val```.

---

    ln.randomize(variable_name, min, max, override)
    shorthand: rset(variable_name, min, max, override)
    
If a variable by ```variable_name``` doesn't already exist in the environment, or if ```override``` is true, sets variable ```variable_name``` to ```math.random(min, max)```.

---

    ln.chari() -> number
    shorthand: ci() -> number

Returns the current character index, works on char templates too.

---

    ln.syltime(p) -> number
    shorthand: st(p) -> number

Returns ```syl.start_time + syl.duration*p```, or ```syl.start_time``` if ```p``` is not provided.

---

    ln.syldur(p) -> number
    shorthand: sd(p) -> number

Returns ```syl.duration*p```, or ```syl.duration``` if ```p``` is not provided.

## line table - info about the line and tags within it

    ln.line.tag(list) -> string
 
Returns a string containing the first match found in the currently processed line for each of the tags listed in the list given as an argument. You can also call this with just a string defining one tag.

---

    ln.line.tags(list) -> string
 
Same as above, but returns all matches for each tag. Useful for transforms.

---

    ln.line.c(n) -> string
    shorthand: gc(n) -> string
 
Returns a string containing either the color from the matching color tag in the line, or if that's not possible, the style's default color. ```n``` can be 1, 2, 3 or 4. Calling the function without an argument returns color 1.

---

    ln.line.a(n) -> string
    shorthand: ga(n) -> string
 
Same as ```c(n)```, but for alpha.

---

    ln.line.style_c(n) -> string
    ln.line.style_a(n) -> string
 
Same as the two above functions, but these just always give the style's default color.

---

    ln.line.buffers(startmin_k, endmin_k, startmin_fad, endmin_fad) -> number, number
    ln.line.buffers(startmin, endmin) -> number, number
 
Returns durations for fade-in and fade-out effects. There are 2 ways this function can work.
1. If there is a \fad tag present in the source line, this will return the values in that \fad tag. If these are smaller than `startmin_fad`/`endmin_fad`, `startmin_fad`/`endmin_fad` is returned instead.
2. Otherwise, this will take the length of empty syllables at the start and end of the line. If these are smaller than `startmin_k`/`endmin_k`, `startmin_k`/`endmin_k` is returned instead.

If only 2 parameters are provided, they will be used in both of the above cases.

---

    ln.line.len_stripped() -> number
    ln.line.len() -> number
    ln.line.len_raw() -> number
	
Each returns the unicode character length of ```line.text_stripped```, ```line.text``` and ```line.text_raw``` respectively. Necessary if you have kanji in your kara.

## tag table - tag generation and handling

    ln.tag.pos(alignment, anchorpoint, xoffset, yoffset, line_kara_mode) -> string
    ln.tag.pos(table) -> string

Creates \an and \pos tags. 

Calling this without arguments will set \an to whatever is the style default, and set the position to where the text would normally be. This is useful for syl/char templates.

`alignment` is what this sets the \an tag to. Defaults to the alignment defined in the line's style.\
`anchorpoint` defines the alignment value used for calculating the base position. Defaults to the same as the `alignment` argument, or the alignment defined in the line's style. For example, `anchorpoint=3` will calculate the bottom right of the text as the base position.\
`xoffset` and `yoffset` are offsets applied to the default position of the text.\
`line_kara_mode` should be true when using this with a *line* template, to tell the function to only generate one move tag at the start of the line.

If a table is passed as the first argument, all arguments will be read from there. The table should have keys named after the arguments here. These arguments have shorter or more easily understandable aliases that will also work:\
`xoffset`: `offset_x`\
`yoffset`: `offset_y`

---

    ln.tag.move(xoff0, yoff0, xoff1, yoff1, time0, time1, alignment, anchorpoint, line_kara_mode) -> string
    ln.tag.move(table) -> string
	
Creates \an and \move tags. 

`xoff0`, `yoff0`, `xoff1` and `yoff1` are offsets applied to the default position of the text.\
`xoff0` and `yoff0` define the starting position of the move. They default to 0 if not set.\
`xoff1` and `yoff1` define the ending position of the move. They default to 0 if not set.\
`time0` and `time1` are the times put in the \move tag and work as you'd expect. Leaving these arguments out will also leave them out of the tag, causing the move to occur over the whole duration of the line.\
`alignment` is what this sets the \an tag to. Defaults to the alignment defined in the line's style.\
`anchorpoint` defines the alignment value used for calculating the base position. Defaults to the same as the `alignment` argument, or the alignment defined in the line's style. For example, `anchorpoint=3` will calculate the bottom right of the text as the base position.\
`line_kara_mode` should be true when using this with a *line* template, to tell the function to only generate one move tag at the start of the line.

If a table is passed as the first argument, all arguments will be read from there. The table should have keys named after the arguments here. These arguments have shorter or more easily understandable aliases that will also work:\
`xoff0`: `x_start`, `x0`\
`yoff0`: `y_start`, `y0`\
`xoff1`: `x_end`, `x1`\
`yoff1`: `y_end`, `y1`

---
	
	ln.tag.t(a1, a2, a3, a4) -> string
	
Creates a transform tag, works exactly like simply writing out the transform tag in the templater like ```\t(!a1!,!a2!,!a3!,!a4!)``` - except it rounds the times to a sane precision. Putting in fewer variables works the same way as a transform tag too. Useful because you don't have to write as many exclamation points.

---

	ln.tag.parse_transform(tag) -> number, number, number, string
	
Returns the start time, end time, acceleration and transformed tags of a transform tag.

---

	ln.tag.mod_transform(tag, starttime_mod, endtime_mod, accel_mod, tags_mod) -> string
	
Makes changes to a transform tag and returns it. 
```starttime_mod```, ```endtime_mod``` and ```accel_mod``` are strings that work like this:
	"<symbol><number>"
```symbol``` can be -, + or =. + and - add ```number``` to and substract ```number``` from the original value. = sets the value to ```number```, and so does just inputting a number without a prefix.
tag_mod works like this:
	"<symbol><string>"
```symbol``` can once again be -, + or =. + adds ```string``` to the tag string, - deletes all instances of ```string``` from the tag string, and = or no prefix sets the tag string to ```string```.

## wave table - pushing the limits of ASS

Arguably the most advanced part of the library so far. Useful for shaking text, "floating" text and who knows what else. Can make pretty convincing sine waves without going completely frame-by-frame.


	waveX = ln.wave.new()

Creates a new table to store the wave function you're creating.

---

	waveX.addWave(waveform, wavelength, amplitude, phase)

Adds an elementary waveform or white noise to the wave function. 

```waveform``` can be any of: ```"noise"```/```"random"```, ```"sine"```, ```"square"```, ```"triangle"``` and ```"sawtooth"```. If you don't know what these waves look like, google them.

```wavelength``` is the length of one period in milliseconds. The white noise is periodic too. If you want more random noise, see the next function and use a math.random() there.

```amplitude``` is the amplitude of the waveform. ```1```, for example, will get you a maximum value of ```1``` and a minimum value of ```-1```. Defaults to 1 if left out.

```phase``` is the phase shift, in periods, applied to the waveform. Negative values will delay the waveform, positive values will do the opposite. For noise, this value instead seeds the random number generator. Defaults to 0 if left out.

---

	waveX.addFunction(func)
	
Adds a user defined function to the wave function. ```func``` must be a function that takes a single value, time.

Example: ```!waveX.addFunction(function(t) return _G.math.random()*2-1 end)!``` will work as noise. ```!waveX.addFunction(function(t) return t*t end)!``` will make an upwards-opening parabola.

---

	waveX.getValue(time) -> number
	
Gets the value of the wave function at ```time```.

---

	ln.wave.transform(wave, tags, starttime, endtime, delay, framestep, jumpToStartingPosition, dutyCycle) -> string
	
Creates a set of transforms according to a wave function.

```wave``` is a wave table created as shown above.

```tags``` is a table of strings that are the aegisub override tags to animate, for example ```{"fscx", "fscy"}```. A single string will work too, it converts it to a list automatically and carries on. Color tags, font changes and other tags that take string values are generally not supported for obvious reasons, but alpha tags are. I might add color support at a later point in time, for animated rainbows and other silly stuff.

```tags``` can *also* be a list of string and function pairs, such as ```{{"fscx", function(x) return -x end}, {"fscy", function(x) return x*x end}}```. If functions are passed along with the tag strings, they will transform the value received from the waveform at each point in time. Useful for using the same waveform on several different tags, such as scale and shear at the same time - one takes values around 100 and the other around 0. 

```starttime``` is the time to start animating (relative to line start, like with transform tags). Can be left empty/nil to default to line start.

```endtime``` is the time to end animating (relative to line start, like with transform tags). Can be left empty/nil to default to line end.

```delay``` is a time value in milliseconds that the waveform is delayed by. Can be left empty/nil to default to 0.

```framestep``` is the time in frames (assuming 23.976 fps) between generated transform tags' start times. 1 will result in the animation following the waveform exactly at normal framerates, for 60fps playback you could use 0.4 and that would work too, and sine waves still look pretty convincing with values up to 3 thanks to some creative use of the acceleration value in transform tags. If left empty/nil, defaults to 2.

```jumpToStartingPosition``` is a boolean value. If true, the function will generate an instant (technically 1ms) transform at ```starttime``` to jump the affected values to the correct number instantly. Without this it'll blend in a bit smoother, but might look bad in some cases. If left empty/nil, defaults to true.

```dutyCycle``` is a number value between 0 and 1 that dictates how much of each step the transform is active. With 1, ```framestep``` values above 1 will animate smoothly, and with values near 0 they will jump to the given value near-instantly - in conjunction with a larger framestep this might be useful if you want to emulate a lower framerate to match things that are animated every second or third frame. If left empty/nil, defaults to 1.

Example of use (run on an \an5 line):

	code: waveS = ln.wave.new(); waveC = ln.wave.new();
	code: waveS.addWave("sine", 1000, 40, 0); waveC.addWave("sine", 1000, 40, 0.25)
	template: {\4c&H0000FF&\pos($x,$y)!ln.wave.transform(waveC, "xshad", nil, nil, 0, 3)!!ln.wave.transform(waveS, "yshad", nil, nil, 0, 3)!} {this will be jerky due to the default dutyCycle of 0.2}
	template: {\4c&H00FFFF&\pos($x,$y)!ln.wave.transform(waveC, "xshad", nil, nil, 0, 3, false, nil, 1)!!ln.wave.transform(waveS, "yshad", nil, nil, 0, 3, false, nil, 1)!} {this will be smooth but not an exact circle}
	template: {\4c&H00FF00&\pos($x,$y)!ln.wave.transform(waveC, "xshad", nil, nil, 0, 1, false, nil, 1)!!ln.wave.transform(waveS, "yshad", nil, nil, 0, 1, false, nil, 1)!} {this will be smooth and closer to an exact circle, pretty much perfect on ~24fps}

Try out lower ```framestep``` values on the second template line and see what happens. High values seem to make the shadow jump around on the circle, and even 3 still jumps around a tiny bit when used for going in circles like this, but 2 starts to look really convincing.

## color table - fancy fairy magic

    ln.color.byRGB(r,g,b) -> string
    shorthand: rgb(r,g,b) -> string

Creates an ASS color value string for override tags. r, g and b are red, green and blue values between 0 and 255.

---

    ln.color.byHSL(h,s,l) -> string
    shorthand: hsl(h,s,l) -> string

Creates an ASS color value string for override tags. h, s and l are hue, saturation and lightness values between 0 and 255. The values are in this range to be consistent with Aegisub's color picker.

---

    ln.color.lumaHSL(h,s,y) -> string
    shorthand: hsy(h,s,y) -> string

Creates an ASS color value string for override tags. h, s and y are hue, saturation and luma values between 0 and 255. The values are in this range to be consistent with Aegisub's color picker.

This differs from the normal HSL function by preserving perceived brightness of the color between different hues. The human eye sees green as much brighter than blue, for example. TV.709 values are used.

---

    ln.color.rgb.get(string) -> number, number, number
    ln.color.rgb.add(string,r,g,b) -> number, number, number
    ln.color.hsl.get(string) -> number, number, number
    ln.color.hsl.add(string,h,s,l) -> number, number, number
	
These return either the three RGB or HSL values, and the add functions add the values you give to the numbers that are returned. HSL handles hue correctly, all values are kept within the 0-255 limits.

## math table

	ln.math.clamp(value, min, max) -> number
	shorthand: clamp(value, min, max) -> number

Returns min if value is below min, max if value is over max, or value otherwise. Useful for keeping a value within bounds.

---

	ln.math.modloop(value, min, max) -> number

Returns a value that has been moved to the specified range by substracting or adding the range's width to it enough times - for example 5.6,0,1 would return 5.6-5x1=0.6, and 7,40,52 would return 7+3x12=43. As a more practical example, modloop(789,-180,180) will get you 69 which can be used to keep angles in a nice range.

---

	ln.math.modbounce(value, min, max) -> number

Works like modloop, but every second pass over the range is mirrored so that if value is allowed to rise indefinitely, the curve for that would trace a triangle wave pattern. I used this for limiting hues in gradients.

---

	ln.math.log(base, n) -> number

Calculates ```base```-based logarithm for ```n```.

---

	ln.math.sgn(n) -> number

Returns -1 for negative numbers ```n``` and 1 otherwise.

---

	Additional shorthands:
	rnd(...) for math.random(...)
	fl(n) for math.floor(n)

# Modified karatemplater

	--[[
	 List of unauthorized unofficial modifications by logarithm:
	  - gave the execution environment access to the subtitles object
	  - made notext and noblank modifiers work with pre-line templates and non-k-timed lines like they do with other template types(maybe some other stuff too)
	  - added variable ci, available with by-char templates, which tells which letter of the current syllable is being processed
	  - increased inline variable positioning precision to .1 pixel
	  - added option to generate kfx without generating furigana styles
	  - calling maxloop() with something below the current j will abort outputting the current template line
	  - redid line, preline, syl and other such keywords: pre-line is now just line, old line is now lsyl, and lword/lchar are like lsyl for words and chars. char and word also work with code lines
	  - added 'style' modifier which works kind of like fxgroup: for example templates with 'style romaji' are run on only lines with "romaji" in the style name. Intended for use with the 'all' keyword
	 ]]
