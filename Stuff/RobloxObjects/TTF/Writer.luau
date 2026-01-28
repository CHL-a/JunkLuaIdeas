--[[
	file parsing into a struct

	Sources:
	 1. https://tchayen.github.io/posts/ttf-file-parsing
	 2. for checking: https://fontdrop.info/#/?darkmode=true
	 3. https://developer.apple.com/fonts/TrueType-Reference-Manual/RM06/Chap6Tables.html
	 4. https://learn.microsoft.com/en-us/typography/opentype/spec/glyf
	 5. https://stevehanov.ca/blog/?id=143
	TTF file format:
	
	All values are parsed in big-endian unless stated otherwise
	
	Legend:
	+-------+-------+-----------------------------------------------------------------------------+
	|Index  |Text   |Description                                                                  |
	+-------+-------+-----------------------------------------------------------------------------+
	|Type   |uxx    |Unsigned x bit int                                                           |
	|       |ixx    |Signed x bit int                                                             |
	|       |str[x] |String of x bytes                                                            |
	|       |SDesc  |See Description                                                              |
	|       |fixed  |Fixed point number, not done in scifi notation, consumes 32 bits, divided 16 |
	|       |       |on 16 (or 16.16)                                                             |
	|       |date   |Internally, it's stored as a u64 stored as seconds since mac_epoch, but      |
	|       |       |current script will use structs                                              |
	|       |byte[x]|x bytes, most likely, without meaning.                                       |
	+-------+-------+-----------------------------------------------------------------------------+
	
	Defintions:
	+-------+-------------------------------------------------------------------------------------+
	|Word   |Definition                                                                           |
	+-------+-------------------------------------------------------------------------------------+
	|Contour|A list of points, usually either straight (two points), or part of a bezier quadratic|
	|       |curve (three points, two describes the end and one describes the curve, which is off |
	|       |the line). This list describes a line, which describes the edge of a 2D shape. The   |
	|       |direction which the points are placed describes the shape if it's filled (clockwise) |
	|       |or not (counter-clockwise).                                                          |
	+-------+-------------------------------------------------------------------------------------+
	
	File layout:
	+-------+--------------+------+---------------------------------------------------------------+
	|Section|Name          |Type  |Description                                                    |
	+-------+--------------+------+---------------------------------------------------------------+
	|Header |scalar_type   |u32   |                                                               |
	|       |num_tables    |u16   |Number of tables for for upcoming section                      |
	|       |search_range  |u16   |                                                               |
	|       |entry_selector|u16   |                                                               |
	|       |range_shift   |u16   |                                                               |
	|General|index         |str[4]|Index for the table, used for lookup, for a table stored later |
	|table  |checksum      |u32   |data integrity value, in this case, the check is suming all    |
	|info   |              |      |Bytes in sets of u32 then % 2^32 or & 2^32-1 (0xFFFF_FFFF or   |
	|       |              |      |u32_max)                                                       |
	|       |offset        |u32   |Offset from beginning of file to the table                     |
	|       |length        |u32   |Length of the table in bytes                                   |
	|Tables |See Desc      |SDesc |Due to the nature of having an offset and length, anything     |
	|       |              |      |after this will contain a collection of tables, all of which   |
	|       |              |      |may not follow a particular order in conventional sense        |
	+-------+--------------+------+---------------------------------------------------------------+
	
	Tables:
	 * due to the nature of a checksum, offset and length, they may not be immediately processed, as 
	   checksums requires the sum of u32s, some bytes may have to be discarded
	 * Tables already described in the apple spec (3) will be described in this section, they are 
	   processed up to down
	   * Types table as defined in (3)
	+------------+-------------+-------------------------------------+
	|Apple type  |Document type|Description                          |
	+------------+-------------+-------------------------------------+
	|Fixed       |fixed        |16.16 fixed point number             |
	|uintxx      |uxx          |                                     |
	|longDateTime|date         |See date description and struct above|
	|FWord       |i16          |Alias                                |
	|intxx       |ixx          |                                     |
	+------------+-------------+-------------------------------------+
	 * Specific notes, which the majority is already covered by Apple and Microsoft
	+----+-----------------+------------------------------------------------------------------------+
	|Tble|Index            |Description                                                             |
	+----+-----------------+------------------------------------------------------------------------+
	|cmap|EncodingRecords  |Multiple records based on platform. Offset denotes a referral to a      |
	|    |                 |format struct, it is possible to have more than two formats, and it is  |
	|    |                 |possible for two encoding records to refer to a format. That being said,|
	|    |                 |After this, check if length has been fully consumed.                    |
	|    |                 |version                                                                 |
	|    |                 |                                                                        |
	|cmap|format           |Based on above, the value for formats is based on a map of offset to    |
	|    |                 |format struct                                                           |
	|    |                 |                                                                        |
	|loca|offsets          |Though these numbers do indicate the relative offset for table glyf. If |
	|    |                 |data is read as i16s to parse into array elements, then each element is |
	|    |                 |multiplied by 2 to get the actual offset.                               |
	|    |                 |                                                                        |
	|    |                 |The way it's structured, it is an array of num_glyphs + 1 glyphs, in    |
	|    |                 |this case, for any offset of tables.loca.offset[i], and next_offset at  |
	|    |                 |tables.loca.offset[i + 1], offset denotes the offset of the glyph within|
	|    |                 |the file, upon the glyph blob, and next_offset - offset is the length of|
	|    |                 |the blob.                                                               |
	|    |                 |                                                                        |
	|glyf|any              |Same general case, ususally there's a header, then accompanied by glyph |
	|    |                 |denoted either simple or more complex. Those types offer their own      |
	|    |                 |struct format, but like regular tables, they sometimes have extra zeros |
	|    |                 |because offsets may come in even numbers.                               |
	|    |flags (simple)   |This part might be confusing because we assume that flags does refer to |
	|    |                 |a glyf but it actually refers to a point. flags is a byte array of      |
	|    |                 |the same length of the amount of points inside a glyf (or               |
	|    |                 |last(end_pnts_of_contours) + 1). Therefore, each byte is a bitfield for |
	|    |                 |the point at the same index.                                            |
	|    |x_coordinates &  |Despite an array, the transformation of raw data to real values is      |
	|    |y_coordinates    |actually a bit more intricate. In order to make an array of coordinate  |
	|    |(simple)         |values, the flags array is the primary determinate for deciding how data|
	|    |                 |is read and transformed.                                                |
	|    |                 |                                                                        |
	|    |                 |However, whatever value determines the next element of the axis         |
	|    |                 |coordinate array is based on the previous element, which is usually     |
	|    |                 |added. Therefore:                                                       |
	|    |                 |                                                                        |
	|    |                 |```                                                                     |
	|    |                 |next_value_in_array = delta + previous_value_in_array                   |
	|    |                 |```                                                                     |
	|    |                 |                                                                        |
	|    |                 |delta is the primary value that is used to determine the next value.    |
	|    |                 |Given specific booleans, is_short as B and is_same as S, from the       |
	|    |                 |respective bitfield using the specific flags based on axis:             |
	|    |                 | +--+-----------------------------------------------------------------+ |
	|    |                 | |BS|Description                                                      | |
	|    |                 | +--+-----------------------------------------------------------------+ |
	|    |                 | |T*|delta is defined as a read byte from the stream, then multipled  | |
	|    |                 | |  |by a sign based on S, which is 1 or -1 if S is 1 or 0            | |
	|    |                 | |  |respectively.                                                    | |
	|    |                 | |FT|Given that this case is specifically referring to Apple's ttf    | |
	|    |                 | |  |documentation, then this case results the next_value_in_array    | |
	|    |                 | |  |being the same as previous. Therefore, delta is 0                | |
	|    |                 | |FF|delta is a read i16 from the stream.                             | |
	|    |                 | +--+-----------------------------------------------------------------+ |
	|    |                 |                                                                        |
	|hhea|advance_width_max|Within alone characters of a font, it's usually fine to leave it alone  |
	|    |                 |but when it's the case when you attempt to merge characters, then how   |
	|    |                 |this is calculated as such:                                             |
	|    |                 |                                                                        |
	|    |                 |Given L[i] as the ith element of hmtx.long_hor_metrics, then,           |
	|    |                 |advance_width_max = max(L[i].advance_width)                             |
	|    |x_max_extent     |Same situation as above, but it also uses values from table head.       |
	|    |                 |It is defined as (subject to change):                                   |
	|    |                 |                                                                        |
	|    |                 |x_delta = head.max.x - head.min.x                                       |
	|    |                 |x_max_extent = max(0, unpack(hmtx.left_side_bearings)) + x_delta        |
	|    |                 |                                                                        |
	|    |                 |At least, that's how it should be, where I sourced my testing fonts     |
	|    |                 |from, this formula isn't consistent, for now, it is defined as:         |
	|    |                 |                                                                        |
	|    |                 |x_max_extent = L[1].left_side_bearing + x_delta                         |
	|    |                 |                                                                        |
	|OS/2|x_avg_char_width |Based on the calculation as defined in microsoft's documentation,       |
	|    |                 |It really is a literal average definition over some collection, atm,    |
	|    |                 |I dont really plan on including an implementation of normalizing this in|
	|    |                 |the normalization function. Contact me if there is a structural purpose |
	|    |                 |to this value, but it is noted here in case some implementation is being|
	|    |                 |used without my knowing.                                                |
	|    |                 |                                                                        |


	+----+-----------------+------------------------------------------------------------------------+
	
	Formats:
	 * Same odd format as tables
	   * defined here: https://learn.microsoft.com/en-us/typography/opentype/spec/cmap#format-4-segment-mapping-to-delta-values
]]

