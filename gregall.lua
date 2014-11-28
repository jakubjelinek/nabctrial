local gregallaliases = {
["ci~"] = "cl>",
["pe~"] = "ta>",
["vs~"] = "ta>",
["pf~"] = "po>",
["sc~"] = "pe>2",
["sa~"] = "pe>2",
["suu1"] = "ta-",
["ppu1"] = "ta-",
["pfg"] = "sfm",
["cl~"] = "vi>",
["pr~"] = "vs>",
["ppt1"] = "ta" }

local function gregallreadfont(pfx, font_id)
  local tab = {}
  local metrics = {}
  local fontdata = fonts.hashes.identifiers[font_id]
  for key, value in pairs(fontdata.resources.unicodes) do
    local g = fontdata.characters[value]
    local name = key:gsub("B", ">"):gsub("N", "-"):gsub("E", "!"):gsub("T", "~")
    if g and (value >= 0xe400) and (value < 0xf000) then
      tab[name] = "{\\" .. pfx .. "\\char" .. value .. "}"
      metrics[name] = { width = g.width, height = g.height, depth = g.depth }
    end
  end
  for key, value in pairs(gregallaliases) do
    if tab[value] and not tab[key] then
      tab[key] = tab[value]
      metrics[key] = metrics[value]
    end
  end
  return tab, metrics
end

-- only works for fonts loaded so far
local name_id = {}
for key, value in pairs(fonts.hashes.identifiers) do
   name_id[value.shared.rawdata.metadata.fontname] = key
end

gregalltab = {}
local gregallmetrics = {}
gregalltab.gregall, gregallmetrics.gregall = gregallreadfont("GreGall", name_id["gregall"])
gregalltab.gregallmod, gregallmetrics.gregallmod = gregallreadfont("GreGallModern", name_id["SGallModern"])
local gregallneumekinds = { vi = 1, pu = 1, ta = 1, gr = 1, cl = 1, un = 1, pv = 1, pe = 1, po = 1, to = 1, ci = 1, sc = 1, pf = 1, sf = 1, tr = 1,
		      st = 1, ds = 1, ts = 1, tg = 1, bv = 1, tv = 1, pr = 1, pi = 1, vs = 1, ["or"] = 1, sa = 1, pq = 1, qi = 1, ql = 1, pt = 1 }
local gregalllskinds = { c = 1, t = 1, s = 1, l = 1, x = 1, ["+"] = 1, a = 1, al = 1, am = 1, b = 1, cm = 1, co = 1, cw = 1, d = 1, e = 1, eq = 1,
		   ew = 1, f = 1, fid = 1, fr = 1, g = 1, h = 1, hp = 1, hn = 1, i = 1, im = 1, iv = 1, k = 1, lb = 1, lc = 1, len = 1,
		   lm = 1, lp = 1, lt = 1, m = 1, md = 1, moll = 1, n = 1, nl = 1, nt = 1, p = 1, par = 1, pfec = 1, pm = 1, q = 1,
		   sb = 1, sc = 1, sc = 1, simil = 1, simul = 1, sj = 1, sjc = 1, sjcm = 1, sm = 1, st = 1, sta = 1, su = 1, tb = 1,
		   th = 1, tm = 1, tw = 1, v = 1, ve = 1, vol = 1 }

-- Parse a single base neume
local gregallparse_base = function (str, idx, len)
  local ret = str:sub(idx, idx + 1)
  local alt = {}
  local height = 5
  local alts = "-><~MSG"
  if idx >= len or not gregallneumekinds[ret] then return 1 end
  idx = idx + 2
  -- The alternation modifiers can be written in arbitrary order,
  -- canonicalize it and remove duplicates.
  while idx <= len and alts:find(str:sub(idx, idx)) do
    alt[str:sub(idx, idx)] = 1
    idx = idx + 1
  end
  for i = 1, 7 do
    local c = alts:sub(i, i)
    if alt[c] then ret = ret .. c end
  end
  -- This is followed by a single optional variant digit.
  if idx <= len and string.find("123456789", str:sub(idx, idx)) then
    ret = ret .. str:sub(idx, idx)
    idx = idx + 1
  end
  -- Ambitus not handled yet, neither during parsing, nor when
  -- typesetting.
  -- Optional height, h[a-m].
  if idx < len and str:sub(idx, idx) == "h" then
    local p = string.find("abcdefghijklm", str:sub(idx + 1, idx + 1))
    if not p then return 1 end
    height = p - 1
    idx = idx + 2
  end
  return 0, idx, ret, height
end

