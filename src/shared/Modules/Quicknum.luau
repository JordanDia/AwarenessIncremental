--!optimize 2
--!native
--[[
		INFORMATION
				
	Creator: @Valkzius
	Name: Quicknum
	Description: A number library designed to be the fastest possible with numbers up to ~ee307.73 | 2^2^1024
	please give credit if used
	
		Function List
	
	Remember to scroll down
		
CONVERSION:
	.fromNumber(number) => converts number to quicknum
	.toNumber(quicknum) => converts quicknum to number
	.new(a,b)           => creates quicknum equal to a * 2^b
	.new10(a,b)           => creates quicknum equal to a * 10^b
	
ROUNDING:
	.floor(n)        => greatest integer less than n
	.round(n)        => closest integer to n
	.ceil(n)         => least integer greater than n
	
COMPARISON:
	.eq(n1, n2)      => a == b
	.lt(n1, n2)      => a < b
	.gt(n1, n2)      => a > b
	.lte(n1, n2)     => a <= b
	.gte(n1, n2)     => a >= b
	
ARITHMETIC:
	.add(n1,n2)      => n1 + n2
	.sub(n1,n2)      => n1 - n2
	.mul(n1,n2)      => n1 * n2
	.div(n1,n2)      => n1 / n2
	.recip(n)        => 1 / n
	.intdiv(n1,n2)   => n1 // n2 -- division then floor ex. 33 // 4 = 8
	.mod(n1,n2)      => n1 % n2
	.pow(n1,n2)      => n1 ^ n2
	.root(n1,n2)     => n1 ^ (1 / n2)
	.sqrt(n)         => n ^ 0.5
	.pow2(n)         => 2 ^ n
	.pow10(n)        => 10 ^ n
	.exp(n)          => e ^ n (e = ~2.71828)
	.log(n1,n2)      => logarithm of n1 in base n2
	.log10(n)        => logarithm of n in base 10
	.log2(n)         => logarithm of n in base 2
	.ln(n)           => natural logarithm of n (base ~2.71828)
	.neg(n)          => -n
	.abs(n)          => |n| -- absolute value of n
	
EQUALS:
	.addeq(n1,n2)    => n1 += n2
	.subeq(n1,n2)    => n1 -= n2
	.muleq(n1,n2)    => n1 *= n2
	.diveq(n1,n2)    => n1 /= n2
	.recipeq(n)      => n = 1 / n
	.intdiveq(n1,n2) => n1 //= n2 -- division then floor ex. 33 // 4 = 8
	.modeq(n1,n2)    => n1 %= n2
	.poweq(n1,n2)    => n1 ^= n2
	.rooteq(n1,n2)   => n1 ^= (1 / n2)
	.sqrteq(n)       => n ^= 0.5
	.pow2eq(n)       => n = 2 ^ n
	.pow10eq(n)      => n = 10 ^ n
	.expeq(n)        => n = e ^ n (e = ~2.71828)
	.logeq(n1,n2)    => n1 = logarithm of n1 in base n2
	.log10eq(n)      => n = logarithm of n in base 10
	.log2eq(n)       => n = logarithm of n in base 2
	.lneq(n)         => n = natural logarithm of n (base ~2.71828)
	.negeq(n)        => n = -n
	.abseq(n)        => n = |n| -- absolute value of n

MISC:
	.sign(n)       => returns 1 if n is positive, -1 if negative, and 0 if n equals 0
	.isPositive(n) => returns true if n is positive, else false
	.isNegative(n) => returns true if n is negative, else false
	.isZero(n)     => returns true if n is zero, else false
	
	.lbencode(n) => encodes n into something that could be stored in an OrderedDataStore
	.lbdecode(n) => decodes n from .lbencode()
	.encode(n) => encodes n into a string without data loss
	.decode(n) => decodes n from .encode()
	
	.random(n1,n2)    => random number between n1 and n2
	.geosum(base,mul,start,last)    => sum of geometric series from start -> last	
	.geosumR(base,mul,start,amount) => end index of geometric series that starts from 'start' and sums to amount

STRING:
	.tostring(n,suffixtype) => converts using the suffix type given (defaults to .DefaultSuffixType below)
	.scientific(n) => converts n to scientific notation without rounding
]]
local num = {}
num.SuffixTypes = {
	Scientific =     0 , -- scientific notation is always on (ex. 5.756e2)
	Scientific3 =    1 , -- scientific notation starts at 1e3 (ex. 5.756e8)
	Scientific36 =   2 , -- scientific notation starts at 1e36 (ex. 5.756e38)
	Scientific306 =  3 , -- scientific notation starts at 1e306 (ex. 5.756e308)
	Scientific3006 = 4 , -- scientific notation starts at 1e3006 (ex. 5.756e3008)
	Engineer = 	     5 , -- engineer notation is always on (ex. 575.6e0)
	Engineer3 =      6 , -- engineer notation starts at 1e3 (ex. 575.6e6)
	Engineer36 =     7 , -- engineer notation starts at 1e36 (ex. 575.6e36)
	Engineer306 =    8 , -- engineer notation starts at 1e306 (ex. 575.6e306)
	Engineer3006 =   9 , -- engineer notation starts at 1e3006 (ex. 575.6e3006)
	Alphabet =    10, -- alphabet notation engineer style (ex. 53,000,000 = 53.00ab, starts at 1e3)
}
num.DefaultSuffixType = num.SuffixTypes.Scientific306
--[[
		HELPFUL TIPS
		
1: 
	DONT DO THIS: n1 = .add(n1,n2)
	DO THIS: .addeq(n1,n2)
	WHY?: Due to optimizations its over twice as fast to do the .addeq() method,
		this also applies to any other function with a counterpart in the EQUALS section.
	
2:
	DONT DO THIS: .add(n1, .fromNumber(n2))
	DO THIS: .add(n1,n2) [even if n2 is a number]
	WHY?: We automatically convert numbers to our format and it's faster,
		this also applies to almost all functions.
		
]]
local THRESHOLD = 53
local intmax = 2^THRESHOLD
local convert10 = math.log10(2)
local convertE = math.log(2)
local powlist = {}
for i=1,THRESHOLD do powlist[i] = 2^-i end
--[[
	Returns both parts of a Quicknum
]]
function num.show(n) 
	return buffer.readf64(n,0),buffer.readf64(n,8)
end
--[[
	Converts number to a Quicknum
]]
function num.fromNumber(n) 
	local buf = buffer.create(16)
	local m,e = math.frexp(n)
	buffer.writef64(buf,0,m)
	buffer.writef64(buf,8,e)
	return buf
end
--[[
	Converts Quicknum to a number
]]
function num.toNumber(n)
	if type(n) ~= "buffer" then 
		error("Wrong Type: toNumber(), Input 1")
	end
	return math.ldexp(buffer.readf64(n,0),buffer.readf64(n,8))
end
--[[
	Creates Quicknum equal to a * 2^b
]]
function num.new(a,b)
	local buf = buffer.create(16)
	if a == 0 then 
		return buf
	end
	local m,e = math.frexp(a)
	buffer.writef64(buf,0,m)
	buffer.writef64(buf,8,b+e)
	return buf
end
--[[
	Creates Quicknum equal to a * 10^b
]]
function num.new10(a,b)
	local buf = buffer.create(16)
	if a == 0 then 
		return buf
	end
	b /= convert10
	local floor = math.floor(b)
	local m,e = math.frexp(a * math.pow(2,b - floor))
	buffer.writef64(buf,0,m)
	buffer.writef64(buf,8,floor+e)
	return buf
end
--[[
	n1 < n2
]]
function num.lt(n1, n2)
	local m1,e1,m2,e2
	if type(n1) == "buffer" then
		m1 = buffer.readf64(n1,0)
		e1 = buffer.readf64(n1,8)
	elseif type(n1) == "number" then
		m1,e1 = math.frexp(n1)
	else
		error("Wrong Type: lt(), Input 1")
	end
	if type(n2) == "buffer" then
		m2 = buffer.readf64(n2,0)
		e2 = buffer.readf64(n2,8)
	elseif type(n2) == "number" then
		m2,e2 = math.frexp(n2)
	else
		error("Wrong Type: lt(), Input 2")
	end
	local sign1 = math.sign(m1)
	local sign2 = math.sign(m2)
	if sign1 < sign2 then return true
	elseif sign1 > sign2 then return false
	elseif e1 == e2 then return m1 < m2
	else return e1 < e2 end
end
--[[
	n1 <= n2
]]
function num.lte(n1, n2)
	local m1,e1,m2,e2
	if type(n1) == "buffer" then
		m1 = buffer.readf64(n1,0)
		e1 = buffer.readf64(n1,8)
	elseif type(n1) == "number" then
		m1,e1 = math.frexp(n1)
	else
		error("Wrong Type: lte(), Input 1")
	end
	if type(n2) == "buffer" then
		m2 = buffer.readf64(n2,0)
		e2 = buffer.readf64(n2,8)
	elseif type(n2) == "number" then
		m2,e2 = math.frexp(n2)
	else
		error("Wrong Type: lte(), Input 2")
	end
	local sign1 = math.sign(m1)
	local sign2 = math.sign(m2)
	if sign1 < sign2 then return true
	elseif sign1 > sign2 then return false
	elseif e1 == e2 then return n1 <= n2
	else return e1 <= e2 end
