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
		print (@"Calculate size\n");
		long dl;
		uint8[] data;
		uint i = 0;
		long written = 0;
		Glyph? g;
		unowned List<Table> tables;
		unichar indice = 0;
		
		if (!font.has_glyph ("notdef.")) {
			font.create_not_def ();
		}
		
		assert (font.has_glyph ("notdef."));
		
		directory_table.process ();	
		tables = directory_table.get_tables ();

		dl = directory_table.get_font_file_size ();
		
		if (dl == 0) {
			warning ("font is of zero size.");
			return;
		}
		
		data = new uint8[dl];

		foreach (Table t in tables) {
			foreach (uint8 d in t.get_font_data ().data) {
				data[i] = d;
				i++;
			}	
		}
		
		while (written < data.length) {
			written += os.write (data[written:data.length]);
		}
		
		directory_table.cmap_table.get_font_data ().print ();
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

class FontData : Object {

	// Read pointer
	int rp = 0;
	
	// length without pad
	uint32 len = 0;
		
	public List<uint8> data = new List<uint8> ();

	public FontData () {
	}
	
	public void write_table (OtfInputStream dis, uint32 offset, uint32 len) {
		uint32 l = len + len % 4;  // padding after end of table
		
		dis.seek (offset);
	
		for (uint32 i = 0; i < l; i++) {
			add (dis.read_byte ());
		}	
	}
	
	public void print () {
		unowned List<unowned uint8>? u = data;
		
		stdout.printf (@"Table data:\n");
		
		if (u == null) {
			stdout.printf (@"null\n");
			return;
		}
		
		foreach (uint8 d in data) {
			stdout.printf (@"$(d) ");
		}
		
		stdout.printf ("\n");
	}
	
	public uint length_with_padding () {
		return data.length ();
	}	
	
	public uint length () {
		return len;
	}
	
	public void pad () {
		while (data.length () % 4 != 0) {
			data.append (0);
		}	
	}
	
