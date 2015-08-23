/*
    Copyright (C) 2012, 2013, 2014 Johan Mattsson

    This library is free software; you can redistribute it and/or modify 
    it under the terms of the GNU Lesser General Public License as 
    published by the Free Software Foundation; either version 3 of the 
    License, or (at your option) any later version.

    This library is distributed in the hope that it will be useful, but 
    WITHOUT ANY WARRANTY; without even the implied warranty of 
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU 
    Lesser General Public License for more details.
*/

namespace BirdFont {

public class FontData : Object {

	// Read pointer
	uint rp = 0;

	// Write pointer
	uint wp = 0;

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
	
	public int get_read_pos () {
		return (int) rp;
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
			warning ("OtfTable is not padded to correct size.");
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
	
	public void add_u64(uint64 i) {
		uint64 s = (uint32) (i >> 32);
		
		add_u32 ((uint32) s);
		add_u32 ((uint32)(i - (s << 32)));
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
			if (skip_terminating_null && c == '\0') {
				continue;
			}
			
			if (c < 0xFFFF - (1 << 16)) {
				c0 = (uint8) (c >> 8);
				c1 = (uint8) (c - (c0 << 8));
				
				if (little_endian) {
					add (c1);
					add (c0);
				} else {
					add (c0);
					add (c1);
				}
			} else if (c < 0xFFFF - (1 << 16)) {
				int high = (0xFFC00 & c) >> 10;
				int low = (0x03FF & c);
				
				high += 0xD800;
				low += 0xDC00;
				
				c0 = (uint8) (high >> 8);
				c1 = (uint8) (high - (c0 << 8));
				
				if (little_endian) {
					add (c1);
					add (c0);
				} else {
					add (c0);
					add (c1);
				}

				c0 = (uint8) (low >> 8);
				c1 = (uint8) (low - (c0 << 8));
				
				if (little_endian) {
					add (c1);
					add (c0);
				} else {
					add (c0);
					add (c1);
				}
			} else {
				continue;
			}
			
			l += 2;
		}
				
		assert (l == 2 * s.char_count ());
	}
	
	public void add_unichar_utf16 (unichar c) {
		StringBuilder s = new StringBuilder ();
		s.append_unichar (c);
		add_str_utf16 (s.str);
	}
	
	public static uint utf16_strlen (string s) {
		FontData fd = new FontData ();
		fd.add_str_utf16 (s);
		return fd.length_with_padding ();
	}