end
--[[
	n1 > n2
]]
function num.gt(n1, n2)
	local m1,e1,m2,e2
	if type(n1) == "buffer" then
		m1 = buffer.readf64(n1,0)
		e1 = buffer.readf64(n1,8)
	elseif type(n1) == "number" then
		m1,e1 = math.frexp(n1)
	else
		error("Wrong Type: gt(), Input 1")
	end
	if type(n2) == "buffer" then
		m2 = buffer.readf64(n2,0)
		e2 = buffer.readf64(n2,8)
	elseif type(n2) == "number" then
		m2,e2 = math.frexp(n2)
	else
		error("Wrong Type: gt(), Input 2")
	end
	local sign1 = math.sign(m1)
	local sign2 = math.sign(m2)
	if sign1 > sign2 then return true
	elseif sign1 < sign2 then return false
	elseif e1 == e2 then return m1 > m2
	else return e1 > e2 end
end
--[[
	n1 >= n2
]]
function num.gte(n1, n2)
	local m1,e1,m2,e2
	if type(n1) == "buffer" then
		m1 = buffer.readf64(n1,0)
		e1 = buffer.readf64(n1,8)
	elseif type(n1) == "number" then
		m1,e1 = math.frexp(n1)
	else
		error("Wrong Type: gte(), Input 1")
	end
	if type(n2) == "buffer" then
		m2 = buffer.readf64(n2,0)
		e2 = buffer.readf64(n2,8)
	elseif type(n2) == "number" then
		m2,e2 = math.frexp(n2)
	else
		error("Wrong Type: gte(), Input 2")
	end
	local sign1 = math.sign(m1)
	local sign2 = math.sign(m2)
	if sign1 > sign2 then return true
	elseif sign1 < sign2 then return false
	elseif e1 == e2 then return m1 >= m2
	else return e1 >= e2 end
end
--[[
	n1 == n2
]]
function num.eq(n1, n2)
	local m1,e1,m2,e2
	if type(n1) == "buffer" then
		m1 = buffer.readf64(n1,0)
		e1 = buffer.readf64(n1,8)
	elseif type(n1) == "number" then
		m1,e1 = math.frexp(n1)
	else
		error("Wrong Type: eq(), Input 1")
	end
	if type(n2) == "buffer" then
		m2 = buffer.readf64(n2,0)
		e2 = buffer.readf64(n2,8)
	elseif type(n2) == "number" then
		m2,e2 = math.frexp(n2)
	else
		error("Wrong Type: eq(), Input 2")
	end
	return m1 == m2 and e1 == e2
end
--[[
	Greastest integer that is less than n
]]
function num.floor(n)
	local buf = buffer.create(16)
	if type(n) == "buffer" then
		local m = buffer.readf64(n,0)
		local e = buffer.readf64(n,8)
		if m == 0 then
			return buf
		elseif e < 1 then
			if m > 0 then
				return buf
			else
				buffer.writef64(buf,0,-0.5)
				buffer.writef64(buf,8,1)
				return buf
			end
		end
		if e > THRESHOLD then
			buffer.writef64(buf,0,m)
			buffer.writef64(buf,8,e)
			return buf
		end
		m,e = math.frexp(math.floor(math.ldexp(m,e)))
		buffer.writef64(buf,0,m)
		buffer.writef64(buf,8,e)
		return buf
	elseif type(n) == "number" then
		local m,e = math.frexp(math.floor(n))
		buffer.writef64(buf,0,m)
		buffer.writef64(buf,8,e)
		return buf
	else
		error("Wrong Type: floor(), Input 1")
	end
end
--[[
	Closest integer to n
]]
function num.round(n)
	local buf = buffer.create(16)
	if type(n) == "buffer" then
		local m = buffer.readf64(n,0)
		local e = buffer.readf64(n,8)
		if m == 0 then
			return buf
		end
		if e < 0 then
			return buf
		elseif e > THRESHOLD then
			buffer.writef64(buf,0,m)
			buffer.writef64(buf,8,e)
			return buf
		end
		m,e = math.frexp(math.round(math.ldexp(m,e)))
		buffer.writef64(buf,0,m)
		buffer.writef64(buf,8,e)
		return buf
	elseif type(n) == "number" then
		local m,e = math.frexp(math.round(n))
		buffer.writef64(buf,0,m)
		buffer.writef64(buf,8,e)
		return buf
	else
		error("Wrong Type: round(), Input 1")
	end
end
--[[
	Least integer that is greater than n
]]
function num.ceil(n)
	local buf = buffer.create(16)
	if type(n) == "buffer" then
		local m = buffer.readf64(n,0)
		local e = buffer.readf64(n,8)
		if m == 0 then
			return buf
		elseif e < 1 then
			if m < 0 then
				return buf
			else
				buffer.writef64(buf,0,0.5)
				buffer.writef64(buf,8,1)
				return buf
			end
		end
		if e > THRESHOLD then
			buffer.writef64(buf,0,m)
			buffer.writef64(buf,8,e)
			return buf
		end
		m,e = math.frexp(math.ceil(math.ldexp(m,e)))
		buffer.writef64(buf,0,m)
		buffer.writef64(buf,8,e)
		return buf
	elseif type(n) == "number" then
		local m,e = math.frexp(math.ceil(n))
		buffer.writef64(buf,0,m)
		buffer.writef64(buf,8,e)
		return buf
	else
		error("Wrong Type: ceil(), Input 1")
	end
end
--[[
	n1 + n2
	Sum of n1 and n2
]]
function num.add(n1,n2)
	local m1,e1,m2,e2
	if type(n1) == "buffer" then
		m1 = buffer.readf64(n1,0)
		e1 = buffer.readf64(n1,8)
	elseif type(n1) == "number" then
		m1,e1 = math.frexp(n1)
	else
		error("Wrong Type: add(), Input 1")
	end
	if type(n2) == "buffer" then
		m2 = buffer.readf64(n2,0)
		e2 = buffer.readf64(n2,8)
	elseif type(n2) == "number" then
		m2,e2 = math.frexp(n2)
	else
		error("Wrong Type: add(), Input 2")
	end
	local exponentDiff = e1 - e2
	local buf = buffer.create(16)
	if exponentDiff > THRESHOLD then
		buffer.writef64(buf,0,m1)
		buffer.writef64(buf,8,e1)
		return buf
	elseif exponentDiff <-THRESHOLD then 
		buffer.writef64(buf,0,m2)
		buffer.writef64(buf,8,e2)
		return buf
	elseif exponentDiff == 0 then 
		local m,e = math.frexp(m1 + m2)
		buffer.writef64(buf,0,m)
		buffer.writef64(buf,8,e+e1)
		return buf
	elseif e1 > e2 then 
		local m,e = math.frexp(m1 + m2 * powlist[exponentDiff])
		buffer.writef64(buf,0,m)
		buffer.writef64(buf,8,e+e1)
		return buf
	else 
		local m,e = math.frexp(m1 * powlist[-exponentDiff] + m2)
		buffer.writef64(buf,0,m)
		buffer.writef64(buf,8,e+e2)
		return buf
	end
end
--[[
	n1 - n2
	Difference of n1 and n2
]]
function num.sub(n1,n2)
	local m1,e1,m2,e2
	if type(n1) == "buffer" then
		m1 = buffer.readf64(n1,0)
		e1 = buffer.readf64(n1,8)
	elseif type(n1) == "number" then
		m1,e1 = math.frexp(n1)
	else
		error("Wrong Type: sub(), Input 1")
	end
	if type(n2) == "buffer" then
		m2 = buffer.readf64(n2,0)
		e2 = buffer.readf64(n2,8)
	elseif type(n2) == "number" then
		m2,e2 = math.frexp(n2)
	else
		error("Wrong Type: sub(), Input 2")
	end
	local exponentDiff = e1 - e2
	local buf = buffer.create(16)
	if exponentDiff > THRESHOLD then
		buffer.writef64(buf,0,m1)
		buffer.writef64(buf,8,e1)
		return buf
	elseif exponentDiff <-THRESHOLD then 
		buffer.writef64(buf,0,-m2)
		buffer.writef64(buf,8,e2)
		return buf
	elseif exponentDiff == 0 then 
		local m,e = math.frexp(m1 - m2)
		buffer.writef64(buf,0,m)
		buffer.writef64(buf,8,e+e1)
		return buf
	elseif e1 > e2 then 
		local m,e = math.frexp(m1 - m2 * powlist[exponentDiff])
		buffer.writef64(buf,0,m)
		buffer.writef64(buf,8,e+e1)
		return buf
	else 
		local m,e = math.frexp(m1 * powlist[-exponentDiff] - m2)
		buffer.writef64(buf,0,m)
		buffer.writef64(buf,8,e+e2)
		return buf
	end
end
--[[
	n1 * n2
	Product of n1 and n2
]]
function num.mul(n1,n2)
	local m1,e1,m2,e2
	if type(n1) == "buffer" then
		m1 = buffer.readf64(n1,0)
		e1 = buffer.readf64(n1,8)
	elseif type(n1) == "number" then
		m1,e1 = math.frexp(n1)
	else
		error("Wrong Type: mul(), Input 1")
	end
	if type(n2) == "buffer" then
		m2 = buffer.readf64(n2,0)
		e2 = buffer.readf64(n2,8)
	elseif type(n2) == "number" then
		m2,e2 = math.frexp(n2)
	else
		error("Wrong Type: mul(), Input 2")
	end
	local buf = buffer.create(16)
	if m1 == 0 or m2 == 0 then
		return buf
	end
	local m = m1 * m2
	if math.abs(m) < 0.5 then
		buffer.writef64(buf,0,m * 2)
		buffer.writef64(buf,8,e1 + e2 - 1)
		return buf
	else
		buffer.writef64(buf,0,m)
		buffer.writef64(buf,8,e1 + e2)
		return buf
	end