--#####################################################################################
--#####################################################################################
--#####################################################################################

local module = {}
local Bit32Ext = require('../@CHL>Bit32Ext')
local Object = require('../Object')
local Class = require('../Class')
local StringUtils = require('../@CHL>StringUtils')
local Types = require('./@CHL>TTF>Types')
local BinaryStream = require('../@CHL>BinaryStream')
local BufferWrapper = require('../@CHL>BufferWrapper')
local DateTimeAlt = require('../@CHL>DateTime')
local Set = require('../@CHL>Set')
local Dash = require('../@CHL>DashSingular')
local Reader = require('./@CHL>TTF>Reader')
local Shared = require('./@CHL>TTF>Shared')

type ttf_struct = Types.ttf_struct
type date_struct = DateTimeAlt.date_struct

lshift = bit32.lshift
rshift = bit32.rshift
band = bit32.band
disguise = require('../LuaUTypes').disguise
ftest = Bit32Ext.flag_test
bnot = bit32.bnot
bor = bit32.bor
last = Dash.last

function error_incomplete()error('incomplete') end
function error_unimplemented()error('unimplemented') end

--#####################################################################################
--#####################################################################################
--#####################################################################################

function module.get_compensator(value: number, start_at: number, length: number, is_inverse: boolean)
	length = length or 4
	
	start_at = (start_at or 0) + length
	start_at %= 4
	
	local left_length = 4 - start_at
	local right_length = start_at
	
	local left = rshift(value, left_length * 8)
	local right = rshift(lshift(value, right_length * 8), right_length * 8)
	
	value = bor(lshift(right, right_length * 8), left) 
	
	if is_inverse then
		return Bit32Ext.u32_max_after - value
	end
	
	return value
