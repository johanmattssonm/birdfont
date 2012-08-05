/*
    Copyright (C) 2012 Johan Mattsson

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

using Math;

namespace Supplement {

class OpenFontFormatWriter : Object  {

	DataOutputStream os;
	DirectoryTable directory_table;
	
	public OpenFontFormatWriter () {
		directory_table = new DirectoryTable ();
	}
	
	public void open (File file) throws Error {
		if (file.query_exists ()) {
			throw new FileError.EXIST("OpenFontFormatWriter: file exists.");
		}
		
		os = new DataOutputStream(file.create(FileCreateFlags.REPLACE_DESTINATION));
	}
	
	public void write_ttf_font (Font font) throws Error {
		long dl;
		uint8* data;
		uint i = 0;
		long written = 0;
		Glyph? g;
		unowned List<Table> tables;
		unichar indice = 0;
		FontData fd;
		uint l;
			
		directory_table.process ();	
		tables = directory_table.get_tables ();

		dl = directory_table.get_font_file_size ();
		
		if (dl == 0) {
			warning ("font is of zero size.");
			return;
		}
		
		foreach (Table t in tables) {
			fd = t.get_font_data ();
			data = fd.table_data;
			l = fd.length_with_padding ();
			
			for (int j = 0; j < l; j++) {
				os.put_byte (data[j]);
			}
		}
	}
	
	public void close () throws Error {
		os.close ();
	}
}

/** Reader for otf data types. */
class OtfInputStream : Object  {
	
	public FileInputStream fin;
	public DataInputStream din;
	
	public OtfInputStream (FileInputStream i) throws Error {
		din = new DataInputStream (i);
		fin = i;
	}
	
	public void seek (int64 pos) throws Error
		requires (fin.can_seek ()) {
		int64 p = fin.tell ();		
		fin.seek (pos - p, SeekType.CUR);
	}
	
	public Fixed read_fixed () throws Error {
		Fixed f = (Fixed) din.read_uint32 ();
		return f;
	}

	public F2Dot14 read_f2dot14 () throws Error {
		F2Dot14 f = (F2Dot14) din.read_int16 ();
		return f;
	}

	public uint64 read_udate () throws Error {
		return din.read_int64 ();
	}
	
	public int16 read_short () throws Error {
		return din.read_int16 ();
	}
	
	public uint16 read_ushort () throws Error {
		return din.read_uint16 ();
	}
	
	public uint32 read_ulong () throws Error {
		return din.read_uint32 ();
	}

	public uint8 read_byte () throws Error {
		return din.read_byte ();
	}

	public char read_char () throws Error {
		return (char) din.read_byte ();
	}
}

class FontData : Object {

	// Read pointer
	uint rp = 0;

	// Write pointer
	uint wp = 0;
	
	// length without pad
	uint32 len = 0;
	uint32 padding = 0;
	
	uint32 capacity;
	
	public uint8* table_data = null;
	
	public FontData (uint32 size = 1024) {
		capacity = size;
		table_data = malloc (size);
	}
	
	~FontData () {
		if (table_data != null) {
			delete table_data;
			table_data = null;
		}
	}
	
	public void write_at (uint pos, uint8 new_data) 
		requires (pos <= capacity) 
	{
		if (unlikely (pos >= len)) {
			warning ("end of table reached");
		}
		
		table_data[pos]= new_data;
	}
	
	public void write_table (OtfInputStream dis, uint32 offset, uint32 length) throws Error {
		uint32 l = length + (length % 4);  // padding after end of table
		uint8 b;
		
		if (length >= l) {
			expand (l);
		}
		
		if (table_data == null) {
			warning ("Failed to allocate memory for ttf data.");
			return;
		}
		
		seek (0);
		dis.seek (offset);
		
		wp = 0;
		while (wp < l) {
			b = dis.read_byte ();
			add (b);
		}
		
		rp = 0;
	}
	
	public uint length_with_padding () {
		return len;
	}	
	
	public uint length () {
		return len - padding;
	}
	
	public void pad () {
		while (len % 4 != 0) {
			add (0);
			padding++;
		}
	}
	
	/** Add additional checksum data to this checksum. */
	public void continous_check_sum (ref uint32 current_check_sum) {
		uint trp = rp;
		uint l;
		
		if (length_with_padding () % 4 != 0) {
			warning ("Table is not padded to correct size.");
		}
				
		seek (0);

		l = (length () % 4 > 0) ? length () / 4 + 1 : length () / 4; 

		for (uint32 i = 0; i < l; i++) {
			current_check_sum += read_uint32 ();
		}
		
		rp = trp;
	}

	public uint32 check_sum () {
		uint32 sum = 0;
		continous_check_sum (ref sum);
		return sum;
	}
	
	public void seek (uint i) {
		rp = i;
	}
	
	public uint8 read () {
		if (unlikely (rp >= len)) {
			warning ("end of table reached");
			return 0;
		}
		
		return table_data [rp++];
	}
	
	public Fixed read_fixed () {
		return (Fixed) read_uint32 ();
	}

	public uint32 read_ulong () {
		return read_uint32 ();
	}

	public uint32 read_short () {
		uint32 f;
		f = read () << 8;
		f += read ();
		return f;
	}
		
	public uint32 read_uint32 () {
		uint32 f;
		f = read () << 8 * 3;
		f += read () << 8 * 2;
		f += read () << 8 * 1;
		f += read () << 8 * 0;
		return f;
	}
	
	public void add_udate (int64 d) throws Error {
		add_64 (d);
	}
	
	public void add_fixed (Fixed f) throws Error {
		add_u32 (f);
	}

	public void add_fword (int16 word) {
		add_16 (word);
	}

	public void add_f2dot14 (F2Dot14 f) throws Error {
		add_u32 (f);
	}

	public void add_short (int16 d) throws Error {
		add_16 (d);
	}
	
	public void add_ushort (uint16 d) throws Error {
		add_u16 (d);
	}
	
	public void add_ulong (uint32 d) throws Error {
		add_u32 (d);
	}

	public void add_byte (uint8 b) throws Error {
		add (b);
	}
	
	private void expand (uint extra_bytes = 1024) {
		capacity += extra_bytes;
		table_data = (uint8*) try_realloc (table_data, capacity);
		
		if (table_data == null) {
			warning ("Out of memory.");
			capacity = 0;
		}		
	}
	
	public void add (uint8 d) {
		if (unlikely (len == capacity)) {
			expand ();
		}
		
		table_data[wp] = d;
		
		wp++;
		len++;
	}
	
	public void add_u16 (uint16 d) {
		uint16 n = d >> 8;
		add ((uint8)n);
		add ((uint8)(d - (n << 8)));
	}

	public void add_16 (int16 i) {
		uint8 s = (uint8) (i >> 8);
		
		add ((uint8) s);
		add ((uint8) (i - (s << 8)));
	}
	
	public void add_u32 (uint32 i) {
		uint32 s = (uint16) (i >> 16);
		
		add_u16 ((uint16) s);
		add_u16 ((uint16) (i - (s << 16)));
	}

	public void add_32 (int32 i) {
		int32 s = (int16) (i >> 16);
		
		add_16 ((int16) s);
		add_16 ((int16) (i - (s << 16)));
	}
	
	public void add_u64(uint64 i) {
		uint64 s = (uint32) (i >> 32);
		
		add_u32 ((uint32) s);
		add_u32 ((uint32)(i - (s << 32)));		
	}

	public void add_64(int64 i) {
		int64 s = (int32) (i >> 32);
		
		add_u32 ((int32) s);
		add_u32 ((int32)(i - (s << 32)));		
	}
	
	public void add_str_utf16 (string s) {
		int index = 0;
		unichar c;
		uint8 c0;
		uint8 c1;
		int l = 0;
		
		while (s.get_next_char (ref index, out c)) {
			c0 = (uint8) (c >> 8);
			c1 = (uint8) (c - (c0 << 8));
			add (c0);
			add (c1);
			l += 2;
		}
				
		assert (l == 2 * s.char_count ());
	}
	
	public void add_str (string s) {
		uint8[] data = s.data;
		for (int n = 0; n < data.length; n++) { 
			add (data[n]);
		}		
	}
	
	public void add_tag (string s) 
		requires (s.length == 4 && s.data.length == 4) {
		add_str (s);
	}
}

class Coordinate {
	/** TTF coordinate flags. */

	public static const uint8 ON_PATH        = 1 << 0;
	public static const uint8 X_SHORT_VECTOR = 1 << 1;
	public static const uint8 Y_SHORT_VECTOR = 1 << 2;
	public static const uint8 REPEAT         = 1 << 3;

	// same flag or short vector sign flag
	public static const uint8 X_IS_SAME               = 1 << 4; 
	public static const uint8 Y_IS_SAME               = 1 << 5;
	public static const uint8 X_SHORT_VECTOR_POSITIVE = 1 << 4;
	public static const uint8 Y_SHORT_VECTOR_POSITIVE = 1 << 5;

}

class Table : Object {

	public string id = "NO_ID";

	public uint32 checksum = 0;
	public uint32 offset = 0;
	public uint32 length = 0;

	protected FontData? font_data = null;

	public virtual string get_id () {
		return id;
	}
	
	public FontData get_font_data () {
		if (font_data == null) {
			warning (@"No font data for $(id).");
			font_data = new FontData ();
		}
		
		return (!) font_data;
	}

	public virtual void parse (OtfInputStream dis) {
		warning (@"Parse is not implemented for $(id).");
	}

	/** Validate table checksum. */
	public bool validate (OtfInputStream dis) {
		bool valid;
		
		if (length == 0) {
			stderr.printf (@"Table $id is of zero length.\n");			
			valid = false;
		} else {
			valid = Table.validate_table (dis, checksum, offset, length, id);
		}
		
		if (!valid) {
			stderr.printf (@"Table $id is invalid.\n");
		}
		
		return valid;
	}

	public static bool validate_table (OtfInputStream dis, uint32 checksum, uint32 offset, uint32 length, string name) {
		uint32 ch = calculate_checksum (dis, offset, length, name);
		bool c;
		
		c = (ch == checksum);
	
		if (!c) {
			stderr.printf(@"Checksum does not match data for $(name).\n");
			stderr.printf(@"name: $name, checksum: $checksum, offset: $offset, length: $length\n");
			stderr.printf(@"calculated checksum $(ch)\n");
		}
		
		return c;	
	}
	
	public static uint32 calculate_checksum (OtfInputStream dis, uint32 offset, uint32 length, string name) {
		uint32 checksum = 0;
		uint32 l;
			 
		dis.seek (offset);

		l = (length % 4 > 0) ? length / 4 + 1 : length / 4; 

		for (uint32 i = 0; i < l; i++) {
			checksum += dis.read_ulong ();
		}
		
		return checksum;
	}
	
	public static uint16 max_pow_2_less_than_i (uint16 ind) {
		uint16 last = 0;
		uint16 i = 1;
		
		while ((i <<= 1) < ind) {
			last = i;
		}
		
		return last;
	}

	public static uint16 max_log_2_less_than_i (uint16 ind) {
		return (uint16) (Math.log (ind) / Math.log (2));
	}
}

class LocaTable : Table {
	
	uint32* glyph_offsets = null;
	public uint32 size = 0;
	
	public LocaTable () {
		id = "loca";
	}	
	
	~LocaTable () {
		if (glyph_offsets != null) delete glyph_offsets;
	}
	
	public uint32 get_offset (uint32 i) {
		return_if_fail (glyph_offsets != null);
		
		if (size == 0) {
			warning ("No glyphs in loca table");
		}
		
		if (!(0 <= i < size + 1)) {
			warning (@"No offset for glyph $i. Requires (0 <= $i < $(size + 1)");
		}
		
		return glyph_offsets [i];
	}
	
	/** Returns true if glyph at index i is empty and have no body to parse. */
	public bool is_empty (uint32 i) {
		return_if_fail (glyph_offsets != null);

		if (size == 0) {
			warning ("No glyphs in loca table");
		}
				
		if (!(0 <= i < size + 1)) {
			warning (@"No offset for glyph $i. Requires (0 <= $i < $(size + 1)");
		}
		
		return glyph_offsets[i] == glyph_offsets[i + 1];
	}
	
	public void parse (OtfInputStream dis, HeadTable head_table, MaxpTable maxp_table) {
		size = maxp_table.num_glyphs;
		glyph_offsets = new uint32[size + 1];
		
		dis.seek (offset);
		
		printd (@"size: $size\n");
		printd (@"length: $length\n");
		printd (@"length/4-1: $(length / 4 - 1)\n");
		printd (@"length/2-1: $(length / 2 - 1)\n");
		printd (@"head_table.loca_offset_size: $(head_table.loca_offset_size)\n");
		
		switch (head_table.loca_offset_size) {
			case 0:
				for (long i = 0; i < size + 1; i++) {
					glyph_offsets[i] = 2 * dis.read_ushort ();	
					
					if (0 < i < size && glyph_offsets[i - 1] > glyph_offsets[i]) {
						warning (@"Invalid loca table, it must be sorted. ($(glyph_offsets[i - 1]) > $(glyph_offsets[i]))");
						print_offsets ();
					}
				} 
				break;
				
			case 1:
				for (long i = 0; i < size + 1; i++) {
					glyph_offsets[i] = 	dis.read_ulong ();
									
					if (0 < i < size && glyph_offsets[i - 1] > glyph_offsets[i]) {
						warning (@"Invalid loca table, it must be sorted. ($(glyph_offsets[i - 1]) > $(glyph_offsets[i]))");
						print_offsets ();
					}				
				}
				break;
			
			default:
				warning ("unknown size for offset in loca table");
				break;
		}
	}