end
--[[
	n1 / n2
	Quotient of n1 and n2
]]
function num.div(n1,n2)
	local m1,e1,m2,e2
	if type(n1) == "buffer" then
		m1 = buffer.readf64(n1,0)
		e1 = buffer.readf64(n1,8)
	elseif type(n1) == "number" then
		m1,e1 = math.frexp(n1)
	else
		error("Wrong Type: div(), Input 1")
	end
	if type(n2) == "buffer" then
		m2 = buffer.readf64(n2,0)
		e2 = buffer.readf64(n2,8)
	elseif type(n2) == "number" then
		m2,e2 = math.frexp(n2)
	else
		error("Wrong Type: div(), Input 2")
	end
	local buf = buffer.create(16)
	if m1 == 0 or m2 == 0 then
		return buf
	end
	local m = m1 / m2
	if math.abs(m) >= 1 then
		buffer.writef64(buf,0,m / 2)
		buffer.writef64(buf,8,e1 - e2 + 1)
		return buf
	else
		buffer.writef64(buf,0,m)
		buffer.writef64(buf,8,e1 - e2)
		return buf
	end
end
--[[
	1 / n
	Reciprocal of n
]]
function num.recip(n)
	local buf = buffer.create(16)
	if type(n) == "buffer" then
		local m = buffer.readf64(n,0)
		if m == 0 then
			return buf
		end
		m = 0.5 / m
		if math.abs(m) >= 1 then
			buffer.writef64(buf,0,m / 2)
			buffer.writef64(buf,8,2 - buffer.readf64(n,8))
			return buf
		else
			buffer.writef64(buf,0,m)
			buffer.writef64(buf,8,1 - buffer.readf64(n,8))
			return buf
		end
	elseif type(n) == "number" then
		if n == 0 then
			return buf
		end
		local m,e = math.frexp(1 / n)
		buffer.writef64(buf,0,m)
		buffer.writef64(buf,8,e)
		return buf
	else
		error("Wrong Type: recip(), Input 1")
	end
end
--[[
	n1 // n2
	Integer Quotient of n1 and n2
]]
function num.intdiv(n1,n2)
	local m1,e1,m2,e2
	if type(n1) == "buffer" then
		m1 = buffer.readf64(n1,0)
		e1 = buffer.readf64(n1,8)
	elseif type(n1) == "number" then
		m1,e1 = math.frexp(n1)
	else
		error("Wrong Type: intdiv(), Input 1")
	end
	if type(n2) == "buffer" then
		m2 = buffer.readf64(n2,0)
		e2 = buffer.readf64(n2,8)
	elseif type(n2) == "number" then
		m2,e2 = math.frexp(n2)
	else
		error("Wrong Type: intdiv(), Input 2")
	end
	local buf = buffer.create(16)
	if m1 == 0 or m2 == 0 then
		return buf
	end
	local m = m1 / m2
	local e = e1 - e2
	if math.abs(m) >= 1 then
		m /= 2
		e += 1
	end
	if e < 1 then
		if m > 0 then
			return buf
		else
			buffer.writef64(buf,0,-0.5)
			buffer.writef64(buf,8,1)
			return buf
		end
	end
	if e > THRESHOLD then
		buffer.writef64(buf,0,m)
		buffer.writef64(buf,8,e)
		return buf
	end
	m,e = math.frexp(math.floor(math.ldexp(m,e)))
	buffer.writef64(buf,0,m)
	buffer.writef64(buf,8,e)
	return buf
end
--[[
	n1 % n2
	Modulus of n1 and n2
]]
function num.mod(n1,n2)
	local m1,e1,m2,e2
	if type(n1) == "buffer" then
		m1 = buffer.readf64(n1,0)
		e1 = buffer.readf64(n1,8)
	elseif type(n1) == "number" then
		m1,e1 = math.frexp(n1)
	else
		error("Wrong Type: mod(), Input 1")
	end
	if type(n2) == "buffer" then
		m2 = buffer.readf64(n2,0)
		e2 = buffer.readf64(n2,8)
	elseif type(n2) == "number" then
		m2,e2 = math.frexp(n2)
	else
		error("Wrong Type: mod(), Input 2")
	end
	local buf = buffer.create(16)
	if m1 == 0 or m2 == 0 then
		return buf
	end
	local m3 = m1 / m2
	local e3 = e1 - e2
	if math.abs(m3) >= 1 then
		m3 /= 2
		e3 += 1
	end
	if e3 < 1 then
		if m3 > 0 then
			buffer.writef64(buf,0,m1)
			buffer.writef64(buf,8,e1)
			return buf
		else
			m3 = -0.5
			e3 = 1
		end
	elseif e3 <= THRESHOLD then
		m3,e3 =  math.frexp(math.floor(math.ldexp(m3,e3)))
	end
	m3 *= m2
	e3 += e2
	if math.abs(m3) <= 0.5 then
		m3 *= 2
		e3 -= 1
	end
	local exponentDiff = e1 - e3
	if exponentDiff > THRESHOLD then
		buffer.writef64(buf,0,m1)
		buffer.writef64(buf,8,e1)
		return buf
	elseif exponentDiff <-THRESHOLD then 
		buffer.writef64(buf,0,-m3)
		buffer.writef64(buf,8,e3)
		return buf
	elseif exponentDiff == 0 then 
		local m,e = math.frexp(m1 - m3)
		buffer.writef64(buf,0,m)
		buffer.writef64(buf,8,e+e1)
		return buf
	elseif e1 > e2 then 
		local m,e = math.frexp(m1 - m3 * powlist[exponentDiff])
		buffer.writef64(buf,0,m)
		buffer.writef64(buf,8,e+e1)
		return buf
	else 
		local m,e = math.frexp(m1 * powlist[-exponentDiff] - m3)
		buffer.writef64(buf,0,m)
		buffer.writef64(buf,8,e+e3)
		return buf
	end
end
--[[
	n1 ^ n2
	Exponentiation of n1 and n2
]]
function num.pow(n1,n2)
	local m1,e1
	if type(n1) == "buffer" then
		m1 = buffer.readf64(n1,0)
		e1 = buffer.readf64(n1,8)
	elseif type(n1) == "number" then
		m1,e1 = math.frexp(n1)
	else
		error("Wrong Type: pow(), Input 1")
	end
	local buf = buffer.create(16)
	if m1 == 0 then
		return buf 
	elseif m1 == 0.5 and e1 == 1 then
		buffer.writef64(buf,0,0.5)
		buffer.writef64(buf,8,1)
		return buf
	end
	if type(n2) == "buffer" then
		if buffer.readf64(n2,0) == 0 then
			buffer.writef64(buf,0,0.5)
			buffer.writef64(buf,8,1)
			return buf
		end
		local exp = (e1 + math.log(math.abs(m1),2)) * math.ldexp(buffer.readf64(n2,0),buffer.readf64(n2,8))
		local floor = math.floor(exp)
		buffer.writef64(buf,0,math.sign(m1)*math.pow(2, exp - floor - 1))
		buffer.writef64(buf,8,floor + 1)
		return buf
	elseif type(n2) == "number" then
		if n2 == 0 then
			buffer.writef64(buf,0,0.5)
			buffer.writef64(buf,8,1)
			return buf
		end
		local exp = (e1 + math.log(math.abs(m1),2)) * n2
		local floor = math.floor(exp)
		buffer.writef64(buf,0,math.sign(m1)*math.pow(2, exp - floor - 1))
		buffer.writef64(buf,8,floor + 1)
		return buf
	else
		error("Wrong Type: pow(), Input 2")
	end
end
--[[
	n1 ^ (1 / n2)
	Root of n1 and n2
]]
function num.root(n1,n2)
	local m1,e1
	if type(n1) == "buffer" then
		m1 = buffer.readf64(n1,0)
		e1 = buffer.readf64(n1,8)
	elseif type(n1) == "number" then
		m1,e1 = math.frexp(n1)
	else
		error("Wrong Type: root(), Input 1")
	end
	local buf = buffer.create(16)
	if m1 == 0 then
		return buf 
	elseif m1 == 0.5 and e1 == 1 then
		buffer.writef64(buf,0,0.5)
		buffer.writef64(buf,8,1)
		return buf
	end
	if type(n2) == "buffer" then
		if buffer.readf64(n2,0) == 0 then
			buffer.writef64(buf,0,0.5)
			buffer.writef64(buf,8,1)
			return buf
		end
		local exp = (e1 + math.log(math.abs(m1),2)) / math.ldexp(buffer.readf64(n2,0),buffer.readf64(n2,8))
		local floor = math.floor(exp)
		buffer.writef64(buf,0,math.sign(m1)*math.pow(2, exp - floor - 1))
		buffer.writef64(buf,8,floor + 1)
		return buf
	elseif type(n2) == "number" then
		if n2 == 0 then
			buffer.writef64(buf,0,0.5)
			buffer.writef64(buf,8,1)
			return buf
		end
		local exp = (e1 + math.log(math.abs(m1),2)) / n2
		local floor = math.floor(exp)
		buffer.writef64(buf,0,math.sign(m1)*math.pow(2, exp - floor - 1))
		buffer.writef64(buf,8,floor + 1)
		return buf
	else
		error("Wrong Type: root(), Input 2")
	end
