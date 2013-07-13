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

/** Type2, PostScript outlines */
class CffTable : Table {

	static const uint8 HSTEM = 1;
	static const uint8 VSTEM = 3;
	static const uint8 VMOVETO = 4;
	static const uint8 HLINETO = 6;
	static const uint8 VLINETO = 7;
	static const uint8 ENDCHAR = 14;
	static const uint8 HMOVETO = 22;
	static const uint8 RMOVETO = 21;
	
	static const uint8 CHARSET = 15;
	static const uint8 ENCODING = 16;

	static const uint8 VERSION = 0;

	public int version;

	FontData dis;

	public CffTable () {
		id = "CFF ";
	}

	uint32 read_offset (uint size) throws GLib.Error {
		switch (size) {
			case 0:
				warning ("offset size is zero");
				return dis.read_byte ();
			case 1:
				return dis.read_byte ();
			case 2:
				return dis.read_ushort ();
			case 4:
				return dis.read_ulong ();
			default:
				warn_if_reached ();
				break;
		}
		
		warning ("offset size is zero");
		return 0;
	}

	List<uint32> read_index () throws Error {
		uint32 offset_size, off;
		int entries;
		List<uint32> offsets = new List<uint32> ();
		
		entries = dis.read_ushort ();
		printd (@"number of entries $(entries)\n");
		
		if (entries == 0) {
			printd ("skip index");
			return offsets;
		}
		
		offset_size = dis.read ();
		printd (@"Offset size $(offset_size)\n");
		
		// read the end offset as well
		for (int i = 0; i <= entries; i++) {
			off = read_offset (offset_size);
			printd (@"offset $(off)\n");
			offsets.append (off);
		}
		
		return offsets;
	}

	public override void parse (FontData dis) throws Error {
		uint v1, v2, offset_size, header_size, len;
		string data;
		List<uint32> offsets, dict_index;
		int id, val;
		int off; // offset relative to table position
		
		dis.seek (offset);
		this.dis = dis;
		
		printd ("Parse CFF.\n");
		v1 = dis.read ();
		v2 = dis.read ();
		printd (@"Version $v1.$v2\n");
		header_size = dis.read ();
		printd (@"Header size $(header_size)\n");
		offset_size = dis.read ();
		printd (@"Offset size $(offset_size)\n");
			
		// name index
		offsets = read_index ();
		
		// name data
		for (int i = 0; i < offsets.length () - 1; i++) {
			off = (int) offsets.nth (i).data;
			len = offsets.nth (i + 1).data - off;
			//dis.seek (offset + off + header_size);
			data = dis.read_string (len);
			print (@"Found name $data\n");		
		}	

		// dict index
		print (@"dict index\n");
		dict_index = read_index ();

		// dict data
		id = 0;
		val = 0;
		for (int i = 0; i < dict_index.length () - 1; i++) {
			off = (int) offsets.nth (i).data;
			len = dict_index.nth (i + 1).data - dict_index.nth (i).data;
			//dis.seek (offset + off + header_size);
			
			//for (int j = 0; j < len; j++) {
				
				if (dis.next_is_operator ()) {
					id = dis.read ();
		
					if (id == 12) {
						id = dis.read ();
					} else {
						switch (id) {
							case 0:
								version = val;
								break;
							default:
								stderr.printf ("unknown operator");
								break;
						}
					}			
				} else {
					val = dis.read_charstring_value ();	
				}

				printd (@"$i: id $(id)\n");
				printd (@"val $(val)\n");
				//printd (@"B $(dis.read ())\n");
			//}	
		}		

		// string index
		read_index ();
	}
	
	public void process () throws GLib.Error {
		FontData fd = new FontData ();
		string name = "typeface";
		
		// header
		fd.add_byte (1); // format version (1.0)
		fd.add_byte (0);
	
		fd.add_byte (4); // header size
		fd.add_byte (2); // offset field size - ushort
		
		// name index:
		fd.add_ushort (1);	// number of entries
		fd.add_byte (2); 	// offset field size
		fd.add_ushort (1);	// offset			
		fd.add ((uint8) name.length); // length of string
		fd.add_str (name);
	
		// top dict index
		fd.add_ushort (1);	// number of entries
		fd.add_byte (2); 	// offset field size
		fd.add_ushort (1);	// offset
		fd.add_ushort (2);	// offset

		fd.add_charstring_value (0);
		fd.add_byte (CHARSET);

		// string index
		fd.add_byte (0);

		// TODO: glyph gid to cid map
		fd.add_byte (0);
		
		fd.pad ();
	
		this.font_data = fd;
	}
}

}