end

--#####################################################################################
--#####################################################################################
--#####################################################################################

--#####################################################################################
--#####################################################################################
--#####################################################################################

local Map = require('../@CHL>Map')

type ttf_writer = Types.ttf_writer
type dict<T> = Map.dictionary<T>

Writer = {}
tfind = table.find
tinsert = table.insert

function write_number_call(index: string, bytes_consumed: number)
	return function(self: ttf_writer, value: number, shallow_start_at: number?)
		local referral = self.referral
		local buff_w = referral.buffer
		
		if not shallow_start_at then
			self.offset += bytes_consumed
			referral[index](referral, value, true)

			for i = 1, bytes_consumed do
				local byte = buff_w:readu8(i - 1)

				self:place_byte(byte)
			end
		else
			-- implementation for shallow writing without offset increment
			local file = self.consumer.buffw
			
			file[index](file, shallow_start_at, value, true)
			
			local checksum_start = self.offset - self.current_length
			local relative_offset = (shallow_start_at - checksum_start) % 4

			local checksum_comp = module.get_compensator(value, relative_offset, bytes_consumed)
			
			self:add_to_checksum(checksum_comp)
		end
	end
end

function Writer.new(b_w_consumer: BufferWrapper.to_buffw_consumer): ttf_writer
	local self: ttf_writer = Object.simple.new(Writer)
	self.referral = BinaryStream.writer.new(b_w_consumer)
	self.consumer = b_w_consumer
	self.offset = 0
	
	self.checksum_buffer_w = BufferWrapper.from.size(8)
	self.checksum_offset = 0
	self.current_length = 0
	
	return self
