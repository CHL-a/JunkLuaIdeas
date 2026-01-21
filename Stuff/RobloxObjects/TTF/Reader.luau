local module = {}

local BufferWrapper = require('../@CHL>BufferWrapper')
local Reader = require('./@CHL>TTF>Reader')
local Types = require('./@CHL>TTF>Types')
local Writer = require('./@CHL>TTF>Writer')
local Map = require('../@CHL>Map')
local Dash = require('../@CHL>DashSingular')
local Shared = require('./@CHL>TTF>Shared')
local Bit32Ext = require('../@CHL>Bit32Ext')

type dict<T> = Map.dictionary<T>
type ttf_struct = Types.ttf_struct

disguise = require('../LuaUTypes').disguise

--#####################################################################################
--#####################################################################################
--#####################################################################################

tinsert = table.insert
tsort = table.sort

function module.from_file(buff: buffer)
	local it = BufferWrapper.iterator.new(buff)
	local reader = Reader.reader.new(it)
	local result: ttf_struct = disguise{}

	reader.struct = result

	local scalar_type = reader:readu32(true)
	local num_tables = reader:readu16(true)
	local search_range = reader:readu16(true)
	local entry_selector = reader:readu16(true)
	local range_shift = reader:readu16(true)

	result.scalar_type = scalar_type
	result.num_tables = num_tables
	result.search_range = search_range
	result.entry_selector = entry_selector
	result.range_shift = range_shift

	local table_meta = {}
	local order = {}

	for i = 1, num_tables do
		local tag = reader:read_string(4)
		local checksum = reader:readu32(true)
		local offset = reader:readu32(true)
		local length = reader:readu32(true)

		tinsert(order, tag)

		table_meta[tag] = {
			checksum = checksum,
			offset = offset,
			length = length
		}
	end

	tsort(order, function(index_1, index_2)return table_meta[index_1].offset < table_meta[index_2].offset end)

	result.table_meta = table_meta
	result.tables = disguise{}

	for _, v in order do
		local t = table_meta[v]

		reader:reset_checksum()
		reader:read_table(v)

		if reader.offset ~= t.length + t.offset then
			warn('not all evaluated bytes parsed:', v)
			print(result.tables[v])
			print(result)
			print(`offset={t.offset}\nlen={t.length}\ncurrent_offset={reader.offset}\ncurrent_len={reader.offset-t.offset}`)
		end

		local n = t.offset + t.length
		for i = reader.offset + 1, n do -- this should not be iterated if parsing of above is done right
			reader:readu8()
		end

		-- gap fill
		while reader.checksum_offset ~= 0 do
			reader:readu8()
		end

		local checksum = reader:get_checksum()

		if checksum ~= t.checksum and v ~= 'head' then
			--print(reader.checksum_buffer_w:to_string(3))
			print(reader, t, reader:get_checksum())
			warn(`bad checksum: table={v}, {checksum} ~= {t.checksum}`)
		end
	end
	
	return result
end

--#####################################################################################
--#####################################################################################
--#####################################################################################