	public void print_offsets () {
		for (int i = 0; i < size; i++) {
			print (@"get_offset ($i): $(get_offset (i))\n");
		}
	}
	
	public void process (GlyfTable glyf_table, HeadTable head_table) {
		FontData fd = new FontData ();
		Font font = Supplement.get_current_font ();
		uint32 last = 0;
		
		foreach (uint32 o in glyf_table.location_offsets) {
			warn_if_fail (o % 2 == 0);
		}
	
		if (head_table.loca_offset_size == 0) {
			foreach (uint32 o in glyf_table.location_offsets) {
				fd.add_u16 ((uint16) (o / 2));
				
				printd (@"o0: $(o)\n");
				
				if (o < last) {
					warning (@"Loca table must be sorted. ($o < $last)");
				}
				
				last = o;
			}
			
		} else if (head_table.loca_offset_size == 1) {
			foreach (uint32 o in glyf_table.location_offsets) {
				fd.add_u32 (o);
				
				printd (@"o1: $(o)\n");
				
				if (o < last) {
					warning (@"Loca table must be sorted. ($o < $last)");
				}
				
				last = o;
			}
			
		} else {
			warn_if_reached ();
		}
		
		// err maybe not +1
		if (!(glyf_table.location_offsets.length () == glyf_table.glyphs.length () + 1)) {
			warning (@"(glyf_table.location_offsets.length () == glyf_table.glyphs.length () + 1) ($(glyf_table.location_offsets.length ()) == $(glyf_table.glyphs.length () + 1))");
		}
		
		font_data = fd;		
	}
}

class GlyfTable : Table {
	
	// Flags for composite glyph
	static const uint16 BOTH_ARE_WORDS = 1 << 0;
	static const uint16 SCALE = 1 << 3;
	static const uint16 RESERVED = 1 << 4;
	static const uint16 MORE_COMPONENTS = 1 << 5;
	static const uint16 SCALE_X_Y = 1 << 6;
	static const uint16 SCALE_WITH_ROTATTION = 1 << 7;
	static const uint16 INSTRUCTIONS = 1 << 8;

	public int16 xmin = 0;
	public int16 ymin = 0;
	public int16 xmax = 0;
	public int16 ymax = 0;
	
	public LocaTable loca_table;
	
	public List<uint32> location_offsets; 

	// list of glyphs sorted in the order we expect to find them in a
	// ttf font. notdef is the firs glyph followed by null and nonmarkingreturn.
	// after that will all assigned glyphs appear in sorted order, all 
	// remaining unassigned glyphs live in the last part of the file.	
	public List<Glyph> glyphs;
	
	uint16 max_points = 0;
	uint16 max_contours = 0;
	
	public GlyfTable (LocaTable l) {
		id = "glyf";
		loca_table = l;
		location_offsets = new List<uint32> ();
		glyphs = new List<Glyph> ();
	}	

	public uint16 get_max_contours () {
		return max_contours;
	}

	public uint16 get_max_points () {
		return max_points;
	}

	public uint16 get_first_char () {
		foreach (Glyph g in glyphs) {
			if (g.is_unassigned ()) {
				continue;
			}
			
			return (uint16)g.unichar_code;
		}
		
		return 0;
	}
	
	public uint16 get_last_char () {
		unowned List<Glyph> gl = glyphs.last ();
		Glyph g = (!) gl.data;
		
		while (gl != glyphs.first ()) {
			g = (!) gl.data;
			
			if (!g.is_unassigned ()) {
				break;
			}
			
			gl = gl.prev;
		}
		
		return (uint16)g.unichar_code; 
	}
			
	/** Add this glyph from thread safe callback to the running gui. */
	void add_glyph (Glyph g) {
		IdleSource idle = new IdleSource ();

		idle.set_callback (() => {
			Font font = Supplement.get_current_font ();
			font.add_glyph_callback (g);
			return false;
		});

		idle.attach (null);
	}
	
	public void parse (OtfInputStream dis, CmapTable cmap, LocaTable loca, HmtxTable hmtx_table, HeadTable head_table, PostTable post_table) throws GLib.Error {
		uint32 glyph_offset;
		Glyph glyph = new Glyph ("");
		double xmin, xmax;
		double units_per_em = head_table.get_units_per_em ();
		unichar character = 0;
		string name;	

		printd (@"loca.size: $(loca.size)\n");
		// post_table.print_all ();
		
		// notdef character:
		character = cmap.get_char (0);

		if (character != 0) {
			warning ("notdef has a another value in cmap table");
		}
		
		glyph = parse_next_glyf (dis, 0, 0, out xmin, out xmax, units_per_em);
		glyph.left_limit = 0;
		glyph.right_limit = glyph.left_limit + hmtx_table.get_advance (0);
		glyph.name = post_table.get_name (0);
		glyph.set_unassigned (true);		
		add_glyph (glyph);				
		
		if (glyph.name != ".notdef") {
			warning ("First glyph must be .notdef");
		}
		
		for (int i = 1; i < loca.size; i++) {
			try {
				character = cmap.get_char (i);
				name = post_table.get_name (i);
				
				if (name == "") {
					StringBuilder name_c = new StringBuilder ();
					name_c.append_unichar (character);
					name = name_c.str;
				}

				printd (@"name: $(name)\n");
				
				if (!loca.is_empty (i)) {	
					glyph_offset = loca.get_offset(i);
					
					glyph = parse_next_glyf (dis, character, glyph_offset, out xmin, out xmax, units_per_em);
					
					glyph.left_limit = xmin - hmtx_table.get_lsb (i);
					glyph.left_limit = 0;
					glyph.right_limit = glyph.left_limit + hmtx_table.get_advance (i);
					
					printd (@"$(glyph.right_limit) = $(glyph.left_limit) + $(hmtx_table.get_advance (i))\n");
					
					if (xmin > glyph.right_limit || xmax < glyph.left_limit) {
						warning (@"Glyph $(name) is outside of it's box.");
						glyph.left_limit = xmin;
						glyph.right_limit = xmax;
					}
					
				} else {
					// add empty glyph
					glyph = new Glyph (name, character);
					glyph.left_limit = -hmtx_table.get_lsb (i);
					glyph.right_limit = hmtx_table.get_advance (i) - hmtx_table.get_lsb (i);				
				}
				
				glyph.name = name;

				if (character == 0) {
					glyph.set_unassigned (true);
				}
				
				if (character == 0 && name != "") {
					stderr.printf (@"gid: $i\n");
					stderr.printf (@"char: $((uint) character)\n");
					stderr.printf (@"name: $(name)\n");
				}
								
				add_glyph (glyph);
				
			} catch (Error e) {
				stderr.printf (@"Cmap length $(cmap.get_length ()) glyfs\n");
				stderr.printf (@"Loca size: $(loca.size)\n");
				stderr.printf (@"Loca offset at $i: $glyph_offset\n");
				stderr.printf (@"Glyph name: $(name)\n");
				stderr.printf (@"Unicode character: $((uint64)character)\n");
				stderr.printf (@"\n");
				stderr.printf (@"Falied to parse glyf: $(e.message)\n");
				
				break;
			}
		}
	}
	
	Glyph parse_next_composite_glyf (OtfInputStream dis, unichar character) throws Error {
		uint16 component_flags = 0;
		uint16 glyph_index;
		int16 arg1;
		int16 arg2;
		uint16 arg1and2;
		F2Dot14 scale;
		
		F2Dot14 scalex;
		F2Dot14 scaley;
		
		F2Dot14 scale01;
		F2Dot14 scale10;
		
		uint16 num_instructions;
		
		Glyph glyph;
		StringBuilder name = new StringBuilder ();
		name.append_unichar (character);

		do {
			component_flags = dis.read_ushort ();
			glyph_index = dis.read_ushort ();

			if ((component_flags & BOTH_ARE_WORDS) > 0) {
				arg1 = dis.read_short ();
				arg1 = dis.read_short ();			
			} else {
				arg1and2 = dis.read_ushort ();
			}
			
			// if ((component_flags & RESERVED) > 0)
			
			if ((component_flags & SCALE) > 0) {
				scale = dis.read_f2dot14 ();
			}

			if ((component_flags & SCALE_X_Y) > 0) {
				scalex = dis.read_f2dot14 ();
				scaley = dis.read_f2dot14 ();
			}

			if ((component_flags & SCALE_WITH_ROTATTION) > 0) {
				scalex = dis.read_f2dot14 ();
				scale01 = dis.read_f2dot14 ();
				scale10 = dis.read_f2dot14 ();
				scaley = dis.read_f2dot14 ();
			}
			
		} while ((component_flags & MORE_COMPONENTS) > 0);
		
		if ((component_flags & INSTRUCTIONS) > 0) {
			num_instructions = dis.read_ushort ();
			
			for (int i = 0; i < num_instructions; i++) {
				dis.read_byte ();
			}
		}

		glyph = new Glyph (name.str, character);
		
		return glyph;
	}
	
