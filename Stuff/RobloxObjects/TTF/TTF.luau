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
	+----+---------------------+------------------------------------------------------------------------+
	|Tble|Index                |Description                                                             |
	+----+---------------------+------------------------------------------------------------------------+
	|cmap|EncodingRecords      |Multiple records based on platform. Offset denotes a referral to a      |
	|    |                     |format struct, it is possible to have more than two formats, and it is  |
	|    |                     |possible for two encoding records to refer to a format. That being said,|
	|    |                     |After this, check if length has been fully consumed.                    |
	|    |                     |version                                                                 |
	|    |                     |                                                                        |
	|cmap|format               |Based on above, the value for formats is based on a map of offset to    |
	|    |                     |format struct.                                                          |
	|    |                     |                                                                        |
	|    |                     |Furthermore, glyph_index_maps also has an implicit character called     |
	|    |                     |.notdef, which is the default character which has no assigned glyph but |
	|    |                     |needs to be visually displayed. Therefore glyph_index_map[0] implicitly |
	|    |                     | = 0.                                                                   |
	|    |                     |                                                                        |
	|    |                     |Also the glyph_index_map is 0 based, so a specific offset of a          |
	|    |                     |particular character of ascii value i is denoted as                     |
	|    |                     |loca.offsets[glyph_index_map[i] + 1]                                    |
	|    |                     |                                                                        |
	|    |                     |This comment isn't related to the format, but there's some hidden rule  |
	|    |                     |that the implicit glyphs must be sorted by codepoint value. More        |
	|    |                     |evaluated or not depends if I find it.                                  |
	|    |                     |                                                                        |
	|    |format (4),          |The usual case is that if id_range_offset[i] == 0, then id_delta is     |
	|    |  id_range_offsets[i]|used, otherwise, the usual case is that id_range_offset is used to      |
	|    |                     |locate the glyph index, which turns a bit complex. It is defined as     |
	|    |                     |this:                                                                   |
	|    |                     |                                                                        |
	|    |                     |id_range_offsets_start = address where offsets start                    |
	|    |                     |current_range_offset = i * 2, given i = ith segment (0 based)           |
	|    |                     |id_range_offset = id_range_offsets[i]                                   |
	|    |                     |start_code_offset = (c - start_code) * 2, given c = codepoint, from     |
	|    |                     |    c is iterating from [start_codes[i], end_code[i])                   |
	|    |                     |glyph_index_address = id_range_offsets_start + current_range_offset +   |
	|    |                     |    id_range_offset + start_code_offset                                 |
	|    |                     |glyph_index = *glyph_index_address                                      |
	|    |                     |                                                                        |
	|    |                     |glyph_index_address refers to
	|    |                     |
	|    |                     |
	|    |                     |                                                                        |
	|    |                     |                                                                        |
	|loca|offsets              |Though these numbers do indicate the relative offset for table glyf. If |
	|    |                     |data is read as i16s to parse into array elements, then each element is |
	|    |                     |multiplied by 2 to get the actual offset.                               |
	|    |                     |                                                                        |
	|    |                     |The way it's structured, it is an array of num_glyphs + 1 glyphs, in    |
	|    |                     |this case, for any offset of tables.loca.offset[i], and next_offset at  |
	|    |                     |tables.loca.offset[i + 1], offset denotes the offset of the glyph within|
	|    |                     |the file, upon the glyph blob, and next_offset - offset is the length of|
	|    |                     |the blob.                                                               |
	|    |                     |                                                                        |
	|glyf|any                  |Same general case, ususally there's a header, then accompanied by glyph |
	|    |                     |denoted either simple or more complex. Those types offer their own      |
	|    |                     |struct format, but like regular tables, they sometimes have extra zeros |
	|    |                     |because offsets may come in even numbers.                               |
	|    |                     |                                                                        |
	|    |flags (simple)       |This part might be confusing because we assume that flags does refer to |
	|    |                     |a glyf but it actually refers to a point. flags is a byte array of      |
	|    |                     |the same length of the amount of points inside a glyf (or               |
	|    |                     |last(end_pnts_of_contours) + 1). Therefore, each byte is a bitfield for |
	|    |                     |the point at the same index.                                            |
	|    |                     |                                                                        |
	|    |x_coordinates &      |Despite an array, the transformation of raw data to real values is      |
	|    |y_coordinates        |actually a bit more intricate. In order to make an array of coordinate  |
	|    |(simple)             |values, the flags array is the primary determinate for deciding how data|
	|    |                     |is read and transformed.                                                |
	|    |                     |                                                                        |
	|    |                     |However, whatever value determines the next element of the axis         |
	|    |                     |coordinate array is based on the previous element, which is usually     |
	|    |                     |added. Therefore:                                                       |
	|    |                     |                                                                        |
	|    |                     |```                                                                     |
	|    |                     |next_value_in_array = delta + previous_value_in_array                   |
	|    |                     |```                                                                     |
	|    |                     |                                                                        |
	|    |                     |delta is the primary value that is used to determine the next value.    |
	|    |                     |Given specific booleans, is_short as B and is_same as S, from the       |
	|    |                     |respective bitfield using the specific flags based on axis:             |
	|    |                     | +--+-----------------------------------------------------------------+ |
	|    |                     | |BS|Description                                                      | |
	|    |                     | +--+-----------------------------------------------------------------+ |
	|    |                     | |T*|delta is defined as a read byte from the stream, then multipled  | |
	|    |                     | |  |by a sign based on S, which is 1 or -1 if S is 1 or 0            | |
	|    |                     | |  |respectively.                                                    | |
	|    |                     | |FT|Given that this case is specifically referring to Apple's ttf    | |
	|    |                     | |  |documentation, then this case results the next_value_in_array    | |
	|    |                     | |  |being the same as previous. Therefore, delta is 0                | |
	|    |                     | |FF|delta is a read i16 from the stream.                             | |
	|    |                     | +--+-----------------------------------------------------------------+ |
	|    |                     |                                                                        |
	|hhea|advance_width_max    |Within alone characters of a font, it's usually fine to leave it alone  |
	|    |                     |but when it's the case when you attempt to merge characters, then how   |
	|    |                     |this is calculated as such:                                             |
	|    |                     |                                                                        |
	|    |                     |Given L[i] as the ith element of hmtx.long_hor_metrics, then,           |
	|    |                     |advance_width_max = max(L[i].advance_width)                             |
	|    |x_max_extent         |Same situation as above, but it also uses values from table head.       |
	|    |                     |It is defined as (subject to change):                                   |
	|    |                     |                                                                        |
	|    |                     |x_delta = head.max.x - head.min.x                                       |
	|    |                     |x_max_extent = max(0, unpack(hmtx.left_side_bearings)) + x_delta        |
	|    |                     |                                                                        |
	|    |                     |At least, that's how it should be, where I sourced my testing fonts     |
	|    |                     |from, this formula isn't consistent, for now, it is defined as:         |
	|    |                     |                                                                        |
	|    |                     |x_max_extent = L[1].left_side_bearing + x_delta                         |
	|    |                     |                                                                        |
	|OS/2|x_avg_char_width     |Based on the calculation as defined in microsoft's documentation,       |
	|    |                     |It really is a literal average definition over some collection, atm,    |
	|    |                     |I dont really plan on including an implementation of normalizing this in|
	|    |                     |the normalization function. Contact me if there is a structural purpose |
	|    |                     |to this value, but it is noted here in case some implementation is being|
	|    |                     |used without my knowing.                                                |
	|    |                     |                                                                        |
	+----+---------------------+------------------------------------------------------------------------+
	
	Formats:
	 * Same odd format as tables
	   * defined here: https://learn.microsoft.com/en-us/typography/opentype/spec/cmap#format-4-segment-mapping-to-delta-values
]]

--#####################################################################################
--#####################################################################################
--#####################################################################################

local module = {}
local Bit32Ext = require('../@CHL>Bit32Ext')
local Types = require('./@CHL>TTF>Types')
local TTFStruct = require('./@CHL>TTF>Struct')

type ttf_struct = Types.ttf_struct
type glyf = Types.glyf

export type glyph_array = TTFStruct.glyph_array
export type glyph_array_element = TTFStruct.glyph_array_element

--#####################################################################################
--#####################################################################################
--#####################################################################################

--#####################################################################################
--#####################################################################################
--#####################################################################################

--#####################################################################################
--#####################################################################################
--#####################################################################################

module.reader = require('./@CHL>TTF>Reader')
module.writer = require('./@CHL>TTF>Writer')
module.shared = require('./@CHL>TTF>Shared')
module.struct = TTFStruct

--#####################################################################################
--#####################################################################################
--#####################################################################################

return module