function module.to_file(struct: ttf_struct): BufferWrapper.object
	local buffer_consumer = BufferWrapper.consumer.new()
	local writer = Writer.writer.new(buffer_consumer)

	writer.struct = struct

	writer:writeu32(struct.scalar_type)
	writer:writeu16(struct.num_tables)
	writer:writeu16(struct.search_range)
	writer:writeu16(struct.entry_selector)
	writer:writeu16(struct.range_shift)

	-- table metadata, indicated with map<table_name, file_offset>
	local table_metadatas: dict<number> = {}
	local current_tables = Dash.keys(struct.tables)

	tsort(current_tables)

	for _, i in current_tables do
		local v = struct.table_meta[i]

		table_metadatas[i] = writer.offset
		-- obviously temporary values, they'll be assigned later
		writer:write_string(i)
		writer:write_string('cksm')
		writer:write_string('ofst')
		writer:write_string('lenn')
	end

	tsort(current_tables, Writer.writer.sort_by_implicit_order)

	-- tables
	for _, i in current_tables do
		local v = struct.tables[i]
		writer:reset_checksum()
		writer:reset_length()

		-- set offset
		local metadata_offset = table_metadatas[i]
		local starting_offset = writer.offset
		buffer_consumer.buffw:writeu32(metadata_offset + 8, starting_offset, true)

		-- do stuff here
		--[[
		if starting_offset ~= struct.table_meta[i].offset then
			warn(`wrong starting offset: {i} {starting_offset}~={struct.table_meta[i].offset}`)
		end
		]]

		--print(i, starting_offset, v, struct.table_meta[i])

		if not Writer.writer.tables[i] then
			warn(`table {i} has no writer`)
			break
		end

		writer:write_table(i, v)

		-- complete other metadatas
		buffer_consumer.buffw:writeu32(metadata_offset + 12, writer.current_length, true)

		--[[
		if writer.current_length ~= struct.table_meta[i].length then
			warn(`length mismatch at {i}: {writer.current_length} ~= {struct.table_meta[i].length}`)
		end
		--]]

		while writer.checksum_offset ~= 0 do
			writer:writeu8(0x00)
		end

		buffer_consumer.buffw:writeu32(metadata_offset + 4, writer:get_checksum(), true)
		
		--[[
		if writer:get_checksum() ~= struct.table_meta[i].checksum then
			warn(`checksum mismatch at {i}: {writer:get_checksum()} ~= {struct.table_meta[i].checksum}`)
		end
		--]]
	end
	
	local head_checksum_adjustment = 0
	local n = buffer_consumer.size
	local i = 0
	
	while i < n do
		local chunk = buffer_consumer.buffw:readu32(i, true)
		
		head_checksum_adjustment = bit32.band(chunk + head_checksum_adjustment, Bit32Ext.u32_max)
		
		i += 4
	end
	
	head_checksum_adjustment = bit32.lshift(0xB1B0AFBA - head_checksum_adjustment, 0)
	
	if head_checksum_adjustment < 0  then
		warn('unhandled case: head_checksum_adjustment < 0: ', head_checksum_adjustment)
	end
	
	buffer_consumer.buffw:writeu32(writer.head_checksum_adjustment_offset, 0xB1B0AFBA - head_checksum_adjustment, true)
	
	return buffer_consumer:build()
end

--#####################################################################################
--#####################################################################################
--#####################################################################################

lshift = bit32.lshift
tclear = table.clear
tfind = table.find