end

function Writer.write_string(self: ttf_writer, str: string)
	for i = 1, #str do
		self:writeu8(str:byte(i))
	end
end

function Writer.reset_length(self: ttf_writer)
	self.current_length = 0
end

function Writer.add_to_checksum(self: ttf_writer, value: number) 
	local sum = self:get_checksum() + value
	
	self.checksum_buffer_w:writeu32(4, lshift(sum, 0), true)
end

function Writer.place_byte(self: ttf_writer, byte: number, is_shallow: boolean)
	local checksum_buffer = self.checksum_buffer_w

	checksum_buffer:writeu8(self.checksum_offset, byte)

	self.checksum_offset += 1

	if self.checksum_offset > 3 then
		self.checksum_offset = 0

		local batch = self:get_partial()

		if Reader.do_print_checksums then
			warn('unimplemented')
			-- print(`{batch},{sum}->{lshift(batch + sum, 0)}`)
		end
		
		self:add_to_checksum(batch)
	end
	
	if not is_shallow then
		self.current_length += 1
	end
end

function Writer.compensate_checksum(self: ttf_writer, value: number, at: number, length: number)
	
end

function Writer.write_fixed(self: ttf_writer, num: number)
	local integer = num * 2 ^ 16
	if integer % 1 ~= 0 then
		warn('bad int:', integer)
	end
	self:writeu32(integer)
end

function Writer.write_table(self: ttf_writer, specific_index: string, value: dict<any>)
	local func = Writer.tables[specific_index]
	
	assert(func, `does not exist {specific_index}`)
	
	func(self, value)
end

function Writer.sort_by_implicit_metadata(value_a: string, value_b: string): boolean
	local found_a = tfind(Writer.implicit_order, value_a)
	local found_b = tfind(Writer.implicit_order, value_b)

	if not found_b and not found_a then
		return StringUtils.compare_strings(value_a, value_b)
	elseif not found_b then
		return true
	elseif not found_a then
		return false
	else
		return found_a < found_b
	end
end

function Writer.sort_by_implicit_order(value_a: string, value_b: string): boolean
	local found_a = tfind(Writer.implicit_order, value_a)
	local found_b = tfind(Writer.implicit_order, value_b)
	
	if not found_b and not found_a then
		return StringUtils.compare_strings(value_a, value_b)
	elseif not found_b then
		return true
	elseif not found_a then
		return false
	else
		return found_a < found_b
	end
end

function Writer.write_date(self: ttf_writer, date: date_struct)
	-- atm just as a safe bet, use an already implemented method
	local mac_epoch = DateTimeAlt.struct.to.date_time(DateTimeAlt.mac_epoch:to_struct())
	local date_time = DateTimeAlt.struct.to.date_time(date)
	local seconds_since = date_time.UnixTimestamp - mac_epoch.UnixTimestamp
	local upper, lower = seconds_since // Bit32Ext.u32_max_after, lshift(seconds_since, 0)
	
	self:writeu32(upper)
	self:writeu32(lower)
end

function Writer.write_vector2(self: ttf_writer, value: Vector2)
	self:writei16(value.X)
	self:writei16(value.Y)
end

Writer.tables = {}

