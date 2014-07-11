/*
    Copyright (C) 2012, 2014 Johan Mattsson

    This library is free software; you can redistribute it and/or modify 
    it under the terms of the GNU Lesser General Public License as 
    published by the Free Software Foundation; either version 3 of the 
    License, or (at your option) any later version.

    This library is distributed in the hope that it will be useful, but 
    WITHOUT ANY WARRANTY; without even the implied warranty of 
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU 
    Lesser General Public License for more details.
*/

[CCode (cname = "load_freetype_font")]
public extern static StringBuilder? load_freetype_font (string file, out int error);

[CCode (cname = "validate_freetype_font")]
public extern static bool validate_freetype_font (string file);

namespace BirdFont {

[SimpleType]
[CCode (has_type_id = false)] // Vala bug
public struct Fixed : uint32 {

	public bool @equals (uint16 upper, uint16 lower) {
		uint32 t = (upper << 16) + lower;
		return (t == this);		
	}

	public string get_string () {
		uint a = this >> 16;
		return @"$(a).$(this - (a << 16))";
	}
}

[SimpleType]
[CCode (has_type_id = false)] // same as above
public struct F2Dot14 : uint32 {
}

errordomain BadFormat {
	PARSE
}

public class OpenFontFormatReader : Object {
	
	public DirectoryTable directory_table;
	public FontData font_data = new FontData ();
	
	OtfInputStream dis;
	File file;
	
	public OpenFontFormatReader () {
		directory_table = new DirectoryTable ();
	}
	
	public void close () {
		dis.close ();
	}
	
	public Glyph? read_glyph (string name) {
		try {
			return directory_table.glyf_table.read_glyph (name);
		} catch (GLib.Error e) {
			warning (e.message);
		}
		
		return null;
	}
	
	public void parse_index (string file_name) throws Error {
		file = File.new_for_path (file_name);
		if (!file.query_exists ()) {
			throw new FileError.EXIST(@"OpenFontFormatReader: file does not exist. $((!) file.get_path ())");
		}
			
		dis = new OtfInputStream (file.read ());
		
		parse_index_tables ();
	}
	
	void parse_index_tables () throws Error {
		OffsetTable offset_table;
		
		FileInfo file_info = file.query_info ("*", FileQueryInfoFlags.NONE);
		uint32 file_size = (uint32) file_info.get_size ();

        try {
			font_data.write_table (dis, 0, file_size);
		} catch (GLib.Error e) {
			warning (@"Failed to read font data. $(e.message)");
		}

		offset_table = new OffsetTable (directory_table);
		offset_table.parse (font_data);
		
		directory_table = new DirectoryTable ();
		directory_table.set_offset_table (offset_table);
		directory_table.parse (font_data, this);		
	}

	public void parse_all_tables () throws Error {
		directory_table.parse_all_tables (font_data, this);
		
		if (!directory_table.validate_tables (font_data, file)) {
			warning ("Missing required table or bad checksum.");
		}
	}

	public void parse_kern_table () throws Error {
		directory_table.parse_kern_table (font_data);
	}

	public void parse_cmap_table () throws Error {
		directory_table.parse_cmap_table (font_data);
	}

	public void parse_head_table () throws Error {
		directory_table.parse_head_table (font_data);
	}
			
	public void set_limits () {
		Font f = OpenFontFormatWriter.font;
		
		if (is_null (f)) {
			f = BirdFont.get_current_font ();
		}
		
		f.top_position = get_ascender ();
		f.top_limit = f.top_position + 5;
		f.xheight_position = f.top_position + 5;
		f.bottom_position = get_descender ();
		f.bottom_limit = f.bottom_position - 5;	
	}

	public double get_ascender () {
		return directory_table.hhea_table.get_ascender ();
	}
	
	public double get_descender () {
		return directory_table.hhea_table.get_descender ();
	}
	
	public uint32 get_head_checksum () {
		return directory_table.head_table.get_adjusted_checksum ();
	}
	
	public static void append_kerning (StringBuilder bf_data, string file_name) {
		string s = parse_kerning (file_name);
		bf_data.append (s);
	}
	
	public static string parse_kerning (string file_name) {
		KernTable kern_table;
		CmapTable cmap_table;
		HeadTable head_table;
		OpenFontFormatReader reader = new OpenFontFormatReader ();
		StringBuilder bf_kerning = new StringBuilder ();
		unichar left, right;
		double kerning, units_per_em;
		uint npairs = 0;
		
		try {
			reader.parse_index (file_name);
			reader.parse_kern_table ();
			reader.parse_cmap_table ();
			reader.parse_head_table ();
			
			kern_table = reader.directory_table.kern_table;
			cmap_table = reader.directory_table.cmap_table;
			head_table = reader.directory_table.head_table;
			
			npairs = kern_table.kerning.length ();
			
			units_per_em = HeadTable.units_per_em;
			
			foreach (Kern k in kern_table.kerning) {
				left = cmap_table.get_char (k.left);
				right = cmap_table.get_char (k.right);
				kerning = 100 * (k.kerning / units_per_em);
				
				if (left <= 0x1F || right <= 0x1F) {
					warning ("Ignoring kerning of control character.");
				} else {
					bf_kerning.append ("<kerning left=\"");
					bf_kerning.append (BirdFontFile.serialize_unichar (left));
					bf_kerning.append ("\" ");
					bf_kerning.append ("right=\"");
					bf_kerning.append (BirdFontFile.serialize_unichar (right));
					bf_kerning.append ("\" ");
					bf_kerning.append ("hadjustment=\"");
					bf_kerning.append (@"$kerning".replace (",", "."));
					bf_kerning.append ("\" />\n");
				}
			}
		} catch (GLib.Error e) {
			warning (@"Failed to parse font. $(e.message)");
		}
		
		return bf_kerning.str;				
	}
}
}
