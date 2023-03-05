--[[
With help from luac.nl and a vm
]]

-- 0 MOVE
--  copy a value
local a = 1
local b = a

-- 1 LOADK
--  load a constant
local c = 'sample constant A'

--  load a constant bool
-- 2 LOADBOOL
local d = true
local e = false

-- 3 LOADNIL
--  load nils, possibly a range
local f = nil

-- 4 GETUPVAL
--  get upvals, or get variables from an upper scope of a function
function g()
	local h = a
end

-- 5 GETGLOBAL
--  duh
local i = print

-- 6 GETTABLE
--  indexing
local j = {}
_ = j[1]

-- 7 SETGLOBAL
--  duh
k = a

-- 8 SETUPVAL
--  sets upvals or sets variables from an upper scope of a function
local l = 1
function m()
	l = 2
end

-- 9 SETTABLE
--  newindexing
local n = {}
n[1] = 2

-- 10 NEWTABLE
--  duh
local o = {}

-- 11 SELF
--  signifies and preps an object call aka, using the colon
local p = {}

function p.q(self)
	print(self)
end

p:q()

--[[
	12 ADD
	13 SUB
	14 MUL
	15 DIV
	16 MOD
	17 POW
	18 UNM
	19 NOT
	20 LEN
	21 CONCAT
]]

--  duh
--  note: in luac.nl, it merged all constant numbers into one constant number, so i
--  had to make assign a variable and used that instead
local r = 1
r = (
	((((((1 + r) - 3) * r) / 5) % r) ^ -7)
)
local s = true
s = not s
local t = #'' .. 'Hey'

-- 22 JMP
--  This one is a bit unique, there is a pointer, and this opcode tells it to go somewhere 
--  else, controll structures like if statements, and loops dont have their own opcode like 
--  the operators, so they rely on this specific opcode as a result. EX:
--[[
	if statement: conditional being false, JMP past the control statements, or a set of instructions

	if false then -- here
		print'conditional is not supposed to be false'
	end
	--jumped here

	loops: conditional being true, do set of instructions, then set pointer to the iteration, or jump backwards

	-- then back here
	while true do -- here

		-- then here
	end

	-- NOTE: for each of these structures, there's also an opcode named "TEST", we will go over that later
]]

local u = true
if u then
	print('hi')
end

--[[
	23 EQ
	24 LT
	25 LE
]]
--  comparison operations but theres a neat observation, the reason why there isnt any ~=, <, or <= is because what 
--   operands make these operators false also make their inverses true. Refer to the chart
--[[   Operator | Inverse
	   ==       | ~=
	   >        | <=
	   >=       | <
--]]

local v, _ = 
	1 == 2, 
	3 ~= 4

-- 26 TEST
--  if the conditional is falsy, then the pointer skips the next instruction, refer to example of opcode 22

-- 27 TESTSET
--  functions as opcode 26, but handles "and" and "or"
local w, x = true, true
local y = w and x

-- 28 CALL
--  duh
function z()
	print('hi2')
end

z()
-- 29 TAILCALL
--  occurs when you return with a called function, thus tail call
function a1()
	return a1()
end

-- 30 RETURN
--  duh
function a2()
	return''
end

-- 31 FORLOOP
-- 32 FORPREP
--  opcode for regular for loops, opcode 31 performs the iterations, opcode 32 sets them up (start, end, step and possibibly the current iteration)
for a3 = 1, 2, .1 do
	print('hi3',a3)
end

-- 33 TFORLOOP
--  opcode specifically for for each loops or "for _, _ in pairs{}do end"
for _, _ in next, {1} do
	print('hi4')
end

-- 34 SETLIST
--  opcode used for setting the list or arrays, not dictionaries
local a4 = {
	1, 2, 3
}

-- 35 CLOSE
--  close all lua upvals, (for some reason, its exclusive in 5.4 (at least), 
--  but it won't appear in 5.1)

local a8 
for _, _ in next, {} do 
	return a8 
end -- appears here

-- 36 CLOSURE
--  ends the function, wraps it up ig?
function a5()

end

-- 37 VARARG
--  special case where theres variant arguments
function a6(...)
	local a7 = {...}
end
