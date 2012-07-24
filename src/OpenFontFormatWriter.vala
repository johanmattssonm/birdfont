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
	
	public void add_glyf (Glyf glyf) {
		directory_table.get_glyf_table ().add (glyf);
	}
	
	private void add_glyph (Glyph glyph) {
		unichar char_code = glyph.get_unichar ();
		Glyf g = new Glyf (char_code);
		Contour contour;
		
		foreach (Path p in glyph.path_list) {
			contour = new Contour (p);
			g.add_contour (contour);
		}
		
		add_glyf (g);
	}
	
	public void write_font_file (Font font) throws Error {
		long dl = directory_table.get_font_file_size ();
		uint8[] data = new uint8[dl];
		uint i = -1;
		long written = 0;
		Glyph? g;
		unowned List<Table> tables;
		unichar indice = 0;
		
		while (true) {
			g = font.get_glyph_indice (indice++);
			
			if (g == null) {
				break;
			}

			add_glyph ((!) g);
		}
		
		tables = directory_table.get_tables ();
		
		foreach (Table t in tables) {
			foreach (uint8 d in t.get_font_data ().data) {
				data[++i] = d;
			}
		}
		
		while (written < data.length) { 
			written += os.write (data[written:data.length]);
		}
	}
	
	public void close () throws Error {
		os.close ();
	}
}

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
		Fixed f = din.read_uint32 ();
		return f;
	}

	public F2Dot14 read_f2dot14 () throws Error {
		F2Dot14 f = din.read_int16 ();
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
}

class Contour : Object {
	
	public List<Coordinate> coordinates;
	
	public Contour (Path path) {
		coordinates = new List<Coordinate> ();
		set_path (path);
	}
		
	void set_path (Path path) {
		Coordinate c;
		
		if (path.points.length () == 0) {
			return;
		}
		
		c = new Coordinate ();
		foreach (EditPoint e in path.points) {
			c.x = (int16) e.x * 1000; // Fixa: do mapping to em-width and int16.MAX, and use em as 1:1 in canvas 
			c.y = (int16) e.y * 1000;
			c.flag = Coordinate.ON_PATH;
			
			coordinates.append (c);
		}
	}
	
	// TODO:
	//void add_phantoms () 
	
	bool is_clockwise (Path path) {
		uint len = path.points.length ();
		return_val_if_fail (len > 0, false);
		
		uint i = 0;
		unowned List<EditPoint> iter = path.points.first ();
		
		double xmax = iter.data.x;
		double ymax = iter.data.y;
		double xmin = iter.data.x;
		double ymin = iter.data.y;
		
		uint i_xmax = i;
		uint i_ymax = i;
		uint i_xmin = i;
		uint i_ymin = i;

		foreach (EditPoint ee in path.points) {

			if (xmax < ee.x) {
				xmax = iter.data.x;
				i_xmax = i;
			}
			
			if (ymax < ee.y) {
				ymax = iter.data.y;
				i_ymax = i;
			}
			
			if (xmin > ee.x) {
				xmin = iter.data.x;
				i_xmin = i;
			}
			
			if (ymin > ee.y) {
				ymin = iter.data.y;
				i_ymin = i;
			}

			i++;
		}
	
		return is_clockwise_extrema (i_xmax, i_ymax, i_xmin, i_ymin);
	}
	
	bool is_clockwise_extrema (uint i_xmax, uint i_ymax, uint i_xmin, uint i_ymin) {
		uint t, i;
		
		for (i = 0; i < 4; i++) {
					
			if (i_ymin <= i_xmin <= i_ymax <= i_xmax) {
				return true;
			}
			
			if (i_ymin <= i_xmax <= i_ymax <= i_xmin) {
				return false;
			}
			
			// shift it 
			t = i_xmin;
			i_xmin = i_ymin;
			i_ymin = i_xmax;
			i_xmax = i_ymax;
			i_ymax = t;
		}

		warn_if_reached ();
		
		return true;
	}

	public uint16 get_end_point () {
		return_val_if_fail (coordinates.length () != 0, 0);
		return coordinates.first ().data.y;
	}
}

class Glyf : Object {

	public List<Contour> contours;
	
	public uint32 char_code;
	
	public Glyf (unichar character_code) {
		char_code = (uint32) character_code;
	}
	
	public uint32 get_char_code () {
		return char_code;
	}
	
	public void add_contour (Contour c) {
		contours.append (c);
	}
	
	/** Get advance with from lsb to begining of next glyph. */
	public uint16 get_width() {
		return 1000; // fixme
	}
	
	/** Get left side bearing, (lsb) */
	public int16 get_left() {
			return -1 * (get_width() / 2); 
	}
	
	public void get_boundries (out int16 xmin, out int16 ymin, out int16 xmax, out int16 ymax) {
		xmin = int16.MAX;
		ymin = int16.MAX;
		xmax = int16.MIN;
		ymax = int16.MIN;
		
		// Fixme we do need to add phantom points
		foreach (var contour in contours) {
			foreach (var v in contour.coordinates) {
				if (v.x < xmin) xmin = v.x;
				if (v.x > xmax) xmax = v.x;
				if (v.y < ymin) ymin = v.y;
				if (v.y > ymax) ymax = v.y;
			}
		}
		
		return;
	}
	
}

class FontData : Object {

	public List<uint8> data;
	
	public FontData () {
	}
	
	public uint length () {
		return data.length ();
	}
	
