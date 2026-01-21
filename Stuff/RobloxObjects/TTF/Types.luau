local BinaryStream = require('../@CHL>BinaryStream')
local DateTimeAlt = require('../@CHL>DateTime')
local BufferWrapper = require('../@CHL>BufferWrapper')
local Map = require('../@CHL>Map')

type writer = BinaryStream.writer
type reader = BinaryStream.reader
type date_struct = DateTimeAlt.date_struct
type buffer_w = BufferWrapper.object
type map<I, V> = Map.simple<I, V>
type dict<T> = Map.dictionary<T>

export type long_hor_metric = {
	advance_width: number;
	left_side_bearing: number;
}

export type encoding_record = {
	platform_id: number;
	encoding_id: number;
	offset: number;
	
	-- a non file value that refers to the cmap based on format
	cmap_format: cmap_format;
}

export type cmap_format = {
	offset: number;
	format_number: number;
}

export type cmap_format_0 = {
	length: number;
	language: number;
	glyph_index_array: {number};
} & cmap_format

export type cmap_format_4 = {
	length: number;
	language: number;
	seg_count_x2: number;
	search_range: number;
	entry_selector: number;
	range_shift: number;
	end_code: {number};
	reserved: number;
	start_code: {number};
	id_delta: {number};
	id_range_offset: {number};
	id_range_offsets_start: number;
	glyph_index_array: {number};
	
	-- not guaranteed
	glyph_index_array_length: number;
	
	glyph_index_map: map<number, number>;
} & cmap_format

export type glyf_header = {
	number_of_contours: number;
	is_simple: boolean;
	min: Vector2;
	max: Vector2;
}

export type glyf = {
	offset: number;
	length: number;
	is_end: boolean?;
	header: glyf_header;
	simple_data: simple_glyf;
}

export type simple_glyf = {
	end_pnts_of_contours: {number};
	instruction_length: number;
	instructions: {number};
	flags: {number};
	x_coordinates: {number};
	y_coordinates: {number};
}

export type name_record = {
	platform_id: number;
	platform_specific_id: number;
	language_id: number;
	name_id: number;
	length: number;
	offset: number;
	value: string;
}

export type gasp_record = {
	range_max_ppem: number;
	range_gasp_behavior: number;
}

export type index_assign = {
	label: string;
	value_type: string;
	args: {any}?;
}

export type post_format_2 = {
	num_glyphs: number;
	glyph_name_index: {number};
	string_bulk: {string};
}

--[[
	primary struct indicating data of the font
]]
export type ttf_struct = {
	scalar_type: number;
	num_tables: number;
	search_range: number;
	entry_selector: number;
	range_shift: number;
	table_meta: dict<{
		checksum: number;
		offset: number;
		length: number;
	}>;
	tables: {
		head: {
			major_version: number;
			minor_version: number;
			font_revision: number;
			checksum_adjustment: number;
			magic_number: number;
			flags: number;
			units_per_em: number;
			created: date_struct;
			modified: date_struct;
			--[[
			x_min: number;
			y_min: number;
			x_max: number;
			y_max: number;
			]]
			min: Vector2;
			max: Vector2;
			mac_style: number;
			lowest_rec_ppem: number;
			font_direction_hint: number;
			index_to_loc_format: number;
			glyph_data_format: number;
		};
		hhea: {
			hhea_version: number;
			ascent: number;
			descent: number;
			line_gap: number;
			advance_width_max: number;
			min_left_side_bearing: number;
			min_right_side_bearing: number;
			x_max_extent: number;
			caret_slope_rise: number;
			caret_slope_run: number;
			caret_offset: number;
			metric_data_format: number;
			num_of_long_hor_metrics: number;
		};
		maxp: {
			maxp_version: number;
			num_glyphs: number;
			max_points: number;
			max_contours: number;
			max_composite_points: number;

			max_composite_contours: number;
			max_zones: number;
			max_twilight_points: number;
			max_storage: number;
			max_function_defs: number;

			max_instruction_defs: number;
			max_stack_elements: number;
			max_size_of_instructions: number;
			max_component_elements: number;
			max_component_depth: number;
		};
		['OS/2']: {
			os_2_version: number;
			x_avg_char_width: number;
			us_weight_class: number;
			us_width_class: number;
			fs_type: number;
			
			--[[
			y_subscript_x_size: number;
			y_subscript_y_size: number;
			y_subscript_x_offset: number;
			y_subscript_y_offset: number;
			y_superscript_x_size: number;

			y_superscript_y_size: number;
			y_superscript_x_offset: number;
			y_superscript_y_offset: number;
			]]
			y_subscript_size: Vector2;
			y_subscript_offset: Vector2;
			y_superscript_size: Vector2;
			y_superscript_offset: Vector2;
			
			y_strikeout_size: number;
			y_strikeout_position: number;

			s_family_class: number;
			panose: {number};

			ul_unicode_range1: number;
			ul_unicode_range2: number;
			ul_unicode_range3: number;
			ul_unicode_range4: number;

			ach_vend_id: string;
			fs_selection: number;
			fs_first_char_index: number;
			fs_last_char_index: number;
			
			s_typo_ascender: number;
			s_typo_descender: number;
			s_typo_line_gap: number;
			us_win_ascent: number;
			us_win_descent: number;
			
			ul_code_page_range_1: number;
			ul_code_page_range_2: number;
			sx_height: number;
			s_cap_height: number;
			us_default_char: number;
			
			us_break_char: number;
			us_max_context: number;
		};
		hmtx: {
			long_hor_metrics: {long_hor_metric};
			left_side_bearings: {number};
		};
		cmap: {
			cmap_version: number;
			num_tables: number;
			encoding_records: {encoding_record};
			encoding_record_offset: number;
			-- specifically, format_number to format struct
			formats: {cmap_format}
		};
		prep: {
			control_value_program: {number};
		};
		['cvt ']: {
			control_values: {number};
		};
		loca: {
			offsets: {number}
		};
		glyf: {
			list: {glyf};
		};
		name: {
			format: number;
			count: number;
			strings_offset: number;
			name_records: {name_record};
			strings: string;
			-- generally, this above strings does repeat twice in terms of readability but the difference is that the first one consumes 1 byte,
			-- and the second one consumes 2 bytes, in terms of big endian ushorts (wtf?)
			
			-- this is a name_id to string_value map (by reference)
			name_id_to_string: map<number, string>;

			-- this is a name to string_value map (by reference)
			name_to_string: map<string, string>;
		};
		post: {
			format: number;
			italic_angle: number;
			underline_position: number;
			underline_thickness: number;
			is_fixed_pitch: number;
			min_mem_type42: number;
			max_mem_type42: number;
			min_mem_type1: number;
			max_mem_type1: number;
			post_format_2: post_format_2;
		};
		gasp: {
			gasp_version: number;
			num_ranges: number;
			gasp_records: {gasp_record}
		}
	}
}

