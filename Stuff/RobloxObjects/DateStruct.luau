--[[
Legend:
+----+-----------+----------------------------+----+
|unit|unit name  |unit conversion             |bits|
+----+-----------+----------------------------+----+
|s   |millisecond|                            |10  |
|S   |second     |(1000s = 1S)                |6   |
|m   |minute     |(60S   = 1m)                |6   |
|h   |hour       |(60m   = 1h)                |5   |
|d   |day        |(24h   = 1d)                |5   |
|M   |month      |(31d   = 1M) * presuming max|5   |
|y   |year       |(12M   = 1y)                |    |
+----+-----------+----------------------------+----+

bit dump:
vvvs ssss ssss sSSS
SSSm mmmm mhhh hhdd
dddM MMMM yyyy yyyy
yyyy yyyy yyyy yyyy

v for versioning, but can also be rearranged to be at the front, and exists for 
maintenance, strictly speaking, if v == 0b111, then thats means a different date 
format is used or some of the sorts

an unsigned 64 integer representing seconds has a date capacity of 
(2^59)/(3^3*5^2*1461) years, or around 5.84542E11 years

The proposed data format above has a date capacity of 2^48 years or exactly
2.81474E14 years

For convience of the reader the following are 1-based values: month and day

while datetime:ToUniversalTime() exists, this format provides a binary compression and decompression method
]]

export type struct = {
	year: number;
	month: number;
	day: number;
	hour: number;
	minute: number;
	second: number;
	millisecond: number;
	version: number;
}

--local UnitTest = require('./@CHL>UnitTest')
local module = {}

module.from = {}

function module.new(): struct
	return {
		version = 0;
	}
end

function module.from.date_time(value: DateTime): struct
	local self: struct = module.new()
	local referral_struct = value:ToUniversalTime()
	
	self.year = referral_struct.Year
	self.month = referral_struct.Month
	self.day = referral_struct.Day
	self.hour = referral_struct.Hour
	self.minute = referral_struct.Minute
	self.second = referral_struct.Second
	self.millisecond = referral_struct.Millisecond
	
	return self
end

-- function module.__chl_unit_test(describe: UnitTest.describe)end

return module