end
--[[
	n ^ 0.5
	Square Root of n
]]
function num.sqrt(n)
	local m,e
	if type(n) == "buffer" then
		m = buffer.readf64(n,0)
		e = buffer.readf64(n,8)
	elseif type(n) == "number" then
		m,e = math.frexp(n)
	else
		error("Wrong Type: sqrt(), Input 1")
	end
	local buf = buffer.create(16)
	if m == 0 then
		return buf 
	elseif m == 0.5 and e == 1 then
		buffer.writef64(buf,0,0.5)
		buffer.writef64(buf,8,1)
		return buf
	end
	local exp = e / 2
	local floor = math.floor(exp)
	local a,b = math.frexp(math.pow(2, exp - floor) * (if m > 0 then math.pow(m, 0.5) else -math.pow(-m, 0.5)))
	buffer.writef64(buf,0,a)
	buffer.writef64(buf,8,b + floor)
	return buf
end
--[[
	2 ^ n
	Exponentiation of 2 and n
]]
function num.pow2(n)
	local m,e
	if type(n) == "buffer" then
		m = buffer.readf64(n,0)
		e = buffer.readf64(n,8)
	elseif type(n) == "number" then
		m,e = math.frexp(n)
	else
		error("Wrong Type: pow2(), Input 1")
	end
	local buf = buffer.create(16)
	local exp = math.ldexp(m,e)
	local floor = math.floor(exp)
	buffer.writef64(buf,0,math.pow(2, exp - floor - 1))
	buffer.writef64(buf,8,floor + 1)
	return buf
end
--[[
	10 ^ n
	Exponentiation of 10 and n
]]
function num.pow10(n)
	local m,e
	if type(n) == "buffer" then
		m = buffer.readf64(n,0)
		e = buffer.readf64(n,8)
	elseif type(n) == "number" then
		m,e = math.frexp(n)
	else
		error("Wrong Type: pow10(), Input 1")
	end
	local buf = buffer.create(16)
	local exp = math.ldexp(m,e) / convert10
	local floor = math.floor(exp)
	buffer.writef64(buf,0,math.pow(2, exp - floor - 1))
	buffer.writef64(buf,8,floor + 1)
	return buf
end
--[[
	e ^ n (e = ~2.71828)
	Exponentiation of e and n
]]
function num.exp(n)
	local m,e
	if type(n) == "buffer" then
		m = buffer.readf64(n,0)
		e = buffer.readf64(n,8)
	elseif type(n) == "number" then
		m,e = math.frexp(n)
	else
		error("Wrong Type: exp(), Input 1")
	end
	local buf = buffer.create(16)
	local exp = math.ldexp(m,e) / convertE
	local floor = math.floor(exp)
	buffer.writef64(buf,0,math.pow(2, exp - floor - 1))
	buffer.writef64(buf,8,floor + 1)
	return buf
end
--[[
	Logarithm of n1 in base n2
]]
function num.log(n1,n2)
	local m1,e1
	if type(n1) == "buffer" then
		m1 = buffer.readf64(n1,0)
		e1 = buffer.readf64(n1,8)
	elseif type(n1) == "number" then
		m1,e1 = math.frexp(n1)
	else
		error("Wrong Type: log(), Input 1")
	end
	local buf = buffer.create(16)
	if m1 == 0 or (e1 == 1 and m1 == 0.5) then
		return buf
	end
	if type(n2) == "buffer" then
		if buffer.readf64(n2,0) == 0.5 and buffer.readf64(n2,8) == 1 then
			return buf
		end
		local n1m,n1e = math.frexp(e1 + math.log(m1,2))
		local n2m,n2e = math.frexp(buffer.readf64(n2,8) + math.log(buffer.readf64(n2,0),2) - 1)
		n1m /= n2m
		if math.abs(n1m) >= 1 then
			buffer.writef64(buf,0,n1m/2)
			buffer.writef64(buf,8,n1e-n2e+1)
			return buf
		else
			buffer.writef64(buf,0,n1m)
			buffer.writef64(buf,8,n1e-n2e)
			return buf
		end
	elseif type(n2) == "number" then
		if n2 == 1 then
			return buf
		end
		local a,b = math.frexp(e1 * math.log(2,n2) + math.log(m1,n2))
		buffer.writef64(buf,0,a)
		buffer.writef64(buf,8,b)
		return buf
	else
		error("Wrong Type: log(), Input 2")
	end
end
--[[
	Logarithm of n in base 10
]]
function num.log10(n)
	local m,e
	if type(n) == "buffer" then
		m = buffer.readf64(n,0)
		e = buffer.readf64(n,8)
	elseif type(n) == "number" then
		m,e = math.frexp(n)
	else
		error("Wrong Type: log10(), Input 1")
	end
	local buf = buffer.create(16)
	if m == 0 or (e == 1 and m == 0.5) then
		return buf
	end
	local a,b = math.frexp(e * convert10 + math.log10(m))
	buffer.writef64(buf,0,a)
	buffer.writef64(buf,8,b)
	return buf
end
--[[
	Logarithm of n in base 2
]]
function num.log2(n)
	local m,e
	if type(n) == "buffer" then
		m = buffer.readf64(n,0)
		e = buffer.readf64(n,8)
	elseif type(n) == "number" then
		m,e = math.frexp(n)
	else
		error("Wrong Type: log2(), Input 1")
	end
	local buf = buffer.create(16)
	if m == 0 or (e == 1 and m == 0.5) then
		return buf
	end
	local a,b = math.frexp(e + math.log(m,2))
	buffer.writef64(buf,0,a)
	buffer.writef64(buf,8,b)
	return buf
end
--[[
	Natural Logarithm of n (base ~2.71828)
]]
function num.ln(n)
	local m,e
	if type(n) == "buffer" then
		m = buffer.readf64(n,0)
		e = buffer.readf64(n,8)
	elseif type(n) == "number" then
		m,e = math.frexp(n)
	else
		error("Wrong Type: ln(), Input 1")
	end
	local buf = buffer.create(16)
	if m == 0 or (e == 1 and m == 0.5) then
		return buf
	end
	local a,b = math.frexp(e * convertE + math.log(m))
	buffer.writef64(buf,0,a)
	buffer.writef64(buf,8,b)
	return buf
end
--[[
	-n
	Negative n
]]
function num.neg(n)
	if type(n) == "buffer" then
		local buf = buffer.create(16)
		buffer.writef64(buf,0,-buffer.readf64(n,0))
		buffer.writef64(buf,8,buffer.readf64(n,8))
		return buf
	elseif type(n) == "number" then
		local m,e = math.frexp(n)
		local buf = buffer.create(16)
		buffer.writef64(buf,0,-m)
		buffer.writef64(buf,8,e)
		return buf
	else
		error("Wrong Type: neg(), Input 1")
	end
end
--[[
	|n|
	Absolute value of n
]]
function num.abs(n)
	if type(n) == "buffer" then
		local buf = buffer.create(16)
		buffer.writef64(buf,0,math.abs(buffer.readf64(n,0)))
		buffer.writef64(buf,8,buffer.readf64(n,8))
		return buf
	elseif type(n) == "number" then
		local m,e = math.frexp(n)
		local buf = buffer.create(16)
		buffer.writef64(buf,0,math.abs(m))
		buffer.writef64(buf,8,e)
		return buf
	else
		error("Wrong Type: abs(), Input 1")
	end
end
--[[
	n1 += n2
	Sets n1 to the Sum of n1 and n2
]]
function num.addeq(n1,n2)
	if type(n1) ~= "buffer" then error("Wrong Type: addeq(), Input 1") end
	local m2,e2
	if type(n2) == "buffer" then
		m2 = buffer.readf64(n2,0)
		e2 = buffer.readf64(n2,8)
	elseif type(n2) == "number" then
		m2,e2 = math.frexp(n2)
	else
		error("Wrong Type: addeq(), Input 2")
	end
	local exponentDiff = buffer.readf64(n1,8) - e2
	if exponentDiff > THRESHOLD then
		return n1
	elseif exponentDiff <-THRESHOLD then 
		buffer.writef64(n1,0,m2)
		buffer.writef64(n1,8,e2)
		return n1
	elseif exponentDiff == 0 then 
		local m,e = math.frexp(buffer.readf64(n1,0) + m2)
		buffer.writef64(n1,0,m)
		buffer.writef64(n1,8,e+buffer.readf64(n1,8))
		return n1
	elseif buffer.readf64(n1,8) > e2 then 
		local m,e = math.frexp(buffer.readf64(n1,0) + m2 * powlist[exponentDiff])
		buffer.writef64(n1,0,m)
		buffer.writef64(n1,8,e+buffer.readf64(n1,8))
		return n1
	else 
		local m,e = math.frexp(buffer.readf64(n1,0) * powlist[-exponentDiff] + m2)
		buffer.writef64(n1,0,m)
		buffer.writef64(n1,8,e+e2)
		return n1
	end
end
--[[
	n1 -= n2
	Sets n1 to the Difference of n1 and n2
]]
function num.subeq(n1,n2)
	if type(n1) ~= "buffer" then error("Wrong Type: subeq(), Input 1") end
	local m2,e2
	if type(n2) == "buffer" then
		m2 = buffer.readf64(n2,0)
		e2 = buffer.readf64(n2,8)
	elseif type(n2) == "number" then
		m2,e2 = math.frexp(n2)
	else
		error("Wrong Type: subeq(), Input 2")
	end
	local exponentDiff = buffer.readf64(n1,8) - e2
	if exponentDiff > THRESHOLD then
		return n1
	elseif exponentDiff <-THRESHOLD then 
		buffer.writef64(n1,0,-m2)
		buffer.writef64(n1,8,e2)
		return n1
	elseif exponentDiff == 0 then 
		local m,e = math.frexp(buffer.readf64(n1,0) - m2)
		buffer.writef64(n1,0,m)
		buffer.writef64(n1,8,e+buffer.readf64(n1,8))
		return n1
	elseif buffer.readf64(n1,8) > e2 then 
		local m,e = math.frexp(buffer.readf64(n1,0) - m2 * powlist[exponentDiff])
		buffer.writef64(n1,0,m)
		buffer.writef64(n1,8,e+buffer.readf64(n1,8))
		return n1
	else 
		local m,e = math.frexp(buffer.readf64(n1,0) * powlist[-exponentDiff] - m2)
		buffer.writef64(n1,0,m)
		buffer.writef64(n1,8,e+e2)
		return n1
	end