function Writer.tables.head(self: ttf_writer, value)
	self:writeu16(value.major_version)
	self:writeu16(value.minor_version)
	self:write_fixed(value.font_revision)
	
	self.head_checksum_adjustment_offset = self.offset
	self:writeu32(0x00) -- value.checksum_adjustment
	self:writeu32(value.magic_number)
	
	self:writeu16(value.flags)
	self:writeu16(value.units_per_em)
	self:write_date(value.created)
	self:write_date(value.modified)
	self:write_vector2(value.min)

	self:write_vector2(value.max)
	self:writeu16(value.mac_style)
	self:writeu16(value.lowest_rec_ppem)
	self:writei16(value.font_direction_hint)
	self:writei16(value.index_to_loc_format)
	
	self:writei16(value.glyph_data_format)
end

function Writer.tables.hhea(self: ttf_writer, value)
	self:write_fixed(value.hhea_version)
	self:writei16(value.ascent)
	self:writei16(value.descent)
	self:writei16(value.line_gap)
	self:writeu16(value.advance_width_max)
	
	self:writei16(value.min_left_side_bearing)
	self:writei16(value.min_right_side_bearing)
	self:writei16(value.x_max_extent)
	self:writei16(value.caret_slope_rise)
	self:writei16(value.caret_slope_run)
	
	self:writei16(value.caret_offset)
	self:writeu32(value.reserved_1)
	self:writeu32(value.reserved_2)
	self:writei16(value.metric_data_format)
	
	self:writeu16(value.num_of_long_hor_metrics)
end

function Writer.tables.maxp(self: ttf_writer, value: dict<any>)
	self:write_fixed(value.maxp_version)
	self:writeu16(value.num_glyphs)
	self:writeu16(value.max_points)
	self:writeu16(value.max_contours)
	self:writeu16(value.max_composite_points)
	
	self:writeu16(value.max_composite_contours)
	self:writeu16(value.max_zones)
	self:writeu16(value.max_twilight_points)
	self:writeu16(value.max_storage)
	self:writeu16(value.max_function_defs)
	
	self:writeu16(value.max_instruction_defs)
	self:writeu16(value.max_stack_elements)
	self:writeu16(value.max_size_of_instructions)
	self:writeu16(value.max_component_elements)
	self:writeu16(value.max_component_depth)
end

function Writer.tables.hmtx(self: ttf_writer, value: dict<any>)
	for _, v in value.long_hor_metrics do
		self:writeu16(v.advance_width)
		self:writei16(v.left_side_bearing)
	end

	for _, v in value.left_side_bearings do
		self:writei16(v)
	end
end

Writer.tables['OS/2'] = function(self: ttf_writer, value: dict<any>)
	self:writeu16(value.os_2_version)
	self:writei16(value.x_avg_char_width)
	self:writeu16(value.us_weight_class)
	self:writeu16(value.us_width_class)
	self:writei16(value.fs_type)
	
	self:write_vector2(value.y_subscript_size)
	self:write_vector2(value.y_subscript_offset)
	self:write_vector2(value.y_superscript_size)
	self:write_vector2(value.y_superscript_offset)
	self:writei16(value.y_strikeout_size)
	
	self:writei16(value.y_strikeout_position)
	self:writei16(value.s_family_class)
	
	for i = 1, 10 do
		self:writeu8(value.panose[i])
	end
	
	self:writeu32(value.ul_unicode_range_1)
	self:writeu32(value.ul_unicode_range_2)
	self:writeu32(value.ul_unicode_range_3)
	self:writeu32(value.ul_unicode_range_4)
	
	self:write_string(value.ach_vend_id)
	self:writeu16(value.fs_selector)
	self:writeu16(value.fs_first_char_index)
	self:writeu16(value.fs_last_char_index)
	self:writei16(value.s_typo_ascender)
	
	self:writei16(value.s_typo_descender)
	self:writei16(value.s_typo_line_gap)
	self:writeu16(value.us_win_ascent)
	self:writeu16(value.us_win_descent)
	
	self:writeu32(value.ul_code_page_range_1)
	self:writeu32(value.ul_code_page_range_2)
	self:writei16(value.sx_height)
	self:writei16(value.s_cap_height)
	self:writeu16(value.us_default_char)

	self:writeu16(value.us_break_char)
	self:writeu16(value.us_max_context)
