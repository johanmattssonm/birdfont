/*
    Copyright (C) 2012 2013 2014 2015 Johan Mattsson

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
	
	public uint offset = 0; // for debugging
	
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
	public void continous_checksum (ref uint32 current_checksum) {
		uint trp = rp;
		uint l;
		
		if (length_with_padding () % 4 != 0) {
			warning ("OtfTable is not padded to correct size.");
		}
				
		seek (0);

		l = (length () % 4 > 0) ? length () / 4 + 1 : length () / 4; 

		for (uint32 i = 0; i < l; i++) {
			current_checksum += read_uint32 ();
		}
		
		rp = trp;
		
		return;
	}

	public uint32 checksum () {
		uint32 sum = 0;
		continous_checksum (ref sum);
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
			if (c <= 0x7FFF) {
				c0 = (uint8) (c >> 8);
				c1 = (uint8) (c - (c0 << 8));
				
				if (little_endian) {
					add (c1);
					add (c0);
				} else {
					add (c0);
					add (c1);
				}
			} else if (c <= 0xFFFFF) {
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
				if (c == 196) add ((uint8) 128);
				if (c == 197) add ((uint8) 129);
				if (c == 199) add ((uint8) 130);
				if (c == 201) add ((uint8) 131);
				if (c == 209) add ((uint8) 132);
				if (c == 214) add ((uint8) 133);
				if (c == 220) add ((uint8) 134);
				if (c == 225) add ((uint8) 135);
				if (c == 224) add ((uint8) 136);
				if (c == 226) add ((uint8) 137);
				if (c == 228) add ((uint8) 138);
				if (c == 227) add ((uint8) 139);
				if (c == 229) add ((uint8) 140);
				if (c == 231) add ((uint8) 141);
				if (c == 233) add ((uint8) 142);
				if (c == 232) add ((uint8) 143);
				if (c == 234) add ((uint8) 144);
				if (c == 235) add ((uint8) 145);
				if (c == 237) add ((uint8) 146);
				if (c == 236) add ((uint8) 147);
				if (c == 238) add ((uint8) 148);
				if (c == 239) add ((uint8) 149);
				if (c == 241) add ((uint8) 150);
				if (c == 243) add ((uint8) 151);
				if (c == 242) add ((uint8) 152);
				if (c == 244) add ((uint8) 153);
				if (c == 246) add ((uint8) 154);
				if (c == 245) add ((uint8) 155);
				if (c == 250) add ((uint8) 156);
				if (c == 249) add ((uint8) 157);
				if (c == 251) add ((uint8) 158);
				if (c == 252) add ((uint8) 159);
				if (c == 8224) add ((uint8) 160);
				if (c == 176) add ((uint8) 161);
				if (c == 162) add ((uint8) 162);
				if (c == 163) add ((uint8) 163);
				if (c == 167) add ((uint8) 164);
				if (c == 8226) add ((uint8) 165);
				if (c == 182) add ((uint8) 166);
				if (c == 223) add ((uint8) 167);
				if (c == 174) add ((uint8) 168);
				if (c == 169) add ((uint8) 169);
				if (c == 8482) add ((uint8) 170);
				if (c == 180) add ((uint8) 171);
				if (c == 168) add ((uint8) 172);
				if (c == 8800) add ((uint8) 173);
				if (c == 198) add ((uint8) 174);
				if (c == 216) add ((uint8) 175);
				if (c == 8734) add ((uint8) 176);
				if (c == 177) add ((uint8) 177);
				if (c == 8804) add ((uint8) 178);
				if (c == 8805) add ((uint8) 179);
				if (c == 165) add ((uint8) 180);
				if (c == 181) add ((uint8) 181);
				if (c == 8706) add ((uint8) 182);
				if (c == 8721) add ((uint8) 183);
				if (c == 8719) add ((uint8) 184);
				if (c == 960) add ((uint8) 185);
				if (c == 8747) add ((uint8) 186);
				if (c == 170) add ((uint8) 187);
				if (c == 186) add ((uint8) 188);
				if (c == 937) add ((uint8) 189);
				if (c == 230) add ((uint8) 190);
				if (c == 248) add ((uint8) 191);
				if (c == 191) add ((uint8) 192);
				if (c == 161) add ((uint8) 193);
				if (c == 172) add ((uint8) 194);
				if (c == 8730) add ((uint8) 195);
				if (c == 402) add ((uint8) 196);
				if (c == 8776) add ((uint8) 197);
				if (c == 8710) add ((uint8) 198);
				if (c == 171) add ((uint8) 199);
				if (c == 187) add ((uint8) 200);
				if (c == 8230) add ((uint8) 201);
				if (c == 160) add ((uint8) 202);
				if (c == 192) add ((uint8) 203);
				if (c == 195) add ((uint8) 204);
				if (c == 213) add ((uint8) 205);
				if (c == 338) add ((uint8) 206);
				if (c == 339) add ((uint8) 207);
				if (c == 8211) add ((uint8) 208);
				if (c == 8212) add ((uint8) 209);
				if (c == 8220) add ((uint8) 210);
				if (c == 8221) add ((uint8) 211);
				if (c == 8216) add ((uint8) 212);
				if (c == 8217) add ((uint8) 213);
				if (c == 247) add ((uint8) 214);
				if (c == 9674) add ((uint8) 215);
				if (c == 255) add ((uint8) 216);
				if (c == 376) add ((uint8) 217);
				if (c == 8260) add ((uint8) 218);
				if (c == 8364) add ((uint8) 219);
				if (c == 8249) add ((uint8) 220);
				if (c == 8250) add ((uint8) 221);
				if (c == 64257) add ((uint8) 222);
				if (c == 64258) add ((uint8) 223);
				if (c == 8225) add ((uint8) 224);
				if (c == 183) add ((uint8) 225);
				if (c == 8218) add ((uint8) 226);
				if (c == 8222) add ((uint8) 227);
				if (c == 8240) add ((uint8) 228);
				if (c == 194) add ((uint8) 229);
				if (c == 202) add ((uint8) 230);
				if (c == 193) add ((uint8) 231);
				if (c == 203) add ((uint8) 232);
				if (c == 200) add ((uint8) 233);
				if (c == 205) add ((uint8) 234);
				if (c == 206) add ((uint8) 235);
				if (c == 207) add ((uint8) 236);
				if (c == 204) add ((uint8) 237);
				if (c == 211) add ((uint8) 238);
				if (c == 212) add ((uint8) 239);
				if (c == 63743) add ((uint8) 240);
				if (c == 210) add ((uint8) 241);
				if (c == 218) add ((uint8) 242);
				if (c == 219) add ((uint8) 243);
				if (c == 217) add ((uint8) 244);
				if (c == 305) add ((uint8) 245);
				if (c == 710) add ((uint8) 246);
				if (c == 732) add ((uint8) 247);
				if (c == 175) add ((uint8) 248);
				if (c == 728) add ((uint8) 249);
				if (c == 729) add ((uint8) 250);
				if (c == 730) add ((uint8) 251);
				if (c == 184) add ((uint8) 252);
				if (c == 733) add ((uint8) 253);
				if (c == 731) add ((uint8) 254);
				if (c == 711) add ((uint8) 255);
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