end
--[[
	n1 *= n2
	Sets n1 to the Product of n1 and n2
]]
function num.muleq(n1,n2)
	if type(n1) ~= "buffer" then error("Wrong Type: muleq(), Input 1") end
	local m2,e2
	if type(n2) == "buffer" then
		m2 = buffer.readf64(n2,0)
		e2 = buffer.readf64(n2,8)
	elseif type(n2) == "number" then
		m2,e2 = math.frexp(n2)
	else
		error("Wrong Type: muleq(), Input 2")
	end
	if buffer.readf64(n1,0) == 0 or m2 == 0 then
		buffer.writef64(n1,0,0)
		buffer.writef64(n1,8,0)
		return n1
	end
	local m = buffer.readf64(n1,0) * m2
	if math.abs(m) < 0.5 then
		buffer.writef64(n1,0,m * 2)
		buffer.writef64(n1,8,buffer.readf64(n1,8) + e2 - 1)
		return n1
	else
		buffer.writef64(n1,0,m)
		buffer.writef64(n1,8,buffer.readf64(n1,8) + e2)
		return n1
	end
end
--[[
	n1 /= n2
	Sets n1 to the Quotient of n1 and n2
]]
function num.diveq(n1,n2)
	if type(n1) ~= "buffer" then error("Wrong Type: diveq(), Input 1") end
	local m2,e2
	if type(n2) == "buffer" then
		m2 = buffer.readf64(n2,0)
		e2 = buffer.readf64(n2,8)
	elseif type(n2) == "number" then
		m2,e2 = math.frexp(n2)
	else
		error("Wrong Type: diveq(), Input 2")
	end
	if buffer.readf64(n1,0) == 0 or m2 == 0 then
		buffer.writef64(n1,0,0)
		buffer.writef64(n1,8,0)
		return n1
	end
	local m = buffer.readf64(n1,0) / m2
	if math.abs(m) >= 1 then
		buffer.writef64(n1,0,m * 0.5)
		buffer.writef64(n1,8,buffer.readf64(n1,8) - e2 + 1)
		return n1
	else
		buffer.writef64(n1,0,m)
		buffer.writef64(n1,8,buffer.readf64(n1,8) - e2)
		return n1
	end
end
--[[
	n = 1 / n
	Sets n to the Reciprocal of n
]]
function num.recipeq(n)
	if type(n) ~= "buffer" then error("Wrong Type: recipeq(), Input 1") end
	if buffer.readf64(n,0) == 0 then
		return n
	end
	local m = 0.5 / buffer.readf64(n,0)
	if math.abs(m) >= 1 then
		buffer.writef64(n,0,m / 2)
		buffer.writef64(n,8,2 - buffer.readf64(n,8))
		return n
	else
		buffer.writef64(n,0,m)
		buffer.writef64(n,8,1 - buffer.readf64(n,8))
		return n
	end
end
--[[
	n1 //= n2
	Sets n1 to the Integer Quotient of n1 and n2
]]
function num.intdiveq(n1,n2)
	if type(n1) ~= "buffer" then error("Wrong Type: intdiveq(), Input 1") end
	local m2,e2
	if type(n2) == "buffer" then
		m2 = buffer.readf64(n2,0)
		e2 = buffer.readf64(n2,8)
	elseif type(n2) == "number" then
		m2,e2 = math.frexp(n2)
	else
		error("Wrong Type: intdiv(), Input 2")
	end
	if buffer.readf64(n1,0) == 0 or m2 == 0 then
		buffer.writef64(n1,0,0)
		buffer.writef64(n1,8,0)
		return n1
	end
	local m = buffer.readf64(n1,0) / m2
	local e = buffer.readf64(n1,8) - e2
	if math.abs(m) >= 1 then
		m /= 2
		e += 1
	end
	if e < 1 then
		if m > 0 then
			buffer.writef64(n1,0,0)
			buffer.writef64(n1,8,0)
			return n1
		else
			buffer.writef64(n1,0,-0.5)
			buffer.writef64(n1,8,1)
			return n1
		end
	end
	if e < 1 then
	end
	if e > THRESHOLD then
		buffer.writef64(n1,0,m)
		buffer.writef64(n1,8,e)
		return n1
	end
	m,e = math.frexp(math.floor(math.ldexp(m,e)))
	buffer.writef64(n1,0,m)
	buffer.writef64(n1,8,e)
	return n1
end
--[[
	n1 %= n2
	Sets n1 to the Modulus of n1 and n2
]]
function num.modeq(n1,n2)
	if type(n1) ~= "buffer" then error("Wrong Type: modeq(), Input 1") end
	local m2,e2
	if type(n2) == "buffer" then
		m2 = buffer.readf64(n2,0)
		e2 = buffer.readf64(n2,8)
	elseif type(n2) == "number" then
		m2,e2 = math.frexp(n2)
	else
		error("Wrong Type: modeq(), Input 2")
	end
	if buffer.readf64(n1,0) == 0 or m2 == 0 then
		buffer.writef64(n1,0,0)
		buffer.writef64(n1,8,0)
		return n1
	end
	local m3 = buffer.readf64(n1,0) / m2
	local e3 = buffer.readf64(n1,8) - e2
	if math.abs(m3) >= 1 then
		m3 /= 2
		e3 += 1
	end
	if e3 < 1 then
		if m3 > 0 then
			return n1
		else
			m3 = -0.5
			e3 = 1
		end
	elseif e3 <= THRESHOLD then
		m3,e3 =  math.frexp(math.floor(math.ldexp(m3,e3)))
	end
	m3 *= m2
	e3 += e2
	if math.abs(m3) <= 0.5 then
		m3 *= 2
		e3 -= 1
	end
	local exponentDiff = buffer.readf64(n1,8) - e3
	if exponentDiff > THRESHOLD then
		return n1
	elseif exponentDiff <-THRESHOLD then 
		buffer.writef64(n1,0,-m3)
		buffer.writef64(n1,8,e3)
		return n1
	elseif exponentDiff == 0 then 
		local m,e = math.frexp(buffer.readf64(n1,0) - m3)
		buffer.writef64(n1,0,m)
		buffer.writef64(n1,8,e+buffer.readf64(n1,8))
		return n1
	elseif buffer.readf64(n1,0) > e2 then 
		local m,e = math.frexp(buffer.readf64(n1,0) - m3 * powlist[exponentDiff])
		buffer.writef64(n1,0,m)
		buffer.writef64(n1,8,e+buffer.readf64(n1,8))
		return n1
	else 
		local m,e = math.frexp(buffer.readf64(n1,0) * powlist[-exponentDiff] - m3)
		buffer.writef64(n1,0,m)
		buffer.writef64(n1,8,e+e3)
		return n1
	end
end
--[[
	n1 ^= n2
	Sets n1 to the Exponentiation of n1 and n2
]]
function num.poweq(n1,n2)
	if type(n1) ~= "buffer" then error("Wrong Type: poweq(), Input 1") end
	if buffer.readf64(n1,0) == 0 then
		return n1 
	elseif buffer.readf64(n1,0) == 0.5 and buffer.readf64(n1,8) == 1 then
		return n1
	end
	if type(n2) == "buffer" then
		if buffer.readf64(n2,0) == 0 then
			buffer.writef64(n1,0,0.5)
			buffer.writef64(n1,8,1)
			return n1
		end
		local exp = (buffer.readf64(n1,8) + math.log(math.abs(buffer.readf64(n1,0)),2)) * math.ldexp(buffer.readf64(n2,0),buffer.readf64(n2,8))
		local floor = math.floor(exp)
		buffer.writef64(n1,0,math.sign(buffer.readf64(n1,0))*math.pow(2, exp - floor - 1))
		buffer.writef64(n1,8,floor + 1)
		return n1
	elseif type(n2) == "number" then
		if n2 == 0 then
			buffer.writef64(n1,0,0.5)
			buffer.writef64(n1,8,1)
			return n1
		end
		local exp = (buffer.readf64(n1,8) + math.log(math.abs(buffer.readf64(n1,0)),2)) * n2
		local floor = math.floor(exp)
		buffer.writef64(n1,0,math.sign(buffer.readf64(n1,0))*math.pow(2, exp - floor - 1))
		buffer.writef64(n1,8,floor + 1)
		return n1
	else
		error("Wrong Type: poweq(), Input 2")
	end
