util = require 'aegisub.util'

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
lnlib = {
	init = function(tv)
		tenv = tv
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
		tags = function (tags) 
			local ret = ""
			if type(tags) == "string" then tags = {tags} end
			for i=1,#tags do
				local ci = 1
				while ci < #tenv.line.raw and ci > 0 do
					local si, ei = findtag(tenv.line.raw, tags[i], ci)
					if ei ~= 0 then ci = ei+1 else ci = -1 end
					ret = ret .. tenv.line.raw:sub(si, ei)
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
			if time0 == 0 and time1 == tenv.line.duration then time0 = nil time1 = nil end
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
		end
	},
	
	color = {
		byRGB = function(r,g,b)
			return string.format("&H%02X%02X%02X",r,g,b)
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
			
			return string.format("&H%02X%02X%02X",255*(r+m),255*(g+m),255*(b+m))
		end
	},
	
	math = {
	},
	
	subs = {
	}
}

return lnlib