--[[
	Current info on checksum implementation:
	All bytes read are automatically recorded and must be reset to begin a new checksum check.
	
	currently should accept buffer iterators only because of some values indicating file offsets
	which may point to other tables (ie, cmap format 4 and glyf)
]]
export type ttf_reader = {
	referral: reader;
	struct: ttf_struct;
	checksum_buffer_w: buffer_w;
	checksum_offset: number;

	-- functions responsible for reading checksums
	place_byte: (self: ttf_reader, byte: number)->();
	reset_checksum: (self:ttf_reader)->();
	get_checksum: (self:ttf_reader)->number;
	get_partial: (self: ttf_reader)->number;
	
	-- for basic data types
	read_vector2: (self: ttf_reader)->Vector2;
	read_fixed: (self: ttf_reader)->number;
	read_date: (self: ttf_reader)->date_struct;
	read_buffer: (self: ttf_reader, length: number | (ttf_reader)->number)->buffer;
	
	-- function for reading specific file
	get_buffer: (self: ttf_reader)->buffer;
	
	read_table: (self: ttf_reader, specific_index: string)->();

} & reader

export type ttf_writer = {
	referral: writer;
	consumer: BufferWrapper.to_buffw_consumer;
	struct: ttf_struct;
	
	-- checksums
	checksum_buffer_w: buffer_w;
	checksum_offset: number;
	
	place_byte: (self: ttf_writer, byte: number, is_shallow: boolean)->();
	reset_checksum: (self:ttf_writer)->();
	get_checksum: (self:ttf_writer)->number;
	get_partial: (self: ttf_writer)->number;
	
	add_to_checksum: (self: ttf_writer, value: number)->();
	
	
	-- in addition, also include length checking
	current_length: number;
	reset_length: (self: ttf_writer)->();
	
	-- data types
	write_string: (self: ttf_writer, str: string)->();
	write_fixed: (self: ttf_writer, value: number)->();
	write_table: (self: ttf_writer, index: string, value: dict<any>)->();
	write_date: (self: ttf_writer, value: date_struct)->();
	write_vector2: (self: ttf_writer, value: Vector2)->();
	
	-- super primative date types, if shallow_start_at is provided, then it will not write the length
	writeu8: (self: ttf_writer, value: number, shallow_start_at: number?)->();
	writeu16: (self: ttf_writer, value: number, shallow_start_at: number?)->();
	writei16: (self: ttf_writer, value: number, shallow_start_at: number?)->();
	writeu32: (self: ttf_writer, value: number, shallow_start_at: number?)->();
} & writer

return true