	Glyph parse_next_glyf (OtfInputStream dis, unichar character, uint32 glyph_offset,
		out double xmin, out double xmax, double units_per_em) throws Error {

		uint16* end_points = null;
		uint8* instructions = null;
		uint8* flags = null;
		int16* xcoordinates = null;
		int16* ycoordinates = null;
		
		int npoints = 0;
		
		int16 ncontours;
		int16 ixmin;
		int16 iymin;
		int16 ixmax;
		int16 iymax;
		uint16 ninstructions;
		
		int nflags;
		
		Error? error = null;
		
		StringBuilder name = new StringBuilder ();
		name.append_unichar (character);

		dis.seek (offset + glyph_offset);
		
		ncontours = dis.read_short ();
		
		if (ncontours == 0) {
			warning (@"Got zero contours in glyph $(name.str).");

			// should skip body
		}
				
		if (ncontours == -1) {
			return parse_next_composite_glyf (dis, character);
		}
				
		if (ncontours < -1) {
			warning (@"Got $ncontours contours in glyf table.");
			error = new BadFormat.PARSE ("Invalid glyf");
			throw error;
		}
		
		ixmin = dis.read_short ();
		iymin = dis.read_short ();
		ixmax = dis.read_short ();
		iymax = dis.read_short ();

		end_points = new uint16[ncontours + 1];
		for (int i = 0; i < ncontours; i++) {
			end_points[i] = dis.read_ushort (); // FIXA: mind shot vector is negative
			
			if (i > 0 && end_points[i] < end_points[i -1]) {
				warning (@"Next endpoint has bad value in $(name.str). (end_points[i] > end_points[i -1])  ($(end_points[i]) > $(end_points[i -1])) i: $i ncontours: $ncontours");
			}
		}
		
		if (ncontours > 0) {
			npoints = end_points[ncontours - 1] + 1;
		} else {
			npoints = 0;
		}
		
		// FIXA: implement instructions (maybe)
		ninstructions = dis.read_ushort ();		
		instructions = new uint8[ninstructions + 1];
		uint8 repeat;
		for (int i = 0; i < ninstructions; i++) {
			instructions[i] = dis.read_byte ();
		}

		nflags = 0;
		flags = new uint8[npoints + 1];
		for (int i = 0; i < npoints; i++) {
			flags[i] = dis.read_byte ();
			
			if ((flags[i] & Coordinate.REPEAT) > 0) {
				repeat = dis.read_byte ();
				
				if (i + repeat >= npoints) {
					error = new BadFormat.PARSE ("Too many flags in glyf in glyph $(name.str). (i >= ninstructions).");
					break;
				}
				
				for (int j = 0; j < repeat; j++) {
					flags[j + i + 1] = flags[i];
				}
				
				nflags += repeat;
				i += repeat;
			}
			
			nflags++;
		}
		
		if (nflags != npoints) {
			warning (@"(nflags != npoints) ($nflags != $npoints) in $(name.str)");
			error = new BadFormat.PARSE (@"Wrong number of flags in glyph $(name.str). (nflags != npoints) ($nflags != $npoints)");
		}
		
		warn_if_fail (nflags == npoints);

		printd (@"npoints: $npoints\n");
		printd (@"ncontours: $ncontours\n");
		printd (@"ninstructions: $ninstructions\n");
		printd (@"nflags: $nflags\n");
				
		int16 last = 0;
		xcoordinates = new int16[npoints + 1];
		for (int i = 0; i < npoints; i++) {
			if ((flags[i] & Coordinate.X_SHORT_VECTOR) > 0) {	
				if ((flags[i] & Coordinate.X_SHORT_VECTOR_POSITIVE) > 0) {
					xcoordinates[i] = last + dis.read_byte ();
				} else {
					xcoordinates[i] = last - dis.read_byte ();
				}
			} else {
				if ((flags[i] & Coordinate.X_IS_SAME) > 0) {
					xcoordinates[i] = last;
				} else {
					xcoordinates[i] = last + dis.read_short ();
				}
			}
			
			last = xcoordinates[i];
			
			if (!(ixmin <= last <= ixmax))	{
				stderr.printf (@"x is out of bounds in glyph $(name.str). ($ixmin <= $last <= $ixmax)\n");
			}
		}
		
		last = 0;
		ycoordinates = new int16[npoints + 1];
		for (int i = 0; i < npoints; i++) {
			if ((flags[i] & Coordinate.Y_SHORT_VECTOR) > 0) {	
				if ((flags[i] & Coordinate.Y_SHORT_VECTOR_POSITIVE) > 0) {
					ycoordinates[i] = last + dis.read_byte ();
				} else {
					ycoordinates[i] = last - dis.read_byte ();
				}
			} else {
				if ((flags[i] & Coordinate.Y_IS_SAME) > 0) {
					ycoordinates[i] = last;
				} else {
					ycoordinates[i] = last + dis.read_short ();
				}
			}
			
			last = ycoordinates[i];
			
			if (!(iymin <= last <= iymax))	{
				stderr.printf (@"y is out of bounds in glyph $(name.str). ($iymin <= $last <= $iymax)\n");
			}
		}
		
		int j = 0;
		int first_point;
		int last_point = 0;
		Glyph glyph;
		double startx, starty;
		double x, y, rx, ry, lx, ly, nx, ny;

		glyph = new Glyph (name.str, character);
		
		xmin = ixmin * 1000.0 / units_per_em;
		xmax = ixmax * 1000.0 / units_per_em;
		
		for (int i = 0; i < ncontours; i++) {
			x = 0;
			y = 0;
			
			Path path = new Path ();
			EditPoint edit_point = new EditPoint ();
			bool prev_is_curve = false;
			
			first_point = j;
			last_point = end_points[i];
			for (; j <= end_points[i]; j++) {

				if (j >= npoints) {
					warning (@"j >= npoints in glyph $(name.str). (j: $j, end_points[i]: $(end_points[i]), npoints: $npoints)");
					break;
				}
								
				x = xcoordinates[j] * 1000.0 / units_per_em; // in proportion to em width
				y = ycoordinates[j] * 1000.0 / units_per_em;
				
				if ((flags[j] & Coordinate.ON_PATH) > 0) {
					// Point
					edit_point = new EditPoint ();
					edit_point.set_position (x, y);
					path.add_point (edit_point);
					
					if (prev_is_curve) {
						edit_point.get_left_handle ().set_point_type (PointType.CURVE);
						edit_point.get_left_handle ().length = 0;						
					} else {
						edit_point.recalculate_linear_handles ();
					}
									
					prev_is_curve = false;
				} else {
									
					if (prev_is_curve) {
						x = x - (x - edit_point.right_handle.x ()) / 2;
						y = y - (y - edit_point.right_handle.y ()) / 2;

						edit_point = new EditPoint ();
						edit_point.set_position (x, y);
						path.add_point (edit_point);
					}

					x = xcoordinates[j] * 1000.0 / units_per_em; // in proportion to em width
					y = ycoordinates[j] * 1000.0 / units_per_em;

					edit_point.get_left_handle ().set_point_type (PointType.CURVE);
					edit_point.get_left_handle ().length = 0;
						
					edit_point.type = PointType.CURVE;
					edit_point.get_right_handle ().set_point_type (PointType.CURVE);
					edit_point.get_right_handle ().move_to_coordinate (x, y);
					
					prev_is_curve = true;
				} 
			}
			
			// last to first point
			if (prev_is_curve) {
				x = xcoordinates[first_point] * 1000.0 / units_per_em; // in proportion to em width
				y = ycoordinates[first_point] * 1000.0 / units_per_em;
				
				x = x - (x - edit_point.right_handle.x ()) / 2;
				y = y - (y - edit_point.right_handle.y ()) / 2;
				
				edit_point = new EditPoint ();
				edit_point.set_position (x, y);
				path.add_point (edit_point);
				
				x = xcoordinates[first_point] * 1000.0 / units_per_em; // in proportion to em width
				y = ycoordinates[first_point] * 1000.0 / units_per_em;

				edit_point.get_left_handle ().set_point_type (PointType.CURVE);
				edit_point.get_left_handle ().length = 0;
					
				edit_point.type = PointType.CURVE;
				edit_point.get_right_handle ().set_point_type (PointType.CURVE);
				edit_point.get_right_handle ().move_to_coordinate (x, y);
			}
			
			// curve last to first
			x = xcoordinates[first_point] * 1000.0 / units_per_em; // in proportion to em width
			y = ycoordinates[first_point] * 1000.0 / units_per_em;
			edit_point.type = PointType.CURVE;
			edit_point.get_right_handle ().set_point_type (PointType.CURVE);
			edit_point.get_right_handle ().move_to_coordinate (x, y);
			
			path.close ();
			
			glyph.add_path (path);
		}
		
		// glyphs with no bounding boxes
		if (ixmax <= ixmin) {
			warning (@"Bounding box is bad. (xmax == xmin) ($xmax == $xmin)");
			
			if (glyph.path_list.length () > 0) {
				
				Path ps = ((!) glyph.path_list.first ()).data;
				
				ps.update_region_boundries ();
				xmin = ps.xmin;
				xmax = ps.xmax;

				foreach (Path p in glyph.path_list) {
					p.update_region_boundries ();
					
					if (p.xmin < xmin) {
						xmin = p.xmin;
					}
					
					if (p.xmax > xmax) {
						xmax = p.xmax;
					}
				}
				
			}
		}
						
		if (end_points != null) delete end_points;
		if (instructions != null) delete instructions;
		if (flags != null) delete flags;
		if (xcoordinates != null) delete xcoordinates;
		if (ycoordinates != null) delete ycoordinates;
		
		if (error != null) {
			warning ("failed to parse glyph");
			throw (!) error;
		}
		
		return glyph;
	}

	public void process_glyph (Glyph g, FontData fd) {
		double gxmin, gymin, gxmax, gymax;

		int16 end_point;
		int16 last_end_point;
		int16 npoints;
		int16 ncontours;
		int16 nflags;
		
		int16 x, y;

		Font font = Supplement.get_current_font ();
		
		g.remove_empty_paths ();
		if (g.path_list.length () == 0) {
			// ensure that location_offsets == location_offset + 1
			return;
		}
		
		g.remove_empty_paths ();
		
		ncontours = (int16) g.path_list.length ();
		fd.add_short (ncontours);
		
		g.boundries (out gxmin, out gymin, out gxmax, out gymax);
		
		// remove:
		xmin = (int16) (gxmin - g.left_limit);
		ymin = (int16) (gymin + font.base_line);
		xmax = (int16) (gxmax - g.left_limit);
		ymax = (int16) (gymax + font.base_line);
		
		fd.add_16 (xmin);
		fd.add_16 (ymin);
		fd.add_16 (xmax);
		fd.add_16 (ymax);
		
		// save this for head table
		if (this.xmin > xmin) this.xmin = xmin;
		if (this.ymin > ymin) this.ymin = ymin;
		if (this.xmax > xmax) this.xmax = xmax;
		if (this.ymax > ymax) this.ymax = ymax;
		
		// end points
		end_point = 0;
		last_end_point = 0;
		foreach (Path p in g.path_list) {
			foreach (EditPoint e in p.points) {
				end_point++;
			}
			fd.add_u16 (end_point - 1);
			
			if (end_point - 1 < last_end_point) {
				warning (@"Next endpoint has bad value. (end_point - 1 < last_end_point)  ($(end_point - 1) < $last_end_point");
			}
			
			last_end_point = end_point - 1;
		}
		
		fd.add_u16 (0); // instruction length 
		
		// instructions should go here 
		
		npoints = (ncontours > 0) ? end_point : 0; // +1?
		
		if (npoints > max_points) {
			max_points = npoints;
		}
		
		if (ncontours > max_contours) {
			max_contours = ncontours;
		}
		
		// flags
		nflags = 0;
		foreach (Path p in g.path_list) {
			foreach (EditPoint e in p.points) {
				fd.add_byte (Coordinate.ON_PATH);
				nflags++;
			}
		}
		
		if (nflags != npoints) {
			warning (@"(nflags != npoints)  ($nflags != $npoints) in glyph $(g.name). ncontours: $ncontours");
		}
		assert (nflags == npoints);
		
		// x coordinates
		double prev = 0;
		foreach (Path p in g.path_list) {
			foreach (EditPoint e in p.points) {
				x = (int16) (e.x - prev - g.left_limit);
				fd.add_16 (x);
				prev = e.x - g.left_limit;
			}
		}

		// x coordinates
		prev = 0;
		foreach (Path p in g.path_list) {
			foreach (EditPoint e in p.points) {
				y = (int16) (e.y - prev + font.base_line);
				fd.add_16 (y);
				prev = e.y + font.base_line;
			}
		}
		
		// glyph need padding too for loca table to be correct
		if (fd.length () % 4 != 0) {
			fd.add (0);
		}
	}

	// necessary in order to have glyphs sorted according to ttf specification
	public void create_glyph_table () {
		Glyph? gl;
		Glyph g;
		Font font = Supplement.get_current_font ();
		uint32 indice;

		// add notdef. character at index zero + other special chars first
		glyphs.append (font.get_not_def_character ());
		// glyphs.append (font.get_null_character ());
		// glyphs.append (font.get_nonmarking_return ());
			
		// add glyphs, first all assigned then the unassigned ones
		for (indice = 0; (gl = font.get_glyph_indice (indice)) != null; indice++) {		
			g = (!) gl;
			
			if (g.name == "notdef" || g.name == "null"  || g.name == "nonmarkingreturn") {
				continue;
			}
			
			glyphs.append (g);
		}	
		
	}

	public void process () {
		FontData fd = new FontData ();
		
		create_glyph_table ();
		
		foreach (Glyph g in glyphs) {
			// set values for loca table
			location_offsets.append (fd.length ());
			
			process_glyph (g, fd);
		}

		location_offsets.append (fd.length ()); // last entry in loca table is special
		
		fd.pad ();
						
		font_data = fd;	
	}
}

class CmapSubtable : Table {

	// Override these methods in subtables for each format.
	
	/** Obtain length of subtable in bytes. */
	public virtual uint get_length () {
		warning ("Invalid CmapSubtable");
		return 0;
	}
	
	/** Get char code for a glyph id. */
	public virtual unichar get_char (uint32 i) {
		warning ("Invalid CmapSubtable");
		return 0;
	}
	
	public void print_cmap () {
		StringBuilder s;
		unichar c;
		for (uint32 i = 0; i < get_length (); i++) {
			s = new StringBuilder ();
			c = get_char (i);
			s.append_unichar (c);
			print (@"Char: $(s.str)  val ($((uint32)c))\tindice: $(i)\n");
		}
	}
}

/** Format 4 cmap subtable */
class CmapSubtableWindowsUnicode : CmapSubtable {
	uint16 format = 0;
	HashTable <uint64?, unichar> table = new HashTable <uint64?, unichar> (int64_hash, int_equal);
	
	public CmapSubtableWindowsUnicode () {
	}
	
	~CmapSubtableWindowsUnicode () {

	}

	public override uint get_length () {
		return table.size ();
	}
	
	public override unichar get_char (uint32 indice) {
		int64? c = table.lookup (indice);
		
		if (c == 0 && indice == 0) {
			return 0;
		}
		
		if (c == 0) {
			while (table.lookup (--indice) == 0) {
				if (indice == 0) {
					return 0;
				}
			} 
			
			warning (@"There is no char for glyph number $indice in cmap table. table.size: $(table.size ()))");
			return 0;
		}
		
		return (unichar) c;
	}
	
	public override void parse (OtfInputStream dis) {
		dis.seek (offset);
		
		format = dis.read_ushort ();
		
		switch (format) {
			case 4:
				parse_format4 (dis);
				break;
			
			default:
				stderr.printf (@"CmapSubtable is in format $format, it is not supportet (yet).\n");
				break;
		}
	}
		
	public void parse_format4 (OtfInputStream dis) {
		uint16 lang;
		uint16 seg_count_x2;
		uint16 seg_count;
		uint16 search_range;
		uint16 entry_selector;
		uint16 range_shift;

		uint16* end_char = null;
		uint16* start_char = null;
		int16* id_delta = null;
		uint16* id_range_offset = null;
		uint16* glyph_id_array = null;
	
		uint32 gid_len;
		
		length = dis.read_ushort ();
		lang = dis.read_ushort ();
		seg_count_x2 = dis.read_ushort ();
		search_range = dis.read_ushort ();
		entry_selector = dis.read_ushort ();
		range_shift = dis.read_ushort ();
		
		return_if_fail (seg_count_x2 % 2 == 0);

		seg_count = seg_count_x2 / 2;
		
		printd (@"seg_count: $seg_count\n");
		
		end_char = new uint16[seg_count];
		for (int i = 0; i < seg_count; i++) {
			end_char[i] = dis.read_ushort ();
		}
		
		if (end_char[seg_count - 1] != 0xFFFF) {
			warning ("end_char is $(end_char[seg_count - 1]), expecting 0xFFFF.");
		}
		
		dis.read_ushort (); // Reserved
		
		start_char = new uint16[seg_count];
		for (int i = 0; i < seg_count; i++) {
			start_char[i] = dis.read_ushort ();
		}

		id_delta = new int16[seg_count];
		for (int i = 0; i < seg_count; i++) {
			id_delta[i] = dis.read_short ();
		}

		id_range_offset = new uint16[seg_count];
		for (int i = 0; i < seg_count; i++) {
			id_range_offset[i] = dis.read_ushort ();
		}

		if (length == 0) {
			warning ("cmap subtable version 4 has length 0.");
			return;
		}

		gid_len = (length - 16 - 8 * seg_count) / 2;
		printd (@"length: $length\n");
		printd (@"gid_len: $gid_len\n");
		glyph_id_array = new uint16[gid_len];
		for (int i = 0; i < gid_len; i++) {
			glyph_id_array[i] = dis.read_ushort ();
		}
		
		// map all values in a hashtable
		int indice = 0;
		unichar character = 0;
		uint32 id;
		for (uint16 i = 0; i < seg_count && start_char[i] != 0xFFFF; i++) {
			
			// print_range (start_char[i], end_char[i], id_delta[i], id_range_offset[i]);
			
			uint16 j = 0;
			do {
				character = start_char[i] + j;
				indice = start_char[i] + id_delta[i] + j;
				
				if (id_range_offset[i] == 0) {
					table.insert (indice, character);
				} else {
					// the awkward indexing trick:
					id = id_range_offset[i] / 2 + j + i - seg_count;
					
					if (!(0 <= id < gid_len)) {
						warning (@"(0 <= id < gid_len) (0 <= $id < $gid_len)");
						break;
					}
					
					indice = glyph_id_array [id] + id_delta[i];
										
					StringBuilder s = new StringBuilder ();
					s.append_unichar (character);
										
					table.insert (indice, character);
				}
				
				j++;
			} while (character != end_char[i]);
	
		}
		
		if (end_char != null) delete end_char;
		if (start_char != null) delete start_char;
		if (id_delta != null) delete id_delta;
		if (id_range_offset != null) delete id_range_offset;
		if (glyph_id_array != null) delete glyph_id_array;
		
		// it has a character for every glyph indice
		// assert (validate_subtable ());
	}
	