end

function Writer.tables.cmap(self: ttf_writer, value)
	local start = self.offset
	
	self:writeu16(value.cmap_version)
	self:writeu16(value.num_tables)
	
	local offset_to_assign = {}
	
	for i, v in value.encoding_records do
		self:writeu16(v.platform_id)
		self:writeu16(v.encoding_id)
		
		offset_to_assign[i] = self.offset
		self:writeu32(0)
	end
	
	for _, format: Types.cmap_format in value.formats do
		local current_offset = self.offset
		local offset = format.offset
		self:writeu16(format.format_number)
		
		if format.format_number == 0 then
			local format_0: Types.cmap_format_0 = format

			self:writeu16(format_0.length)
			self:writeu16(format_0.language)

			for i = 1, 256 do
				self:writeu8(format_0.glyph_index_array[i])
			end
		elseif format.format_number == 4 then
			local format_4: Types.cmap_format_4 = format

			local seg_count_x2 = format_4.seg_count_x2
			local seg_count = seg_count_x2 / 2
			
			local length_offset = self.offset
			
			self:writeu16(0x00)
			self:writeu16(format_4.language)
			self:writeu16(seg_count_x2)
			self:writeu16(format_4.search_range)
			self:writeu16(format_4.entry_selector)
			self:writeu16(format_4.range_shift)
			
			for i = 1, seg_count do
				self:writeu16(format_4.end_code[i])
			end

			self:writeu16(format_4.reserved)

			for i = 1, seg_count do
				self:writeu16(format_4.start_code[i])
			end

			for i = 1, seg_count do
				self:writei16(format_4.id_delta[i])
			end

			local glyph_array_start_at = self.offset + seg_count * 2
			
			for i = 1, seg_count do
				local id_range_offset_at_i = format_4.id_range_offset[i]
				
				if id_range_offset_at_i ~= 0 then 
					local expected_offset = glyph_array_start_at + #format_4.glyph_index_array * 2
					local id_range_offset_at_offset = self.offset -- equiv to (i-1) * 2 + &id_range_offsets
					
					id_range_offset_at_i = expected_offset - id_range_offset_at_offset
					
					local start_codepoint = format_4.start_code[i]
					local end_codepoint = format_4.end_code[i]
					
					for i = start_codepoint, end_codepoint do
						tinsert(format_4.glyph_index_array, format_4.glyph_index_map[i])
					end
				end
				
				self:writeu16(id_range_offset_at_i)
			end
			
			for _, v in format_4.glyph_index_array do
				self:writeu16(v)
			end
			
			-- added two since length offset is 2 after the format number, length encompasses format number as well
			self:writeu16(self.offset - length_offset + 2, length_offset)
		else
			error_unimplemented()
		end
		
		for i, record: Types.encoding_record in value.encoding_records do
			if record.offset == offset then
				local assigning_offset = offset_to_assign[i]
				self:writeu32(current_offset - start, assigning_offset)
			end
		end
	end
	
	--[[
	-- how formats is decided isn't clear, maybe
	local formats = value.formats
	local used_set = {}
	
	while true do
		-- parse formats by earliest offset
		
		local earliest_format = nil;
		
		for _, v in formats do
			local relative = v.offset - start
			
			if used_set[relative] then continue; end
			
			if not earliest_format or v.offset < earliest_format.offset then
				earliest_format = v
			end
		end
		
		if not earliest_format then break end
		
		-- write formats
		local format_begin = self.offset
		local format_relative = format_begin - start
		
		if format_relative ~= earliest_format.offset - start then
			print(format_relative, earliest_format.offset - start, earliest_format)
			warn('mismatched formats')
			error_incomplete()
		end
		
		self:writeu16(earliest_format.format_number)
		
		if earliest_format.format_number == 0 then
			local format_0: Types.cmap_format_0 = earliest_format
			
			self:writeu16(format_0.length)
			self:writeu16(format_0.language)
			
			for i = 1, 256 do
				self:writeu8(format_0.glyph_index_array[i])
			end
		elseif earliest_format.format_number == 4 then
			local format_4: Types.cmap_format_4 = earliest_format
			
			local seg_count_x2 = format_4.seg_count_x2
			local seg_count = seg_count_x2 / 2
			
			self:writeu16(format_4.length)
			self:writeu16(format_4.language)
			self:writeu16(seg_count_x2)
			self:writeu16(format_4.search_range)
			self:writeu16(format_4.entry_selector)
			self:writeu16(format_4.range_shift)
			
			for i = 1, seg_count do
				self:writeu16(format_4.end_code[i])
			end
			
			self:writeu16(format_4.reserved)
			
			for i = 1, seg_count do
				self:writeu16(format_4.start_code[i])
			end
			
			for i = 1, seg_count do
				self:writei16(format_4.id_delta[i])
			end

			for i = 1, seg_count do
				self:writeu16(format_4.id_range_offset[i])
			end
			
			for i = 2, seg_count do
				if format_4.id_range_offset[i] ~= 0 then
					error_unimplemented()
				end
			end
		else
			error_unimplemented()
		end
		
		-- mark as used and write in memory the encoding records which use format
		used_set[format_relative] = true
		
		for i, v in value.encoding_records do
			if v.offset == format_relative then
				local encoding_record_offset = offset_to_assign[i]
				self:writeu32(format_relative, encoding_record_offset)
			end
		end
	end
--]]
end