	/** Add additional checksum data to this checksum. */
	public void continous_check_sum (out uint32 current_check_sum) {
		uint32 val = 0;
		uint8 b = 3;
		
		current_check_sum = 0;
		
		if (data.length () % 4 > 0) {
			stderr.printf("Warning table data is not padded to correct size.\n");
		}
		
		foreach (uint8 v in data) {
			val += v << b*8;
			
			if (b == 0) {
				current_check_sum += val;
				val = 0;
				b = 3;
			}
			
			b--;
		}
	}
	
	public uint32 check_sum () {
		uint32 sum = 0;
		continous_check_sum (out sum);
		return sum;
	}
	
	public void add (uint8 d) {
		data.append (d);
	}
	
	public void add_u16 (uint16 d) {
		uint16 n = d >> 8;
		add ((uint8)n);
		n <<= 8;
		add ((uint8)(d - n));
	}

	public void add_16 (int16 i) {
		add_u16 (i + (uint16.MAX/2));
	}
	
	public void add_u32 (uint32 i) {
		uint32 s = (uint16) (i >> 16);
		
		add_u16 ((uint16) s);
		add_u16 ((uint16) (i - (s << 16)));
	}

	public void add_u64(uint64 i) {
		uint64 s = (uint32) (i >> 32);
		
		add_u32 ((uint32) s);
		add_u32 ((uint32)(i - (s << 32)));		
	}

	public void add_tag (string s) 
		requires (s.length == 4 && s.data.length == 4) {
		
		uint8[] data = s.data;
		for (int n = 0; n < data.length; n++) { 
			add (data[n]);
		}		
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

	public uint8 flag = 0;
	public int16 x = 0;
	public int16 y = 0;
}

class Table : Object {

	public string id = "NO_ID";

	public uint32 checksum = 0;
	public uint32 offset = 0;
	public uint32 length = 0;

	public virtual string get_id () {
		return id;
	}
	
	public virtual FontData get_font_data () {
		warning ("No font data for table.");
		return new FontData ();
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
		uint32 ch = calculate_ckecksum (dis, offset, length, name);
		bool c;
		
		c = (ch != checksum);
		
		if (!c) {
			stderr.printf(@"Checksum does not match data for $(name).\n");
			stderr.printf(@"name: $name, checksum: $checksum, offset: $offset, length: $length\n");
		}
		
		return c;	
	}

	public static uint32 calculate_ckecksum (OtfInputStream dis, uint32 offset, uint32 length, string name) {
		uint32 checksum = 0;
		uint32 val = 0;
		uint8 v;
		uint8 b = 3;
		
		dis.seek (offset);

		if (length % 4 > 0) {
			stderr.printf(@"Warning table data is not padded to correct size in $(name).\n");
		}

		for (uint32 i = 0; i < length; i++) {
			v = dis.read_byte ();
			val += v << b*8;
			
			if (b == 0) {
				checksum += val;
				val = 0;
				b = 3;
			}
			
			b--;
		}
		
		return checksum;
	}
}

class LocaTable : Table {
	
	uint32* glyph_offsets = null;
	public uint32 size = 0;
	
	public LocaTable () {
	}	
	
	~LocaTable () {
		if (glyph_offsets != null) delete glyph_offsets;
	}
	
	public uint32 get_last_glyph_length () {
		return_if_fail (glyph_offsets != null);
		
		if (size == 0) {
			warning ("No glyphs in loca table");
		}
		
		return glyph_offsets[size + 1];
	}
	
	public uint32 get_offset (uint32 i) {
		return_if_fail (glyph_offsets != null);
		
		if (size == 0) {
			warning ("No glyphs in loca table");
		}
		
		if (!(0 <= i < size + 1)) {
			warning (@"No offset for glyph $i. Requires (0 <= $i < $(size + 1)");
		}
		
		return 2 * glyph_offsets [i];
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
		
		if (i == size -1) {
			return get_last_glyph_length () == 0;
		}
		
		return glyph_offsets[i] == glyph_offsets[i + 1];
	}
	
