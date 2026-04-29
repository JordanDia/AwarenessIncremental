local ReplicatedStorage = game:GetService("ReplicatedStorage")
local num = require(ReplicatedStorage.Shared.Modules.Quicknum)

local SUFFIXES = {
	"K",      -- 1e3
	"M",      -- 1e6
	"B",      -- 1e9
	"T",      -- 1e12
	"Qd",     -- 1e15
	"Qn",     -- 1e18
	"Sx",     -- 1e21
	"Sp",     -- 1e24
	"Oc",     -- 1e27
	"No",     -- 1e30
	"Dc",     -- 1e33
	"UDc",    -- 1e36
	"DDc",    -- 1e39
	"TDc",    -- 1e42
	"QdDc",   -- 1e45
	"QnDc",   -- 1e48
	"SxDc",   -- 1e51
	"SpDc",   -- 1e54
	"OcDc",   -- 1e57
	"NoDc",   -- 1e60
	"Vg",     -- 1e63
	"UVg",    -- 1e66
	"DVg",    -- 1e69
	"TVg",    -- 1e72
	"QdVg",   -- 1e75
	"QnVg",   -- 1e78
	"SxVg",   -- 1e81
	"SpVg",   -- 1e84
	"OcVg",   -- 1e87
	"NoVg",   -- 1e90
	"Tg",     -- 1e93
	"UTg",    -- 1e96
	"DTg",    -- 1e99
	"TTg",    -- 1e102
	"QdTg",   -- 1e105
	"QnTg",   -- 1e108
	"SxTg",   -- 1e111
	"SpTg",   -- 1e114
	"OcTg",   -- 1e117
	"NoTg",   -- 1e120
	"Qg",     -- 1e123
	"UQg",    -- 1e126
	"DQg",    -- 1e129
	"TQg",    -- 1e132
	"QdQg",   -- 1e135
	"QnQg",   -- 1e138
	"SxQg",   -- 1e141
	"SpQg",   -- 1e144
	"OcQg",   -- 1e147
	"NoQg",   -- 1e150
	"Qng",    -- 1e153
	"UQng",   -- 1e156
	"DQng",   -- 1e159
	"TQng",   -- 1e162
	"QdQng",  -- 1e165
	"QnQng",  -- 1e168
	"SxQng",  -- 1e171
	"SpQng",  -- 1e174
	"OcQng",  -- 1e177
	"NoQng",  -- 1e180
	"Sxg",    -- 1e183
	"USxg",   -- 1e186
	"DSxg",   -- 1e189
	"TSxg",   -- 1e192
	"QdSxg",  -- 1e195
	"QnSxg",  -- 1e198
	"SxSxg",  -- 1e201
	"SpSxg",  -- 1e204
	"OcSxg",  -- 1e207
	"NoSxg",  -- 1e210
	"Spg",    -- 1e213
	"USpg",   -- 1e216
	"DSpg",   -- 1e219
	"TSpg",   -- 1e222
	"QdSpg",  -- 1e225
	"QnSpg",  -- 1e228
	"SxSpg",  -- 1e231
	"SpSpg",  -- 1e234
	"OcSpg",  -- 1e237
	"NoSpg",  -- 1e240
	"Ocg",    -- 1e243
	"UOcg",   -- 1e246
	"DOcg",   -- 1e249
	"TOcg",   -- 1e252
	"QdOcg",  -- 1e255
	"QnOcg",  -- 1e258
	"SxOcg",  -- 1e261
	"SpOcg",  -- 1e264
	"OcOcg",  -- 1e267
	"NoOcg",  -- 1e270
	"Nog",    -- 1e273
	"UNog",   -- 1e276
	"DNog",   -- 1e279
	"TNog",   -- 1e282
	"QdNog",  -- 1e285
	"QnNog",  -- 1e288
	"SxNog",  -- 1e291
	"SpNog",  -- 1e294
	"OcNog",  -- 1e297
	"NoNog",  -- 1e300
	"Cg",     -- 1e303
}

local LOG10_2 = math.log10(2)

-- Converts buffer or plain number to decimal mantissa [1,10) and integer exponent.
local function toDecimalParts(n)
	local m, e
	if type(n) == "buffer" then
		m = buffer.readf64(n, 0)
		e = buffer.readf64(n, 8)
	elseif type(n) == "number" then
		if n == 0 or n ~= n then return 0, 0 end
		if n == math.huge or n == -math.huge then
			return 1.79, 308
		end
		m, e = math.frexp(n)
	else
		return 0, 0
	end
	if m == 0 then return 0, 0 end
	-- Convert from binary (mantissa * 2^exponent) to decimal
	m = m * 2
	e = e - 1
	local exp = e * LOG10_2
	local eDec = math.floor(exp)
	local mDec = m * math.pow(10, exp - eDec)
	if mDec >= 10 then
		mDec = mDec * 0.1
		eDec = eDec + 1
	end
	return mDec, eDec
end

local function formatParts(m, e)
	if e < 3 then
		return tostring(math.floor(m * math.pow(10, e) + 0.5))
	end
	local idx = math.floor(e / 3)
	if idx > #SUFFIXES then
		-- scientific fallback for values beyond Cg (1e303)
		return string.format("%.2fe+%d", m, e)
	end
	local mod3 = e % 3
	return string.format("%." .. (2 - mod3) .. "f", m * math.pow(10, mod3)) .. SUFFIXES[idx]
end

-- Formats a Quicknum buffer or plain number using the game's suffix table.
-- Accepts an optional skeleton string (ignored, for drop-in compat with FormatNumber calls).
local function FormatQN(n, _skeleton)
	local m, e = toDecimalParts(n)
	if m == 0 then return "0" end
	return formatParts(m, e)
end

return FormatQN