	/** Add additional checksum data to this checksum. */
	public void continous_check_sum (ref uint32 current_check_sum) {
		int trp = rp;
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
	
	public void seek (int i) {
		rp = i;
	}
	
	public uint8 read () {
		return data.nth (rp++).data;
	}
	
	public Fixed read_fixed () {
		return read_uint32 ();
	}

	public uint32 read_uint32 () {
		uint32 f;
		f = read () << 32 - 8 * 1;
		f += read () << 32 - 8 * 2;
		f += read () << 32 - 8 * 3;
		f += read () << 32 - 8 * 4;
		return f;
	}
	
	public void add_udate (int64 d) throws Error {
		add_64 (d);
	}
	
	public void add_fixed (Fixed f) throws Error {
		add_u32 (f);
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
	
	public void add (uint8 d) {
		data.append (d);
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
					
					print (@"glyph_offsets[i]: $(glyph_offsets[i])\n");
					
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
		
		print (@"get_last_glyph_length (): $(get_last_glyph_length ())\n");
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
				
				print (@"o0: $(o)\n");
				
				if (o < last) {
					warning (@"Loca table must be sorted. ($o < $last)");
				}
				
				last = o;
			}
			
		} else if (head_table.loca_offset_size == 1) {
			foreach (uint32 o in glyf_table.location_offsets) {
				fd.add_u32 (o);
				
				print (@"o1: $(o)\n");
				
				if (o < last) {
					warning (@"Loca table must be sorted. ($o < $last)");
				}
				
				last = o;
			}
			
		} else {
			warn_if_reached ();
		}
		
		if (!(glyf_table.location_offsets.length () == font.length ())) {
			warning (@"(glyf_table.location_offsets.length () == font.length ()) ($(glyf_table.location_offsets.length ()) == $(font.length ()))");
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
	
	public GlyfTable (LocaTable l) {
		id = "glyf";
		loca_table = l;
		location_offsets = new List<uint32> ();
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
	
	public void parse (OtfInputStream dis, CmapTable cmap, LocaTable loca, HmtxTable hmtx_table, HeadTable head_table) throws GLib.Error {
		uint32 glyph_offset;
		Glyph glyph = new Glyph ("");
		double xmin, xmax;
		double units_per_em = head_table.get_units_per_em ();
		unichar character = 0;
		StringBuilder name = new StringBuilder ();		

		print (@"loca.size: $(loca.size)\n");
		
		// notdef. character:
		character = cmap.get_char (0);

		if (character != 0) {
			warning ("notdef. has a another value in cmap table");
		}
		
		glyph = parse_next_glyf (dis, 0, 0, out xmin, out xmax, units_per_em);
		glyph.left_limit = 0;
		glyph.right_limit = glyph.left_limit + hmtx_table.get_advance (0);
		glyph.name = "notdef.";
		glyph.set_unassigned (true);		
		add_glyph (glyph);				
		
		for (uint32 i = 1; i < loca.size; i++) {
			try {
				character = cmap.get_char (i);
				name = new StringBuilder ();
				
				if (character == '\0') {
					name.append ("null");
				} else {
					name.append_unichar (character);
				}
				
				print (@"name: $(name.str)\n");
				
				if (!loca.is_empty (i)) {	
					glyph_offset = loca.get_offset(i);
					
					glyph = parse_next_glyf (dis, character, glyph_offset, out xmin, out xmax, units_per_em);
					
					//glyph.left_limit = xmin - hmtx_table.get_lsb (i);
					glyph.left_limit = 0;
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
				
				add_glyph (glyph);
				
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
		
		print (@"PARSE NEXT GLYF\n");
		
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
		// assert (nflags == npoints);

		print (@"npoints: $npoints\n");
		print (@"ncontours: $ncontours\n");
		print (@"ninstructions: $ninstructions\n");
		print (@"nflags: $nflags\n");
				
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
		int16 xmin;
		int16 ymin;
		int16 xmax;
		int16 ymax;

		double gxmin, gymin, gxmax, gymax;

		int16 end_point;
		int16 last_end_point;
		int16 npoints;
		int16 ncontours;
		int16 nflags;
		
		int16 x, y;

		Font font = Supplement.get_current_font ();
		
		// glyph need padding too, but to two byte boundries 
		if (fd.length () % 2 != 0) {
			fd.add (0);
		}
		
		// set values for loca table
		location_offsets.append (fd.length ());
		
		g.remove_empty_paths ();
		
		ncontours = (int16) g.path_list.length ();
		fd.add_short (ncontours);
		
		g.boundries (out gxmin, out gymin, out gxmax, out gymax);
		
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
	}

	public void process () {
		FontData fd = new FontData ();
		uint32 indice;
		Glyph? gl;
		Glyph g;
		Font font = Supplement.get_current_font ();
		
		assert (font.has_glyph ("notdef."));
		
		// add notdef. character at index zero
		gl = font.get_glyph ("notdef.");
		process_glyph ((!)gl, fd);
	
		
		// add glyphs
		for (indice = 0; (gl = font.get_glyph_indice (indice)) != null; indice++) {		
			g = (!) gl;
			
			if (g.name == "notdef.") {
				continue;
			}
			
			process_glyph (g, fd);
		}

		// last entry in loca table
		location_offsets.append (fd.length ());
		
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
		
		print (@"seg_count: $seg_count\n");
		
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
		print (@"length: $length\n");
		print (@"gid_len: $gid_len\n");
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
	
	public void process (FontData fd) {
		GlyphRange glyph_range = new GlyphRange ();
		Font font = Supplement.get_current_font ();
		unowned List<UniRange> ranges;
			
		unichar i = 0;
		Glyph? gl;
		Glyph g;
		
		uint16 seg_count_2;
		uint16 seg_count;
		uint16 search_range;
		uint16 entry_selector;
		uint16 range_shift;				
		
		uint16 gid_length = 0;
		
		uint32 indice;
		
		for (i = 0; (gl = font.get_glyph_indice (i)) != null; i++) {
			g = (!) gl;
			
			if (!g.is_unassigned ()) {
				glyph_range.add_single (g.unichar_code);
			}
		}
		
		glyph_range.print_all ();
		
		ranges = glyph_range.get_ranges ();
		seg_count = (uint16) ranges.length () + 1;
		seg_count_2 =  seg_count * 2;
		search_range = 2 * (2 << (uint16) (Math.log (seg_count) / Math.log (2)));
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
		indice = 0;
		foreach (UniRange u in ranges) {
			if (u.stop >= 0xFFFF) {
				warning ("Not implemented yet.");
			}
			
			fd.add_ushort ((uint16) u.stop);
			indice += u.length ();
		}
		fd.add_ushort (0xFFFF); // Last segment
		
		fd.add_ushort (0); // Reserved
		
		// start codes
		indice = 1; // one since first glyph is notdef.
		foreach (UniRange u in ranges) {
			if (u.start >= 0xFFFF) {
				warning ("Not implemented yet.");
			}
			
			fd.add_ushort ((uint16) u.start);
			indice += u.length ();
		}
		fd.add_ushort (0xFFFF); // Last segment

		// delta
		indice = 1;
		foreach (UniRange u in ranges) {
			
			if ((u.start - indice) > 0xFFFF && u.start > indice) {
				warning ("Need range offset.");
			}
			
			fd.add_ushort ((uint16) (indice - u.start));
			indice += u.length ();
		}
		fd.add_ushort (0); // Last segment
		
		// range offset
		foreach (UniRange u in ranges) {
			if (u.stop <= 0xFFFF) {
				fd.add_ushort (0);
			} else {
				warning ("Not implemented yet.");
			}
		}
		
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

		print (@"cmap version: $version\n");
		print (@"cmap subtables: $nsubtables\n");
				
		if (version != 0) {
			warning (@"Bad version for cmap table: $version expecting 0. Number of subtables: $nsubtables");
			return;
		}
		
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
		print (@"subtable_offset: $(subtable_offset)\n");
		
		fd.add_ulong (subtable_offset);
		cmap.process (fd);

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
	
	uint32 check_sum_adjustment = 0;

	uint16 mac_style;
	uint16 lowest_PPEM;
	int16 font_direction_hint;
		
	public int16 loca_offset_size = 1;
	int16 glyph_data_format;

	Fixed version;
	Fixed font_revision;
	
	uint32 checksum_adjustment;
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
		
		checksum_adjustment = dis.read_ulong ();
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
	
	public void set_check_sum_adjustment (uint32 csa) {
		check_sum_adjustment = csa;
	}
	
	public void process () {
		FontData font_data = new FontData ();
		Fixed version = 1 << 16;

		Fixed font_revision = 0;

		font_data.add_fixed (version);
		font_data.add_fixed (font_revision);
		
		// Zero on the first run and updated by directory tables checksum calculation
		// for the entire font.
		font_data.add_u32 (check_sum_adjustment); // TODO
		
		font_data.add_u32 (0x5F0F3CF5); // magic number
		
		font_data.add_u16 (BASELINE_AT_ZERO | LSB_AT_ZERO); // flags
		
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
		
		print (@"loca_offset_size: $loca_offset_size\n");
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
		
		fd.add_u16 (0); // advanceWidthMax Maximum advance width value in 'hmtx' table.
		
		fd.add_16 (0); // minLeftSideBearing
		fd.add_16 (0); // minRightSideBearing
		fd.add_16 (0); // xMaxExtent Max(lsb + (xMax - xMin))
		
		fd.add_16 (0); // caretSlopeRise
		fd.add_16 (0); // caretSlopeRun
		fd.add_16 (0); // caretOffset
		
		// reserved
		fd.add_16 (0);
		fd.add_16 (0);
		fd.add_16 (0);
		fd.add_16 (0);
		
		fd.add_16 (0); // metricDataFormat 0 for current format.
		
		fd.add_u16 ((uint16) font.length()); // numberOfHMetrics Number of hMetric entries in 'hmtx' table

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
		
	HeadTable head_table;
	
	public HmtxTable (HeadTable h) {
		head_table = h;
		id = "hmtx";
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
			return;
		}
		
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
	
	public void process () {
		FontData fd = new FontData ();
		Font font = Supplement.get_current_font ();
		Glyph g;
		
		// advance and lsb
		for (uint i = 0; i < font.length (); i++) {
			g = (!) font.get_glyph_indice (i);
			fd.add_u16 ((uint16) (g.right_limit - g.left_limit));
			fd.add_16 (0);
		}
		
		// monospaced lsb ...
		
		font_data = fd;
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
		print (@"Maxp version: $(format.get_string ())\n");
		
		num_glyphs = dis.read_ushort ();
		
		if (format.equals (0, 5)) {
			return;
		}
		
		// Format 1.0 continues here
	}
	
	public void process () {
		FontData fd = new FontData();
		Font font = Supplement.get_current_font ();
		uint16 max_points, max_contours;
				
		// Version 0.5 for fonts with cff data and 1.0 for ttf
		fd.add_u16 (0);
		fd.add_u16 (5);
		
		if (font.length () == 0) {
			warning ("Zero glyphs in maxp table.");
		}
		
		fd.add_u16 ((uint16) font.length ()); // numGlyphs in the font

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
		
		version = dis.read_ulong ();
		num_tables = dis.read_ushort ();
		search_range = dis.read_ushort ();
		entry_selector = dis.read_ushort ();
		range_shift = dis.read_ushort ();
		
		print (@"Font file version $(version.get_string ())\n");
		print (@"Number of tables $num_tables\n");		
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
	
	public NameTable () {
		id = "name";
	}
	
	public string get_id () {
		return "name";
	}

	public void process () {	
		FontData fd = new FontData ();
		
		this.font_data = fd;
	}
}

class Os2Table : Table {
	
	public Os2Table () {
		id = "OS/2";
	}
	
	public void process () {
		FontData fd = new FontData ();
		
		fd.add_u16 (4); // USHORT Version 0x0000, 0x0001, 0x0002, 0x0003, 0x0004

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
		fd.add_u16 (0); // USHORT usFirstCharIndex
		fd.add_u16 (0); // USHORT usLastCharIndex

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
	
	public PostTable () {
		id = "post";	
	}
	
	public void process () {
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

		font_data.pad ();
		
		this.font_data = font_data;
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
		hhea_table = new HheaTable (glyf_table, head_table);
		hmtx_table = new HmtxTable (head_table);
		maxp_table = new MaxpTable (glyf_table);
		name_table = new NameTable ();
		os_2_table = new Os2Table (); 
		post_table = new PostTable ();
		
		id = "Directory table";
	}

	public void process () {
		// generate font data
		head_table.process ();
		glyf_table.process ();
		cmap_table.process (glyf_table);
		hhea_table.process ();
		hmtx_table.process ();
		maxp_table.process ();
		name_table.process ();
		os_2_table.process ();
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
			tables.append (glyf_table);
			tables.append (loca_table);
			tables.append (cmap_table);  // The other required tables
			tables.append (hhea_table);
			tables.append (hmtx_table);
			tables.append (maxp_table);
			//tables.append (os_2_table);
			//tables.append (name_table);
			//tables.append (post_table);
		}

		return tables;
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
		
		// FIXA: delete
		FontData fd = new FontData ();
		fd.write_table (dis, cmap_table.offset, cmap_table.length);
		fd.print ();
		
		if (!validate_tables (dis)) {
			warning ("Missing required table or bad checksum.");
			// Fixa: stop processing here, if we want to avoid loading bad fonts
			// return;
		}
		
		head_table.parse (dis);
		hhea_table.parse (dis);
		maxp_table.parse (dis);
		loca_table.parse (dis, head_table, maxp_table);
		hmtx_table.parse (dis, hhea_table, loca_table);
		cmap_table.parse (dis);
		glyf_table.parse (dis, cmap_table, loca_table, hmtx_table, head_table);		
	}
	
	public bool validate_tables (OtfInputStream dis) {
		bool valid = true;

		if (!glyf_table.validate (dis)) {
			warning ("glyf_table has invalid checksum");
			valid = false;
		}
		
		// head checksum is calculated without checksum adjustment for entire file 
		// skip validation for now.
		/*
		if (!head_table.validate (dis)) {
			warning ("head_table has is invalid checksum");
			valid = false;
		}
		*/
		
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
	
		return valid;
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

	public void create_directory () {
		FontData fd;
	
		uint32 table_offset;
		uint32 table_length = 0;
		
		uint32 check_sum = 0;
		
		fd = new FontData ();

		return_val_if_fail (offset_table.num_tables > 0, fd);
		
		table_offset = 0;
		
		table_offset += offset_table.get_font_data ().length_with_padding ();
		table_offset += this.get_font_data ().length_with_padding ();

		head_table.set_check_sum_adjustment (0); // Set this to zero, calculate the sum and update the value

		foreach (Table t in tables) {
			
			print (@"c $(t.id)  offset: $(table_offset)  len with pad  $( t.get_font_data ().length_with_padding ())\n");
			
			if (t is DirectoryTable || t is OffsetTable) {
				continue;
			}
			
			table_length = t.get_font_data ().length (); // without padding
			
			fd.add_tag (t.get_id ()); // name of table
			fd.add_u32 (t.get_font_data ().check_sum ());
			fd.add_u32 (table_offset);
			fd.add_u32 (table_length);
			
			table_offset += t.get_font_data ().length_with_padding ();
		}

		// padding
		fd.pad ();
		
		// Check sum adjustment for the entire font		
		foreach (Table t in tables) {
			if (t is DirectoryTable) {
				fd.continous_check_sum (ref check_sum);
				continue;
			}
			
			t.get_font_data ().continous_check_sum (ref check_sum);
		}
	
		head_table.set_check_sum_adjustment ((uint32)(0xB1B0AFBA - check_sum));
		head_table.process (); // update the value
						
		this.font_data = fd;
	}
	
}

}