-- Parse one neume, which is one base neume or several base neumes
-- separated with ! characters, and all this followed by arbitrary
-- ls, pp and su modifiers.
local gregallparse_neume = function (str, idx, len)
  local err
  local bases = {}
  local heights = {}
  local pp = ''
  local su = ''
  local ls = {}
  local lsidx = 0
  local i = 1
  err, idx, bases[0], heights[0] = gregallparse_base(str, idx, len)
  if err == 1 then return 1 end
  while idx <= len and str:sub(idx, idx) == "!" do
    err, idx, bases[i], heights[i] = gregallparse_base(str, idx + 1, len)
    if err == 1 then return 1 end
    i = i + 1
  end
  while idx < len do
    local v = str:sub(idx, idx + 1)
    if v == "ls" then
      local idx2 = idx + 2
      while idx2 <= len and not string.find("12346789", str:sub(idx2, idx2)) do
	idx2 = idx2 + 1
      end
      if idx2 > len or not gregalllskinds[str:sub(idx + 2, idx2 - 1)] then return 1 end
      ls[lsidx] = str:sub(idx, idx2)
      lsidx = lsidx + 1
      idx = idx2 + 1
    elseif v == "su" or v == "pp" then
      local mod = ''
      idx = idx + 2
      local c = str:sub(idx, idx)
      if idx <= len and string.find("tuvwxy", c) then
	mod = mod .. c
	idx = idx + 1
	c = str:sub(idx, idx)
      end
      -- Pre/subpuncta with height not supported yet
      -- the heights would need to be adjusted relatively to heights[0]
      if idx > len or not string.find("123456789", c) then return 1 end
      mod = mod .. c
      if v == "su" then su = su .. "su" .. mod else pp = pp .. "pp" .. mod end
      idx = idx + 1
    else break end
  end
  return 0, idx, bases, heights, ls, pp, su
end

gregallparse_neumes = function(str, kind)
  local len = str:len()
  local idx = 1
  local ret = ''
  if len == 0 then return "ERR" end
  while idx <= len do
    local err, bases, heights, ls, pp, su, lscount
    err, idx, bases, heights, ls, pp, su = gregallparse_neume (str, idx, len)
    if err == 1 then return ret .. "ERR" end
    local base = bases[0]
    local i = 1
    while bases[i] do
      base = base .. "!" .. bases[i]
      local h = heights[i] - heights[0]
      if h ~= 0 then
	h = h + 5
	if h < 0 or h > 12 then
	  base = "ERR"
	  break
	end
	base = base .. string.sub("abcdefghijklm", h + 1, h + 1)
      end
      i = i + 1
    end
    lscount = 0
    while ls[lscount] do
      if not gregalltab[kind][ls[lscount]:sub(1, -2)] then base = "ERR" end
      lscount = lscount + 1
    end
    if base ~= "ERR" then
      local l = {}
      function l.try (kind, base, parts, pp, su, ls)
	if parts == 2 and pp ~= '' and su ~= '' and gregalltab[kind][base .. pp .. su .. ls] then return base .. pp .. su .. ls, '', '' end
	if parts == 1 and pp ~= '' and gregalltab[kind][base .. pp .. ls] then return base .. pp .. ls, '', su end
	if parts == 1 and su ~= '' and gregalltab[kind][base .. su .. ls] then return base .. su .. ls, pp, '' end
	if parts == 0 and gregalltab[kind][base .. ls] then return base .. ls, pp, su end
	return nil, pp, su
      end
      local r = nil
      local ppsuparts = 0
      if pp ~= '' then ppsuparts = 1 end
      if su ~= '' then ppsuparts = ppsuparts + 1 end
      -- We assume here no character in the font has more than two
      -- significative letters.
      local allparts = ppsuparts + lscount
      if lscount >= 2 then allparts = ppsuparts + 2 end
      -- Try to match as many parts (ls sequences, pp string, su string) as
      for parts = allparts, 0, -1 do
	if lscount >= 2 and parts >= 2 and parts <= 2 + ppsuparts then
	  for i = 0, lscount - 1 do
	    for j = 0, lscount - 1 do
	      if i ~= j then
		r, pp, su = l.try(kind, base, parts - 2, pp, su, ls[i] .. ls[j])
		if r then
		  ls[i] = ''
		  ls[j] = ''
		  break
		end
	      end
	    end
	    if r then break end
	  end
	  if r then break end
	end
	if lscount >= 1 and parts >= 1 and parts <= 1 + ppsuparts then
	  for i = 0, lscount - 1 do
	    r, pp, su = l.try(kind, base, parts - 1, pp, su, ls[i])
	    if r then
	      ls[i] = ''
	      break
	    end
	  end
	  if r then break end
	end
	r, pp, su = l.try(kind, base, parts, pp, su, '')
	if r then break end
      end
      if not r or (pp ~= '' and not gregalltab[kind][pp]) or (su ~= '' and not gregalltab[kind][su]) then
	base = "ERR"
      else
	base = gregalltab[kind][r]
	local above = ''
	local below = ''
	-- Should the pre and subpuncta be somehow specially positioned
	-- against the base neume?
	if pp ~= '' then base = gregalltab[kind][pp] .. base end
	if su ~= '' then base = base .. gregalltab[kind][su] end
	for i = 0, lscount - 1 do
	  if ls[i] ~= '' then
	    local p = ls[i]:sub(-1, -1)
	    local l = ls[i]:sub(1, -2)
	    if p == "2" then
	      above = above .. gregalltab[kind][l]
	    elseif p == "8" then
	      below = below .. gregalltab[kind][l]
	    elseif p == "1" or p == "4" or p == "7" then
	      base = gregalltab[kind][l] .. base
	    elseif p == "3" or p == "6" or p == "9" then
	      base = base .. gregalltab[kind][l]
	    end
	  end
	end
      end
    end
    ret = ret .. base
    while idx <= len and str:sub(idx, idx) == "/" do
      ret = ret .. "\\enspace{}"
      idx = idx + 1
    end
  end
  return ret
end