	void print_range (unichar start_char, unichar end_char, uint16 delta_offset, uint16 range_offset) {
		StringBuilder s = new StringBuilder ();
		StringBuilder e = new StringBuilder ();
		
		s.append_unichar (start_char);
		e.append_unichar (end_char);
		
		// print (@"New range $(s.str) - $(e.str) delta: $delta_offset, range: $range_offset\n");
	}
	
	public void process (FontData fd, GlyfTable glyf_table) {
		GlyphRange glyph_range = new GlyphRange ();
		unowned List<UniRange> ranges;
			
		unichar i = 0;
		Glyph? gl;
		
		uint16 seg_count_2;
		uint16 seg_count;
		uint16 search_range;
		uint16 entry_selector;
		uint16 range_shift;				
		
		uint16 gid_length = 0;
		
		uint32 indice;
		uint32 first_assigned = 0;

		foreach (Glyph g in glyf_table.glyphs) {
			if (!g.is_unassigned ()) {
				first_assigned++;
			} else {
				break;
			}
		}
		printd (@"first_assigned $first_assigned\n");
		first_assigned = 1;
		foreach (Glyph g in glyf_table.glyphs) {
			if (!g.is_unassigned ()) {
				glyph_range.add_single (g.unichar_code);
			}
		}
		
		// glyph_range.print_all ();
		
		ranges = glyph_range.get_ranges ();
		seg_count = (uint16) ranges.length () + 1;
		seg_count_2 =  seg_count * 2;
		search_range = 2 * ((uint16) Math.pow (2, (Math.log (seg_count) / Math.log (2))));
		entry_selector = (uint16) (Math.log (search_range / 2) / Math.log (2));
		range_shift = seg_count_2 - search_range;
		
		// format
		fd.add_ushort (4);
		
		// length of subtable
		fd.add_ushort (16 + 8 * seg_count + gid_length);
		
		// language
		fd.add_ushort (0);
		
		fd.add_ushort (seg_count_2);
		fd.add_ushort (search_range);
		fd.add_ushort (entry_selector);
		fd.add_ushort (range_shift);
		
		// end codes
		indice = first_assigned;
		foreach (UniRange u in ranges) {
			if (u.stop >= 0xFFFF) {
				warning ("Not implemented yet.");
			}
			
			fd.add_ushort ((uint16) u.stop);
			indice += u.length ();
		}
		fd.add_ushort (0xFFFF);
		
		fd.add_ushort (0); // Reserved
		
		// start codes
		indice = first_assigned; // since first glyph are notdef, null and nonmarkingreturn
		foreach (UniRange u in ranges) {
			if (u.start >= 0xFFFF) {
				warning ("Not implemented yet.");
			}
			
			fd.add_ushort ((uint16) u.start);
			indice += u.length ();
		}
		fd.add_ushort (0xFFFF);

		// delta
		indice = first_assigned;
		foreach (UniRange u in ranges) {
			
			if ((u.start - indice) > 0xFFFF && u.start > indice) {
				warning ("Need range offset.");
			}
			
			fd.add_ushort ((uint16) (indice - u.start));
			indice += u.length ();
		}
		fd.add_ushort (0xFFFF);
		
		// range offset
		foreach (UniRange u in ranges) {
			if (u.stop <= 0xFFFF) {
				fd.add_ushort (0);
			} else {
				warning ("Not implemented yet.");
			}
		}
		fd.add_ushort (0);
		
		// Fixa: implement rest of type 4 (mind gid_length in length field)
	}
	
	public bool validate_subtable () {
		uint32 length = get_length ();
		unichar c;
		unichar prev;
		uint32 i = 0;
		uint32 err = 0;
		StringBuilder s;
		
		c = get_char (i);
		if (c != 0) {
			s = new StringBuilder ();
			s.append_unichar (c);
			warning ("nodef. is mapped to $(s.str)");
		}
		
		i++;
		
		while (i < length) {
			if (c == 0) {
				s = new StringBuilder ();
				s.append_unichar (c);
				warning (@"No entry in cmap for index $i. Last avalable char is $(s.str) Got $(s.str), ($((uint32)c))");
				err++;
				return false;
			} else {
				prev = c;
			}
			
			c = get_char (i);
			i++;
		}
		
		if (err > 0) {
			stderr.printf (@"$err glyphs without mapping to a charactercode were found in this font.\n");
		}
		
		return true;
	}
}

class CmapTable : Table { 
	
	GlyfTable glyf_table;	
	List<CmapSubtable> subtables;

	public CmapTable(GlyfTable gt) {
		glyf_table = gt;
		subtables = new List<CmapSubtable> ();
		id = "cmap";
	}
	
	public uint32 get_length () {
		return get_prefered_table ().get_length ();
	}
	
	public unichar get_char (uint32 i) {
		return get_prefered_table ().get_char (i) ;
	}
	
	CmapSubtable get_prefered_table () {
		if (subtables.length () == 0) {
			warning ("No cmap table has been parsed.");
			return new CmapSubtable ();
		}
		
		return subtables.first ().data;
	}
	
	public override string get_id () {
		return "cmap";
	}
	
	public override void parse (OtfInputStream dis) 
		requires (offset > 0 && length > 0) {
			
		uint16 version;
		uint16 nsubtables;
		
		uint16 platform;
		uint16 encoding;
		uint32 sub_offset;
		
		CmapSubtable subtable;
		
		dis.seek (offset);
		
		version = dis.read_ushort ();
		nsubtables = dis.read_ushort ();

		printd (@"cmap version: $version\n");
		printd (@"cmap subtables: $nsubtables\n");
				
		if (version != 0) {
			warning (@"Bad version for cmap table: $version expecting 0. Number of subtables: $nsubtables");
			return;
		}
		
		for (uint i = 0; i < nsubtables; i++) {
			platform = dis.read_ushort ();
			encoding = dis.read_ushort ();
			sub_offset = dis.read_ulong ();	
			
			if (platform == 3 && encoding == 1) {
				printd (@"Parsing Unicode BMP (UCS-2) Platform: $platform Encoding: $encoding\n");
				subtable = new CmapSubtableWindowsUnicode ();
				subtable.offset = offset + sub_offset;
				subtables.append (subtable);
			} else {
				stderr.printf (@"Unknown encoding. Platform: $platform Encoding: $encoding.\n");
			}	
		}
		
		if (subtables.length () == 0) {
			warning ("No suitable cmap subtable found.");
		}
		
		foreach (CmapSubtable t in subtables) {
			t.parse (dis);
			// t.print_cmap ();
		}

	}
	
	/** Character to glyph mapping */
	public void process (GlyfTable glyf_table) {
		FontData fd = new FontData ();
		CmapSubtableWindowsUnicode cmap = new CmapSubtableWindowsUnicode ();
		uint16 n_encoding_tables;
		uint32 subtable_offset = 0;

		uint16 glyph_indice = 0;
			
		n_encoding_tables = 1;
		
		fd.add_u16 (0); // table version
		fd.add_u16 (n_encoding_tables);
		
		fd.add_u16 (3); // platform 
		fd.add_u16 (1); // encoding (Format Unicode UCS-4)

		subtable_offset = fd.length () + 4;
		printd (@"subtable_offset: $(subtable_offset)\n");
		
		fd.add_ulong (subtable_offset);
		cmap.process (fd, glyf_table);

		// padding
		fd.pad ();

		this.font_data = fd;
	}
}

class HeadTable : Table {

	int16 xmin = 0;
	int16 ymin = 0;
	int16 xmax = 0;
	int16 ymax = 0;
	
	uint32 adjusted_checksum = 0;

	uint16 mac_style;
	uint16 lowest_PPEM;
	int16 font_direction_hint;
		
	public int16 loca_offset_size = 1;
	int16 glyph_data_format;

	Fixed version;
	Fixed font_revision;
	
	uint32 magic_number;
	
	uint16 flags;
	
	uint64 created;
	uint64 modified;
		
	uint16 units_per_em = 100;
	
	const uint8 BASELINE_AT_ZERO = 1 << 0;
	const uint8 LSB_AT_ZERO = 1 << 1;
	
	GlyfTable glyf_table;
	
	public HeadTable (GlyfTable gt) {
		glyf_table = gt;
		id = "head";
	}
	
	public double get_units_per_em () {
		return units_per_em * 10; // Fixa: we can refactor this number
	}
	
	public override void parse (OtfInputStream dis) 
		requires (offset > 0 && length > 0) {

		dis.seek (offset);
	
		version = dis.read_fixed ();

		if (!version.equals (1, 0)) {
			warning (@"Expecting head version 1.0 got $(version.get_string ())\n");
		}
		
		font_revision = dis.read_fixed ();
		adjusted_checksum = dis.read_ulong ();
		magic_number = dis.read_ulong ();
		
		if (magic_number != 0x5F0F3CF5) {
			warning (@"Magic number is invalid. Got $(magic_number).");
			return;
		}
		
		flags = dis.read_ushort ();
		
		if ((flags & BASELINE_AT_ZERO) > 0) {
			warning ("Expected flag BASELINE_AT_ZERO  has not been set.");
		}

		if ((flags & LSB_AT_ZERO) > 0) {
			warning ("Flags LSB_AT_ZERO has been set.");
		}
		
		units_per_em = dis.read_ushort ();
		
		created = dis.read_udate ();
		modified = dis.read_udate ();
		
		xmin = dis.read_short ();
		ymin = dis.read_short ();
		
		xmax = dis.read_short ();
		ymax = dis.read_short ();
		
		mac_style = dis.read_ushort ();
		lowest_PPEM = dis.read_ushort ();
		font_direction_hint = dis.read_short ();
		
		loca_offset_size = dis.read_short ();
		glyph_data_format = dis.read_short ();
		
		if (glyph_data_format != 0) {
			warning (@"Unknown glyph data format. Expecting 0 got $glyph_data_format.");
		}
		
		// print_values ();
		// Some deprecated values follow here ...
	}
	
	void print_values () {
		print (@"Version: $(version.get_string ())\n");
		print (@"flags: $flags\n");
		print (@"font_revision: $(font_revision.get_string ())\n");
		print (@"flags: $flags\n");
		print (@"Units per em: $units_per_em\n");
		print (@"lowest_PPEM: $lowest_PPEM\n");
		print (@"font_direction_hint: $font_direction_hint\n");
		print (@"loca_offset_size: $loca_offset_size\n");
		print (@"glyph_data_format: $glyph_data_format\n");
	}
	
	public uint32 get_font_checksum () {
		return adjusted_checksum;
	}
	
	public void set_check_sum_adjustment (uint32 csa) {
		this.adjusted_checksum = csa;
	}
	
	public uint32 get_checksum_position () {
		return 8;
	}
	
	public void process () {
		FontData font_data = new FontData ();
		Fixed version = 1 << 16;
		Fixed font_revision = 1 << 16;

		font_data.add_fixed (version);
		font_data.add_fixed (font_revision);
		
		// Zero on the first run and updated by directory tables checksum calculation
		// for the entire font.
		font_data.add_u32 (adjusted_checksum);
		
		font_data.add_u32 (0x5F0F3CF5); // magic number
		
		// font_data.add_u16 (BASELINE_AT_ZERO | LSB_AT_ZERO);
		font_data.add_u16 (0); // flags
		
		font_data.add_u16 (100); // units per em (should be a power of two for ttf fonts)
		
		font_data.add_64 (0); // creation time since 1904-01-01
		font_data.add_64 (0); // modified time since 1904-01-01
		
		// glyf_table.get_boundries(out xmin, out ymin, out xmax, out ymax);
		
		xmin = glyf_table.xmin;
		ymin = glyf_table.ymin;
		xmax = glyf_table.xmax;
		ymax = glyf_table.ymax;
		
		font_data.add_16 (xmin);
		font_data.add_16 (ymin);
		font_data.add_16 (xmax);
		font_data.add_16 (ymax);
		
		font_data.add_u16 (0); // mac style
		font_data.add_u16 (0); // smallest recommended size in pixels
		font_data.add_16 (2); // deprecated direction hint
		font_data.add_16 (loca_offset_size);  // long offset
		font_data.add_16 (0);  // Use current glyph data format
		
		font_data.pad ();
		
		this.font_data = font_data;
		
		printd (@"loca_offset_size: $loca_offset_size\n");
	}
}

