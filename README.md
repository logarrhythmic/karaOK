
1. [KFX Library](#part-b-the-karaoke-utility-library-karaok)
   	- [How to use](#usage)
   	- [Functions](#functions)
		- [Basic functions](#root-namespace)
		- [Line information](#line-namespace)
		- [Tag generation and manipulation](#tag-namespace)
		- [Wave functions that can be mapped to transforms](#wave-namespace)
		- [Color generation and manipulation](#color-namespace)
		- [Extra math](#math-namespace)
		- [Vector shape generation](#shapes-namespace)
2. [Templater Mod (feature frozen)](#part-a-the-modified-templater)
	- [Keyword changes](#keyword-changes-most-important-partially-breaking)
	- [Different splitting of the line](#line-splitting)
	- [per-word and per-char code sections](#code-wordchar)
	- [style keyword to apply to lines with any matching style](#style-modifier-keyword)
	- [character index variable](#character-index-variable-ci)
	- [less restrictive template execution environment](#expanded-tenv)
	- [notext and noblank keyword fixes](#notext-and-noblank-work-with-all-template-types)
	- [line.text is not destroyed by the templater](#linetext-works-properly-now)
	- [inline dollar variables get one decimal of extra precision](#sub-pixel-inline-variables)
	- [menu entry to run without creating furigana styles](#generate-without-furigana)
	- [maxloop(0) now makes the template run 0 times](#maxloop-power-boost)

# Part A: the karaoke utility library, karaOK
## Usage
Intended usage is loading into the karatemplater with a `code once` line like

    ln = _G.require "ln.kara"; ln.init(tenv)

The variable ```ln``` will now be a table that contains the following functions:

## Functions

**General usage note: Arguments can be left out by passing `nil` in their place, or by passing fewer than the full number of arguments to leave arguments out at the end of the list.**

Note: parts of this will be out of date or outright incorrect. I'm no longer using any of this actively, so tell me if you need something fixed.

### root namespace

#### `init(...)`
    ln.init(tenv_in)

Takes the ```tenv``` variable from the karaoke templater, to allow the library to directly read the current line and syllable and other such things. Also sets shorthands for a few functions. For example, instead of using ```!ln.syltime(0.3)!``` you can use ```!st(0.3)!```. **This should be called in a `code once` line right after `ln = _G.require "ln.kara"` to ensure that functions work properly.** 

#### `set(...)`
    shorthand only: set(var, val)
    
Sets variable ```var``` in the templater environment to value ```val```.

#### `randomize(...) <= tenv.rset(...)`
    ln.randomize(variable_name, min, max, override)
    shorthand: rset(variable_name, min, max, override)
    
If a variable by ```variable_name``` doesn't already exist in the environment, or if ```override``` is true, sets variable ```variable_name``` to ```math.random(min, max)```.

#### `syltime(...) <= tenv.st(...)`
    ln.syltime(p) -> number
    shorthand: st(p) -> number

Returns ```syl.start_time + syl.duration*p```, or ```syl.start_time``` if ```p``` is not provided.

#### `syldur(...) <= tenv.sd(...)`
    ln.syldur(p) -> number
    shorthand: sd(p) -> number

Returns ```syl.duration*p```, or ```syl.duration``` if ```p``` is not provided.

### `line` namespace
##### (info about the line and tags within it)

#### `tag(...)`
    ln.line.tag(list) -> string
 
Returns a string containing the first match found in the currently processed line for each of the tags listed in the list given as an argument. You can also call this with just a string defining one tag.

#### `tags(...)`
    ln.line.tags(list) -> string
 
Same as above, but returns all matches for each tag. Useful for transforms.

    ln.line.tags(list, true) -> table
 
Same as above, but returns a table with each match at a separate index.

#### `c(...) <= tenv.gc(...)`
    ln.line.c(n) -> string
    shorthand: gc(n) -> string
 
Returns a string containing either the color from the matching color tag in the line, or if that's not possible, the style's default color. ```n``` can be 1, 2, 3 or 4. Calling the function without an argument returns color 1.

#### `a(...) <= tenv.ga(...)`
    ln.line.a(n) -> string
    shorthand: ga(n) -> string
 
Same as ```c(n)```, but for alpha.

#### `style_c(...) / style_a(...)`
    ln.line.style_c(n) -> string
    ln.line.style_a(n) -> string
 
Same as the two above functions, but these just always give the style's default color.

#### `buffers(...)`
    ln.line.buffers(startmin_k, endmin_k, startmin_fad, endmin_fad) -> number, number
    ln.line.buffers(startmin, endmin) -> number, number
 
Returns durations for fade-in and fade-out effects. There are 2 ways this function can work.
1. If there is a \fad tag present in the source line, this will return the values in that \fad tag. If these are smaller than `startmin_fad`/`endmin_fad`, `startmin_fad`/`endmin_fad` is returned instead.
2. Otherwise, this will take the length of empty syllables at the start and end of the line. If these are smaller than `startmin_k`/`endmin_k`, `startmin_k`/`endmin_k` is returned instead.

If only 2 parameters are provided, they will be used in both of the above cases.

#### `len_stripped() / len()`
    ln.line.len_stripped() -> number
    ln.line.len() -> number
	
Each returns the unicode character length of ```line.text_stripped``` and ```line.text``` respectively. Necessary if you have kanji in your kara.

### `tag` namespace 
##### (tag generation and handling)

#### `pos(...)`
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

#### `move(...)`
    ln.tag.move(xoff0, yoff0, xoff1, yoff1, time0, time1, alignment, anchorpoint, lsyl_mode) -> string
    ln.tag.move(table) -> string
	
Creates \an and \move tags. 

`xoff0`, `yoff0`, `xoff1` and `yoff1` are offsets applied to the default position of the text.\
`xoff0` and `yoff0` define the starting position of the move. They default to 0 if not set.\
`xoff1` and `yoff1` define the ending position of the move. They default to 0 if not set.\
`time0` and `time1` are the times put in the \move tag and work as you'd expect. Leaving these arguments out will also leave them out of the tag, causing the move to occur over the whole duration of the line.\
`alignment` is what this sets the \an tag to. Defaults to the alignment defined in the line's style.\
`anchorpoint` defines the alignment value used for calculating the base position. Defaults to the same as the `alignment` argument, or the alignment defined in the line's style. For example, `anchorpoint=3` will calculate the bottom right of the text as the base position.\
`lsyl_mode` should be true when using this with a *lsyl* (or similar) template, to tell the function to only generate one move tag at the start of the line.

If a table is passed as the first argument, all arguments will be read from there. (Like named argument in e.g. Python.) The table should have keys named after the arguments here. These arguments have shorter or more easily understandable aliases that will also work:\
`xoff0`: `x_start`, `x0`\
`yoff0`: `y_start`, `y0`\
`xoff1`: `x_end`, `x1`\
`yoff1`: `y_end`, `y1`

#### `t(...)`
	ln.tag.t(a1, a2, a3, a4) -> string
	
Creates a transform tag, works exactly like simply writing out the transform tag in the templater like ```\t(!a1!,!a2!,!a3!,!a4!)``` - except it rounds the times to a sane precision. Putting in fewer variables works the same way as a transform tag too. Useful because you don't have to write as many exclamation points.

#### `parse_transform(...)`
	ln.tag.parse_transform(tag) -> table
	
Returns a table with the start time `t0`, end time `t1`, acceleration `a` and transformed tags `tags` of a transform tag.

#### `mod_transform(...)`
	ln.tag.mod_transform(tag, starttime_mod, endtime_mod, accel_mod, tags_mod) -> string
	
Makes changes to a transform tag and returns it. 
```starttime_mod```, ```endtime_mod``` and ```accel_mod``` are strings that work like this:
	"<symbol><number>"
```symbol``` can be -, + or =. + and - add ```number``` to and substract ```number``` from the original value. = sets the value to ```number```, and so does just inputting a number without a prefix.
tag_mod works like this:
	"<symbol><string>"
```symbol``` can once again be -, + or =. + adds ```string``` to the tag string, - deletes all instances of ```string``` from the tag string, and = or no prefix sets the tag string to ```string```.

### `wave` namespace 
##### pushing the limits of ASS

Arguably the most advanced part of the library so far. Useful for shaking text, "floating" text and who knows what else. Can make pretty convincing sine waves without going completely frame-by-frame.

#### `new()` -> *waveObj*
	waveX = ln.wave.new()

Creates a new table to store the wave function you're creating.

If given parameters, immediately calls ```addWave``` with them.

#### *waveObj*`.addWave(...)`
	waveX.addWave(waveform, wavelength, amplitude, phase)

Adds an elementary waveform or white noise to the wave function. 

```waveform``` can be any of: ```"noise"```/```"random"```, ```"sine"```, ```"square"```, ```"triangle"``` and ```"sawtooth"```. If you don't know what these waves look like, google them.

```wavelength``` is the length of one period in milliseconds. The white noise is periodic too. If you want more random noise, see the next function and use a math.random() there.

```amplitude``` is the amplitude of the waveform. ```1```, for example, will get you a maximum value of ```1``` and a minimum value of ```-1```. Defaults to 1 if left out.

```phase``` is the phase shift, in periods, applied to the waveform. Negative values will delay the waveform, positive values will do the opposite. For noise, this value instead seeds the random number generator. Defaults to 0 if left out.

#### *waveObj*`.addFunction(...)`
	waveX.addFunction(func)
	
Adds a user defined function to the wave function. ```func``` must be a function that takes a single value, time.

Example: ```!waveX.addFunction(function(t) return _G.math.random()*2-1 end)!``` will work as noise. ```!waveX.addFunction(function(t) return t*t end)!``` will make an upwards-opening parabola.

#### *waveObj*`.addConstant(...)`
	waveX.addConstant(c)

Adds a constant value to the wave function. Shorthand for ```waveX.addFunction(function() return c end)```, convenient for centering alpha or colors in the 0..255 range.

#### *waveObj*`.clear()`
	waveX.clear()

Removes all previously registered waveforms/functions from the wave table.

#### *waveObj*`.clear()`
	waveX.setWave(...)
	waveX.setFunction(func)
	waveX.setConstant(c)

Clears the wave table, then adds the corresponding component.

#### *waveObj*`.getValue(...)`
	waveX.getValue(time) -> number
	
Gets the value of the wave function at ```time```.

#### *waveObj*`.transform(...)`
	ln.wave.transform(wave, tags, starttime, endtime, delay, framestep, jumpToStartingPosition, dutyCycle) -> string
	
Creates a set of transforms according to a wave function.

```wave``` is a wave table created as shown above.

```tags``` is a table of strings that are the aegisub override tags to animate, for example ```{"fscx", "fscy"}```. A single string will work too, it converts it to a list automatically and carries on. Color tags, font changes and other tags that take string values are generally not supported for obvious reasons, but alpha tags are. I might add color support at a later point in time, for animated rainbows and other silly stuff.

```tags``` can *also* be a list of string and function pairs, such as ```{{"fscx", function(x) return -x end}, {"fscy", function(x) return x*x end}}```. If functions are passed along with the tag strings, they will transform the value received from the waveform at each point in time. Useful for using the same waveform on several different tags, such as scale and shear at the same time - one takes values around 100 and the other around 0. 

```starttime``` is the time to start animating (relative to line start, like with transform tags). Can be left empty/nil to default to line start.

```endtime``` is the time to end animating (relative to line start, like with transform tags). Can be left empty/nil to default to line end.

```delay``` is a time value in milliseconds that the waveform is delayed by. Can be left empty/nil to default to 0.

```framestep``` is the time in frames (assuming 23.976 fps) between generated transform tags' start times. 1 will result in the animation following the waveform exactly at normal framerates, for 60fps playback you could use 0.4 and that would work too, and sine waves still look pretty convincing with values up to 3 thanks to some creative use of the acceleration value in transform tags. However, because ASS transforms are monotonic, if the start and end times fall on either side of a peak, the wave won't reach the peak. This is usually not a problem, unless your wavelength is significantly less than 1 second. If left empty/nil, defaults to 2.

```jumpToStartingPosition``` is a boolean value. If true, the function will generate an instant (technically 1ms) transform at ```starttime``` to jump the affected values to the correct number instantly. Without this it'll blend in a bit smoother, but might look bad in some cases. If left empty/nil, defaults to true.

```dutyCycle``` is a number value between 0 and 1 that dictates how much of each step the transform is active. With 1, ```framestep``` values above 1 will animate smoothly, and with values near 0 they will jump to the given value near-instantly - in conjunction with a larger framestep this might be useful if you want to emulate a lower framerate to match things that are animated every second or third frame. If left empty/nil, defaults to 1.

Example of use (run on an \an5 line):

	code: waveS = ln.wave.new(); waveC = ln.wave.new();
	code: waveS.addWave("sine", 1000, 40, 0); waveC.addWave("sine", 1000, 40, 0.25)
	template: {\4c&H0000FF&\pos($x,$y)!ln.wave.transform(waveC, "xshad", nil, nil, 0, 3)!!ln.wave.transform(waveS, "yshad", nil, nil, 0, 3)!} {this will be jerky due to the default dutyCycle of 0.2}
	template: {\4c&H00FFFF&\pos($x,$y)!ln.wave.transform(waveC, "xshad", nil, nil, 0, 3, false, nil, 1)!!ln.wave.transform(waveS, "yshad", nil, nil, 0, 3, false, nil, 1)!} {this will be smooth but not an exact circle}
	template: {\4c&H00FF00&\pos($x,$y)!ln.wave.transform(waveC, "xshad", nil, nil, 0, 1, false, nil, 1)!!ln.wave.transform(waveS, "yshad", nil, nil, 0, 1, false, nil, 1)!} {this will be smooth and closer to an exact circle, pretty much perfect on ~24fps}

Try out lower ```framestep``` values on the second template line and see what happens. High values seem to make the shadow jump around on the circle, and even 3 still jumps around a tiny bit when used for going in circles like this, but 2 starts to look really convincing.

### `color` namespace 
##### (fancy fairy magic)

#### `byRGB(...) <= tenv.rgb(...)`
    ln.color.byRGB(r,g,b) -> string
    shorthand: rgb(r,g,b) -> string
Creates an ASS color value string for override tags. r, g and b are red, green and blue values between 0 and 255.

#### `byHSL(...) <= tenv.hsl(...)`
    ln.color.byHSL(h,s,l) -> string
    shorthand: hsl(h,s,l) -> string
Creates an ASS color value string for override tags. h, s and l are hue, saturation and lightness values between 0 and 255. The values are in this range to be consistent with Aegisub's color picker.

#### `lumaHSL(...) <= tenv.hsy(...)`
    ln.color.lumaHSL(h,s,y) -> string
    shorthand: hsy(h,s,y) -> string
Creates an ASS color value string for override tags. h, s and y are hue, saturation and luma values between 0 and 255. The values are in this range to be consistent with Aegisub's color picker.

This differs from the normal HSL function by preserving perceived brightness of the color between different hues. The human eye sees green as much brighter than blue, for example. TV.709 values are used.

#### `rgb.get(...) / rgb.add(...) / hsl.get(...) / hsl.add(...)`
    ln.color.rgb.get(string) -> number, number, number
    ln.color.rgb.add(string,r,g,b) -> number, number, number
    ln.color.hsl.get(string) -> number, number, number
    ln.color.hsl.add(string,h,s,l) -> number, number, number
These return either the three RGB or HSL values, and the add functions add the values you give to the numbers that are returned. HSL handles hue correctly, all values are kept within the 0-255 limits.

### `math` namespace
#### `clamp(...) <= tenv.clamp(...)`
	ln.math.clamp(value, min, max) -> number
	shorthand: clamp(value, min, max) -> number
Returns min if value is below min, max if value is over max, or value otherwise. Useful for keeping a value within bounds.

#### `modloop(...)`
	ln.math.modloop(value, min, max) -> number
Returns a value that has been moved to the specified range by substracting or adding the range's width to it enough times - for example 5.6,0,1 would return 5.6-5x1=0.6, and 7,40,52 would return 7+3x12=43. As a more practical example, modloop(789,-180,180) will get you 69 which can be used to keep angles in a nice range.

#### `modbounce(...)`
	ln.math.modbounce(value, min, max) -> number
Works like modloop, but every second pass over the range is mirrored so that if `value` is allowed to rise indefinitely, the output for that would trace a triangle wave pattern. I used this for limiting hues in gradients.

#### `log(...)`
	ln.math.log(base, n) -> number
Calculates `base`-based logarithm for `n`.

#### `sgn(...)`
	ln.math.sgn(n) -> number
Returns -1 for negative inputs `n` and 1 otherwise.

#### `round(...)`
        ln.math.round(num) -> number 
        ln.math.round(num, idp) -> number 
Rounds `num` to `idp` decimal points of precision, or to integer precision if `idp` is omitted (or 0).

#### `random(...) <= tenv.rnd(...)`
	ln.math.random() -> number
	ln.math.random(max) -> number
	ln.math.random(min,max) -> number
 	shorthand: rnd(...) -> number
Alternate random function that takes inputs like the Lua standard math.random(), but always returns a float in the given range (inclusive).

If no arguments are provided, the range is 0 to 1.

If one argument `max` is provided, the range is 0 to `max`.

If two arguments `min` and `max` are provided, the range is `min` to `max`.

The output is rounded to 4 decimals of precision.

#### `lerp(...)`
	ln.math.lerp(t, a, b)
Linearly interpolates from `a` to `b` as `t` goes from 0 to 1. Works with color and alpha values (given as override tag compatible strings) too.

#### `xerp(...)`
	ln.math.xerp(t, a, b, accel)
Interpolates with acceleration, should match the behaviour of \t tags.

    
#### Added shorthands
	Additional shorthands:
	fl(n) for math.floor(n)

### `shapes` namespace
##### Functions to generate various shapes, as well as fetch some specific preset shapes, as strings.

#### `shift(...)`
    ln.shapes.shift(shape, x, y) -> string

Shifts the given drawing `x` pixels right and `y` pixels down.

#### `rectangle(...)`
    ln.shapes.rectangle(width, height) -> string

Makes a rectangle with the given width and height.

#### `roundedRectangle(...)`
    ln.shapes.roundedRectangle(width, height, radius) -> string

As above, but with rounded corners of radius `radius`.

#### `circle(...)`
    ln.shapes.circle(radius, segments) -> string

Makes a properly centered approximation of a circle of radius `radius`. 
3 segments is particularly useful, as it looks almost perfect and is harder to calculate than 4 without letting this code do the math.

#### `triangle(...)`
    ln.shapes.triangle(side) -> string

Makes an equilateral triangle with given side length. Note: The shape is centered on the center of the triangle's bounding box, not the geometric center.

#### `gear(...)`
    ln.shapes.gear(r1, r2, r3, n, t, tt1, tt2) -> string

Makes a cogwheel shape. `r1`, `r2` and `r3` are the radii that define the size of the central circle and the length and shape of the teeth. `n` is the number of teeth. `t` is the ratio of the available space that each tooth occupies on the central circle. `tt1` and `tt2` control the beveling on the teeth. See the image for a better idea of what's happening. 
![image](https://user-images.githubusercontent.com/1952758/128567717-77da0917-33ae-4026-957d-ffe526261f67.png)

#### preset shapes
    ln.shapes.star
    ln.shapes.heart
    ln.shapes.twinkle1
    ln.shapes.twinkle2
    ln.shapes.twinkle3
    ln.shapes.snowflake
    ln.shapes.stolengleam

Pre-defined shapes.

---

# Part B: the modified templater 
The autoload folder in this repository contains a modified version of the vanilla karatemplater script that should be compatible with files that relied on that one, the only change required should be changing `template line` to `template lsyl` and `template pre-line` to `template line`.

I'm probably not going to make any future additions to this templater, although fixes are always a good idea. I recommend using 0x's KaraTemplater available at https://github.com/The0x539/Aegisub-Scripts/, since that one is actively maintained.

## Keyword changes (most important, partially breaking)
### `pre-line` is just `line`, `line` is `lsyl`, and there are four new keywords: `lword`, `lchar`, `word`, and `furichar`
I just thought this made sense. Naming the two new keywords would also have been difficult without this change. The new behaviors are as follows:

#### `pre-line`
No longer a valid keyword.
#### `line`
One line is output. The template is run once per line, and the line text is appended at the end of the templater output. This is the old `pre-line` behavior.
#### `lsyl`
One line is output. The template is run once per syllable, and the templater output is placed before each syllable in the output line. This is the old `line` behavior.
#### `lword`
One line is output. The template is run once per word, and the templater output is placed before each word in the output line.
#### `lchar`
One line is output. The template is run once per character, and the templater output is placed before each character in the output line. 
#### `word`
Each word generates a separate output line. The template is run once per word, and the word text is appended at the end of the templater output.
#### `furichar`
Each furigana character generates a separate output line. The template is run once per furigana character, and the character is appended at the end of the templater output.

## Line splitting
It's now similar to NyuFX: there are `word`, `syll` and `char` objects.

`syl` is the current smallest part of the line being worked on, like in the vanilla templater. This means it's either the current character, syllable or word. To get the current syllable, use `syll`.

## code word/char
You can use `word` and `char` with `code` lines.

This will run a piece of code before each word or character.

## style modifier keyword
There is a `style` modifier that works similarly to `fxgroup`

For example, a `template line all style romaji` will run on all lines with a style name containing `romaji`.

## character index variable `ci`
There is a character index variable `ci`.

This gives the index number of the character at the start of the current unit being processed (word, syl, char).

## expanded `tenv`
The template execution environment has direct access to the `subtitles` object and additional basic Lua functions in addition to the `string` library, the `math` library, and `_G`.

The `subtitles` object is what automation scripts use to access any given line in the ASS file. This can be used in kfx to get the next or previous line, for example. For specific documentation on the `subtitles` object, see the Aegisub manual. 

Other inclusions: the `table` functions, `pairs`, `ipairs`, `tonumber`, `tostring` and `type`.

## `notext` and `noblank` work with all template types
In the vanilla templater, this is not the case. `notext` was a particularly annoying omission, since vector drawings for non-k-timed lines got the line text added to the end. This was harmless, but annoyed me, and could be an issue if a symbol font is used to do similar things.

## `line.text` works properly now
The vanilla templater blanks out `line.text` and uses it as a buffer to generate the output line. This means the value for `line.text` generated by karaskel was inaccessible at least in some versions of this modified templater, and possibly the vanilla templater. I recently (later note: as of when???) fixed that.

## sub-pixel inline variables
Inline variables (dollar variables) have sub-pixel precision

They have one decimal. The normal behaviour of having only whole pixels made the position values unsuitable for positioning separated parts of a line.

## generate without furigana
There are two automation menu entries, one of which does not generate the furigana styles.

Furigana is only used in a subset of kanji-including kfx, so the styles are just clutter for most people.

## maxloop power boost
`maxloop()` can now stop a line from being generated at all.

Because I thought `maxloop(0)` should work. Setting the maxloop variable lower than the next `j` will also prevent the next line from generating.

## k_retime
Does the same thing as the normal retime function, but also adjusts the current syllable timing. Only works and makes sense with `syl`, `char`, and `furichar` templates.