--[[
	Responsible for normalizing values within ttf_struct
	
	currently mutates all number values (not array values)
	
	optimally, this should also sort glyfs by codepoints instead of current glyf order, that way table cmap can be optimized
	
	idea for later, maybe
]]
function module.normalize(struct: ttf_struct)
	local tables = struct.tables
	local num_glyphs = #tables.hmtx.long_hor_metrics
	local advance_width_max

	for _, v in tables.hmtx.long_hor_metrics do
		advance_width_max = math.max(advance_width_max or 0, v.advance_width)
	end

	tables.hhea.advance_width_max = advance_width_max
	tables.hhea.num_of_long_hor_metrics = num_glyphs

	tables.maxp.num_glyphs = num_glyphs
	
	local cmap = tables.cmap
	cmap.num_tables = #cmap.encoding_records
	
	for _, format in cmap.formats do
		if format.format_number == 4 then
			local format_4: Types.cmap_format_4 = format
			local glyph_index_map = format_4.glyph_index_map
			local keys = Dash.keys(glyph_index_map)
			local seg_count = 0

			tclear(format_4.start_code)
			tclear(format_4.end_code)
			tclear(format_4.id_delta)
			tclear(format_4.id_range_offset)
			tclear(format_4.glyph_index_array)
			
			format_4.glyph_index_array_length = 0
			
			tsort(keys)
			
			local i = 1
			
			while i <= #keys do
				local starting_codepoint = keys[i]
				local index = glyph_index_map[starting_codepoint]
				local ending_codepoint = starting_codepoint
				local current_index = index
				
				seg_count += 1
				i += 1
				
				tinsert(format_4.start_code, starting_codepoint)
				
				local is_linear_increment = false
				local is_const_increment = false
				
				if keys[i] and keys[i] == ending_codepoint + 1 then
					if glyph_index_map[keys[i]] == current_index + 1 then
						is_linear_increment = true
						
						repeat
							i += 1
							ending_codepoint += 1
							current_index += 1
						until keys[i] ~= ending_codepoint + 1 or glyph_index_map[keys[i]] ~= current_index + 1
					elseif glyph_index_map[keys[i]] == current_index then
						is_const_increment = true
						format_4.codepoint_array = {}
						
						repeat
							i += 1
							ending_codepoint += 1
						until keys[i] ~= ending_codepoint + 1 or glyph_index_map[keys[i]] ~= current_index
					end
				end

				tinsert(format_4.end_code, ending_codepoint)
				
				if starting_codepoint == 0xFFFF then
					tinsert(format_4.id_delta, 1)
				elseif is_const_increment then
					tinsert(format_4.id_delta, 0)
				else
					tinsert(format_4.id_delta, index - starting_codepoint)
				end
				
				if not is_const_increment then
					tinsert(format_4.id_range_offset, 0)
				else
					tinsert(format_4.id_range_offset, 1)
					
					format_4.glyph_index_array_length += ending_codepoint - starting_codepoint + 1
				end
				
				
			end

			local entry_selector = math.log(seg_count, 2) // 1
				
			format_4.seg_count_x2 = lshift(seg_count, 1)
			format_4.entry_selector = entry_selector
			format_4.search_range = lshift(1, entry_selector + 1)
			format_4.range_shift = format_4.seg_count_x2 - format_4.search_range
		end
	end
	
	warn('theres more to cmap and glyf in writer')

	local max_contours = 0
	local glyf_max, glyf_min
	local max_points = 0
	for _, glyf in tables.glyf.list do
		if glyf.is_end then
			continue
		end
		
		glyf_max = (glyf_max or glyf.header.max):Max(glyf.header.max)
		glyf_min = (glyf_min or glyf.header.min):Min(glyf.header.min)
		max_points = math.max(max_points, #glyf.simple_data.x_coordinates)
		
		max_contours = math.max(max_contours, glyf.header.number_of_contours)
	end
	
	tables.head.max = glyf_max
	tables.head.min = glyf_min
	tables.maxp.max_contours = max_contours
	tables.maxp.max_points = max_points

	if tables.post.format == 2 then
		tables.post.post_format_2.num_glyphs = tables.maxp.num_glyphs
	end

	tables.gasp.num_ranges = #tables.gasp.gasp_records
end

--#####################################################################################
--#####################################################################################
--#####################################################################################

type glyf = Types.glyf

function module.find_glyf_from_offset(ttf_struct: ttf_struct, offset: number): glyf?
	for _, gylf in ttf_struct.tables.glyf.list do
		if gylf.offset == offset then
			return gylf
		end
	end
end

--#####################################################################################
--#####################################################################################
--#####################################################################################

local Set = require('../@CHL>Set')

type set<T> = Set.simple<T>

export type glyph_array_element = {
	-- denotes either ascii values or codepoints
	codepoints: set<number>;
	is_default: boolean;
	
	horizontal_metric: Types.long_hor_metric;
	
	loca_offset: number;
	loca_size: number;
	
	glyf: glyf?;
	
	post_name: string;
	post_index: number;

}
export type glyph_array = {glyph_array_element}

--[[
	Sorts to allow consistent codepoint based sorting, see notes
]]
function module.glyph_array_element_compare(value_1: glyph_array_element, value_2: glyph_array_element): boolean
	if value_1.is_default then
		return true
	elseif value_2.is_default then
		return false
	end
	
	local codepoints_1 = Set.simple.toArray(value_1.codepoints)
	local codepoints_2 = Set.simple.toArray(value_2.codepoints)
	
	tsort(codepoints_1)
	tsort(codepoints_2)
	
	local codepoint_1 = codepoints_1[1]
	local codepoint_2 = codepoints_2[1]
	
	if codepoint_1 == 0 then
		return true
	elseif codepoint_2 == 0 then
		return false
	elseif not codepoint_1 then
		return true
	elseif not codepoint_2 then
		return false
	else
		return codepoint_1 < codepoint_2
	end
end

function module.glyph_array_merge(value_1: glyph_array, value_2: glyph_array)
	local codepoint_set = {}
	
	for _, element in value_1 do
		for codepoint in element.codepoints do
			codepoint_set[codepoint] = true
		end
	end
	
	for i = 4, #value_2 do
		local element = value_2[i]
		local is_in_set = false
		
		for codepoint in element.codepoints do
			if codepoint_set[codepoint] then
				is_in_set = true
				break
			end
		end
		
		if not is_in_set then
			tinsert(value_1, element)
		end
	end
end


--[[
	note: multiple codepoint values can refer to the same glyph, if you want to demonstrate this, make it point to the same
	glyf instead of making a new one
]]
function module.to_glyph_array(ttf_struct: ttf_struct): glyph_array
	local tables = ttf_struct.tables
	local glyph_array = {}
	local cmap_formats = tables.cmap.formats
	
	for i, v in tables.hmtx.long_hor_metrics do
		local element: glyph_array_element = {}
		local i_0 = i - 1
		
		element.is_default = i == 1
		element.codepoints = {}
		element.horizontal_metric = v
		element.loca_offset = tables.loca.offsets[i]
		element.loca_size = tables.loca.offsets[i + 1] - element.loca_offset
		element.post_index = assert(tables.post.post_format_2).glyph_name_index[i]
		
		local post_name = Shared.enums.post_names[element.post_index]
		
		if not post_name and element.post_index >= 258 then
			post_name = tables.post.post_format_2.string_bulk[element.post_index - 257]
		end
		
		element.post_name = post_name
		
		if element.loca_size ~= 0 then
			element.glyf = module.find_glyf_from_offset(ttf_struct, element.loca_offset)
		end
		
		for _, format in cmap_formats do
			if format.format_number == 4 then
				for codepoint, index in format.glyph_index_map do
					if index ~= i_0 then continue end
					element.codepoints[codepoint] = true
				end
			end
		end
		
		tinsert(glyph_array, element)
	end

	return glyph_array
end

-- directly clears and replaces multiple values in ttf_struct
function module.set_glyph_array(ttf_struct: ttf_struct, value: glyph_array)
	local tables = ttf_struct.tables
	local long_hor_metrics = tables.hmtx.long_hor_metrics
	local cmap_formats = tables.cmap.formats
	local post_format_2 = tables.post.post_format_2
	local loca_offsets = tables.loca.offsets
	local glyf_list = tables.glyf.list
	
	assert(post_format_2)
	
	-- clears and replaces the values
	tclear(long_hor_metrics)
	tclear(loca_offsets)
	tclear(glyf_list)
	
	local nbsp_index
	
	for i, v in value do
		if v.codepoints[160] then
			nbsp_index = i
		end
	end
	
	for _, v in cmap_formats do
		if v.format_number == 0 then
			for i = 1, 256 do
				v.glyph_index_array[i] = 0
			end
			
			v.glyph_index_array[9] = 1
			v.glyph_index_array[10] = 2
			v.glyph_index_array[203] = nbsp_index - 1
		elseif v.format_number == 4 then
			tclear(v.glyph_index_map)
			tclear(v.start_code)
			tclear(v.end_code)
			tclear(v.id_delta)
			tclear(v.id_range_offset)
		end
	end
	
	tclear(post_format_2.glyph_name_index)
	tclear(post_format_2.string_bulk)
	
	-- populate values
	local glyf_array_set = {}
	local current_loca_offset = 0
	
	for i, v in value do
		local i_0 = i - 1
		
		-- hmtx
		tinsert(long_hor_metrics, v.horizontal_metric)
		
		-- cmap
		for codepoint, _ in v.codepoints do
			for _, format in cmap_formats do
				if format.format_number == 0 then
					if codepoint < 0xFFFF then
						format.glyph_index_array[codepoint + 1] = i_0
					end
				elseif format.format_number == 4 then
					format.glyph_index_map[codepoint] = i_0
				end
			end
		end
		
		-- loca and glyf
		tinsert(loca_offsets, current_loca_offset)
		
		local glyf = v.glyf
		if glyf then
			local found = tfind(glyf_array_set, glyf)
			
			if not found then
				tinsert(glyf_array_set, glyf)
				tinsert(glyf_list, glyf)
				current_loca_offset += glyf.length
				found = #glyf_array_set
				
				while current_loca_offset % 4 ~= 0 do
					current_loca_offset += 1
				end
			end
		end
		
		-- post
		tinsert(post_format_2.glyph_name_index, v.post_index)
		
		if v.post_index >= 258 then
			tinsert(post_format_2.string_bulk, v.post_name)
		end
		
	end
	
	tinsert(loca_offsets, current_loca_offset)
end

--#####################################################################################
--#####################################################################################
--#####################################################################################

return module