end
--[[
	n1 ^= (1 / n2)
	Sets n1 to the Root of n1 and n2
]]
function num.rooteq(n1,n2)
	if type(n1) ~= "buffer" then error("Wrong Type: rooteq(), Input 1") end
	if buffer.readf64(n1,0) == 0 then
		return n1 
	elseif buffer.readf64(n1,0) == 0.5 and buffer.readf64(n1,8) == 1 then
		return n1
	end
	if type(n2) == "buffer" then
		if buffer.readf64(n2,0) == 0 then
			buffer.writef64(n1,0,0.5)
			buffer.writef64(n1,8,1)
			return n1
		end
		local exp = (buffer.readf64(n1,8) + math.log(math.abs(buffer.readf64(n1,0)),2)) / math.ldexp(buffer.readf64(n2,0),buffer.readf64(n2,8))
		local floor = math.floor(exp)
		buffer.writef64(n1,0,math.sign(buffer.readf64(n1,0))*math.pow(2, exp - floor - 1))
		buffer.writef64(n1,8,floor + 1)
		return n1
	elseif type(n2) == "number" then
		if n2 == 0 then
			buffer.writef64(n1,0,0.5)
			buffer.writef64(n1,8,1)
			return n1
		end
		local exp = (buffer.readf64(n1,8) + math.log(math.abs(buffer.readf64(n1,0)),2)) / n2
		local floor = math.floor(exp)
		buffer.writef64(n1,0,math.sign(buffer.readf64(n1,0))*math.pow(2, exp - floor - 1))
		buffer.writef64(n1,8,floor + 1)
		return n1
	else
		error("Wrong Type: rooteq(), Input 2")
	end
end
--[[
	n ^= 0.5
	Sets n to the Square Root of n
]]
function num.sqrteq(n)
	if type(n) ~= "buffer" then error("Wrong Type: sqrteq(), Input 1") end
	if buffer.readf64(n,0) == 0 then
		return n 
	elseif buffer.readf64(n,0) == 0.5 and buffer.readf64(n,8) == 1 then
		return n
	end
	local exp = buffer.readf64(n,8) / 2
	local floor = math.floor(exp)
	local a,b = math.frexp(math.pow(2, exp - floor) * (if buffer.readf64(n,0) > 0 then math.pow(buffer.readf64(n,0), 0.5) else -math.pow(-buffer.readf64(n,0), 0.5)))
	buffer.writef64(n,0,a)
	buffer.writef64(n,8,b + floor)
	return n
end
--[[
	n = 2 ^ n
	Sets n to the Exponentiation of 2 and n
]]
function num.pow2eq(n)
	if type(n) ~= "buffer" then error("Wrong Type: pow2eq(), Input 1") end
	local exp = math.ldexp(buffer.readf64(n,0),buffer.readf64(n,8))
	local floor = math.floor(exp)
	buffer.writef64(n,0,math.pow(2, exp - floor - 1))
	buffer.writef64(n,8,floor + 1)
	return n
end
--[[
	n = 10 ^ n
	Sets n to the Exponentiation of 10 and n
]]
function num.pow10eq(n)
	if type(n) ~= "buffer" then error("Wrong Type: pow10eq(), Input 1") end
	local exp = math.ldexp(buffer.readf64(n,0),buffer.readf64(n,8)) / convert10
	local floor = math.floor(exp)
	buffer.writef64(n,0,math.pow(2, exp - floor - 1))
	buffer.writef64(n,8,floor + 1)
	return n
end
--[[
	n = e ^ n (e = ~2.71828)
	Sets n to the Exponentiation of e and n
]]
function num.expeq(n)
	if type(n) ~= "buffer" then error("Wrong Type: expeq(), Input 1") end
	local exp = math.ldexp(buffer.readf64(n,0),buffer.readf64(n,8)) / convertE
	local floor = math.floor(exp)
	buffer.writef64(n,0,math.pow(2, exp - floor - 1))
	buffer.writef64(n,8,floor + 1)
	return n
end
--[[
	Sets n1 to the Logarithm of n1 in base n2
]]
function num.logeq(n1,n2)
	if type(n1) ~= "buffer" then error("Wrong Type: logeq(), Input 1") end
	if buffer.readf64(n1,0) == 0 or (buffer.readf64(n1,8) == 1 and buffer.readf64(n1,0) == 0.5) then
		buffer.writef64(n1,0,0)
		buffer.writef64(n1,8,0)
		return n1
	end
	if type(n2) == "buffer" then
		if buffer.readf64(n2,0) == 0.5 and buffer.readf64(n2,8) == 1 then
			buffer.writef64(n1,0,0)
			buffer.writef64(n1,8,0)
			return n1
		end
		local n1m,n1e = math.frexp(buffer.readf64(n1,8) + math.log(buffer.readf64(n1,0),2))
		local n2m,n2e = math.frexp(buffer.readf64(n2,8) + math.log(buffer.readf64(n2,0),2) - 1)
		n1m /= n2m
		if math.abs(n1m) >= 1 then
			buffer.writef64(n1,0,n1m/2)
			buffer.writef64(n1,8,n1e-n2e+1)
			return n1
		else
			buffer.writef64(n1,0,n1m)
			buffer.writef64(n1,8,n1e-n2e)
			return n1
		end
	elseif type(n2) == "number" then
		if n2 == 1 then
			buffer.writef64(n1,0,0)
			buffer.writef64(n1,8,0)
			return n1
		end
		local a,b = math.frexp(buffer.readf64(n1,8) * math.log(2,n2) + math.log(buffer.readf64(n1,0),n2))
		buffer.writef64(n1,0,a)
		buffer.writef64(n1,8,b)
		return n1
	else
		error("Wrong Type: logeq(), Input 2")
	end
end
--[[
	Sets n to the Logarithm of n in base 10
]]
function num.log10eq(n)
	if type(n) ~= "buffer" then error("Wrong Type: log10eq(), Input 1") end
	if buffer.readf64(n,0) == 0 or (buffer.readf64(n,8) == 1 and buffer.readf64(n,0) == 0.5) then
		return n
	end
	local a,b = math.frexp(buffer.readf64(n,8) * convert10 + math.log10(buffer.readf64(n,0)))
	buffer.writef64(n,0,a)
	buffer.writef64(n,8,b)
	return n
end
--[[
	Sets n to the Logarithm of n in base 2
]]
function num.log2eq(n)
	if type(n) ~= "buffer" then error("Wrong Type: log10eq(), Input 1") end
	if buffer.readf64(n,0) == 0 or (buffer.readf64(n,8) == 1 and buffer.readf64(n,0) == 0.5) then
		return n
	end
	local a,b = math.frexp(buffer.readf64(n,8) + math.log(buffer.readf64(n,0), 2))
	buffer.writef64(n,0,a)
	buffer.writef64(n,8,b)
	return n
end
--[[
	Sets n to the Natural Logarithm of n (base ~2.71828)
]]
function num.lneq(n)
	if type(n) ~= "buffer" then error("Wrong Type: lneq(), Input 1") end
	if buffer.readf64(n,0) == 0 or (buffer.readf64(n,8) == 1 and buffer.readf64(n,0) == 0.5) then
		return n
	end
	local a,b = math.frexp(buffer.readf64(n,8) * convertE + math.log(buffer.readf64(n,0)))
	buffer.writef64(n,0,a)
	buffer.writef64(n,8,b)
	return n
end
--[[
	n = -n
	Sets n to Negative n
]]
function num.negeq(n)
	if type(n) ~= "buffer" then error("Wrong Type: negeq(), Input 1") end
	buffer.writef64(n,0,-buffer.readf64(n,0))
	buffer.writef64(n,8,buffer.readf64(n,8))
	return n
end
--[[
	n = |n|
	Sets n to the Absolute value of n
]]
function num.abseq(n)
	if type(n) ~= "buffer" then error("Wrong Type: abseq(), Input 1") end
	buffer.writef64(n,0,math.abs(buffer.readf64(n,0)))
	buffer.writef64(n,8,buffer.readf64(n,8))
	return n
end
--[[
	Sum of Geometric Series Range from start to last
	start term is: base * mul ^ start
	last term is: base * mul ^ last
	returns sum of the terms between
]]
function num.geosum(base, mul, start, last)
	local m1,e1,m2,e2
	if type(base) == "buffer" then
		m1 = buffer.readf64(base,0)
		e1 = buffer.readf64(base,8)
	elseif type(base) == "number" then
		m1,e1 = math.frexp(base)
	else
		error("Wrong Type: geosum(), Input 1")
	end
	local buf = buffer.create(16)
	if m1 == 0 then
		return buf
	end
	if type(mul) == "buffer" then
		m2 = buffer.readf64(mul,0)
		e2 = buffer.readf64(mul,8)
	elseif type(mul) == "number" then
		m2,e2 = math.frexp(mul)
	else
		error("Wrong Type: geosum(), Input 2")
	end
	local mf,ef
	if m2 == 0.5 and e2 == 1 then
		mf,ef = math.frexp(last - start)
		if mf == 0 then
			return buf
		end
	else
		local m2log2 = math.log(math.abs(m2),2)
		local p1m,p1e
		if last == 0 then
			p1m = 0.5
			p1e = 1
		else
			local exp = (e2 + m2log2) * last
			local floor = math.floor(exp)
			p1m = math.sign(m2)*math.pow(2, exp - floor - 1)
			p1e = floor + 1
		end
		local p2m,p2e
		if start == 0 then
			p2m = 0.5
			p2e = 1
		else
			local exp = (e2 + m2log2) * start
			local floor = math.floor(exp)
			p2m = math.sign(m2)*math.pow(2, exp - floor - 1)
			p2e = floor + 1
		end
		local p3m,p3e
		local exponentDiff = p1e - p2e
		if exponentDiff > THRESHOLD then
			p3m = p1m
			p3e = p1e
		elseif exponentDiff <-THRESHOLD then 
			p3m = -p2m
			p3e = p2e
		elseif exponentDiff == 0 then 
			p3m,p3e = math.frexp(p1m - p2m)
			p3e += p1e
		elseif p1e > p2e then 
			p3m,p3e = math.frexp(p1m - p2m * powlist[exponentDiff])
			p3e += p1e
		else 
			p3m,p3e = math.frexp(p1m * powlist[-exponentDiff] - p2m)
			p3e += p2e
		end
		local p4m,p4e
		exponentDiff = e2 - 1
		if exponentDiff > THRESHOLD then
			p4m = m2
			p4e = e2
		elseif exponentDiff <-THRESHOLD then 
			p4m = -0.5
			p4e = 1
		elseif exponentDiff == 0 then 
			p4m,p4e = math.frexp(m2 - 0.5)
			p4e += e2
		elseif e2 > 1 then 
			p4m,p4e = math.frexp(m2 - 0.5 * powlist[exponentDiff])
			p4e += e2
		else 
			p4m,p4e = math.frexp(m2 * powlist[-exponentDiff] - 0.5)
			p4e += 1
		end
		mf = p3m / p4m
		ef = p3e - p4e
		if math.abs(mf) >= 1 then
			mf /= 2
			ef += 1
		end
	end
	local m = mf * m1
	if math.abs(m) < 0.5 then
		buffer.writef64(buf,0,m * 2)
		buffer.writef64(buf,8,ef + e1 - 1)
		return buf
	else
		buffer.writef64(buf,0,m)
		buffer.writef64(buf,8,ef + e1)
		return buf
	end
