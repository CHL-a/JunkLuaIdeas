local Object = require('./Object')
local Class = require('./Class')

export type object = {
	referral: string;
	i: number;
	
	proceed: (self: object, i: number?)->();
	reset: (self: object, s: string)->();
	peek: (self: object, len: number?, offset: number?)->string;
	peek_back: (self: object, len: number?, offset: number?)->string;
	is_at_end: (self: object)->boolean;
	peek_until: (self: object, other: string, plain: boolean?)->(string, string);
	pop: (self: object, len: number?, offset: number?)->string;
	peek_match: (self: object, pattern: string, raw: boolean?)->string?;
	c_pop: (self: object, other: string, plain: boolean?) -> boolean;
	pop_until: (self: object, other: string, plain: boolean?)->(string, string);
	get_snapshot: (self: object)->string;
} & Object.object_inheritance

local module = {}
disguise = require('./LuaUTypes').disguise

function module.new(s: string): object
	local self: object = Object.from.class(module)
	
	self:reset(s)
	
	return self
end

function module.is_at_end(self: object)return self.i > #self.referral end
function module.proceed(self: object, i: number?)self.i+=(i or 1) end

function module.peek_match(self: object, pattern: string, raw: boolean?)
	local gap, caught = self:peek_until(pattern, raw)
	
	if #gap > 0 then return nil end
	
	return caught
end

function module.reset(self: object, s: string)
	self.referral = s;
	self.i = 1
end

function module.pop(self: object, len: number?, offset: number?)
	local s = self:peek(len, offset)
	self:proceed(len)
	return s
end

function module.peek(self: object, len: number?, offset: number?)
	len = len or 1
	offset = offset or 0
	
	return self.referral:sub(
		self.i + disguise(offset), 
		self.i + disguise(offset) + disguise(len) - 1
	)
end

function module.peek_back(self: object, len: number?, offset: number?)
	len = len or 1
	offset = offset or -disguise(len)
	
	return self:peek(len, offset)
end

function module.peek_until(self: object, other: string, plain: boolean?)
	local from, to = self.referral:find(other, self.i, plain)
	local gap, other = 
		if from
			then self.referral:sub(self.i, from - 1)
			else self.referral:sub(self.i),
		if from 
			then self.referral:sub(from, to)
			else ""
	
	return gap, other
end

function module.c_pop(self: object, other: string, plain: boolean?)
	local gap, other = self:peek_until(other, plain)
	local result = #gap == 0 and #other > 0
	
	if result then
		self:proceed(#other)
	end
	
	return result
end

function module.pop_until(self: object, other: string, plain: boolean?)
	local gap, other = self:peek_until(other, plain)
	
	self:proceed(#gap + #other)
	
	return gap, other
end

function module.get_snapshot(self: object)
	local line_break_i = self.i - 1
	
	while line_break_i > 0 and self.referral:sub(line_break_i, line_break_i) ~= '\n' do
		line_break_i -= 1
	end
	
	local line_break_j = self.referral:find('\n', self.i) or #self.referral + 1
	local line1 = `{self.referral:sub(line_break_i + 1, line_break_j - 1)} \n`
	local space_count = self.i - line_break_i - 1
	local line2 = `{(' '):rep(space_count)}^`
	local result = line1 .. line2
	
	return result
end

function module.test()
	
	local a = module.new('ABC\ndef')
	assert(a:peek() == 'A')
	assert(a:pop() == 'A')
	assert(a:peek() == 'B')
	
	--assert(a:check_hop('B',true))
	
	print(a)
	print('\n'.. a:get_snapshot())
	
	a:proceed(2)
	
	print('\n'.. a:get_snapshot())

	a:proceed(1)
	
	print('\n'.. a:get_snapshot())
end

Class.makeProperClass(module, '@CHL>StringParser')

return module