function Writer.tables.prep(self: ttf_writer, value)
	for _, v in value.control_value_program do
		self:writeu8(v)
	end
end

Writer.tables['cvt '] = function(self: ttf_writer, value: dict<any>)
	local control_values = value.control_values

	for _, v in control_values do
		self:write_fixed(v)
	end
end

function Writer.tables.loca(self: ttf_writer, value: dict<any>)
	local is_short = self.struct.tables.head.index_to_loc_format ~= 1 

	for _, v in value.offsets do
		if is_short then
			self:writeu16(v / 2)
		else
			self:writeu32(v)
		end
	end
end

function write_coordinate_array(self: ttf_writer, glyf: Types.glyf, is_x: boolean?)
	local flags_simple = Shared.flags.glyf.simple
	local is_short_mask = is_x and flags_simple.x_short or flags_simple.y_short
	local is_same_mask = is_x and flags_simple.x_same or flags_simple.y_same
	local coordinate_array = glyf.simple_data[`{is_x and 'x' or 'y'}_coordinates`]

	assert(glyf.header.number_of_contours >= 0)

	local result = {}
	local current_flags = 1
	local n = last(glyf.simple_data.end_pnts_of_contours) + 1
	local flags = glyf.simple_data.flags
	
	for i, v in flags do
		local is_byte = ftest(v, is_short_mask)
		local is_same = ftest(v, is_same_mask)
		
		local previous = coordinate_array[i - 1] or 0
		local current = coordinate_array[i]
		
		if is_byte then
			local value_1 = current - previous
			
			if not is_same then
				value_1 = -value_1
			end
			
			self:writeu8(value_1)
		elseif not is_same then
			local written_value = current - previous
			self:writei16(written_value)
		end
	end

	return result
end

function Writer.tables.glyf(self: ttf_writer,  value: dict<any>)
	local struct = self.struct
	local meta = struct.table_meta.glyf
	
	local current_offset = 0
	
	for i, v in value.list :: {Types.glyf} do
		local starting_offset = self.offset
		local header = v.header
		
		if v.is_end then
			break
		end
		
		self:writei16(header.number_of_contours)
		self:write_vector2(header.min)
		self:write_vector2(header.max)
		
		if not header.is_simple then
			print(v)
			error_incomplete()
		else
			local simple = v.simple_data
			
			for _, v in simple.end_pnts_of_contours do
				self:writeu16(v)
			end
			
			self:writeu16(simple.instruction_length)
			
			for _, v in simple.instructions do
				self:writeu8(v)
			end
			
			local i = 1
			local glyf_flag_mask = Shared.flags.glyf.simple.repeat_flag
			local glyf_flag_mask_inverse = bnot(glyf_flag_mask)
			
			while simple.flags[i] do
				local flag = simple.flags[i]
				local check_flag
				local length = 0
				
				i += 1
				check_flag = simple.flags[i]
				
				while check_flag == flag do
					i += 1
					length += 1
					check_flag = simple.flags[i]
				end
				
				if length == 0 then
					flag = band(flag, glyf_flag_mask_inverse)
				else
					flag = bor(flag, glyf_flag_mask)
				end
				
				self:writeu8(flag)
				
				if length >= 1 then
					self:writeu8(length)
				end
			end
			
			write_coordinate_array(self, v, true)
			write_coordinate_array(self, v, false)
		end
		
		local length = self.offset - starting_offset
		
		while length % 4 ~= 0 do
			self:writeu8(0)
			length += 1
		end
		
		
	end
	
	while self.offset < meta.offset + meta.length do
		self:writeu8(0)
	end