class HheaTable : Table {

	Fixed version;
	int16 ascender;
	int16 descender;
	int16 linegap;
	uint16 max_advance;
	int16 min_lsb;
	int16 min_rsb;
	int16 xmax_extent;
	int16 carret_slope;
	int16 carret_slope_run;
	int16 carret_offset;
	
	int16 metric_format;
	public int16 num_horizontal_metrics;
		
	GlyfTable glyf_table;
	HeadTable head_table;
	HmtxTable hmtx_table;
	
	public HheaTable (GlyfTable g, HeadTable h, HmtxTable hm) {
		glyf_table = g;
		head_table = h;
		hmtx_table = hm;
		id = "hhea";
	}
	
	public double get_ascender () {
		return ascender * 1000 / head_table.get_units_per_em ();
	}

	public double get_descender () {
		return descender * 1000 / head_table.get_units_per_em ();
	}
	
	public void parse (OtfInputStream dis) throws Error {
		dis.seek (offset);
		
		version = dis.read_fixed ();
		
		if (!version.equals (1, 0)) {
			warning (@"wrong version in hhea table $(version.get_string ())");
		}
		
		ascender = dis.read_short ();
		descender = dis.read_short ();
		linegap = dis.read_short ();
		max_advance = dis.read_ushort ();
		min_lsb = dis.read_short ();
		min_rsb = dis.read_short ();
		xmax_extent = dis.read_short ();
		carret_slope = dis.read_short ();
		carret_slope_run = dis.read_short ();
		carret_offset = dis.read_short ();
		
		// reserved x 4
		dis.read_short ();
		dis.read_short ();
		dis.read_short ();
		dis.read_short ();
		
		metric_format = dis.read_short ();
		num_horizontal_metrics = dis.read_short ();
	}
	
	public void process () {
		Font font = Supplement.get_current_font ();
		FontData fd = new FontData ();
		Fixed version = 1 << 16;
		
		fd.add_fixed (version); // table version
				
		// TODO: units per em
		fd.add_16 ((int16) (-1 * (font.top_position - font.base_line))); // Ascender
		fd.add_16 ((int16) (-1 * font.bottom_position)); // Descender
		fd.add_16 (0); // LineGap
				
		fd.add_u16 (hmtx_table.max_advance); // maximum advance width value in 'hmtx' table.
		
		fd.add_16 (hmtx_table.min_lsb); // min left side bearing
		fd.add_16 (hmtx_table.min_rsb); // min right side bearing
		fd.add_16 (hmtx_table.max_extent); // x max extent Max(lsb + (xMax - xMin))
		
		fd.add_16 (1); // caretSlopeRise
		fd.add_16 (0); // caretSlopeRun
		fd.add_16 (0); // caretOffset
		
		// reserved
		fd.add_16 (0);
		fd.add_16 (0);
		fd.add_16 (0);
		fd.add_16 (0);
		
		fd.add_16 (0); // metricDataFormat 0 for current format.
		
		fd.add_u16 ((uint16) glyf_table.glyphs.length()); // numberOfHMetrics Number of hMetric entries in 'hmtx' table

		// padding
		fd.pad ();
		this.font_data = fd;
	}
}

class HmtxTable : Table {
	
	uint32 nmetrics;
	uint32 nmonospaced;
		
	uint16* advance_width = null;
	uint16* left_side_bearing = null;
	uint16* left_side_bearing_monospaced = null;
	
	public int16 max_advance = 0;
	public int16 max_extent = 0;
	public int16 min_lsb = 0; 
	public int16 min_rsb = 0;
			
	HeadTable head_table;
	GlyfTable glyf_table;
	
	public HmtxTable (HeadTable h, GlyfTable gt) {
		head_table = h;
		glyf_table = gt;
		id = "hmtx";
	}
	
	~HmtxTable () {
		if (advance_width != null) delete advance_width;
		if (left_side_bearing != null) delete left_side_bearing; 
	}

	public double get_advance (uint32 i) {
		return_val_if_fail (i < nmetrics, 0.0);
		return_val_if_fail (advance_width != null, 0.0);
		
		return advance_width[i] * 1000 / head_table.get_units_per_em ();
	}
		
	/** Get left side bearing relative to xmin. */
	public double get_lsb (uint32 i) {
		return_val_if_fail (i < nmetrics, 0.0);
		return_val_if_fail (left_side_bearing != null, 0.0);
		
		return left_side_bearing[i] * 1000 / head_table.get_units_per_em ();
	}

	/** Get left side bearing relative to xmin for monospaces fonts. */
	public double get_lsb_mono (uint32 i) 
		requires (i < nmonospaced && left_side_bearing_monospaced != null) {
		return left_side_bearing_monospaced[i] * 1000 / head_table.get_units_per_em ();
	}
		
	public void parse (OtfInputStream dis, HheaTable hhea_table, LocaTable loca_table) {
		nmetrics = hhea_table.num_horizontal_metrics;
		nmonospaced = loca_table.size - nmetrics;
		
		dis.seek (offset);
		
		if (nmetrics > loca_table.size) {
			warning (@"(nmetrics > loca_table.size) ($nmetrics > $(loca_table.size))");
			return;
		}
		
		advance_width = new uint16[nmetrics];
		left_side_bearing = new uint16[nmetrics];
		left_side_bearing_monospaced = new uint16[nmonospaced];
		
		for (int i = 0; i < nmetrics; i++) {
			advance_width[i] = dis.read_ushort ();
			left_side_bearing[i] = dis.read_short ();
			
			// Delete: print (@"advance_width[i] $(advance_width[i])    $(left_side_bearing[i]) \n");
		}
		
		for (int i = 0; i < nmonospaced; i++) {
			left_side_bearing_monospaced[i] = dis.read_short ();
		}
	}
	
	public void process () {
		FontData fd = new FontData ();
		Font font = Supplement.get_current_font ();

		int16 advance;
		int16 extent;
		int16 rsb;
		int16 lsb;
		
		double xmin;
		double ymin;
		double xmax;
		double ymax;
		
		// advance and lsb
		foreach (Glyph g in glyf_table.glyphs) {
			g.boundries (out xmin, out ymin, out xmax, out ymax);

			lsb = (int16) (xmin - g.left_limit + 0.5);
			advance = (int16) (g.right_limit - g.left_limit + 0.5);
			extent = (int16) (lsb + (xmax - xmin) + 0.5);
			rsb = (int16) (advance - extent);

			printd (@"$(g.name) advance: $advance  = $((int16) (g.right_limit))  -  $((int16) (g.left_limit))\n");
						
			fd.add_u16 (advance);
			fd.add_16 (lsb);
	
			if (advance > max_advance) {
				max_advance = advance;
			}
			
			if (extent > max_extent) {
				max_extent = extent;
			}
			
			if (rsb < min_rsb) {
				min_rsb = rsb;
			}

			if (lsb < min_lsb) {
				min_lsb = lsb;
			}
		}
		
		// monospaced lsb ...
		
		font_data = fd;
		
		warn_if_fail (max_advance != 0);
	}
}


class MaxpTable : Table {
	
	GlyfTable glyf_table;
	
	public uint16 num_glyphs = 0;
	
	public MaxpTable (GlyfTable g) {
		glyf_table = g;
		id = "maxp";
	}
	
	public override void parse (OtfInputStream dis) 
		requires (offset > 0 && length > 0) {
		Fixed format;
		
		dis.seek (offset);
		
		format = dis.read_fixed ();
		printd (@"Maxp version: $(format.get_string ())\n");
		
		num_glyphs = dis.read_ushort ();
		
		if (format == 0x00005000) {
			return;
		}
		
		// Format 1.0 continues here
	}
	
	public void process () {
		FontData fd = new FontData();
		uint16 max_points, max_contours;
				
		// Version 0.5 for fonts with cff data and 1.0 for ttf
		fd.add_u32 (0x00010000);
		
		if (glyf_table.glyphs.length () == 0) {
			warning ("Zero glyphs in maxp table.");
		}
		
		fd.add_u16 ((uint16) glyf_table.glyphs.length ()); // numGlyphs in the font

		fd.add_u16 (glyf_table.get_max_points ()); // max points
		fd.add_u16 (glyf_table.get_max_contours ()); // max contours
		fd.add_u16 (0); // max composite points
		fd.add_u16 (0); // max composite contours
		fd.add_u16 (0); // max zones
		fd.add_u16 (0); // twilight points
		fd.add_u16 (0); // max storage
		fd.add_u16 (0); // max function defs
		fd.add_u16 (0); // max instruction defs
		fd.add_u16 (0); // max stack elements
		fd.add_u16 (0); // max size of instructions
		fd.add_u16 (0); // max component elements
		fd.add_u16 (0); // component depth
		
		fd.pad ();
		
		this.font_data = fd;
	}
}

class OffsetTable : Table {
	DirectoryTable directory_table;
		
	public uint16 num_tables = 0;
	uint16 search_range = 0;
	uint16 entry_selector = 0;
	uint16 range_shift = 0;
	
	public OffsetTable (DirectoryTable t) {
		id = "Offset table";
		directory_table = t;
	}
		
	public void parse (OtfInputStream dis) throws Error {
		Fixed version;
		
		dis.seek (offset);
		
		version = dis.read_fixed ();
		num_tables = dis.read_ushort ();
		search_range = dis.read_ushort ();
		entry_selector = dis.read_ushort ();
		range_shift = dis.read_ushort ();
		
		printd (@"Font file version $(version.get_string ())\n");
		printd (@"Number of tables $num_tables\n");		
	}
	
	public void process () {
		FontData fd = new FontData ();
		Fixed version = 1 << 16;
	
		// version 1.0 for TTF CFF else use OTTO
		assert (version.equals (1, 0));
		
		num_tables = (uint16) directory_table.get_tables ().length () - 2; // number of tables, skip DirectoryTable and OffsetTable
		
		search_range = max_pow_2_less_than_i (num_tables) * 16;
		entry_selector = max_log_2_less_than_i (num_tables);
		range_shift = 16 * num_tables - search_range;

		fd.add_fixed (version);
		fd.add_u16 (num_tables);
		fd.add_u16 (search_range);
		fd.add_u16 (entry_selector);
		fd.add_u16 (range_shift);
		
		// skip padding for offset table 
		
		this.font_data = fd;
	}
}

class NameTable : Table {

	static const uint16 COPYRIGHT_NOTICE = 0;
	static const uint16 FONT_NAME = 1;
	static const uint16 SUBFAMILY_NAME = 2;
	static const uint16 UNIQUE_IDENTIFIER = 3;
	static const uint16 FULL_FONT_NAME = 4; // name + subfamily
	static const uint16 VERSION = 5;
	static const uint16 DESCRIPTION = 10;
	
	List<string> text;
			
	public NameTable () {
		id = "name";
		text = new List<string> ();
	}

	public void print_all () {
		stdout.printf (@"$(text.length ()) name table texts:\n");
		foreach (string s in text) {
			stdout.printf (s);
			stdout.printf ("\n");
		}
	}

	public void parse (OtfInputStream dis) throws Error {
		uint16 format;

		dis.seek (offset);
		
		format = dis.read_ushort ();
		
		switch (format) {
			case 0:
				parse_format0 (dis);
				break;
				
			case 1:
				warning ("name table format 1 is not implemented yet");
				break;
			
			default:
				warning (@"unknown format $format in name table");
				break;
		}
	}
	
	public void parse_format0 (OtfInputStream dis) throws Error {
		uint16 count;
		uint16 storage_offset;
		
		List<uint16> strlen = new List<uint16> ();
		List<uint16> off = new List<uint16> ();
		List<uint16> name_id = new List<uint16> ();
		List<uint16> encoding_id = new List<uint16> ();
		List<uint16> platform = new List<uint16> ();
		List<uint16> lang = new List<uint16> ();
				
		count = dis.read_ushort ();
		storage_offset = dis.read_ushort ();
		
		for (int i = 0; i < count; i++) {
			platform.append (dis.read_ushort ());
			encoding_id.append (dis.read_ushort ());
			lang.append (dis.read_ushort ());
			name_id.append (dis.read_ushort ());
			strlen.append (dis.read_ushort ());
			off.append (dis.read_ushort ());
		}

		int plat;
		StringBuilder str;
		for (int i = 0; i < count; i++) {
			plat = platform.nth (i).data;
			dis.seek (offset + storage_offset + off.nth (i).data);
			str = new StringBuilder ();
			
			switch (plat) {
				case 1:
					for (int j = 0; j < strlen.nth (i).data; j++) {
						char c = dis.read_char ();
						str.append_c (c);
					}
					break;
					
				case 3:
					for (int j = 0; j < strlen.nth (i).data; j += 2) {
						unichar c;
						char c0 = dis.read_char ();
						char c1 = dis.read_char ();
												
						c = c0 << 8;
						c += c1;
						
						str.append_unichar (c);
					}
					break;
				
				default:
					break;
			} 
			
			text.append (str.str);
			printd (@"Name id: $(name_id.nth (i).data) platform:  $(platform.nth (i).data) enc: $(encoding_id.nth (i).data) lang: $(lang.nth (i).data) len: $(strlen.nth (i).data) str: \"$(str.str)\"\n");		
		}
	}
	
