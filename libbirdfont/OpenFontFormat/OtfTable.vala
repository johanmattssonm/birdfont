/*
	Copyright (C) 2012, 2013 Johan Mattsson

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

public class OtfTable : Object {

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

	public bool has_data () {
		return length > 0;
	}

	public virtual void parse (FontData dis) throws GLib.Error {
		warning (@"Parse is not implemented for $(id).");
	}

	/** Validate table checksum. */
	public bool validate (FontData dis) {
		bool valid;
		
		if (length == 0) {
			stderr.printf (@"OtfTable $id is of zero length.\n");			
			valid = false;
		} else {
			valid = OtfTable.validate_table (dis, checksum, offset, length, id);
		}
		
		if (!valid) {
			stderr.printf (@"OtfTable $id is invalid.\n");
		}
		
		return valid;
	}

	public static bool validate_table (FontData dis, uint32 checksum, uint32 offset, uint32 length, string name) {
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
	
	public static uint32 calculate_checksum (FontData dis, uint32 offset, uint32 length, string name) {
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

}