end

function Writer.tables.name(self: ttf_writer, value: dict<any>)
	assert(value.format == 0)
	local start = self.offset
	
	self:writeu16(value.format)
	self:writeu16(#value.name_records)
	
	local string_bulk_offset_location = self.offset
	
	self:writeu16(0)
	
	local has_default_bulk = not not value.strings --and false
	local bulk = has_default_bulk and value.strings or ''

	for _, v: Types.name_record in value.name_records do
		self:writeu16(v.platform_id)
		self:writeu16(v.platform_specific_id)
		self:writeu16(v.language_id)
		self:writeu16(v.name_id)
		
		if has_default_bulk then
			self:writeu16(v.length)
			self:writeu16(v.offset)
		else
			local value = v.value

			self:writeu16(#value)

			local found = bulk:find(value, nil, true)

			if found then
				self:writeu16(found - 1)
			else
				self:writeu16(#bulk)
				bulk ..= value
			end
		end
	end
	
	local relative = self.offset - start
	
	self:writeu16(relative, string_bulk_offset_location)
	
	self:write_string(bulk)
end

function Writer.tables.post(self: ttf_writer, value: dict<any>)
	assert(value.format == 2)
	self:write_fixed(value.format)
	self:write_fixed(value.italic_angle)
	self:writei16(value.underline_position)
	self:writei16(value.underline_thickness)
	self:writeu32(value.is_fixed_pitch)
	self:writeu32(value.min_mem_type42)
	self:writeu32(value.max_mem_type42)
	self:writeu32(value.min_mem_type1)
	self:writeu32(value.max_mem_type1)
	
	if value.format == 2 then
		local post_format_2: Types.post_format_2 = value.post_format_2
		
		-- subject to rewrite
		self:writeu16(post_format_2.num_glyphs)
		
		for _, v in post_format_2.glyph_name_index do
			self:writeu16(v)
		end
		
		for _, v in post_format_2.string_bulk do
			self:writeu8(#v)
			self:write_string(v)
		end
	end
end

function Writer.tables.gasp(self: ttf_writer, value: dict<any>)
	self:writeu16(value.gasp_version)
	self:writeu16(value.num_ranges)
	
	for _, v: Types.gasp_record in value.gasp_records do
		self:writeu16(v.range_max_ppem)
		self:writeu16(v.range_gasp_behavior)
	end
end

Writer.writeu8 = write_number_call('writeu8', 1)
Writer.writeu16 = write_number_call('writeu16', 2)
Writer.writei16 = write_number_call('writei16', 2)
Writer.writeu32 = write_number_call('writeu32', 4)

Writer.get_partial = Reader.reader.get_partial
Writer.get_checksum = Reader.reader.get_checksum
Writer.reset_checksum = Reader.reader.reset_checksum

Writer.implicit_order = {
	'head', 'hhea', 'maxp', 'OS/2', 'hmtx', 'cmap', 'prep', 'cvt ',
	'loca', 'glyf', 'name', 'post', 'gasp',
}

Class.make_proper_class(Writer, '@CHL>TTF>Writer')

module.writer = Writer

--#####################################################################################
--#####################################################################################
--#####################################################################################

--#####################################################################################
--#####################################################################################
--#####################################################################################

return module