	public void process () {
		FontData fd = new FontData ();
		Font font = Supplement.get_current_font ();
		uint16 len = 0;
		string t;
		uint16 p;
		uint16 l;
		uint16 num_records;

		List<uint16> type = new List<uint16> ();
		List<string> text = new List<string> ();

		text.append ("Copyright");
		type.append (COPYRIGHT_NOTICE);
		
		text.append (font.get_name ());
		type.append (FONT_NAME);

		text.append ("Regular");
		type.append (SUBFAMILY_NAME);

		text.append (font.get_name ()); // TODO: validate
		type.append (UNIQUE_IDENTIFIER);

		text.append (font.get_name ());
		type.append (FULL_FONT_NAME);

		text.append ("Version 1.0;");
		type.append (VERSION);
						
		num_records = (uint16) text.length ();
		
		fd.add_ushort (0); // format 1
		fd.add_ushort (2 * num_records); // nplatforms * nrecords 
		fd.add_ushort (6 + 12 * 2 * num_records); // string storage offset

		for (int i = 0; i < num_records; i++) {
			t = (!) text.nth (i).data;
			p = (!) type.nth (i).data;
			l = (uint16) t.len ();
			
			fd.add_ushort (1); // platform
			fd.add_ushort (0); // encoding id
			fd.add_ushort (0); // language
			fd.add_ushort (p); // name id 
			fd.add_ushort (l); // strlen
			fd.add_ushort (len); // offset from begining of string storage
			len += l;				
		}	

		for (int i = 0; i < num_records; i++) {
			t = (!) text.nth (i).data;
			p = (!) type.nth (i).data;
			l = (uint16) (2 * t.char_count ());

			fd.add_ushort (3); // platform
			fd.add_ushort (1); 	// encoding id
			fd.add_ushort (1033); // language
			fd.add_ushort (p); // name id 
			fd.add_ushort (l); // strlen
			fd.add_ushort (len); // offset from begining of string storage
			len += l;
		}

		// platform 1
		foreach (string s in text) {
			fd.add_str (s); 
		}
		
		// platform 3
		foreach (string s in text) {
			fd.add_str_utf16 (s); 
		}

		fd.pad ();
		
		this.font_data = fd;
	}
}

class Os2Table : Table {
	
	public Os2Table () {
		id = "OS/2";
	}
	
	public void parse (OtfInputStream dis) throws Error {
		
	}
	
	public void process (GlyfTable glyf_table) {
		FontData fd = new FontData ();
		
		fd.add_u16 (0x0002); // USHORT Version 0x0000, 0x0001, 0x0002, 0x0003, 0x0004

		fd.add_16 (0); // SHORT xAvgCharWidth

		fd.add_u16 (0); // USHORT usWeightClass
		fd.add_u16 (0); // USHORT usWidthClass
		fd.add_u16 (0); // USHORT fsType

		fd.add_16 (0); // SHORT ySubscriptXSize
		fd.add_16 (0); // SHORT ySubscriptYSize
		fd.add_16 (0); // SHORT ySubscriptXOffset
		fd.add_16 (0); // SHORT ySubscriptYOffset
		fd.add_16 (0); // SHORT ySuperscriptXSize
		fd.add_16 (0); // SHORT ySuperscriptYSize
		fd.add_16 (0); // SHORT ySuperscriptXOffset
		fd.add_16 (0); // SHORT ySuperscriptYOffset
		fd.add_16 (0); // SHORT yStrikeoutSize
		fd.add_16 (0); // SHORT yStrikeoutPosition
		fd.add_16 (0); // SHORT sFamilyClass

		// PANOSE
		fd.add (0); 
		fd.add (0); 
		fd.add (0); 
		fd.add (0); 
		fd.add (0); 
		fd.add (0); 
		fd.add (0); 
		fd.add (0); 
		fd.add (0); 
		fd.add (0); 

		fd.add_u32 (0); // ulUnicodeRange1 Bits 0-31
		fd.add_u32 (0); // ULONG ulUnicodeRange2 Bits 32-63
		fd.add_u32 (0); // ULONG ulUnicodeRange3 Bits 64-95
		fd.add_u32 (0); // ULONG ulUnicodeRange4 Bits 96-127

		fd.add_tag ("----"); // VendID

		fd.add_u16 (0); // USHORT fsSelection
		
		fd.add_u16 (glyf_table.get_first_char ()); // USHORT usFirstCharIndex
		fd.add_u16 (glyf_table.get_last_char ()); // USHORT usLastCharIndex

		fd.add_16 (0); // SHORT sTypoAscender
		fd.add_16 (0); // SHORT sTypoDescender
		fd.add_16 (0); // SHORT sTypoLineGap

		fd.add_u16 (0); // USHORT usWinAscent
		fd.add_u16 (0); // USHORT usWinDescent

		fd.add_u32 (0); // ULONG ulCodePageRange1 Bits 0-31
		fd.add_u32 (0); // ULONG ulCodePageRange2 Bits 32-63

		fd.add_16 (0); // SHORT sxHeight version 0x0002 and later
		fd.add_16 (0); // SHORT sCapHeight version 0x0002 and later

		fd.add_16 (0); // USHORT usDefaultChar version 0x0002 and later
		fd.add_16 (0); // USHORT usBreakChar version 0x0002 and later
		fd.add_16 (0); // USHORT usMaxContext version 0x0002 and later

		// padding
		fd.pad ();
	
		this.font_data = fd;
	}

}

class PostTable : Table {
	
	GlyfTable glyf_table;
	
	List<uint16> index = new List<uint16> ();
	List<string> names = new List<string> ();

	public PostTable (GlyfTable g) {
		id = "post";
		glyf_table = g;
	}

	public string get_name (int gid) {
		uint16 i;
		int k;
		
		if (!(0 <= gid <= index.length ())) {
			warning ("gid is out of range.");
			return "INVALID";
		}
				
		k = (!) index.nth (gid).data;
		
		if (gid != 0 && k == 0) {
			warning (@"Glyph $gid is assigned to name .notdef, only gid 0 can be .notdef character.");
			return "";
		}
		
		if (!(0 <= k <= names.length ())) {
			warning ("k is out of range.");
			return "INVALID";
		}
				
		return (!) names.nth (k).data;
	}
	
	public void parse (OtfInputStream dis) throws Error {
		dis.seek (offset);
		
		Fixed format = dis.read_fixed ();
		Fixed italic = dis.read_fixed ();
		
		int16 underlie_pos = dis.read_short ();
		int16 underlie_thickness = dis.read_short ();
		uint32 is_fixed_pitch  = dis.read_ulong ();
		
		uint32 mem_min42  = dis.read_ulong ();
		uint32 mem_max42  = dis.read_ulong ();
		uint32 mem_min1  = dis.read_ulong ();
		uint32 mem_max1  = dis.read_ulong ();
		
		uint16 nnames  = dis.read_ushort ();
		
		if (format != 0x00020000) {
			warning ("Only post tables of version 2 will parset got $(format.get_string ())");
			return;
		}
		
		printd (@"format: $(format.get_string ())\n");
		printd (@"italic: $(italic.get_string ())\n");
		printd (@"underlie_pos: $(underlie_pos)\n");
		printd (@"underlie_thickness: $(underlie_thickness)\n");
		printd (@"is_fixed_pitch: $(is_fixed_pitch)\n");
		printd (@"mem_min42: $(mem_min42)\n");
		printd (@"mem_max42: $(mem_max42)\n");
		printd (@"mem_min1: $(mem_min1)\n");
		printd (@"mem_max1: $(mem_max1)\n");
		printd (@"\n");
		
		printd (@"Num names: $(nnames)\n");
		
		uint16 k;
		int non_standard_names = 0;
		for (uint16 i = 0; i < nnames; i++) {
			k = dis.read_ushort ();
			index.append (k);
			
			if (k >= 258) {
				non_standard_names++;
			}
		}
		
		add_standard_names ();
		
		// read non standard names
		for (int i = 0; i < non_standard_names; i++) {
			uint8 len = dis.read_byte ();
			StringBuilder name = new StringBuilder ();
			int gid = (!) index.nth (i).data;
			
			for (int j = 0; j < len; j++) {
				name.append_c (dis.read_char ());
			}
			
			// print (@"Name gid: $gid len: $len: $(name.str)\n");
			
			names.append (name.str);
		}		
	}
	
	public void print_all () {
		print (@"PostScript glyph mapping:\n");
		for (int i = 0; i < index.length (); i++) {
			print (@"gid $i -> $(get_name (i))\n");
		}
	}
	
	public void print_avaliable_names () {
		print (@"Post table names:\n");
		foreach (var n in names) {
			print (@"$n\n");
		}
	}
	
	// the Macintosh standard order
	private void add_standard_names () {
		names.append (".notdef");
		names.append (".null");
		names.append ("nonmarkingreturn");
		names.append ("space");
		names.append ("exclam");
		names.append ("quotedbl");
		names.append ("numbersign");
		names.append ("dollar");
		names.append ("percent");
		names.append ("ampersand");
		names.append ("quotesingle");
		names.append ("parenleft");
		names.append ("parenright");
		names.append ("asterisk");
		names.append ("plus");
		names.append ("comma");
		names.append ("hyphen");
		names.append ("period");
		names.append ("slash");
		names.append ("zero");
		names.append ("one");
		names.append ("two");
		names.append ("three");
		names.append ("four");
		names.append ("five");
		names.append ("six");
		names.append ("seven");
		names.append ("eight");
		names.append ("nine");
		names.append ("colon");
		names.append ("semicolon");
		names.append ("less");
		names.append ("equal");
		names.append ("greater");
		names.append ("question");
		names.append ("at");
		names.append ("A");
		names.append ("B");
		names.append ("C");
		names.append ("D");
		names.append ("E");
		names.append ("F");
		names.append ("G");
		names.append ("H");
		names.append ("I");
		names.append ("J");
		names.append ("K");
		names.append ("L");
		names.append ("M");
		names.append ("N");
		names.append ("O");
		names.append ("P");
		names.append ("Q");
		names.append ("R");
		names.append ("S");
		names.append ("T");
		names.append ("U");
		names.append ("V");
		names.append ("W");
		names.append ("X");
		names.append ("Y");
		names.append ("Z");
		names.append ("bracketleft");
		names.append ("backslash");
		names.append ("bracketright");
		names.append ("asciicircum");
		names.append ("underscore");
		names.append ("grave");
		names.append ("a");
		names.append ("b");
		names.append ("c");
		names.append ("d");
		names.append ("e");
		names.append ("f");
		names.append ("g");
		names.append ("h");
		names.append ("i");
		names.append ("j");
		names.append ("k");
		names.append ("l");
		names.append ("m");
		names.append ("n");
		names.append ("o");
		names.append ("p");
		names.append ("q");
		names.append ("r");
		names.append ("s");
		names.append ("t");
		names.append ("u");
		names.append ("v");
		names.append ("w");
		names.append ("x");
		names.append ("y");
		names.append ("z");
		names.append ("braceleft");
		names.append ("bar");
		names.append ("braceright");
		names.append ("asciitilde");
		names.append ("Adieresis");
		names.append ("Aring");
		names.append ("Ccedilla");
		names.append ("Eacute");
		names.append ("Ntilde");
		names.append ("Odieresis");
		names.append ("Udieresis");
		names.append ("aacute");
		names.append ("agrave");
		names.append ("acircumflex");
		names.append ("adieresis");
		names.append ("atilde");
		names.append ("aring");
		names.append ("ccedilla");
		names.append ("eacute");
		names.append ("egrave");
		names.append ("ecircumflex");
		names.append ("edieresis");
		names.append ("iacute");
		names.append ("igrave");
		names.append ("icircumflex");
		names.append ("idieresis");
		names.append ("ntilde");
		names.append ("oacute");
		names.append ("ograve");
		names.append ("ocircumflex");
		names.append ("odieresis");
		names.append ("otilde");
		names.append ("uacute");
		names.append ("ugrave");
		names.append ("ucircumflex");
		names.append ("udieresis");
		names.append ("dagger");
		names.append ("degree");
		names.append ("cent");
		names.append ("sterling");
		names.append ("section");
		names.append ("bullet");
		names.append ("paragraph");
		names.append ("germandbls");
		names.append ("registered");
		names.append ("copyright");
		names.append ("trademark");
		names.append ("acute");
		names.append ("dieresis");
		names.append ("notequal");
		names.append ("AE");
		names.append ("Oslash");
		names.append ("infinity");
		names.append ("plusminus");
		names.append ("lessequal");
		names.append ("greaterequal");
		names.append ("yen");
		names.append ("mu");
		names.append ("partialdiff");
		names.append ("summation");
		names.append ("product");
		names.append ("pi");
		names.append ("integral");
		names.append ("ordfeminine");
		names.append ("ordmasculine");
		names.append ("Omega");
		names.append ("ae");
		names.append ("oslash");
		names.append ("questiondown");
		names.append ("exclamdown");
		names.append ("logicalnot");
		names.append ("radical");
		names.append ("florin");
		names.append ("approxequal");
		names.append ("Delta");
		names.append ("guillemotleft");
		names.append ("guillemotright");
		names.append ("ellipsis");
		names.append ("nonbreakingspace");
		names.append ("Agrave");
		names.append ("Atilde");
		names.append ("Otilde");
		names.append ("OE");
		names.append ("oe");
		names.append ("endash");
		names.append ("emdash");
		names.append ("quotedblleft");
		names.append ("quotedblright");
		names.append ("quoteleft");
		names.append ("quoteright");
		names.append ("divide");
		names.append ("lozenge");
		names.append ("ydieresis");
		names.append ("Ydieresis");
		names.append ("fraction");
		names.append ("currency");
		names.append ("guilsinglleft");
		names.append ("guilsinglright");
		names.append ("fi");
		names.append ("fl");
		names.append ("daggerdbl");
		names.append ("periodcentered");
		names.append ("quotesinglbase");
		names.append ("quotedblbase");
		names.append ("perthousand");
		names.append ("Acircumflex");
		names.append ("Ecircumflex");
		names.append ("Aacute");
		names.append ("Edieresis");
		names.append ("Egrave");
		names.append ("Iacute");
		names.append ("Icircumflex");
		names.append ("Idieresis");
		names.append ("Igrave");
		names.append ("Oacute");
		names.append ("Ocircumflex");
		names.append ("apple");
		names.append ("Ograve");
		names.append ("Uacute");
		names.append ("Ucircumflex");
		names.append ("Ugrave");
		names.append ("dotlessi");
		names.append ("circumflex");
		names.append ("tilde");
		names.append ("macron");
		names.append ("breve");
		names.append ("dotaccent");
		names.append ("ring");
		names.append ("cedilla");
		names.append ("hungarumlaut");
		names.append ("ogonek");
		names.append ("caron");
		names.append ("Lslash");
		names.append ("lslash");
		names.append ("Scaron");
		names.append ("scaron");
		names.append ("Zcaron");
		names.append ("zcaron");
		names.append ("brokenbar");
		names.append ("Eth");
		names.append ("eth");
		names.append ("Yacute");
		names.append ("yacute");
		names.append ("Thorn");
		names.append ("thorn");
		names.append ("minus");
		names.append ("multiply");
		names.append ("onesuperior");
		names.append ("twosuperior");
		names.append ("threesuperior");
		names.append ("onehalf");
		names.append ("onequarter");
		names.append ("threequarters");
		names.append ("franc");
		names.append ("Gbreve");
		names.append ("gbreve");
		names.append ("Idotaccent");
		names.append ("Scedilla");
		names.append ("scedilla");
		names.append ("Cacute");
		names.append ("cacute");
		names.append ("Ccaron");
		names.append ("ccaron");
		names.append ("dcroat");
	}
	
