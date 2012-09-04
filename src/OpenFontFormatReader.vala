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

[SimpleType]
[CCode (has_type_id = false)] // Vala bug
internal struct Fixed : uint32 {

	public void @set (uint16 upper, uint16 lower) {
		uint32* p = &this;
		*p = (upper << 16) + lower;
	}

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
internal struct F2Dot14 : uint32 {
}

errordomain BadFormat {
	PARSE
}

class OpenFontFormatReader : Object {
	
	public DirectoryTable directory_table;
	
	OtfInputStream dis;
	File file;
	
	public OpenFontFormatReader () {
		directory_table = new DirectoryTable ();
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
		FontData fd = new FontData ();
		
		FileInfo file_info = file.query_info ("*", FileQueryInfoFlags.NONE);
		uint32 file_size = (uint32) file_info.get_size ();

        try {
			fd.write_table (dis, 0, file_size);
		} catch (GLib.Error e) {
			warning (@"Failed to read font data. $(e.message)");
		}

		offset_table = new OffsetTable (directory_table);
		offset_table.parse (fd);
		
		directory_table = new DirectoryTable ();
		directory_table.set_offset_table (offset_table);
		directory_table.parse (fd, file, this);
	}

	public void set_limits () {
		Font f = Supplement.get_current_font ();
		
		f.base_line = 0;
		f.top_position = -get_ascender ();
		f.top_limit = f.top_position - 5;
		f.xheight_position = f.top_position - 5;
		f.bottom_position = -get_descender ();
		f.bottom_limit = f.bottom_position + 5;	
	}

	public double get_ascender () {
		return directory_table.hhea_table.get_ascender ();
	}
	
	public double get_descender () {
		return directory_table.hhea_table.get_descender ();
	}

	public unowned List<string> get_all_names () {
		return directory_table.post_table.get_all_names ();
	}
	
	public uint32 get_head_checksum () {
		return directory_table.head_table.get_adjusted_checksum ();
	}
}
}
