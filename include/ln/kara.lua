util = require 'aegisub.util'

matchfloat = "%-?%f[%.%d]%d*%.?%d*%f[^%.%d%]]"

function booltost(bool)
    if bool == nil then
        return "nil";
    end
    if bool then
        return "true";
    else
        return "false";
    end
end

function tabletost(t)
    local tabst = "{ ";
    local i = 0;
    for key,val in pairs(t) do
        i = i+1
        if key ~= i then
            tabst = tabst .. key ..":"
        end
        tabst = tabst .. makestring(val);
        
        tabst = tabst .. ", "
        
    end
    tabst = tabst .. " }";
    return tabst;
end

function makestring(variable)
    if variable == nil then
        return "nil";
    elseif type(variable) == "number" or type(variable) == "string" then
        return variable .. "";
    elseif type(variable) == "boolean" then
        return booltost(variable);
    elseif type(variable) == "table" then
        return tabletost(variable);
    else
        aegisub.debug.out("unknown")
        return type(variable);
    end;
end

function findtag(text, tagtype, startindex, endindex)
    local valuestarts = "[0123456789%&%-%(]";
    if tagtype == nil then tagtype = "[^\\%}]"; valuestarts = "[^\\%}]" end;
    if tagtype == "fn" then valuestarts = "[^\\%}]" end;
    if tagtype == "t" then valuestarts = "[(]" end;
    if tagtype == "inline_fx" then tagtype = "%-"; valuestarts = "[^\\%}]"; end;
    if tagtype == "c" or tagtype == "1c" then tagtype = "1?c" end;
    if startindex == nil then startindex = 1 end;
    if endindex == nil then endindex = -1 end;
    if text == nil then return 0,0 end;
    tagstart = text:find("\\" .. tagtype .. valuestarts, startindex);
    if tagstart == nil then return 0,0 end;
    local depth = 0;
    for i=startindex,tagstart do
        local c = text:sub(i,i)
        if c == "(" then depth = depth + 1 end;
        if c == ")" then depth = depth - 1 end;
    end
    if depth ~= 0 then
        return 0,0 
    end
    depth = 0
    local max_i = endindex;
    if max_i < 0 then max_i = text:len() + 1 + max_i end;
    for i = tagstart + 1, math.min(text:len(), max_i) do
        local c = text:sub(i, i);
        if c == "(" then depth = depth + 1 end;
        if c == ")" then depth = depth - 1 end;
        --if tagtype == "t" then aegisub.debug.out("i=".. i ..", c=".. c ..", depth=".. depth .."\n") end;
        if c == "}" or (c == "\\" and depth == 0) then
            return tagstart, i - 1
        end
    end
    return 0,0;
end

local tenv

function an2point(alignment)
    x = 1 + ((alignment - 1) % 3);
    y = 1 + (alignment - x) / 3;
    yval = tenv.line.bottom;
    if y == 2 then
        yval = tenv.line.middle;
    elseif y > 2 then
        yval = tenv.line.top;
    end
    if tenv.syl ~= nil then
        xval = tenv.line.left + tenv.syl.left;
        if x == 2 then
            xval = tenv.line.left + tenv.syl.center;
        elseif x > 2 then
            xval = tenv.line.left + tenv.syl.right;
        end
    else
        xval = tenv.line.left;
        if x == 2 then
            xval = tenv.line.center;
        elseif x > 2 then
            xval = tenv.line.right;
        end
    end
    return xval, yval;
end

local lnlib
local buffers = {}

function startbuffertime(min)
    if lnlib.line.tag("fad") ~= "" then
        return tonumber(string.match(lnlib.line.tag("fad"), "%d+"));
    else
        if #(tenv.line.kara or {}) == 0 then
            return min;
        end
        if tenv.line.kara[1].text == "" or tenv.line.kara[1].text == " " then
            return math.max(min,tenv.line.kara[1].duration);
        end
    end
    return min;
end