end
--[[
	End Index of Geometric Series Range starting at 'start'
	start term is: base * mul ^ start
	range sum is: amount
	returns end index
]]
function num.geosumR(base, mul, start, amount)
	local m1,e1,m2,e2,m3,e3
	if type(base) == "buffer" then
		m1 = buffer.readf64(base,0)
		e1 = buffer.readf64(base,8)
	elseif type(base) == "number" then
		m1,e1 = math.frexp(base)
	else
		error("Wrong Type: geosumR(), Input 1")
	end
	local buf = buffer.create(16)
	if m1 == 0 then
		return buf
	end
	if type(mul) == "buffer" then
		m2 = buffer.readf64(mul,0)
		e2 = buffer.readf64(mul,8)
	elseif type(mul) == "number" then
		m2,e2 = math.frexp(mul)
	else
		error("Wrong Type: geosumR(), Input 2")
	end
	if m2 == 0 then
		return buf
	end
	if type(amount) == "buffer" then
		m3 = buffer.readf64(amount,0)
		e3 = buffer.readf64(amount,8)
	elseif type(amount) == "number" then
		m3,e3 = math.frexp(amount)
	else
		error("Wrong Type: geosumR(), Input 3")
	end
	if m3 == 0 then
		return buf
	end
	local mf,ef
	if m2 == 0.5 and e2 == 1 then
		mf = m3 / m1
		ef = e3 - e1
		if math.abs(mf) >= 1 then
			mf /= 2
			ef += 1
		end
	else
		local p1m,p1e
		local exponentDiff = e2 - 1
		if exponentDiff > THRESHOLD then
			p1m = m2
			p1e = e2
		elseif exponentDiff <-THRESHOLD then 
			p1m = -0.5
			p1e = 1
		elseif exponentDiff == 0 then 
			p1m,p1e = math.frexp(m2 - 0.5)
			p1e += e2
		elseif e2 > 1 then 
			p1m,p1e = math.frexp(m2 - 0.5 * powlist[exponentDiff])
			p1e += e2
		else 
			p1m,p1e = math.frexp(m2 * powlist[-exponentDiff] - 0.5)
			p1e += 1
		end
		p1m *= m3
		p1e += e3
		if math.abs(p1m) < 0.5 then
			p1m *= 2
			p1e -= 1
		end
		local p2m,p2e
		if start == 0 then
			p2m = 0.5
			p2e = 1
		else
			local exp = (e2 + math.log(math.abs(m2),2)) * start
			local floor = math.floor(exp)
			p2m = math.sign(m2)*math.pow(2, exp - floor - 1)
			p2e = floor + 1
		end
		p2m *= m1
		p2e += e1
		if math.abs(p2m) < 0.5 then
			p2m *= 2
			p2e -= 1
		end
		p1m /= p2m
		p1e -= p2e
		if math.abs(p1m) >= 1 then
			p1m /= 2
			p1e += 1
		end
		exponentDiff = p1e - 1
		if exponentDiff > THRESHOLD then
			p2m = p1m
			p2e = p1e
		elseif exponentDiff <-THRESHOLD then 
			p2m = 0.5
			p2e = 1
		elseif exponentDiff == 0 then 
			p2m,p2e = math.frexp(p1m + 0.5)
			p2e += p1e
		elseif p1e > 1 then 
			p2m,p2e = math.frexp(p1m + 0.5 * powlist[exponentDiff])
			p2e += p1e
		else 
			p2m,p2e = math.frexp(p1m * powlist[-exponentDiff] + 0.5)
			p2e += 1
		end
		mf,ef = math.frexp(p2e + math.log(p2m,2))
		p1m,p1e = math.frexp(e2 + math.log(m2,2))
		mf /= p1m
		ef -= p1e
		if math.abs(mf) >= 1 then
			mf /= 2
			ef += 1
		end
	end
	local m4,e4 = math.frexp(start)
	local exponentDiff = ef - e4
	if exponentDiff > THRESHOLD then
		buffer.writef64(buf,0,mf)
		buffer.writef64(buf,8,ef)
		return buf
	elseif exponentDiff <-THRESHOLD then 
		buffer.writef64(buf,0,m4)
		buffer.writef64(buf,8,e4)
		return buf
	elseif exponentDiff == 0 then 
		local m,e = math.frexp(mf + m4)
		buffer.writef64(buf,0,m)
		buffer.writef64(buf,8,e+ef)
		return buf
	elseif ef > e4 then 
		local m,e = math.frexp(mf + m4 * powlist[exponentDiff])
		buffer.writef64(buf,0,m)
		buffer.writef64(buf,8,e+ef)
		return buf
	else 
		local m,e = math.frexp(mf * powlist[-exponentDiff] + m4)
		buffer.writef64(buf,0,m)
		buffer.writef64(buf,8,e+e4)
		return buf
	end
end
--[[
	Encodes n into a number that can be stored in an OrderedDataStore (Leaderboard)
]]
function num.lbencode(n)
	local m,e
	if type(n) == "buffer" then
		m = buffer.readf64(n,0)
		e = buffer.readf64(n,8)
	elseif type(n) == "number" then
		m,e = math.frexp(n)
	else
		error("Wrong Type: lbencode(), Input 1")
	end
	if m == 0 then return 0 end
	local exp = e + math.log(math.abs(m), 2)
	local se = math.sign(exp)
	exp = math.log(math.abs(exp) + 1, 2)
	return (1024 + se * exp) * 4398046511104 * math.sign(m)
end
--[[
	Decodes n from the number returned by .lbencode()
]]
function num.lbdecode(n)
	if type(n) ~= "number"  then
		error("Wrong Type: lbdecode(), Input 1")
	end
	local buf = buffer.create(16)
	if n == 0 then 
		return buf
	end
	local s = math.sign(n)
	n = (math.abs(n) / 4398046511104) - 1024
	local se = math.sign(n)
	n = se * (2 ^ math.abs(n) - 1)
	local floor = math.floor(n)
	buffer.writef64(buf,0,s*math.pow(2, n - floor - 1))
	buffer.writef64(buf,8,floor + 1)
	return buf
end
--[[
	1 if n is positive, -1 if negative, and 0 if n equals 0
]]
function num.sign(n)
	if type(n) == "buffer" then
		return math.sign(buffer.readf64(n,0))
	elseif type(n) == "number" then
		return math.sign(n)
	else
		error("Wrong Type: sign(), Input 1")
	end
end
--[[
	true if n is positive, else false
]]
function num.isPositive(n)
	if type(n) == "buffer" then
		return buffer.readf64(n,0) > 0
	elseif type(n) == "number" then
		return n > 0
	else
		error("Wrong Type: isPositive(), Input 1")
	end
end
--[[
	true if n is negative, else false
]]
function num.isNegative(n)
	if type(n) == "buffer" then
		return buffer.readf64(n,0) < 0
	elseif type(n) == "number" then
		return n < 0
	else
		error("Wrong Type: isNegative(), Input 1")
	end
end
--[[
	true if n is zero, else false
]]
function num.isZero(n)
	if type(n) == "buffer" then
		return buffer.readf64(n,0) == 0
	elseif type(n) == "number" then
		return n == 0
	else
		error("Wrong Type: isZero(), Input 1")
	end
