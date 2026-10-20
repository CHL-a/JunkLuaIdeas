local InstanceUtils = require('./@CHL>InstanceUtils')

local module = {}

--###############################################################################################################################################################################
--###############################################################################################################################################################################
--###############################################################################################################################################################################
local unit_test = {}

test = {}

export type describe = typeof(unit_test.describe)
export type unit_testing_function = (describe: describe) -> ()

function test.func(f: unit_testing_function)
	unit_test.id = unit_test.id or debug.traceback()
	f(unit_test.describe)
end

function test.library(lib)
	if not lib then return end
	
	local unit_test_func = lib.__chl_unit_test
	
	if unit_test_func == false then return;end
	
	if not unit_test_func then
		unit_test_func = lib.unit_test
	end
	
	if unit_test_func then
		test.func(unit_test_func)
	end
end

function test.module_script(module_script: ModuleScript)
	if not (module_script and module_script:IsA('ModuleScript')) then
		return
	end
	
	test.library(require(module_script))
end

function test.all_folders()
	for _, folder: Folder in test.module_folder_tests do
		if not (folder and folder:IsA('Folder')) then continue end
		
		for _, item in folder:GetChildren() do
			if item:IsA('ModuleScript') then
				test.module_script(item)
			end
		end
	end
end

test.module_folder_tests = {
	InstanceUtils.find_first_descendant(game:GetService('ReplicatedStorage'), 'Objects'),
	InstanceUtils.find_first_descendant(game:GetService('ServerScriptService'), 'Objects')
}

--###############################################################################################################################################################################
--###############################################################################################################################################################################
--###############################################################################################################################################################################

unit_test.comparators = {}
unit_test.comparison = {}
unit_test.id = nil

function unit_test.describe(s: string, f: (expect: typeof(unit_test.expect)) -> ())
	unit_test.comparison.description = s
	unit_test.id = unit_test.id or '<NONE>'
	
	f(unit_test.expect)
	
	table.clear(unit_test.comparison)
	unit_test.id = nil
end

function unit_test.reset_comparison()
	local comparison = unit_test.comparison
	
	comparison.explicit_negate = nil
	comparison.expected = nil
	comparison.got = nil
end

function unit_test.expect<T>(value: T): typeof(unit_test.comparators)
	local comparison = unit_test.comparison
	
	unit_test.reset_comparison()
	
	comparison.got = value
	return unit_test.comparators
end

function unit_test.does_pass()
	local comparison = unit_test.comparison
	local result = comparison.does_pass
	
	if comparison.explicit_negate then
		result = not result
	end
	
	return result
end

function unit_test.closure_string()
	local comparison = unit_test.comparison
	local does_pass = unit_test.does_pass()
	local result = `[{does_pass and 'PASSED' or 'FAILED'}] {comparison.description}`
	
	return result
end

function unit_test.closure()
	local closure_string = unit_test.closure_string()
	
	if unit_test.does_pass() and not unit_test.fails_only then
		print(closure_string, unit_test.comparison)
	elseif not unit_test.does_pass() then
		warn(closure_string, unit_test.comparison)
	end
end

function unit_test.comparators.to_be<T>(other: T)
	unit_test.comparison.expected = other
	unit_test.comparison.does_pass = unit_test.comparison.got == other
	unit_test.closure()
end

function unit_test.comparators.to_not<T>(other: T): typeof(unit_test.comparators)
	local comparison = unit_test.comparison
	comparison.explicit_negate = not comparison.explicit_negate
	return unit_test.comparators
end

function unit_test.comparators.to_be_less_than<T>(other: T)
	unit_test.comparison.expected = other
	unit_test.comparison.does_pass = unit_test.comparison.got < other
	unit_test.closure()
end

function unit_test.comparators.to_be_less_or_equal_to<T>(other: T)
	unit_test.comparison.expected = other
	unit_test.comparison.does_pass = unit_test.comparison.got <= other
	unit_test.closure()
end

function unit_test.comparators.to_be_greater_than<T>(other: T)
	unit_test.comparison.expected = other
	unit_test.comparison.does_pass = unit_test.comparison.got > other
	unit_test.closure()
end

function unit_test.comparators.to_be_greater_or_equal_to<T>(other: T)
	unit_test.comparison.expected = other
	unit_test.comparison.does_pass = unit_test.comparison.got >= other
	unit_test.closure()
end

function unit_test.comparators.to_span_fields_over<T>(other: T)
	local does_pass = true
	local comparison = unit_test.comparison
	
	comparison.expected = other
	
	for i, v in other do
		if comparison.expected[i] ~= v then
			does_pass = false
			break
		end
	end
	
	unit_test.comparison.does_pass = does_pass
	unit_test.closure()
end

function fuzzy_equal(a: number, b: number, epsilon: number?)
	local epsilon = epsilon or unit_test.epsilon
	local half_range = math.abs(a - b)
	
	return half_range < epsilon
end

function unit_test.comparators.to_be_around<T>(other: T, precision: number?)
	local comparison = unit_test.comparison
	comparison.expected = other
	
	unit_test.comparison.does_pass = fuzzy_equal(comparison.got, comparison.expected, precision)
	
	unit_test.closure()
end

function unit_test.comparators.to_span_fields_around_over<T>(other: T, precision: number?)
	local does_pass = true
	local comparison = unit_test.comparison
	
	comparison.expected = other
	
	for i, v in other do
		if fuzzy_equal(comparison.expected[i], v, precision) == false then
			does_pass = false
			break
		end
	end
	
	
	unit_test.comparison.does_pass = does_pass
	unit_test.closure()
end

unit_test.fails_only = true
unit_test.epsilon = 0.000001

module.unit_test = unit_test
module.__chl_unit_test = false

--###############################################################################################################################################################################
--###############################################################################################################################################################################
--###############################################################################################################################################################################

module.test = test

return module
