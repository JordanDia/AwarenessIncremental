-- Configuration
-- The suffixes for abbreviation in every power of thousands.
local COMPACT_SUFFIX = {
	"K",      -- Thousand (1e3)
	"M",      -- Million (1e6)
	"B",      -- Billion (1e9)
	"T",      -- Trillion (1e12)
	"Qd",     -- Quadrillion (1e15)
	"Qn",     -- Quintillion (1e18)
	"Sx",     -- Sextillion (1e21)
	"Sp",     -- Septillion (1e24)
	"Oc",     -- Octillion (1e27)
	"No",     -- Nonillion (1e30)
	"Dc",     -- Decillion (1e33)
	"UDc",    -- Undecillion (1e36)
	"DDc",    -- Duodecillion (1e39)
	"TDc",    -- Tredecillion (1e42)
	"QdDc",   -- Quattuordecillion (1e45)
	"QnDc",   -- Quindecillion (1e48)
	"SxDc",   -- Sexdecillion (1e51)
	"SpDc",   -- Septendecillion (1e54)
	"OcDc",   -- Octodecillion (1e57)
	"NoDc",   -- Novemdecillion (1e60)
	"Vg",     -- Vigintillion (1e63)
	"UVg",    -- Unvigintillion (1e66)
	"DVg",    -- Duovigintillion (1e69)
	"TVg",    -- Trevigintillion (1e72)
	"QdVg",   -- Quattuorvigintillion (1e75)
	"QnVg",   -- Quinvigintillion (1e78)
	"SxVg",   -- Sexvigintillion (1e81)
	"SpVg",   -- Septenvigintillion (1e84)
	"OcVg",   -- Octovigintillion (1e87)
	"NoVg",   -- Novemvigintillion (1e90)
	"Tg",     -- Trigintillion (1e93)
	"UTg",    -- Untrigintillion (1e96)
	"DTg",    -- Duotrigintillion (1e99)
	"TTg",    -- Tretrigintillion (1e102)
	"QdTg",   -- Quattuortrigintillion (1e105)
	"QnTg",   -- Quintrigintillion (1e108)
	"SxTg",   -- Sextrigintillion (1e111)
	"SpTg",   -- Septentrigintillion (1e114)
	"OcTg",   -- Octotrigintillion (1e117)
	"NoTg",   -- Novemtrigintillion (1e120)
	"Qg",     -- Quadragintillion (1e123)
	"UQg",    -- Unquadragintillion (1e126)
	"DQg",    -- Duoquadragintillion (1e129)
	"TQg",    -- Trequadragintillion (1e132)
	"QdQg",   -- Quattuorquadragintillion (1e135)
	"QnQg",   -- Quinquadragintillion (1e138)
	"SxQg",   -- Sexquadragintillion (1e141)
	"SpQg",   -- Septenquadragintillion (1e144)
	"OcQg",   -- Octoquadragintillion (1e147)
	"NoQg",   -- Novemquadragintillion (1e150)
	"Qng",    -- Quinquagintillion (1e153)
	"UQng",   -- Unquinquagintillion (1e156)
	"DQng",   -- Duoquinquagintillion (1e159)
	"TQng",   -- Trequinquagintillion (1e162)
	"QdQng",  -- Quattuorquinquagintillion (1e165)
	"QnQng",  -- Quinquinquagintillion (1e168)
	"SxQng",  -- Sexquinquagintillion (1e171)
	"SpQng",  -- Septenquinquagintillion (1e174)
	"OcQng",  -- Octoquinquagintillion (1e177)
	"NoQng",  -- Novemquinquagintillion (1e180)
	"Sxg",    -- Sexagintillion (1e183)
	"USxg",   -- Unsexagintillion (1e186)
	"DSxg",   -- Duosexagintillion (1e189)
	"TSxg",   -- Tresexagintillion (1e192)
	"QdSxg",  -- Quattuorsexagintillion (1e195)
	"QnSxg",  -- Quinsexagintillion (1e198)
	"SxSxg",  -- Sexsexagintillion (1e201)
	"SpSxg",  -- Septensexagintillion (1e204)
	"OcSxg",  -- Octosexagintillion (1e207)
	"NoSxg",  -- Novemsexagintillion (1e210)
	"Spg",    -- Septuagintillion (1e213)
	"USpg",   -- Unseptuagintillion (1e216)
	"DSpg",   -- Duoseptuagintillion (1e219)
	"TSpg",   -- Treseptuagintillion (1e222)
	"QdSpg",  -- Quattuorseptuagintillion (1e225)
	"QnSpg",  -- Quinseptuagintillion (1e228)
	"SxSpg",  -- Sexseptuagintillion (1e231)
	"SpSpg",  -- Septenseptuagintillion (1e234)
	"OcSpg",  -- Octoseptuagintillion (1e237)
	"NoSpg",  -- Novemseptuagintillion (1e240)
	"Ocg",    -- Octogintillion (1e243)
	"UOcg",   -- Unoctogintillion (1e246)
	"DOcg",   -- Duooctogintillion (1e249)
	"TOcg",   -- Treoctogintillion (1e252)
	"QdOcg",  -- Quattuoroctogintillion (1e255)
	"QnOcg",  -- Quinoctogintillion (1e258)
	"SxOcg",  -- Sexoctogintillion (1e261)
	"SpOcg",  -- Septenoctogintillion (1e264)
	"OcOcg",  -- Octooctogintillion (1e267)
	"NoOcg",  -- Novemoctogintillion (1e270)
	"Nog",    -- Nonagintillion (1e273)
	"UNog",   -- Unnonagintillion (1e276)
	"DNog",   -- Duononagintillion (1e279)
	"TNog",   -- Trenonagintillion (1e282)
	"QdNog",  -- Quattuornonagintillion (1e285)
	"QnNog",  -- Quinnonagintillion (1e288)
	"SxNog",  -- Sexnonagintillion (1e291)
	"SpNog",  -- Septennonagintillion (1e294)
	"OcNog",  -- Octononagintillion (1e297)
	"NoNog",  -- Novemnonagintillion (1e300)
	"Cg",     -- Centillion (1e303)
}
local CACHED_SKELETON_SETTINGS = true
--