	public void parse (OtfInputStream dis, HeadTable head_table, MaxpTable maxp_table) {
		size = maxp_table.num_glyphs;
		glyph_offsets = new uint32[size + 1];
		
		dis.seek (offset);
		
		print (@"size: $size\n");
		print (@"length: $length\n");
		print (@"length/4-1: $(length / 4 - 1)\n");
		print (@"length/2-1: $(length / 2 - 1)\n");
		print (@"head_table.loca_offset_size: $(head_table.loca_offset_size)\n");
		
		switch (head_table.loca_offset_size) {
			case 0:
				for (long i = 0; i < size + 1; i++) {
					glyph_offsets[i] = dis.read_ushort ();	
					
					if (i > 0 && glyph_offsets[i - 1] > glyph_offsets[i]) {
						warning (@"Invalid loca table, it must be sorted. ($(glyph_offsets[i - 1]) > $(glyph_offsets[i]))");
					}
				} 
				break;
				
			case 1:
				for (long i = 0; i < size + 1; i++) {
					glyph_offsets[i] = 	dis.read_ulong ();
					
					if (i > 0 && glyph_offsets[i - 1] > glyph_offsets[i]) {
						warning (@"Invalid loca table, it must be sorted. ($(glyph_offsets[i - 1]) > $(glyph_offsets[i]))");
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
		
		print (@"get_last_glyph_length (): $(get_last_glyph_length ())\n");
	}
}

class GlyfTable : Table {
	
	public List<Glyf> glyfs = new List<Glyf> (); // FIXA: remove this
	
	public List<Glyph> glyphs = new List<Glyph> ();
	
	FontData? font_data = null;
	
	int16 xmin = int16.MAX; // FIXA: remove these
	int16 ymin = int16.MAX;
	int16 xmax = int16.MIN;
	int16 ymax = int16.MIN;
	
	// Flags for composite glyph
	static const uint16 BOTH_ARE_WORDS = 1 << 0;
	static const uint16 SCALE = 1 << 3;
	static const uint16 RESERVED = 1 << 4;
	static const uint16 MORE_COMPONENTS = 1 << 5;
	static const uint16 SCALE_X_Y = 1 << 6;
	static const uint16 SCALE_WITH_ROTATTION = 1 << 7;
	static const uint16 INSTRUCTIONS = 1 << 8;
	
	public GlyfTable () {
	}	
	
	public void add (Glyf glyf) {
		glyfs.insert_sorted_with_data (glyf, (a, b) => {
				if (a.char_code < b.char_code) return -1;
				if (a.char_code > b.char_code) return 1;
				return 0;				
			});
	}
	
	public void parse (OtfInputStream dis, CmapTable cmap, LocaTable loca, HmtxTable hmtx_table, HeadTable head_table) {
		uint32 glyph_offset;
		Glyph glyph = new Glyph ("");
		double xmin, xmax;
		
		for (uint32 i = 0; i < loca.size; i++) {
			unichar character = 0;
			StringBuilder name = new StringBuilder ();
				
			try {
				character = cmap.get_char (i);
				name = new StringBuilder ();
				name.append_unichar (character);
				
				if (!loca.is_empty (i)) {	
					glyph_offset = loca.get_offset(i);
					
					glyph = parse_next_glyf (dis, character, glyph_offset, out xmin, out xmax, head_table.get_units_per_em ());
					
					glyph.left_limit = xmin - hmtx_table.get_lsb (i);
					glyph.right_limit = glyph.left_limit + hmtx_table.get_advance (i);
					
					if (xmin > glyph.right_limit || xmax < glyph.left_limit) {
						warning (@"Glyph $(name.str) is outside of it's box.");
						glyph.left_limit = xmin;
						glyph.right_limit = xmax;
					}
					
				} else {
					// add empty glyph
					glyph = new Glyph (name.str, character);
					glyph.left_limit = -hmtx_table.get_lsb (i);
					glyph.right_limit = hmtx_table.get_advance (i) - hmtx_table.get_lsb (i);				
				}
				
				if (character == 0 && i != 0) {
					glyph.set_unassigned (true);
				}
				
				glyphs.append (glyph);
				
			} catch (Error e) {
				stderr.printf (@"Cmap length $(cmap.get_length ()) glyfs\n");
				stderr.printf (@"Loca size: $(loca.size)\n");
				stderr.printf (@"Loca offset at $i: $glyph_offset\n");
				stderr.printf (@"Glyph name: $(name.str)\n");
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
				warning (@"Bad endpoint ($(end_points[i]) < $(end_points[i -1])) in glyph $(name.str).");
				error = new BadFormat.PARSE ("Invalid glyf");
				throw error;
			}
		}
		
		if (ncontours > 0) {
			npoints = end_points[ncontours - 1] + 1;
		} else {
			npoints = 0;
		}

		// FIXA: Implement this
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
				
				// Fixa: delete print (@"Repeat flag $repeat\n");
				
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
		
		if (nflags < npoints) {
			warning (@"(nflags != npoints) ($nflags != $npoints)");
			error = new BadFormat.PARSE (@"Wrong number of flags in glyph $(name.str). (nflags != npoints) ($nflags != $npoints)");
		}
		
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
			
			for (; j <= end_points[i]; j++) {

				if (j >= npoints) {
					warning (@"j >= npoints in glyph $(name.str). (j: $j, end_points[i]: $(end_points[i]))");
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
			
			path.close ();
			
			if (path.points.length () > 0 && path.points.last ().data.type == PointType.CURVE) {
				path.points.first ().data.get_left_handle ().set_point_type (PointType.CURVE);
				path.points.first ().data.get_left_handle ().length = 0;
			}
			
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
		
	public string get_id () {
		return "glyf";
	}
	
	public FontData get_font_data () {
		if (font_data != null) return (!) font_data;
		
		FontData fd = new FontData ();
		font_data = fd;
		
		foreach (var g in glyfs) {
			add_glyf_data (g, fd);
		}
		
		// padding
		while (fd.length () % 4 != 0) {
			fd.add(0);
		}

		return fd;
	}

	public void get_boundries (out int16 xmin, out int16 ymin, out int16 xmax, out int16 ymax) {
		get_font_data();
		
		xmin = this.xmin;
		ymin = this.ymin;
		xmax = this.xmax;
		ymax = this.ymax;
	}
	
	private void add_glyf_data (Glyf glyf, FontData fd) {
		uint16 n_instructions = 0;
		int16 n_contours = (int16) glyf.contours.length();
		
		fd.add_16 (n_contours);
		
		add_boundries (glyf, fd);
		
		foreach (var contour in glyf.contours) {
			fd.add_u16 (contour.get_end_point ()); // endPtsOfContour
		}
		
		fd.add_u16 (n_instructions); // TrueType Instruction reference
		
		for (uint16 i = 0; i < n_instructions; i++) {
			fd.add (0); // instruction
		}
		
		foreach (var contour in glyf.contours) {
			add_flags (contour.coordinates, fd); // flags for outline coordinate (flags[n])
		}
		
		foreach (var contour in glyf.contours) {
			add_x_coordinates (contour.coordinates, fd); // X-coordinates 
		}
		
		foreach (var contour in glyf.contours) {
			add_y_coordinates (contour.coordinates, fd); // Y-coordinates
		}
		
	}
	
	private void add_boundries (Glyf glyf, FontData fd) {
		int16 xmin, ymin, xmax, ymax;
		
		glyf.get_boundries (out xmin, out ymin, out xmax, out ymax);
		
		fd.add_16 (xmin);
		fd.add_16 (ymin); 
		fd.add_16 (xmax);
		fd.add_16 (xmax);

		if (this.xmin > xmin) this.xmin = xmin;
		if (this.ymin > ymin) this.ymin = ymin;
		if (this.xmax < xmax) this.xmax = xmax;
		if (this.ymax < ymax) this.ymax = ymax;

	}

	private void add_flags (List<Coordinate> coordinates, FontData fd) {
			foreach (var v in coordinates) {
				fd.add (v.flag);
			}
	}

	private static bool in_flag (uint8 val, uint8 flag) {
		return (val & flag) == val;
	}
	
	private void add_x_coordinates (List<Coordinate> coordinates, FontData fd) {
		int16 last = 0;
		foreach (var v in coordinates) {
			if (in_flag (Coordinate.X_SHORT_VECTOR, v.flag)) {
				fd.add ((uint8) (v.x - last));
			} else {
				fd.add_16 (v.x - last);
			}
			last = v.x;
		}
	}

	private void add_y_coordinates (List<Coordinate> coordinates, FontData fd) {
		int16 last = 0;
		foreach (var v in coordinates) {
			if (in_flag (Coordinate.Y_SHORT_VECTOR, v.flag)) {
				fd.add ((uint8)(v.y - last));
			} else {
				fd.add_16 (v.y - last);
			}
			last = v.y;
		}
	}
		
}

/** Format 4 cmap subtable */
class CmapSubtable : Table {

	public virtual uint get_length () {
		warning ("Invalid CmapSubtable");
		return 0;
	}
	
	public virtual unichar get_char (uint32 i) {
		warning ("Invalid CmapSubtable");
		return 0;
	}
}

class CmapSubtableWindowsUnicode : CmapSubtable {
	uint16 format = 0;
	HashTable <uint64?, unichar> table = new HashTable <uint64?, unichar> (int64_hash, int_equal);
	
	public CmapSubtableWindowsUnicode () {
	}
	
	~CmapSubtableWindowsUnicode () {

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
			
			// FIXA: yes there is for null character
			warning (@"There is no char for glyph number $indice in cmap table. table.size: $(table.size ()))");
			return 0;
		}
		
		return (unichar) c;
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

		print (@"seg_count_x2: $seg_count_x2 \n");
		print (@"seg_count: $seg_count \n");
		print (@"lang: $lang \n");
		print (@"seg_count: $seg_count \n");
		
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

		gid_len = (length - 16 - 8 * seg_count) / 2;
		glyph_id_array = new uint16[gid_len];
		for (int i = 0; i < gid_len; i++) {
			glyph_id_array[i] = dis.read_ushort ();
		}
		
		// map all values in a hashtable
		int indice = 0;
		unichar character = 0;
		uint32 id;
		for (uint16 i = 0; i < seg_count && start_char[i] != 0xFFFF; i++) {
			
			print (@"Insert range $((int)start_char[i]) to $((int)end_char[i]). id_delta[i] $(id_delta[i])  id_range_offset[i] $(id_range_offset[i])\n");
			
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
					
					print (@"$(s.str) -> $indice      j $j  id_delta[i] $(id_delta[i])  id $id gidi  $(glyph_id_array [id])   char: $((uint32)character)\n");
					
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
		
		// it is has a character for every glyph indice
		// assert (validate_subtable ());
	}
	
	public bool validate_subtable () {
		uint32 length = get_length ();
		unichar c;
		unichar prev;
		uint32 i = 0;
		uint32 err = 0;
		StringBuilder s;
		
		c = get_char (i);
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
	FontData? table_data;
	
	List<CmapSubtable> subtables;

	public CmapTable(GlyfTable gt) {
		glyf_table = gt;
		table_data = null;
		subtables = new List<CmapSubtable> ();
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
		
		if (version != 0) {
			warning (@"Bad version for cmap table: $version. Number of subtables: $nsubtables");
			return;
		}
		
		print (@"cmap version: $version\n");
		print (@"cmap subtables: $nsubtables\n");
		
		for (uint i = 0; i < nsubtables; i++) {
			platform = dis.read_ushort ();
			encoding = dis.read_ushort ();
			sub_offset = dis.read_ulong ();	
			
			if (platform == 3 && encoding == 1) {
				print (@"Parsing Unicode BMP (UCS-2) Platform: $platform Encoding: $encoding\n");
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
		}
	}
	
	/** Character to glyph mapping */
	public override FontData get_font_data () {

		// FIXA: need complete rewrite

		if (table_data != null) return (!) table_data;
		
		FontData fd = new FontData ();
		table_data = fd;
		
		List<CmapSubtable> subtables = cmap_sub_tables ();
		uint16 n_encoding_tables = (uint16) subtables.length ();
		uint32 offset;

		uint16 glyph_indice = 0;
			
		fd.add_u16 (0); // table version
		fd.add_u16 (n_encoding_tables);
		
		fd.add_u16 (3); // platform
		fd.add_u16 (10); // Format Unicode UCS-4
		
		offset = fd.data.length () + 4;
		
		fd.add_u32 (offset);
/*
		foreach (CmapSubtable cmap in subtables) {
			uint32 num_chars = cmap.num_chars;
			uint32 table_length = 20 + 2 * num_chars; // of subtable
			uint32 language = 0;
			uint32 start_char_code = cmap.start_char_code;
			
			// Subtable
			fd.add_u16 (cmap.FORMAT_TRIMMED_ARRAY); // Format for this subtable
			fd.add_u16 (0);  // Reserved

			fd.add_u32 (table_length);
			fd.add_u32 (language);
			fd.add_u32 (start_char_code);
			fd.add_u32 (num_chars);
			
			for (int i = 0; i < num_chars; i++) {
				fd.add_u16 (glyph_indice++);
			}
		}
	*/	
		// padding
		while (fd.length () % 4 != 0) {
			fd.add(0);
		}


		return fd;
	}

 // FIXME:
	List<CmapSubtable> cmap_sub_tables () {
		List<CmapSubtable> maps = new List<CmapSubtable> ();
		
		CmapSubtable cmap = new CmapSubtable ();
/*		
		uint32 charcode = 0;
		uint32 last = 0;
		foreach (Glyf g in glyf_table.glyfs) {
				charcode = g.get_char_code ();
				
				if (charcode != last + 1 || last == 0) {	
					cmap = new CmapSubtable ();
					cmap.start_char_code = charcode;
					
					maps.append(cmap);
				}
				
				last = charcode;
				cmap.num_chars++;
				
				assert(maps.length () > 0);
		}
*/		
		return maps;
	}

	CmapSubtable load_cmap_sub_table (OtfInputStream dis, uint32 offset) {
		CmapSubtable cmap = new CmapSubtable ();
		
		uint32 charcode = 0;
		uint32 last = 0;
		uint32 format;
		
		format = dis.read_ushort ();
		
		print ("Cmap subtable format $format.\n");
		
		return cmap;
	}
}

class HeadTable : Table {
	
	int16 xmin = 0;
	int16 ymin = 0;
	int16 xmax = 0;
	int16 ymax = 0;
	
	uint32 check_sum_adjustment = 0;

	uint16 mac_style;
	uint16 lowest_PPEM;
	int16 font_direction_hint;
		
	public int16 loca_offset_size;
	int16 glyph_data_format;
	
	uint16 units_per_em = 0;
	
	GlyfTable glyf_table;
	
	public HeadTable (GlyfTable gt) {
		glyf_table = gt;
	}
	
	public double get_units_per_em () {
		return units_per_em * 10; // Fixa: we can refactor this number
	}
	
	public override void parse (OtfInputStream dis) 
		requires (offset > 0 && length > 0) {
			
		Fixed version;
		Fixed font_revision;
		
		uint32 checksum_adjustment;
		uint32 magic_number;
		
		uint16 flags;
		
		uint64 created;
		uint64 modified;
		
		List<CmapSubtable> maps = new List<CmapSubtable> ();

		dis.seek (offset);
	
		version = dis.read_fixed ();
		print (@"Version: $(version.get_string ())\n");
		
		if (!version.equals (1, 0)) {
			warning ("Expecting head version 1.0");
			return;
		}
		
		font_revision = dis.read_fixed ();
		
		checksum_adjustment = dis.read_ulong ();
		magic_number = dis.read_ulong ();
		
		if (magic_number != 0x5F0F3CF5) {
			warning (@"Magic number is invalid. Got $(magic_number).");
			return;
		}
		
		flags = dis.read_ushort ();
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
			warning ("Unknown glyph data format.");
		}
		
		print (@"Units per em: $units_per_em\n");

		// Some deprecated values follow here ...
	}	
	
	public string get_id () {
			return "head";
	}
	
	public void set_check_sum_adjustment (uint32 csa) {
		check_sum_adjustment = csa;
	}
	
	public FontData get_font_data () {
		
		FontData font_data = new FontData ();
		
		font_data.add_u16 (1); // table version
		font_data.add_u16 (0);
		
		// font revision
		font_data.add_u16 (0);
		font_data.add_u16 (0);
		
		// Zero on the first run and updated by directory tables checksum calculation
		// for the entire font.
		font_data.add_u32 (check_sum_adjustment); // TODO
		
		font_data.add_u32 (0x5F0F3CF5); // magic number
		
		font_data.add_u16 (0); // clear flags
		
		font_data.add_u16 (2048); // units per em (in power of two for ttf)
		
		font_data.add_u64 (0); //creation time since 1904-01-01
		font_data.add_u64 (0); //modified time since 1904-01-01
		
		glyf_table.get_boundries(out xmin, out ymin, out xmax, out ymax);
		
		font_data.add_16 (xmin);
		font_data.add_16 (ymin);
		font_data.add_16 (xmax);
		font_data.add_16 (ymax);
		
		font_data.add_u16 (0); // mac style
		font_data.add_u16 (0); // smallest recommended size in pixels
		font_data.add_u16 (2); // Deprecated direction hint
		font_data.add_16 (1);  // Long offset
		font_data.add_16 (0);  // Use current glyph data format

		// padding
		while (font_data.length () % 4 != 0) {
			font_data.add(0);
		}
		
		return font_data;
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
	
	public HheaTable (GlyfTable g, HeadTable h) {
		glyf_table = g;
		head_table = h;
	}
	
	public string get_id () {
			return "head";
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
		
		warn_if_fail (version.equals (1, 0));
		
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
	
	public FontData get_font_data () {
		FontData font_data = new FontData ();

		font_data.add_u16 (1); // table version
		font_data.add_u16 (0);
		
		font_data.add_16 (0); // Ascender Typographic ascent.
		font_data.add_16 (0); // Descender
		font_data.add_16 (0); // LineGap
		
		font_data.add_u16 (0); // advanceWidthMax Maximum advance width value in 'hmtx' table.
		
		font_data.add_16 (0); // minLeftSideBearing
		font_data.add_16 (0); // minRightSideBearing
		font_data.add_16 (0); // xMaxExtent Max(lsb + (xMax - xMin))
		
		font_data.add_16 (0); // caretSlopeRise
		font_data.add_16 (0); // caretSlopeRun
		font_data.add_16 (0); // caretOffset
		
		// reserved
		font_data.add_16 (0);
		font_data.add_16 (0);
		font_data.add_16 (0);
		font_data.add_16 (0);
		
		font_data.add_16 (0); // metricDataFormat 0 for current format.
		
		font_data.add_u16 ((uint16)glyf_table.glyfs.length()); // numberOfHMetrics Number of hMetric entries in 'hmtx' table

		// hmtx - Horizontal metrix (Own table?)
		foreach (var g in glyf_table.glyfs) {
			font_data.add_u16 (g.get_width());
			font_data.add_16 (g.get_left());
		}
		
		// hmtx for monospaced glyphs
		// ... none right now

		// padding
		while (font_data.length () % 4 != 0) {
			font_data.add(0);
		}
		
		return font_data;
	}
}

class HmtxTable : Table {
	
	uint32 nmetrics;
	uint32 nmonospaced;
		
	uint16* advance_width = null;
	uint16* left_side_bearing = null;
	uint16* left_side_bearing_monospaced = null;
		
	HeadTable head_table;
	
	public HmtxTable (HeadTable h) {
		head_table = h;
	}
	
	~HmtxTable () {
		if (advance_width != null) delete advance_width;
		if (left_side_bearing != null) delete left_side_bearing; 
	}

	public double get_advance (uint32 i) {
		return_if_fail (i < nmetrics);
		return_if_fail (advance_width != null);
		
		return advance_width[i] * 1000 / head_table.get_units_per_em ();
	}
		
	/** Get left side bearing relative to xmin. */
	public double get_lsb (uint32 i) {
		return_if_fail (i < nmetrics);
		return_if_fail (left_side_bearing != null);
		
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
		}
		
		print (@"$(loca_table.size) - $nmetrics\n");
		print (@"nmetrics: $nmetrics, nmonospaced: $nmonospaced\n");
		
		advance_width = new uint16[nmetrics];
		left_side_bearing = new uint16[nmetrics];
		left_side_bearing_monospaced = new uint16[nmonospaced];
		
		for (int i = 0; i < nmetrics; i++) {
			advance_width[i] = dis.read_ushort ();
			left_side_bearing[i] = dis.read_short ();
		}
		
		for (int i = 0; i < nmonospaced; i++) {
			left_side_bearing_monospaced[i] = dis.read_short ();
		}
	}
	
	public FontData get_font_data () {
		FontData font_data = new FontData ();
		
		// FIXA:
		
		return font_data;
	}
}


class MaxpTable : Table {
	
	GlyfTable glyf_table;
	
	public uint16 num_glyphs = 0;
	
	public MaxpTable (GlyfTable g) {
		glyf_table = g;
	}
	
	public string get_id () {
			return "maxp";
	}
	
	public override void parse (OtfInputStream dis) 
		requires (offset > 0 && length > 0) {
		Fixed format;
		
		dis.seek (offset);
		
		format = dis.read_fixed ();
		print (@"Maxp version: $(format.get_string ())\n");
		
		num_glyphs = dis.read_ushort ();
		
		if (format.equals (0, 5)) {
			return;
		}
		
		// Format 1.0 continues here
	}
	
	public FontData get_font_data () {
		FontData font_data = new FontData();
		
		// Version 0.5 for fonts with cff data and 1.0 for ttf
		font_data.add_u16 (1);
		font_data.add_u16 (0);
		
		uint16 max_points, max_contours;
		
		get_max (out max_points, out max_contours);
		
		font_data.add_u16 ((uint16)glyf_table.glyfs.length ()); // numGlyphs in the font
		font_data.add_u16 (max_points);
		font_data.add_u16 (max_contours); // maxContours Maximum contours in a non-composite glyph.
		font_data.add_u16 (0); // maxCompositePoints Maximum points in a composite glyph.
		font_data.add_u16 (0); // maxCompositeContours Maximum contours in a composite glyph.
		font_data.add_u16 (2); // maxZones 1 if instructions do not use the twilight zone (Z0), or 2 if instructions do use Z0; should be set to 2 in most cases.
		font_data.add_u16 (0); // maxTwilightPoints Maximum points used in Z0.
		font_data.add_u16 (0); // maxStorage Number of Storage Area locations.
		font_data.add_u16 (0); // maxFunctionDefs Number of FDEFs.
		font_data.add_u16 (0); // maxInstructionDefs Number of IDEFs.
		font_data.add_u16 (0); // maxStackElements Maximum stack depth2.
		font_data.add_u16 (0); // maxSizeOfInstructions Maximum byte count for glyph instructions.
		font_data.add_u16 (0); // maxComponentElements Maximum number of components referenced at "top level" for any
		font_data.add_u16 (0); // maxComponentDepth Maximum levels of recursion; 1 for simple components.		

		// padding
		while (font_data.length () % 4 != 0) {
			font_data.add(0);
		}
	
		return font_data;
	}

	private void get_max (out uint16 max_points, out uint16 max_contours) {
		max_points = 0;
		max_contours = 0;
		
		foreach (var g in glyf_table.glyfs) {
			uint16 p = 0;
			
			if (g.contours.length() > max_contours) {
				max_contours = (uint16) g.contours.length();
			}
			
			foreach (var c in g.contours) {
				p += (uint16) c.coordinates.length();
			}
			
			if (p > max_points) max_points = p;
		}
		
	}

}

class OffsetTable : Table {
	public uint16 num_tables = 0;
	uint16 search_range = 0;
	uint16 entry_selector = 0;
	uint16 range_shift = 0;
		
	public OffsetTable () {
	}
	
	public void set_num_tables (uint n) {
		num_tables = (uint16) n;
	}
	
	public string get_id () {
			// warn_if_reached ();
			return "Offset table";
	}
	
	public void parse (OtfInputStream dis) throws Error {
		Fixed version;
		
		version = dis.read_ulong ();
		num_tables = dis.read_ushort ();
		search_range = dis.read_ushort ();
		entry_selector = dis.read_ushort ();
		range_shift = dis.read_ushort ();
		
		print (@"Version $(version.get_string ())\n");
		print (@"Number of tables $num_tables\n");		
	}
	
	public FontData get_font_data () {
		FontData fd = new FontData ();

		// version 1.0 for TTF CFF else use OTTO
		fd.add_u16 (1);
		fd.add_u16 (0);

		fd.add_u16 (num_tables);
		fd.add_u16 (search_range);
		fd.add_u16 (entry_selector);		
		fd.add_u16 (range_shift);		

		// padding
		while (fd.length () % 4 != 0) {
			fd.add(0);
		}
		
		return fd;
	}
}

class NameTable : Table {
	
	public NameTable () {	
	}
	
	public string get_id () {
		return "name";
	}
	
	public FontData get_font_data () {
		// TODO: Apple table versioning of font data
		
		FontData font_data = new FontData ();
		
		font_data.add_u16 (0); // Format selector
		font_data.add_u16 (0); // Number of name records.
		font_data.add_u16 (6); // Offset to start of string storage (from start of table).
		
		// ...

		// padding
		while (font_data.length () % 4 != 0) {
			font_data.add(0);
		}
		
		return font_data;
	}

}

class Os2Table : Table {
	
	public Os2Table () {	
	}
	
	public string get_id () {
		return "OS/2";
	}
	
	public FontData get_font_data () {
		FontData font_data = new FontData ();
		
		font_data.add_u16 (4); // USHORT Version 0x0000, 0x0001, 0x0002, 0x0003, 0x0004

		font_data.add_16 (0); // SHORT xAvgCharWidth

		font_data.add_u16 (0); // USHORT usWeightClass
		font_data.add_u16 (0); // USHORT usWidthClass
		font_data.add_u16 (0); // USHORT fsType

		font_data.add_16 (0); // SHORT ySubscriptXSize
		font_data.add_16 (0); // SHORT ySubscriptYSize
		font_data.add_16 (0); // SHORT ySubscriptXOffset
		font_data.add_16 (0); // SHORT ySubscriptYOffset
		font_data.add_16 (0); // SHORT ySuperscriptXSize
		font_data.add_16 (0); // SHORT ySuperscriptYSize
		font_data.add_16 (0); // SHORT ySuperscriptXOffset
		font_data.add_16 (0); // SHORT ySuperscriptYOffset
		font_data.add_16 (0); // SHORT yStrikeoutSize
		font_data.add_16 (0); // SHORT yStrikeoutPosition
		font_data.add_16 (0); // SHORT sFamilyClass

		// PANOSE
		font_data.add (0); 
		font_data.add (0); 
		font_data.add (0); 
		font_data.add (0); 
		font_data.add (0); 
		font_data.add (0); 
		font_data.add (0); 
		font_data.add (0); 
		font_data.add (0); 
		font_data.add (0); 

		font_data.add_u32 (0); // ulUnicodeRange1 Bits 0-31
		font_data.add_u32 (0); // ULONG ulUnicodeRange2 Bits 32-63
		font_data.add_u32 (0); // ULONG ulUnicodeRange3 Bits 64-95
		font_data.add_u32 (0); // ULONG ulUnicodeRange4 Bits 96-127

		font_data.add_tag ("----"); // VendID

		font_data.add_u16 (0); // USHORT fsSelection
		font_data.add_u16 (0); // USHORT usFirstCharIndex
		font_data.add_u16 (0); // USHORT usLastCharIndex

		font_data.add_16 (0); // SHORT sTypoAscender
		font_data.add_16 (0); // SHORT sTypoDescender
		font_data.add_16 (0); // SHORT sTypoLineGap

		font_data.add_u16 (0); // USHORT usWinAscent
		font_data.add_u16 (0); // USHORT usWinDescent

		font_data.add_u32 (0); // ULONG ulCodePageRange1 Bits 0-31
		font_data.add_u32 (0); // ULONG ulCodePageRange2 Bits 32-63

		font_data.add_16 (0); // SHORT sxHeight version 0x0002 and later
		font_data.add_16 (0); // SHORT sCapHeight version 0x0002 and later

		font_data.add_16 (0); // USHORT usDefaultChar version 0x0002 and later
		font_data.add_16 (0); // USHORT usBreakChar version 0x0002 and later
		font_data.add_16 (0); // USHORT usMaxContext version 0x0002 and later

		// padding
		while (font_data.length () % 4 != 0) {
			font_data.add(0);
		}
	
		return font_data;
	}

}

class PostTable : Table {
	
	public PostTable () {	
	}
	
	public string get_id () {
		return "post";
	}
	
	public FontData get_font_data () {
		FontData font_data = new FontData ();
		
		// Version
		font_data.add_u16 (3);
		font_data.add_u16 (0);

		// italicAngle
		font_data.add_u16 (0); 
		font_data.add_u16 (0);
		
		font_data.add_16 (-2); // underlinePosition
		font_data.add_16 (1); // underlineThickness

		font_data.add_u32 (0); // non zero for monospaced font
		
		// mem boundries may be omitted
		font_data.add_u32 (0); // min mem
		font_data.add_u32 (0); // max mem
		
		font_data.add_u32 (0); // min mem for Type1
		font_data.add_u32 (0); // max mem for Type1

		// padding
		while (font_data.length () % 4 != 0) {
			font_data.add(0);
		}
		
		return font_data;
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
	
	OffsetTable offset_table;
	
	List<Table> tables; // Fixa: remove this
				
	public DirectoryTable () {

		offset_table = new OffsetTable ();
		
		glyf_table = new GlyfTable ();
		cmap_table = new CmapTable (glyf_table);
		head_table = new HeadTable (glyf_table);
		hhea_table = new HheaTable (glyf_table, head_table);
		hmtx_table = new HmtxTable (head_table);
		maxp_table = new MaxpTable (glyf_table);
		name_table = new NameTable ();
		os_2_table = new Os2Table (); 
		post_table = new PostTable ();
		loca_table = new LocaTable ();
		
		tables = new List<Table> ();
	}

	public void set_offset_table (OffsetTable ot) {
		offset_table = ot;
	}
	
	public void parse (OtfInputStream dis) throws Error {
		StringBuilder tag = new StringBuilder ();
		uint32 checksum;
		uint32 offset;
		uint32 length;
		
		return_if_fail (offset_table.num_tables > 0);
		
		for (unowned List<Table> t = tables.first (); t != t.last (); t = t.next) {
			tables.remove_link (t);
		}
		
		for (uint i = 0; i < offset_table.num_tables; i++) {
			tag.erase ();
			
			tag.append_unichar ((unichar) dis.read_byte ());
			tag.append_unichar ((unichar) dis.read_byte ());
			tag.append_unichar ((unichar) dis.read_byte ());
			tag.append_unichar ((unichar) dis.read_byte ());
			
			checksum = dis.read_ulong ();
			offset = dis.read_ulong ();
			length = dis.read_ulong ();
			
			print (@"$(tag.str) \toffset: $offset \tlength: $length \tchecksum: $checksum.\n");
			
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
			}
		}
		
		if (!head_table.validate (dis) || !maxp_table.validate (dis) 
			|| !loca_table.validate (dis) || !cmap_table.validate (dis) 
			|| !glyf_table.validate (dis) || !hhea_table.validate (dis)
			|| !hmtx_table.validate (dis))
		{
			warning ("Missing required table");
			return;
		}
		
		head_table.parse (dis);
		hhea_table.parse (dis);
		maxp_table.parse (dis);
		loca_table.parse (dis, head_table, maxp_table);
		hmtx_table.parse (dis, hhea_table, loca_table);
		cmap_table.parse (dis);
		glyf_table.parse (dis, cmap_table, loca_table, hmtx_table, head_table);		
	}
	
	public string get_id () {
		warning ("Don't write id for table directory.");		
		return "Directory table"; // Table id should be ignored for directory table, none the less it has one declared here.
	}
	
	public unowned List<Table> get_tables () {
		return tables;
	}
	
	public GlyfTable get_glyf_table () {
		return glyf_table;
	}
	
	public long get_font_file_size () {
		long length = offset_table.get_font_data ().length ();
		
		foreach (Table t in tables) {
			length += t.get_font_data ().length ();
		}
		
		return length;
	}
	
	public FontData get_font_data () {
		FontData fd = new FontData ();
		
		uint32 table_offset = 0;
		uint32 table_length = 0;
		
		uint32 check_sum = 0;

		// FIXA: clear tables here 

		tables.append (offset_table); // The the directory index tables
		tables.append (this);
		
		tables.append (cmap_table);  // The other required tables
		tables.append (glyf_table);
		tables.append (head_table);
		tables.append (hhea_table);
		tables.append (maxp_table);
		tables.append (name_table);
		tables.append (os_2_table);
		tables.append (post_table);

		offset_table.set_num_tables (tables.length () - 2); // number of tables, skip DirectoryTable and OffsetTable
		
		return_val_if_fail (offset_table.num_tables > 0, fd);
		
		table_offset += offset_table.get_font_data ().length ();
		
		head_table.set_check_sum_adjustment (0);
						
		foreach (Table t in tables) {
			
			if (t is DirectoryTable || t is OffsetTable) {
				continue;
			}
			
			table_length = t.get_font_data ().length ();
			
			fd.add_tag (t.get_id ()); // name of table
			fd.add_u32 (t.get_font_data ().check_sum ());
			fd.add_u32 (table_offset);
			fd.add_u32 (table_length);
			
			table_offset += table_length;
		}

		// padding
		while (fd.length () % 4 != 0) {
			fd.add(0);
		}
		
		// Check sum adjustment for the entire font		
		foreach (Table t in tables) {
			
			if (t is DirectoryTable) {
				fd.continous_check_sum (out check_sum);
				continue;
			}
			
			t.get_font_data ().continous_check_sum (out check_sum);
		}
	
		head_table.set_check_sum_adjustment ((uint32)(0xB1B0AFBA - check_sum));
		
		return fd;
	}
	
}

}
