local AsciiTable = {}

table_insert = table.insert

function AsciiTable.get_larges(of: {{any}}): {number}
	local larges = {}
	
	for _, row in of do
		for c, value in row do
			larges[c] = math.max(larges[c] or 0, #tostring(value))
		end
	end
	
	return larges
end

function AsciiTable.format(of: {{any}}): {string}
	local larges = AsciiTable.get_larges(of)
	local result = {}
	
	-- boundary
	local boundary = '+'
	
	for _, v in larges do
		boundary ..= ('-'):rep(v + 2) .. '+'
	end
	
	table_insert(result, boundary)
	
	-- regular rows
	local n_columns = #larges
	
	for r, row in of do
		
		local row_string = '|'
		
		for c = 1, n_columns do
			local value = tostring(row[c])
			local spaces = larges[c] - #value
			local space = (' '):rep(spaces)
			
			row_string ..= ` {value} {space}|`
		end
		
		table_insert(result, row_string)
		
		if r == 1 then
			table_insert(result, boundary)
		end
	end
	
	table_insert(result, boundary)
	
	return result
end

function AsciiTable.format_whole(of: {{any}}): string
	return table.concat(AsciiTable.format(of), '\n')
end

return AsciiTable