	// mapping with char code to standard order
	int get_standard_index (unichar c) {
		switch (c) {
			// entry 0 is the .notdef
			
			case '\0':
				return 1;
				break;

			case '\r':
				return 2;
				break;

			case ' ': // space
				return 3;
				break;

			case '!':
				return 4;
				break;

			case '"':
				return 5;
				break;

			case '#':
				return 6;
				break;

			case '$':
				return 7;
				break;

			case '%':
				return 8;
				break;

			case '&':
				return 9;
				break;

			case '\'':
				return 10;
				break;

			case '(':
				return 11;
				break;

			case ')':
				return 12;
				break;

			case '*':
				return 13;
				break;

			case '+':
				return 14;
				break;

			case ',':
				return 15;
				break;

			case '-':
				return 16;
				break;

			case '.':
				return 17;
				break;

			case '/':
				return 18;
				break;

			case '0':
				return 19;
				break;

			case '1':
				return 20;
				break;

			case '2':
				return 21;
				break;

			case '3':
				return 22;
				break;

			case '4':
				return 23;
				break;

			case '5':
				return 24;
				break;

			case '6':
				return 25;
				break;

			case '7':
				return 26;
				break;

			case '8':
				return 27;
				break;

			case '9':
				return 28;
				break;

			case ':':
				return 29;
				break;

			case ';':
				return 30;
				break;

			case '<':
				return 31;
				break;

			case '=':
				return 32;
				break;

			case '>':
				return 33;
				break;

			case '?':
				return 34;
				break;

			case '@':
				return 35;
				break;

			case 'A':
				return 36;
				break;

			case 'B':
				return 37;
				break;

			case 'C':
				return 38;
				break;

			case 'D':
				return 39;
				break;

			case 'E':
				return 40;
				break;

			case 'F':
				return 41;
				break;

			case 'G':
				return 42;
				break;

			case 'H':
				return 43;
				break;

			case 'I':
				return 44;
				break;

			case 'J':
				return 45;
				break;

			case 'K':
				return 46;
				break;

			case 'L':
				return 47;
				break;

			case 'M':
				return 48;
				break;

			case 'N':
				return 49;
				break;

			case 'O':
				return 50;
				break;

			case 'P':
				return 51;
				break;

			case 'Q':
				return 52;
				break;

			case 'R':
				return 53;
				break;

			case 'S':
				return 54;
				break;

			case 'T':
				return 55;
				break;

			case 'U':
				return 56;
				break;

			case 'V':
				return 57;
				break;

			case 'W':
				return 58;
				break;

			case 'X':
				return 59;
				break;

			case 'Y':
				return 60;
				break;

			case 'Z':
				return 61;
				break;

			case '[':
				return 62;
				break;

			case '\\':
				return 63;
				break;

			case ']':
				return 64;
				break;

			case '^':
				return 65;
				break;

			case '_':
				return 66;
				break;

			case '`':
				return 67;
				break;

			case 'a':
				return 68;
				break;

			case 'b':
				return 69;
				break;

			case 'c':
				return 70;
				break;

			case 'd':
				return 71;
				break;

			case 'e':
				return 72;
				break;

			case 'f':
				return 73;
				break;

			case 'g':
				return 74;
				break;

			case 'h':
				return 75;
				break;

			case 'i':
				return 76;
				break;

			case 'j':
				return 77;
				break;

			case 'k':
				return 78;
				break;

			case 'l':
				return 79;
				break;

			case 'm':
				return 80;
				break;

			case 'n':
				return 81;
				break;

			case 'o':
				return 82;
				break;

			case 'p':
				return 83;
				break;

			case 'q':
				return 84;
				break;

			case 'r':
				return 85;
				break;

			case 's':
				return 86;
				break;

			case 't':
				return 87;
				break;

			case 'u':
				return 88;
				break;

			case 'v':
				return 89;
				break;

			case 'w':
				return 90;
				break;

			case 'x':
				return 91;
				break;

			case 'y':
				return 92;
				break;

			case 'z':
				return 93;
				break;

			case '{':
				return 94;
				break;

			case '|':
				return 95;
				break;

			case '}':
				return 96;
				break;

			case '~':
				return 97;
				break;

			case 'Ä':
				return 98;
				break;

			case 'Å':
				return 99;
				break;

			case 'Ç':
				return 100;
				break;

			case 'É':
				return 101;
				break;

			case 'Ñ':
				return 102;
				break;

			case 'Ö':
				return 103;
				break;

			case 'Ü':
				return 104;
				break;

			case 'á':
				return 105;
				break;

			case 'à':
				return 106;
				break;

			case 'â':
				return 107;
				break;

			case 'ä':
				return 108;
				break;

			case 'ã':
				return 109;
				break;

			case 'å':
				return 110;
				break;

			case 'ç':
				return 111;
				break;

			case 'é':
				return 112;
				break;

			case 'è':
				return 113;
				break;

			case 'ê':
				return 114;
				break;

			case 'ë':
				return 115;
				break;

			case 'í':
				return 116;
				break;

			case 'ì':
				return 117;
				break;

			case 'î':
				return 118;
				break;

			case 'ï':
				return 119;
				break;

			case 'ñ':
				return 120;
				break;

			case 'ó':
				return 121;
				break;

			case 'ò':
				return 122;
				break;

			case 'ô':
				return 123;
				break;

			case 'ö':
				return 124;
				break;

			case 'õ':
				return 125;
				break;

			case 'ú':
				return 126;
				break;

			case 'ù':
				return 127;
				break;

			case 'û':
				return 128;
				break;

			case 'ü':
				return 129;
				break;

			case '†':
				return 130;
				break;

			case '°':
				return 131;
				break;

			case '¢':
				return 132;
				break;

			case '£':
				return 133;
				break;

			case '§':
				return 134;
				break;

			case '•':
				return 135;
				break;

			case '¶':
				return 136;
				break;

			case 'ß':
				return 137;
				break;

			case '®':
				return 138;
				break;

			case '©':
				return 139;
				break;

			case '™':
				return 140;
				break;

			case '´':
				return 141;
				break;

			case '¨':
				return 142;
				break;

			case '≠':
				return 143;
				break;

			case 'Æ':
				return 144;
				break;

			case 'Ø':
				return 145;
				break;

			case '∞':
				return 146;
				break;

			case '±':
				return 147;
				break;

			case '≤':
				return 148;
				break;

			case '≥':
				return 149;
				break;

			case '¥':
				return 150;
				break;

			case 'µ':
				return 151;
				break;

			case '∂':
				return 152;
				break;

			case '∑':
				return 153;
				break;

			case '∏':
				return 154;
				break;

			case 'π':
				return 155;
				break;

			case '∫':
				return 156;
				break;

			case 'ª':
				return 157;
				break;

			case 'º':
				return 158;
				break;

			case 'Ω':
				return 159;
				break;

			case 'æ':
				return 160;
				break;

			case 'ø':
				return 161;
				break;

			case '¿':
				return 162;
				break;

			case '¡':
				return 163;
				break;

			case '¬':
				return 164;
				break;

			case '√':
				return 165;
				break;

			case 'ƒ':
				return 166;
				break;

			case '≈':
				return 167;
				break;

			case '∆':
				return 168;
				break;

			case '«':
				return 169;
				break;

			case '»':
				return 170;
				break;

			case '…':
				return 171;
				break;

			case ' ': // non breaking space
				return 172;
				break;
							
			case 'À':
				return 173;
				break;

			case 'Ã':
				return 174;
				break;

			case 'Õ':
				return 175;
				break;

			case 'Œ':
				return 176;
				break;

			case 'œ':
				return 177;
				break;

			case '–':
				return 178;
				break;

			case '—':
				return 179;
				break;

			case '“':
				return 180;
				break;

			case '”':
				return 181;
				break;

			case '‘':
				return 182;
				break;

			case '’':
				return 183;
				break;

			case '÷':
				return 184;
				break;

			case '◊':
				return 185;
				break;

			case 'ÿ':
				return 186;
				break;

			case 'Ÿ':
				return 187;
				break;

			case '⁄':
				return 188;
				break;

			case '¤':
				return 189;
				break;

			case '‹':
				return 190;
				break;

			case '›':
				return 191;
				break;

			case 'ﬁ':
				return 192;
				break;

			case 'ﬂ':
				return 193;
				break;

			case '‡':
				return 194;
				break;

			case '·':
				return 195;
				break;

			case '‚':
				return 196;
				break;

			case '„':
				return 197;
				break;

			case '‰':
				return 198;
				break;

			case 'Â':
				return 199;
				break;

			case 'Ê':
				return 200;
				break;

			case 'Á':
				return 201;
				break;

			case 'Ë':
				return 202;
				break;

			case 'È':
				return 203;
				break;

			case 'Í':
				return 204;
				break;

			case 'Î':
				return 205;
				break;

			case 'Ï':
				return 206;
				break;

			case 'Ì':
				return 207;
				break;

			case 'Ó':
				return 208;
				break;

			case 'Ô':
				return 209;
				break;
				
			// Machintosh apple goes here
			// return 210;

			case 'Ò':
				return 211;
				break;

			case 'Ú':
				return 212;
				break;

			case 'Û':
				return 213;
				break;

			case 'Ù':
				return 214;
				break;

			case 'ı':
				return 215;
				break;

			case 'ˆ':
				return 216;
				break;

			case '˜':
				return 217;
				break;

			case '¯':
				return 218;
				break;

			case '˘':
				return 219;
				break;

			case '˙':
				return 220;
				break;

			case '˚':
				return 221;
				break;

			case '¸':
				return 222;
				break;

			case '˝':
				return 223;
				break;

			case '˛':
				return 224;
				break;

			case 'ˇ':
				return 225;
				break;

			case 'Ł':
				return 226;
				break;

			case 'ł':
				return 227;
				break;

			case 'Š':
				return 228;
				break;

			case 'š':
				return 229;
				break;

			case 'Ž':
				return 230;
				break;

			case 'ž':
				return 231;
				break;

			case '¦':
				return 232;
				break;

			case 'Ð':
				return 233;
				break;

			case 'ð':
				return 234;
				break;

			case 'Ý':
				return 235;
				break;

			case 'ý':
				return 236;
				break;

			case 'Þ':
				return 237;
				break;

			case 'þ':
				return 238;
				break;

			case '−':
				return 239;
				break;

			case '×':
				return 240;
				break;

			case '¹':
				return 241;
				break;
				
			case '²':
				return 242;
				break;

			case '³':
				return 243;
				break;

			case '½':
				return 244;
				break;

			case '¼':
				return 245;
				break;

			case '¾':
				return 246;
				break;

			case '₣':
				return 247;
				break;

			case 'Ğ':
				return 248;
				break;

			case 'ğ':
				return 249;
				break;

			case 'İ':
				return 250;
				break;

			case 'Ş':
				return 251;
				break;

			case 'ş':
				return 252;
				break;

			case 'Ć':
				return 253;
				break;

			case 'ć':
				return 254;
				break;

			case 'Č':
				return 255;
				break;

			case 'č':
				return 256;
				break;

			case 'đ':
				return 257;
				break;
		}
		
		return 0;
	}
	
