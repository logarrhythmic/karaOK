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

local lnlib
local tenv
lnlib = {
	init = function(tv)
		tenv = tv
	end,
	line = {
		tags = function (tags) 
			local ret = ""
			if type(tags) == "string" then tags = {tags} end
			for i=1,#tags do
				ret = ret .. tenv.line.raw:sub(findtag(tenv.line.raw, tags[i]))
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
	
	color = {
	},
	
	math = {
	},
	
	subs = {
	}
}

return lnlib