end
--[[
	Random Quicknum between n1 and n2
]]
function num.random(n1, n2)
	local m1,e1,m2,e2
	if type(n1) == "buffer" then
		m1 = buffer.readf64(n1,0)
		e1 = buffer.readf64(n1,8)
	elseif type(n1) == "number" then
		m1,e1 = math.frexp(n1)
	else
		error("Wrong Type: random(), Input 1")
	end
	if type(n2) == "buffer" then
		m2 = buffer.readf64(n2,0)
		e2 = buffer.readf64(n2,8)
	elseif type(n2) == "number" then
		m2,e2 = math.frexp(n2)
	else
		error("Wrong Type: random(), Input 2")
	end
	local buf = buffer.create(16)
	local m3,e3
	local exponentDiff = e2 - e1
	if exponentDiff > THRESHOLD then
		m3 = m2
		e3 = e2
	elseif exponentDiff <-THRESHOLD then 
		m3 = -m1
		e3 = e1
	elseif exponentDiff == 0 then 
		m3,e3 = math.frexp(m2 - m1)
		e3 += e1
	elseif e1 < e2 then 
		m3,e3 = math.frexp(m2 - m1 * powlist[exponentDiff])
		e3 += e2
	else 
		m3,e3 = math.frexp(m2 * powlist[-exponentDiff] - m1)
		e3 += e1
	end
	local m4,e4 = math.frexp(math.random())
	m3 *= m4
	e3 += e4
	if math.abs(m3) < 0.5 then
		m3 *= 2
		e3 -= 1
	end
	exponentDiff = e3 - e1
	if exponentDiff > THRESHOLD then
	elseif exponentDiff <-THRESHOLD then 
		m3 = m1
		e3 = e1
	elseif exponentDiff == 0 then 
		m3,e3 = math.frexp(m3 + m1)
		e3 += e1
	elseif e1 < e3 then 
		local temp = e3
		m3,e3 = math.frexp(m3 + m1 * powlist[exponentDiff])
		e3 += temp
	else 
		m3,e3 = math.frexp(m3 * powlist[-exponentDiff] + m1)
		e3 += e1
	end
	buffer.writef64(buf,0,m3)
	buffer.writef64(buf,8,e3)
	return buf
end
local suffixes = {
	{
		{'k','M','B','T','Qd','Qt','Sx','Sp','Oc','No'},
		{'','U','D','T','Qt','Qn','Sx','Sp','Oc','No'},
		{'','Dc','Vt','Tg','Qg','Qg','sg','Sg','og','ng'},
		{'','Ce','Du','Tr','Qa','Qi','Se','Si','Ot','Ni'},
	},
	{
		{'k','m','b','t','q','Q','s','S','o','n','d'},
	},
	{
		{'z','a','b','c','d','e','f','g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v','w','x','y'},
	},
}
function suffix(i)
	if i <= 10 then return suffixes[1][1][i] end
	if i >= 1001 then return "Mi" end
	return suffixes[1][2][((i-1) % 10)+1]..suffixes[1][3][(((i-1) // 10) % 10 )+1]..suffixes[1][4][(((i-1) // 100) % 10)+1]
end
function Asuffix(i)
	i += 26
	local s = ""
	while i > 0 do
		local v= i
		local x = i % 26
		i = (i-x)/26
		s..=suffixes[3][1][x+1]
	end	
	return s:reverse()
end
function suf(mantissa, exponent)
	local mod3 = exponent % 3
	local e = exponent - mod3
	return string.format("%."..(3-mod3).."f",mantissa*math.pow(10,mod3))..suffix(e/3)
end
function std(mantissa, exponent) return string.format("%.2f",mantissa*10^exponent) end
function sci(mantissa, exponent)
	local msign = math.sign(exponent)
	local mabs = math.abs(exponent)
	if mabs >= 1e36 then
		local e = math.floor(math.log10(mabs))
		return "E"..(if msign == -1 then "-" else "+")..string.format("%.3f",mabs / math.pow(10,e)).."e"..e
	elseif mabs >= 1e5 then
		local e = math.floor(math.log10(mabs))
		local mod3 = e % 3
		return string.format("%.2f",mantissa).."e"..(if msign == -1 then "-" else "")..string.format("%."..(3-mod3).."f",mabs / math.pow(10,e-mod3))..suffixes[2][1][(e-mod3)/3]
	elseif mabs >= 1e3 then
		local thou = (mabs//1000)
		return string.format("%.2f",mantissa).."e"..(if msign == -1 then "-" else "")..thou..","..tostring(mabs-thou*1000+1000):sub(2)
	else return string.format("%.3f",mantissa).."e"..exponent end
end
function eng(mantissa, exponent)
	local msign = math.sign(exponent)
	local mabs = math.abs(exponent)
	if mabs >= 1e36 then
		local e = math.floor(math.log10(mabs))
		return "E"..(if msign == -1 then "-" else "+")..string.format("%.3f",mabs / math.pow(10,e)).."e"..e
	elseif mabs >= 1e4  then
		local e = math.floor(math.log10(mabs))
		local mod3 = e % 3
		return string.format("%.2f",mantissa).."e"..(if msign == -1 then "-" else "")..string.format("%."..(3-mod3).."f",mabs / math.pow(10,e-mod3))..suffixes[2][1][(e-mod3)/3]
	elseif mabs >= 1e3 then
		local mod3 = exponent % 3
		local e = (mabs-mod3)
		local thou = (mabs//1000)
		return string.format("%."..(3-mod3).."f",mantissa*math.pow(10,mod3)).."e"..(if msign == -1 then "-" else "")..thou..","..tostring(e-thou*1000+1000):sub(2)
	else
		local mod3 = exponent % 3
		return string.format("%."..(3-mod3).."f",mantissa*math.pow(10,mod3)).."e"..(exponent-mod3)
	end
end
function alp(mantissa, exponent)
	if exponent < 3 or exponent >= 1e15 then return sci(mantissa,exponent) end
	local mod3 = exponent % 3
	local i = (exponent - mod3) / 3
	return string.format("%."..(3-mod3).."f",mantissa*math.pow(10,mod3))..Asuffix(i)
end
--[[
	Converts Quicknum to a string in given suffixtype
]]
function num.tostring(n, suffixtype)
	local m,e
	if type(n) == "buffer" then
		m = buffer.readf64(n,0)
		e = buffer.readf64(n,8)
	elseif type(n) == "number" then
		m,e = math.frexp(n)
	else
		error("Wrong Type: tostring(), Input 1")
	end
	m *= 2
	e -= 1
	local exp = e * convert10
	local e = math.floor(exp)
	local m = m*math.pow(10,exp-e)
	if m >= 10 then m *= 0.1 e += 1 end
	if suffixtype == nil then suffixtype = num.DefaultSuffixType end
	if suffixtype == num.SuffixTypes.Scientific then return sci(m,e)
	elseif suffixtype == num.SuffixTypes.Scientific3 then return if e >= 3 or e <= -3 then sci(m,e) else std(m,e)
	elseif suffixtype == num.SuffixTypes.Scientific36 then return if e >= 36 or e <= -3 then sci(m,e) elseif e >= 3 then suf(m,e) else std(m,e)
	elseif suffixtype == num.SuffixTypes.Scientific306 then return if e >= 306 or e <= -3 then sci(m,e) elseif e >= 3 then suf(m,e) else std(m,e)
	elseif suffixtype == num.SuffixTypes.Scientific3006 then return if e >= 3006 or e <= -3 then sci(m,e) elseif e >= 3 then suf(m,e) else std(m,e)
	elseif suffixtype == num.SuffixTypes.Engineer then return eng(m,e)
	elseif suffixtype == num.SuffixTypes.Engineer3 then return if e >= 3 or e <= -3 then eng(m,e) else std(m,e)
	elseif suffixtype == num.SuffixTypes.Engineer36 then return if e >= 36 or e <= -3 then eng(m,e) elseif e >= 3 then suf(m,e) else std(m,e)
	elseif suffixtype == num.SuffixTypes.Engineer306 then return if e >= 306 or e <= -3 then eng(m,e) elseif e >= 3 then suf(m,e) else std(m,e)
	elseif suffixtype == num.SuffixTypes.Engineer3006 then return if e >= 3006 or e <= -3 then eng(m,e) elseif e >= 3 then suf(m,e) else std(m,e)
	elseif suffixtype == num.SuffixTypes.Alphabet then return if e < 3 then std(m,e) else alp(m,e)
	end
end
--[[
	Converts Quicknum to a string in scientific notation
]]
function num.scientific(n)
	local m,e
	if type(n) == "buffer" then
		m = buffer.readf64(n,0)
		e = buffer.readf64(n,8)
	elseif type(n) == "number" then
		m,e = math.frexp(n)
	else
		error("Wrong Type: tostring(), Input 1")
	end
	m *= 2
	e -= 1
	local exp = e * convert10
	local e = math.floor(exp)
	local m = m*math.pow(10,exp-e)
	if m >= 10 then m *= 0.1 e += 1 end
	return m.."e"..e
end
--[[
	Encodes for saving in a string without data loss
]]
function num.encode(n)
	if type(n) ~= "buffer" then error("Wrong Type: encode(), Input 1") end
	if buffer.readf64(n,0) == 0 then
		return "0"
	elseif buffer.readf64(n,0) == 0.5 and buffer.readf64(n,8) == 1 then
		return "1"
	end
	local Encoded = buffer.fromstring(game.HttpService:JSONEncode((n)))
	local Base64Length = buffer.len(Encoded) - 35
	local Base64Buffer = buffer.create(Base64Length)
	buffer.copy(Base64Buffer, 0, Encoded, 33, Base64Length)
	return buffer.tostring(Base64Buffer):sub(1,-3)
end
--[[
	Decodes from .encode()
]]
function num.decode(n)
	if type(n) ~= "string" then error("Wrong Type: decode(), Input 1") end
	if n == "0" then
		return buffer.create(16)
	elseif n == "1" then
		local buf = buffer.create(16)
		buffer.writef64(buf,0,0.5)
		buffer.writef64(buf,0,1)
		return buf
	end
	local buf1 = buffer.create(16)
	local buf2 = game.HttpService:JSONDecode("{\"m\":null,\"t\":\"buffer\",\"base64\":\""..n.."==\"}")
	buffer.copy(buf1, 0, buf2)
	return buf1
end
return num