	public void add_macroman_str (string s) {
		int index = 0;
		unichar c;

		while (s.get_next_char (ref index, out c)) {
			if (32 <= c <= 127) {
				add ((uint8) c);
			} else {
				if (c == 128) add_unichar_utf16 ((unichar) 196);
				if (c == 129) add_unichar_utf16 ((unichar) 197);
				if (c == 130) add_unichar_utf16 ((unichar) 199);
				if (c == 131) add_unichar_utf16 ((unichar) 201);
				if (c == 132) add_unichar_utf16 ((unichar) 209);
				if (c == 133) add_unichar_utf16 ((unichar) 214);
				if (c == 134) add_unichar_utf16 ((unichar) 220);
				if (c == 135) add_unichar_utf16 ((unichar) 225);
				if (c == 136) add_unichar_utf16 ((unichar) 224);
				if (c == 137) add_unichar_utf16 ((unichar) 226);
				if (c == 138) add_unichar_utf16 ((unichar) 228);
				if (c == 139) add_unichar_utf16 ((unichar) 227);
				if (c == 140) add_unichar_utf16 ((unichar) 229);
				if (c == 141) add_unichar_utf16 ((unichar) 231);
				if (c == 142) add_unichar_utf16 ((unichar) 233);
				if (c == 143) add_unichar_utf16 ((unichar) 232);
				if (c == 144) add_unichar_utf16 ((unichar) 234);
				if (c == 145) add_unichar_utf16 ((unichar) 235);
				if (c == 146) add_unichar_utf16 ((unichar) 237);
				if (c == 147) add_unichar_utf16 ((unichar) 236);
				if (c == 148) add_unichar_utf16 ((unichar) 238);
				if (c == 149) add_unichar_utf16 ((unichar) 239);
				if (c == 150) add_unichar_utf16 ((unichar) 241);
				if (c == 151) add_unichar_utf16 ((unichar) 243);
				if (c == 152) add_unichar_utf16 ((unichar) 242);
				if (c == 153) add_unichar_utf16 ((unichar) 244);
				if (c == 154) add_unichar_utf16 ((unichar) 246);
				if (c == 155) add_unichar_utf16 ((unichar) 245);
				if (c == 156) add_unichar_utf16 ((unichar) 250);
				if (c == 157) add_unichar_utf16 ((unichar) 249);
				if (c == 158) add_unichar_utf16 ((unichar) 251);
				if (c == 159) add_unichar_utf16 ((unichar) 252);
				if (c == 160) add_unichar_utf16 ((unichar) 8224);
				if (c == 161) add_unichar_utf16 ((unichar) 176);
				if (c == 162) add_unichar_utf16 ((unichar) 162);
				if (c == 163) add_unichar_utf16 ((unichar) 163);
				if (c == 164) add_unichar_utf16 ((unichar) 167);
				if (c == 165) add_unichar_utf16 ((unichar) 8226);
				if (c == 166) add_unichar_utf16 ((unichar) 182);
				if (c == 167) add_unichar_utf16 ((unichar) 223);
				if (c == 168) add_unichar_utf16 ((unichar) 174);
				if (c == 169) add_unichar_utf16 ((unichar) 169);
				if (c == 170) add_unichar_utf16 ((unichar) 8482);
				if (c == 171) add_unichar_utf16 ((unichar) 180);
				if (c == 172) add_unichar_utf16 ((unichar) 168);
				if (c == 173) add_unichar_utf16 ((unichar) 8800);
				if (c == 174) add_unichar_utf16 ((unichar) 198);
				if (c == 175) add_unichar_utf16 ((unichar) 216);
				if (c == 176) add_unichar_utf16 ((unichar) 8734);
				if (c == 177) add_unichar_utf16 ((unichar) 177);
				if (c == 178) add_unichar_utf16 ((unichar) 8804);
				if (c == 179) add_unichar_utf16 ((unichar) 8805);
				if (c == 180) add_unichar_utf16 ((unichar) 165);
				if (c == 181) add_unichar_utf16 ((unichar) 181);
				if (c == 182) add_unichar_utf16 ((unichar) 8706);
				if (c == 183) add_unichar_utf16 ((unichar) 8721);
				if (c == 184) add_unichar_utf16 ((unichar) 8719);
				if (c == 185) add_unichar_utf16 ((unichar) 960);
				if (c == 186) add_unichar_utf16 ((unichar) 8747);
				if (c == 187) add_unichar_utf16 ((unichar) 170);
				if (c == 188) add_unichar_utf16 ((unichar) 186);
				if (c == 189) add_unichar_utf16 ((unichar) 937);
				if (c == 190) add_unichar_utf16 ((unichar) 230);
				if (c == 191) add_unichar_utf16 ((unichar) 248);
				if (c == 192) add_unichar_utf16 ((unichar) 191);
				if (c == 193) add_unichar_utf16 ((unichar) 161);
				if (c == 194) add_unichar_utf16 ((unichar) 172);
				if (c == 195) add_unichar_utf16 ((unichar) 8730);
				if (c == 196) add_unichar_utf16 ((unichar) 402);
				if (c == 197) add_unichar_utf16 ((unichar) 8776);
				if (c == 198) add_unichar_utf16 ((unichar) 8710);
				if (c == 199) add_unichar_utf16 ((unichar) 171);
				if (c == 200) add_unichar_utf16 ((unichar) 187);
				if (c == 201) add_unichar_utf16 ((unichar) 8230);
				if (c == 202) add_unichar_utf16 ((unichar) 160);
				if (c == 203) add_unichar_utf16 ((unichar) 192);
				if (c == 204) add_unichar_utf16 ((unichar) 195);
				if (c == 205) add_unichar_utf16 ((unichar) 213);
				if (c == 206) add_unichar_utf16 ((unichar) 338);
				if (c == 207) add_unichar_utf16 ((unichar) 339);
				if (c == 208) add_unichar_utf16 ((unichar) 8211);
				if (c == 209) add_unichar_utf16 ((unichar) 8212);
				if (c == 210) add_unichar_utf16 ((unichar) 8220);
				if (c == 211) add_unichar_utf16 ((unichar) 8221);
				if (c == 212) add_unichar_utf16 ((unichar) 8216);
				if (c == 213) add_unichar_utf16 ((unichar) 8217);
				if (c == 214) add_unichar_utf16 ((unichar) 247);
				if (c == 215) add_unichar_utf16 ((unichar) 9674);
				if (c == 216) add_unichar_utf16 ((unichar) 255);
				if (c == 217) add_unichar_utf16 ((unichar) 376);
				if (c == 218) add_unichar_utf16 ((unichar) 8260);
				if (c == 219) add_unichar_utf16 ((unichar) 8364);
				if (c == 220) add_unichar_utf16 ((unichar) 8249);
				if (c == 221) add_unichar_utf16 ((unichar) 8250);
				if (c == 222) add_unichar_utf16 ((unichar) 64257);
				if (c == 223) add_unichar_utf16 ((unichar) 64258);
				if (c == 224) add_unichar_utf16 ((unichar) 8225);
				if (c == 225) add_unichar_utf16 ((unichar) 183);
				if (c == 226) add_unichar_utf16 ((unichar) 8218);
				if (c == 227) add_unichar_utf16 ((unichar) 8222);
				if (c == 228) add_unichar_utf16 ((unichar) 8240);
				if (c == 229) add_unichar_utf16 ((unichar) 194);
				if (c == 230) add_unichar_utf16 ((unichar) 202);
				if (c == 231) add_unichar_utf16 ((unichar) 193);
				if (c == 232) add_unichar_utf16 ((unichar) 203);
				if (c == 233) add_unichar_utf16 ((unichar) 200);
				if (c == 234) add_unichar_utf16 ((unichar) 205);
				if (c == 235) add_unichar_utf16 ((unichar) 206);
				if (c == 236) add_unichar_utf16 ((unichar) 207);
				if (c == 237) add_unichar_utf16 ((unichar) 204);
				if (c == 238) add_unichar_utf16 ((unichar) 211);
				if (c == 239) add_unichar_utf16 ((unichar) 212);
				if (c == 240) add_unichar_utf16 ((unichar) 63743);
				if (c == 241) add_unichar_utf16 ((unichar) 210);
				if (c == 242) add_unichar_utf16 ((unichar) 218);
				if (c == 243) add_unichar_utf16 ((unichar) 219);
				if (c == 244) add_unichar_utf16 ((unichar) 217);
				if (c == 245) add_unichar_utf16 ((unichar) 305);
				if (c == 246) add_unichar_utf16 ((unichar) 710);
				if (c == 247) add_unichar_utf16 ((unichar) 732);
				if (c == 248) add_unichar_utf16 ((unichar) 175);
				if (c == 249) add_unichar_utf16 ((unichar) 728);
				if (c == 250) add_unichar_utf16 ((unichar) 729);
				if (c == 251) add_unichar_utf16 ((unichar) 730);
				if (c == 252) add_unichar_utf16 ((unichar) 184);
				if (c == 253) add_unichar_utf16 ((unichar) 733);
				if (c == 254) add_unichar_utf16 ((unichar) 731);
				if (c == 255) add_unichar_utf16 ((unichar) 711);
			}
		}
	}

	public static uint macroman_strlen (string s) {
		FontData fd = new FontData ();
		fd.add_macroman_str (s);
		return fd.length_with_padding ();
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
	
	public void append (FontData fd) {
		fd.seek (0);
		for (int i = 0; i < fd.length (); i++) {
			add (fd.read ());
		}
	}
	
	public void dump () {
		for (uint32 i = 0; i < length_with_padding (); i++) {
			stdout.printf ("%x " , table_data[i]);
		}
		stdout.printf ("\n");
	}
}

}
