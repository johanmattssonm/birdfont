/*
    Copyright (C) 2012, 2013 Johan Mattsson

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

namespace BirdFont {

class FontData : Object {

	// Read pointer
	uint rp = 0;

	// Write pointer
	uint wp = 0;
	
	// length without padding
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
	
	public void write_at (uint pos, uint8 new_data) throws GLib.Error
		requires (pos <= capacity) 
	{		
		if (unlikely (pos >= len)) {
			warning ("end of table reached");
			assert (false);
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
		
		return;
	}

	public uint32 check_sum () {
		uint32 sum = 0;
		continous_check_sum (ref sum);
		return sum;
	}
	
	public void seek_end () {
		seek (len);
	}
		
	public void seek (uint i) {
		rp = i;
		wp = i;
	}

	public void seek_relative (uint i) {
		rp += i;
		wp += i;
	}

	/** Returns true if next byte is a CFF operator */
	public bool next_is_operator () {
		uint8 o = read ();
		seek_relative (-1);
		return (0 <= o <=21);
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

	public uint16 read_ushort () {
		uint16 f;
		f = read () << 8;
		f += read ();
		return f;
	}
	
	public int16 read_int16 () {
		int16 f;
		f = read () << 8;
		f += read ();
		return f;		
	}
	
	public int16 read_short () throws Error {
		return read_int16 ();
	}
	
	public uint32 read_uint32 () {
		uint32 f;
		f = read () << 8 * 3;
		f += read () << 8 * 2;
		f += read () << 8 * 1;
		f += read () << 8 * 0;
		return f;
	}

	public uint64 read_uint64 () {
		uint64 f;
		f = (uint64) read () << 8 * 7;
		f += (uint64) read () << 8 * 6;
		f += (uint64) read () << 8 * 5;
		f += (uint64) read () << 8 * 4;
		f += (uint64) read () << 8 * 3;
		f += (uint64) read () << 8 * 2;
		f += (uint64) read () << 8 * 1;
		f += (uint64) read () << 8 * 0;
		return f;
	}

	public F2Dot14 read_f2dot14 () throws Error {
		F2Dot14 f = (F2Dot14) read_int16 ();
		return f;
	}

	public uint64 read_udate () throws Error {
		return read_uint64 ();
	}

	public uint8 read_byte () throws Error {
		return read ();
	}

	public char read_char () throws Error {
		return (char) read_byte ();
	}

	public string read_string (uint length) throws Error {
		StringBuilder str = new StringBuilder ();
		char c;
		for (int i = 0; i < length; i++) {
			c = read_char ();
			str.append_c (c);
		}
		return str.str;
	}

	public int read_charstring_value () throws Error {
		uint8 a, b;
		a = read ();
		
		if (32 <= a <= 246) {
			return a - 139;
		}
		
		b = read ();
		
		if (247 <= a <= 250) {	
			return (a - 247) * 256 + b + 108;
		}
		
		if (251 <= a <= 254) {
			return -((a - 251) * 256) - b - 108;
		}

		if (a == 255) {
			// Implement it
			warning ("fractions not implemented yet.");
		}

		stderr.printf (@"unexpected value: $a\n");
		warn_if_reached ();
		return 0;
	}
	
	public void add_fixed (Fixed f) throws Error {
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

		if (wp == len) {
			len++;
		}
				
		wp++;
	}

	public void add_littleendian_u16 (uint32 i) {
		add ((int8) (i & 0x00FF));
		add ((int8) ((i & 0xFF00) >> 8));
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

	public void add_littleendian_u32 (uint32 i) {
		add ((int8) (i & 0x000000FF));
		add ((int8) ((i & 0x0000FF00) >> 8));
		add ((int8) ((i & 0x00FF0000) >> 16));
		add ((int8) ((i & 0xFF000000) >> 24));
	}
		
	public void add_u32 (uint32 i) {
		uint32 s = (uint16) (i >> 16);
		
		add_u16 ((uint16) s);
		add_u16 ((uint16) (i - (s << 16)));
	}

	public void add_64(int64 i) {
		int64 s = (int32) (i >> 32);
		
		add_u32 ((int32) s);
		add_u32 ((int32)(i - (s << 32)));		
	}
	
	public void add_str_littleendian_utf16 (string s) {
		add_str_utf16 (s, true);
	}
	
	public void add_str_utf16 (string s, bool little_endian = false) {
		int index = 0;
		unichar c;
		uint8 c0;
		uint8 c1;
		int l = 0;
		
		while (s.get_next_char (ref index, out c)) {
			c0 = (uint8) (c >> 8);
			c1 = (uint8) (c - (c0 << 8));
			
			if (little_endian) {
				add (c1);
				add (c0);
			} else {
				add (c0);
				add (c1);
			}
			
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

	public void add_charstring_value (int v) throws Error {
		int w;
		uint8 t;
		
		if (unlikely (!(-1131 <= v <= 1131))) {
			warning ("charstring value out of range");
			v = 0;		
		}
		
		if (-107 <= v <= 107) {
			add_byte ((uint8) (v + 139));
		} else if (107 < v <= 1131) {
			// positive value
			w = v;
			v -= 108;
			
			t = 0;
			while (v >= 256) {
				v -= 256;
				t++;
			}
			
			add_byte (t + 247);
			add_byte ((uint8) (w - 108 - (t * 256)));		
		} else if (-1131 <= v < -107) {
			// negative value
			v = -v - 108;
			add_byte ((uint8) ((v >> 8) + 251));
			add_byte ((uint8) (v & 0xFF));
		} else {
			// Todo add fraction
		}
	}
}

}