function endbuffertime(min)
    if lnlib.line.tag("fad") ~= "" then
        return tonumber(string.sub(string.match(lnlib.line.tag("fad"), "%,%d+"), 2));
    else
        if #(tenv.line.kara or {}) == 0 then
            return min;
        end
        if tenv.line.kara[#(tenv.line.kara)].text == "" or tenv.line.kara[#(tenv.line.kara)].text == " " then
            return math.max(min,tenv.line.kara[#(tenv.line.kara)].duration);
        end
    end
    return min
end

RGB2HSL = function(r,g,b)
	r = r / 255
	g = g / 255
	b = b / 255
    local ma = math.max(r, g, b);
    local mi = math.min(r, g, b);
    local c = ma - mi;

    --calculate hue
    local h = nil;
    if c ~= 0 then
        if ma == r then
            h = (((g - b) / c) % 6) / 6;
        elseif ma == G then
            h = ((b - r) / c + 2) / 6;
        else
            h = ((r - g) / c + 4) / 6;
        end
    end

    --calculate lightness
    local l = (ma + mi) / 2;

	local s
    --calculate saturation
    if l == 0 or l == 1 then
        s = 0;
    else
        s = c / (1 - math.abs(2 * l - 1));
    end
	return (h or 0)*255, s*255, l*255
end

HSL2RGB = function(h, s, l)
	h = h / 255
	s = s / 255
	l = l / 255
	local r = 0;
	local g = 0;
	local b = 0;
	--chroma
	local c = (1 - math.abs(2 * l - 1)) * s;
	local m = l - c / 2;

	--- if not grayscale, calculate RGB
	if h ~= nil then
		local hu = (h%1) * 6;
		local x = c * (1 - math.abs(hu % 2 - 1));
		if hu < 1 then
			r = c;
			g = x;
		elseif hu < 2 then
			r = x;
			g = c;
		elseif hu < 3 then
			g = c;
			b = x;
		elseif hu < 4 then
			g = x;
			b = c;
		elseif hu < 5 then
			r = x;
			b = c;
		else
			r = c;
			b = x;
		end
	end
	
	return 255*(r+m),255*(g+m),255*(b+m)
end

lnlib = {
	init = function(tv)
		tenv = tv
		tv.ci = lnlib.chari
		tv.st = lnlib.syltime
		tv.gc = lnlib.line.c
		tv.ga = lnlib.line.a
		tv.rgb = lnlib.color.byRGB
		tv.hsl = lnlib.color.byHSL
		tv.hsy = lnlib.color.lumaHSL
		tv.rnd = math.random
	end,
	chari = function()
		local out = 0
		for i=1,tenv.syl.i-1 do
			out = out + #tenv.line.kara[i].text_stripped
		end
		return (tenv.syl.ci or 1) + out
	end,
	syltime = function(p)
		return tenv.syl.start_time+tenv.syl.duration*(p or 0)
	end,
	line = {
		tag = function (tags) 
			local ret = ""
			if type(tags) == "string" then tags = {tags} end
			for i=1,#tags do
				ret = ret .. tenv.line.raw:sub(findtag(tenv.line.raw, tags[i]))
			end
			return ret
		end,
		tags = function (tags, as_list) 
			local ret
			if as_list then
				ret = {}
				local ri = 1
				if type(tags) == "string" then tags = {tags} end
				for i=1,#tags do
					local ci = 1
					while ci < #tenv.line.raw and ci > 0 do
						local si, ei = findtag(tenv.line.raw, tags[i], ci)
						if ei ~= 0 then 
							ci = ei+1 
							ret[ri] = tenv.line.raw:sub(si, ei)
							ri = ri+1
						else ci = -1 end
					end
				end
			else
				ret = ""
				if type(tags) == "string" then tags = {tags} end
				for i=1,#tags do
					local ci = 1
					while ci < #tenv.line.raw and ci > 0 do
						local si, ei = findtag(tenv.line.raw, tags[i], ci)
						if ei ~= 0 then 
							ci = ei+1 
							ret = ret .. tenv.line.raw:sub(si, ei)
						else ci = -1 end
					end
				end
			end
			return ret
		end,
		style_c = function(n)
			n = n or 1
			return color_from_style(tenv.line.styleref["color" .. n])
		end,
		style_a = function(n)
			n = n or 1
			return alpha_from_style(tenv.line.styleref["color" .. n])
		end,
		c = function(n)
			n = n or 1
			local tag = lnlib.line.tags(n .. "c")
			if tag ~= "" then
				return tag:match("&H%x%x%x%x%x%x&")
			else
				return color_from_style(tenv.line.styleref["color" .. n]);
			end
		end,
		a = function(n)
			n = n or 1
			local tag = lnlib.line.tags(n .. "a")
			if tag ~= "" then
				return tag:match("&H%x%x&")
			else
				return alpha_from_style(tenv.line.styleref["color" .. n]);
			end
		end,
		buffers = function(startmin, endmin)
			local buf = buffers[tenv.line.start_time]
			if buf == nil then
				buf = {}
				buf.sb = startbuffertime(startmin)
				buf.eb = endbuffertime(endmin)
				buffers[tenv.line.start_time] = buf
			end
			return buf.sb,buf.eb
		end
	},
	
	tag = {
		pos = function(alignment, anchorpoint, xoffset, yoffset, line_kara_mode)
			alignment = alignment or tenv.line.styleref.align or 5
			anchorpoint = anchorpoint or tenv.line.styleref.align or 5
			xoffset = xoffset or 0
			yoffset = yoffset or 0
			local x,y
			if line_kara_mode then
				if not tenv.line.smart_pos_flag then
					x,y = an2point(anchorpoint)
					tenv.line.smart_pos_flag = true
				end
			elseif tenv.syl == nil then
				x,y = an2point(anchorpoint)
			else
				x,y = an2point(anchorpoint)
			end
			if x ~= nil and y~= nil then
				return "\\an" .. alignment .. "\\pos(" .. x + xoffset .. ", " .. y + yoffset .. ")";
			else
				return "";
			end
		end,
		move = function(xoff1, yoff1, time0, time1, alignment, anchorpoint, xoff0, yoff0, line_kara_mode)
			alignment = alignment or tenv.line.styleref.align or 5
			anchorpoint = anchorpoint or tenv.line.styleref.align or 5
			xoff0 = xoff0 or 0
			yoff0 = yoff0 or 0
			local x,y
			if line_kara_mode then
				if not tenv.line.smart_pos_flag then
					x,y = an2point(anchorpoint)
					tenv.line.smart_pos_flag = true
				end
			elseif tenv.syl == nil then
				x,y = an2point(anchorpoint)
			else
				x,y = an2point(anchorpoint)
			end
			local timest;
			if time0 == nil or time1 == nil then
				timest = ""
			else
				timest = "," .. time0 .. "," .. time1
			end
			if x ~= nil and y~= nil then
				return "\\an" .. alignment .. "\\move(" .. x + xoff0 .. ", " .. y + yoff0 .. "," .. x + xoff1 .. ", " .. y + yoff1 .. timest .. ")";
			else
				return "";
			end
		end,
		t = function(a0, a1, a2, a3)
			if a1 == nil and a2 == nil and a3 == nil then
				a3 = a0; a0 = nil
			elseif a2 == nil and a3 == nil then
				a2 = a0; a3 = a1; a0 = nil; a1 = nil
			elseif a3 == nil then
				a3 = a2; a2 = nil
			end
			local st = "\\t("
			if a0 then st = st .. string.format("%d,",tonumber(a0)) end
			if a1 then st = st .. string.format("%d,",tonumber(a1)) end
			if a2 then st = st .. string.format("%.2f,",tonumber(a2)) end
			st = st .. a3 .. ")"
			return st
		end,
		parse_transform = function(tag)
			if not tag:match("\\t%(") then return nil end
			local f = matchfloat
			local t0, t1, a, tags
			t0, t1, a, tags = tag:match("\\t%((".. f .. "),(" .. f .."),(".. f .."),([^)]*)%)")
			if tags == nil then
				t0, t1, tags = tag:match("\\t%((".. f .. "),(" .. f .."),([^)]*)%)")
			end
			if tags == nil then
				a, tags = tag:match("\\t%((".. f .."),([^)]*)%)")
			end
			if tags == nil then
				tags = tag:match("\\t%(([^)]*)%)")
			end
			return {t0 = tonumber(t0), t1 = tonumber(t1), a = tonumber(a or 1), tags = tags}
		end,
		mod_transform = function(tag, t0mod, t1mod, amod, tagsmod)
			if type(tag) == "string" then tag = {tag} end
			local retst = ""
			for i=1,#tag do
				local parsed = lnlib.tag.parse_transform(tag[i])
				local newt0, newt1, newa, newtags
				
				if t0mod == nil or t0mod == "" or t0mod == 0 or parsed.t0 == nil then
					newt0 = parsed.t0
				elseif t0mod:sub(1,1) == "-" then
					newt0 = parsed.t0 - tonumber(t0mod:sub(2))
				elseif t0mod:sub(1,1) == "+" then
					newt0 = parsed.t0 + tonumber(t0mod:sub(2))
				elseif t0mod:sub(1,1) == "=" then
					newt0 = tonumber(t0mod:sub(2))
				else
					newt0 = tonumber(t0mod)
				end
				
				if t1mod == nil or t1mod == "" or t1mod == 0 or parsed.t1 == nil then
					newt1 = parsed.t1
				elseif t1mod:sub(1,1) == "-" then
					newt1 = parsed.t1 - tonumber(t1mod:sub(2))
				elseif t1mod:sub(1,1) == "+" then
					newt1 = parsed.t1 + tonumber(t1mod:sub(2))
				elseif t1mod:sub(1,1) == "=" then
					newt1 = tonumber(t1mod:sub(2))
				else
					newt1 = tonumber(t1mod)
				end
				
				if amod == nil or amod == "" or amod == 0 then
					newa = parsed.a
				elseif amod:sub(1,1) == "-" then
					newa = parsed.a - tonumber(amod:sub(2))
				elseif amod:sub(1,1) == "+" then
					newa = parsed.a + tonumber(amod:sub(2))
				elseif amod:sub(1,1) == "=" then
					newa = tonumber(amod:sub(2))
				else
					newa = tonumber(amod)
				end
				
				if tagsmod == nil or tagsmod == "" then
					newtags = parsed.tags
				elseif tagsmod:sub(1,1) == "-" then
					newtags = string.gsub(parsed.tags, tagsmod:sub(2),"")
				elseif tagsmod:sub(1,1) == "+" then
					newtags = parsed.tags .. tagsmod:sub(2)
				elseif tagsmod:sub(1,1) == "=" then
					newtags = tagsmod:sub(2)
				else
					newtags = tagsmod
				end
				
				retst = retst .. lnlib.tag.t(newt0, newt1, newa, newtags)
			end
			return retst
		end
	},
	
	color = {
		byRGB = function(r,g,b)
			return string.format("&H%02X%02X%02X&",b,g,r)
		end,
		byHSL = function(h, s, l)
			h = h / 255
			s = s / 255
			l = l / 255
			local r = 0;
			local g = 0;
			local b = 0;
			--chroma
			local c = (1 - math.abs(2 * l - 1)) * s;
			local m = l - c / 2;

			--- if not grayscale, calculate RGB
			if h ~= nil then
				local hu = (h%1) * 6;
				local x = c * (1 - math.abs(hu % 2 - 1));
				if hu < 1 then
					r = c;
					g = x;
				elseif hu < 2 then
					r = x;
					g = c;
				elseif hu < 3 then
					g = c;
					b = x;
				elseif hu < 4 then
					g = x;
					b = c;
				elseif hu < 5 then
					r = x;
					b = c;
				else
					r = c;
					b = x;
				end
			end
			
			return string.format("&H%02X%02X%02X&",255*(b+m),255*(g+m),255*(r+m))
		end,
		lumaHSL = function(h,s,l)
			if h == nil then
				return "&H000000&"
			end
			local y1 = l;
			local r, g, b = HSL2RGB(h, s, l)
			local y2 = r * 0.2126 + g * 0.7152 + b * 0.0722;
			local lumashift = y2 / y1;
			r = math.min(255, r / lumashift);
			g = math.min(255, g / lumashift);
			b = math.min(255, b / lumashift);
			return lnlib.color.byRGB(r,g,b);
		end,
		rgb = {
			get = function(string)
				local r, g, b = extract_color(string)
				return r,g,b
			end,
			add = function(string, dr, dg, db)
				local r, g, b = extract_color(string)
				return r+dr,g+dg,b+db
			end
		},
		hsl = {
			get = function(string)
				local r, g, b = extract_color(string)
				return RGB2HSL(r,g,b)
			end,
			add = function(string, dh, ds, dl)
				local r, g, b = extract_color(string)
				local h, s, l = RGB2HSL(r,g,b)
				return lnlib.math.modloop(h+dh,0,255),lnlib.math.clamp(s+ds,0,255),lnlib.math.clamp(l+dl,0,255)
			end
		}
	},
	
	math = {
		clamp = function(n,min,max)
			return math.min(math.max(n,min),max)
		end,
		modloop = function(n,min,max)
			return (n-min) % (max-min)
		end
	},
	
	subs = {
	}
}

return lnlib