local MainAPI = require(script.Parent.Main)
local FormatNumberSimpleAPI = { }

local SKELETON_CACHE = if CACHED_SKELETON_SETTINGS then { } else nil
local COMPACT_SKELETON_CACHE = if CACHED_SKELETON_SETTINGS then { } else nil

function FormatNumberSimpleAPI.Format(value: number, skeleton: string?): string
	local success
	local formatter = nil

	assert(type(value) == "number", "Value provided must be a number")

	if skeleton == nil then
		skeleton = ""
	end
	assert(type(skeleton) == "string", "Skeleton provided must be a string")

	if CACHED_SKELETON_SETTINGS then
		formatter = SKELETON_CACHE[skeleton]
	end

	if not formatter then
		success, formatter =
			MainAPI.NumberFormatter.forSkeleton(skeleton)
		assert(success, formatter :: string)

		if CACHED_SKELETON_SETTINGS then
			SKELETON_CACHE[skeleton] = formatter
		end
	end

	return (formatter :: MainAPI.NumberFormatter):Format(value)
end

local function toScientificNotation(value: number): string
	if value ~= value then return "NaN" end
	if value == math.huge then return "∞" end
	if value == -math.huge then return "-∞" end
	local absVal = math.abs(value)
	if absVal == 0 then return "0" end
	local exp = math.floor(math.log10(absVal))
	local mantissa = absVal / (10 ^ exp)
	local sign = if value < 0 then "-" else ""
	return sign .. string.format("%.2fe+%d", mantissa, exp)
end

function FormatNumberSimpleAPI.FormatCompact(value: number, skeleton: string?): string
	local success
	local formatter = nil

	assert(type(value) == "number", "Value provided must be a number")

	-- Fall back to scientific notation if value exceeds the suffix table range
	if value == value and value ~= math.huge and value ~= -math.huge then
		local absVal = math.abs(value)
		if absVal > 0 and math.log10(absVal) >= 3 * (#COMPACT_SUFFIX + 1) then
			return toScientificNotation(value)
		end
	end

	if skeleton == nil then
		skeleton = ""
	end
	assert(type(skeleton) == "string", "Skeleton provided must be a string")

	if CACHED_SKELETON_SETTINGS then
		formatter = COMPACT_SKELETON_CACHE[skeleton]
	end

	if not formatter then
		success, formatter =
			MainAPI.NumberFormatter.forSkeleton(skeleton)
		assert(success, formatter :: string)

		formatter = (formatter :: MainAPI.NumberFormatter)
			:Notation(MainAPI.Notation.compactWithSuffixThousands(COMPACT_SUFFIX))

		if CACHED_SKELETON_SETTINGS then
			COMPACT_SKELETON_CACHE[skeleton] = formatter
		end
	end

	assert(#COMPACT_SUFFIX ~= 0, "Please provide the suffix abbreviations for FormatCompact at the top of the Simple ModuleScript")

	return formatter:Format(value)
end

return table.freeze(FormatNumberSimpleAPI)