	public void process () throws Error {
		FontData fd = new FontData ();
		string n;
		
		fd.add_fixed (0x00020000); // Version
		fd.add_fixed (0x00000000); // italicAngle
		
		fd.add_short (-2); // underlinePosition
		fd.add_short (1); // underlineThickness

		fd.add_ulong (0); // non zero for monospaced font
		
		// mem boundries may be omitted
		fd.add_ulong (0); // min mem for type 42
		fd.add_ulong (0); // max mem for type 42
		
		fd.add_ulong (0); // min mem for Type1
		fd.add_ulong (0); // max mem for Type1

		fd.add_ushort ((uint16) glyf_table.glyphs.length ());

		// this part of the spec is so weird
		
		fd.add_ushort ((uint16) 0); // first index is .notdef
		index.append (0);
		
		assert (names.length () == 0);
		add_standard_names ();

		int index;
		Glyph g;
		for (int i = 1; i < glyf_table.glyphs.length (); i++) {
			g = (!) glyf_table.glyphs.nth (i).data;
			index = get_standard_index (g.unichar_code);
			
			if (index != 0) {
				fd.add_ushort ((uint16) index);  // use standard name
			} else {
				index = (int) names.length (); // use font specific name
				fd.add_ushort ((uint16) index);
				names.append (g.get_name ());
			}
			
			this.index.append ((uint16) index);
		}

		for (int i = 258; i < names.length (); i++) {
			n = (!) names.nth (i).data;
			
			if (n.len () > 0xFF) {
				warning ("too long name for glyph $n");
			}
						
			fd.add ((uint8) n.len ()); // length of string
			fd.add_str (n);
		}		

		fd.pad ();
		
		this.font_data = fd;
	}

}

/** Table with list of tables sorted by table tag. */
class DirectoryTable : Table {
	
	public CmapTable cmap_table;
	public GlyfTable glyf_table;
	public HeadTable head_table;
	public HheaTable hhea_table;
	public HmtxTable hmtx_table;
	public MaxpTable maxp_table;
	public NameTable name_table;
	public Os2Table  os_2_table;
	public PostTable post_table;
	public LocaTable loca_table;
	
	public OffsetTable offset_table;
	
	List<Table> tables;
	
	public DirectoryTable () {
		offset_table = new OffsetTable (this);
		
		loca_table = new LocaTable ();
		glyf_table = new GlyfTable (loca_table);
		cmap_table = new CmapTable (glyf_table);
		head_table = new HeadTable (glyf_table);
		hmtx_table = new HmtxTable (head_table, glyf_table);
		hhea_table = new HheaTable (glyf_table, head_table, hmtx_table);
		maxp_table = new MaxpTable (glyf_table);
		name_table = new NameTable ();
		os_2_table = new Os2Table (); 
		post_table = new PostTable (glyf_table);
		
		id = "Directory table";
	}

	public void process () {
		// generate font data
		glyf_table.process ();
		head_table.process ();
		cmap_table.process (glyf_table);
		hmtx_table.process ();
		hhea_table.process ();
		maxp_table.process ();
		name_table.process ();
		os_2_table.process (glyf_table);
		loca_table.process (glyf_table, head_table);
		post_table.process ();
		
		offset_table.process ();
		process_directory (); // this table
	}

	public unowned List<Table> get_tables () {
		if (tables.length () == 0) {
			tables.append (offset_table);
			tables.append (this);

			tables.append (head_table);
			tables.append (cmap_table);
			tables.append (glyf_table);
			tables.append (hhea_table);
			tables.append (hmtx_table);
			tables.append (loca_table);
			tables.append (name_table);
			tables.append (maxp_table);
			tables.append (os_2_table);
			tables.append (post_table);
		}

		return tables;
	}

	public void set_offset_table (OffsetTable ot) {
		offset_table = ot;
	}
	
	public void parse (OtfInputStream dis, File file) throws Error {
		StringBuilder tag = new StringBuilder ();
		uint32 checksum;
		uint32 offset;
		uint32 length;
		
		return_if_fail (offset_table.num_tables > 0);
		
		for (uint i = 0; i < offset_table.num_tables; i++) {
			tag.erase ();
			
			tag.append_unichar ((unichar) dis.read_byte ());
			tag.append_unichar ((unichar) dis.read_byte ());
			tag.append_unichar ((unichar) dis.read_byte ());
			tag.append_unichar ((unichar) dis.read_byte ());
			
			checksum = dis.read_ulong ();
			offset = dis.read_ulong ();
			length = dis.read_ulong ();
			
			printd (@"$(tag.str) \toffset: $offset \tlength: $length \tchecksum: $checksum.\n");
			
			if (tag.str == "hmtx") {
				hmtx_table.id = tag.str;
				hmtx_table.checksum = checksum;
				hmtx_table.offset = offset;
				hmtx_table.length = length;
			} else if (tag.str == "hhea") {
				hhea_table.id = tag.str;
				hhea_table.checksum = checksum;
				hhea_table.offset = offset;
				hhea_table.length = length;	
			} else if (tag.str == "loca") {
				loca_table.id = tag.str;
				loca_table.checksum = checksum;
				loca_table.offset = offset;
				loca_table.length = length;	
			} else if (tag.str == "cmap") {
				cmap_table.id = tag.str;
				cmap_table.checksum = checksum;
				cmap_table.offset = offset;
				cmap_table.length = length;
			} else if (tag.str == "maxp") {
				maxp_table.id = tag.str;
				maxp_table.checksum = checksum;
				maxp_table.offset = offset;
				maxp_table.length = length;
			} else if (tag.str == "glyf") {
				glyf_table.id = tag.str;
				glyf_table.checksum = checksum;
				glyf_table.offset = offset;
				glyf_table.length = length;
			} else if (tag.str == "head") {
				head_table.id = tag.str;
				head_table.checksum = checksum;
				head_table.offset = offset;
				head_table.length = length;
			} else if (tag.str == "name") {
				name_table.id = tag.str;
				name_table.checksum = checksum;
				name_table.offset = offset;
				name_table.length = length;
			} else if (tag.str == "OS/2") {
				os_2_table.id = tag.str;
				os_2_table.checksum = checksum;
				os_2_table.offset = offset;
				os_2_table.length = length;
			} else if (tag.str == "post") {
				post_table.id = tag.str;
				post_table.checksum = checksum;
				post_table.offset = offset;
				post_table.length = length;
			}
			
		}
		
		// FIXA: delete
		/*
		FontData fd = new FontData ();
		fd.write_table (dis, post_table.offset, post_table.length);
		fd.print ();
		*/
		
		printd (@"fd.write_table (dis, post_table.offset, post_table.length) $(post_table.offset) $(post_table.length)\n");
		
		head_table.parse (dis);
		
		if (!validate_tables (dis, file)) {
			warning ("Missing required table or bad checksum.");
			// Fixa: stop processing here, if we want to avoid loading bad fonts
			return;
		}
		
		name_table.parse (dis);
		post_table.parse (dis);
		os_2_table.parse (dis);
		hhea_table.parse (dis);
		maxp_table.parse (dis);
		loca_table.parse (dis, head_table, maxp_table);
		hmtx_table.parse (dis, hhea_table, loca_table);
		cmap_table.parse (dis);
		glyf_table.parse (dis, cmap_table, loca_table, hmtx_table, head_table, post_table);
	}
	
	public bool validate_tables (OtfInputStream dis, File file) {
		bool valid = true;
		uint p = head_table.get_checksum_position ();
		FontData fd = new FontData ();	
		uint32 checksum;
		
		try {

			if (!validate_checksum_for_entire_font (dis, file)) {
				warning ("file has invalid checksum");
			}
							
			fd.write_table (dis, head_table.offset, head_table.length);
			
			// zero out checksum entry in head table before validating it
			fd.write_at (p + 0, 0);
			fd.write_at (p + 1, 0);
			fd.write_at (p + 2, 0);
			fd.write_at (p + 3, 0);	

			checksum = (uint32) fd.check_sum ();	
			
			if (checksum != head_table.checksum) {
				warning ("head_table has is invalid checksum");
				valid = false;				
			}
			
			if (!glyf_table.validate (dis)) {
				warning ("glyf_table has invalid checksum");
				valid = false;
			}
			
			if (!maxp_table.validate (dis)) {
				warning ("maxp_table has is invalid checksum");
				valid = false;
			}
			
			if (!loca_table.validate (dis)) {
				warning ("loca_table has invalid checksum");
				valid = false;
			}
			
			if (!cmap_table.validate (dis)) {
				warning ("cmap_table has invalid checksum");
				valid = false;
			}
			
			if (!hhea_table.validate (dis)) {
				warning ("hhea_table has invalid checksum");
				valid = false;
			}
			
			if (!hmtx_table.validate (dis)) {
				warning ("hmtx_table has invalid checksum");
				valid = false;
			}

			if (!name_table.validate (dis)) {
				warning ("name_table has invalid checksum");
				valid = false;
			}

			if (!os_2_table.validate (dis)) {
				warning ("os_2_table has invalid checksum");
				valid = false;
			}

			if (!post_table.validate (dis)) {
				warning ("post_table has invalid checksum");
				valid = false;
			}
		} catch (GLib.Error e) {
			warning (e.message);
			valid = false;
		}
		
		return valid;
	}
	
	bool validate_checksum_for_entire_font (OtfInputStream dis, File f) {
		FontData fd = new FontData ();
		uint p = head_table.offset + head_table.get_checksum_position ();
		FileInfo file_info = f.query_info ("*", FileQueryInfoFlags.NONE);
		uint32 checksum_font, checksum_head;
		uint32 file_size = (uint32) file_info.get_size ();
		
		if (file_size % 4 != 0) {
			warning ("Font has to be padded to size of uint32 in order to compute checksum.");
			return false;
		}
		
        try {
			fd.write_table (dis, 0, file_size);
		} catch (GLib.Error e) {
			warning (@"Failed to compute checksum since $(e.message)");
		}
		
		// zero out checksum entry in head table before validating it
		fd.write_at (p + 0, 0);
		fd.write_at (p + 1, 0);
		fd.write_at (p + 2, 0);
		fd.write_at (p + 3, 0);
		
		checksum_font = (uint32) (0xB1B0AFBA - fd.check_sum ());
		checksum_head = head_table.get_font_checksum ();
		
		if (checksum_font != checksum_head) {
			warning (@"Fontfile checksum in head table does not match calculated checksum. checksum_font: $checksum_font checksum_head: $checksum_head");
			return false;
		}
		
		return true;
	}
	
	public string get_id () {
		warning ("Don't write id for table directory.");		
		return "Directory table"; // Table id should be ignored for directory table, none the less it has one declared here.
	}
	
	public GlyfTable get_glyf_table () {
		return glyf_table;
	}
	
	public long get_font_file_size () {
		long length = 0;
		
		foreach (Table t in tables) {
			length += t.get_font_data ().length_with_padding ();
		}
		
		return length;
	}
	
	public void process_directory () {
		create_directory (); // create directory without offsets to calculate length of offset table and checksum for entre file
		create_directory (); // generate a valid directory
	}

	// Check sum adjustment for the entire font
	public uint32 get_font_file_checksum () {
		uint32 check_sum = 0;
		foreach (Table t in tables) {
			t.get_font_data ().continous_check_sum (ref check_sum);
		}
		return check_sum;
	}

	public void create_directory () {
		FontData fd;
	
		uint32 table_offset = 0;
		uint32 table_length = 0;
		
		uint32 check_sum = 0;
		
		fd = new FontData ();

		return_val_if_fail (offset_table.num_tables > 0, fd);
		
		table_offset += offset_table.get_font_data ().length_with_padding ();
		
		if (this.font_data != null) {
			table_offset += this.get_font_data ().length_with_padding ();
		}

		head_table.set_check_sum_adjustment (0); // Set this to zero, calculate checksums and update the value
		head_table.process ();
		
		// write the directory 
		foreach (Table t in tables) {
						
			if (t is DirectoryTable || t is OffsetTable) {
				continue;
			}
			
			printd (@"c $(t.id)  offset: $(table_offset)  len with pad  $(t.get_font_data ().length_with_padding ())\n");

			table_length = t.get_font_data ().length (); // without padding
			
			fd.add_tag (t.get_id ()); // name of table
			fd.add_u32 (t.get_font_data ().check_sum ());
			fd.add_u32 (table_offset);
			fd.add_u32 (table_length);
			
			table_offset += t.get_font_data ().length_with_padding ();
		}

		// padding
		fd.pad ();
						
		this.font_data = fd;

		check_sum = get_font_file_checksum ();
		head_table.set_check_sum_adjustment ((uint32)(0xB1B0AFBA - check_sum));
		head_table.process (); // update the value		
	}
	
}

// We could benifit greatly from error detection and validation at a fine grained level in
// this class. At some later point should this code present meaningfull info to the user but 
// for now is the approach just to put a lot of info in the console if we need to do some debugging.
void printd (string s) {
	print (s);
}

}
