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
public struct Fixed : uint32 {

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
public struct F2Dot14 : uint32 {
}

errordomain BadFormat {
	PARSE
}

class OpenFontFormatReader : Object {
	
	OtfInputStream dis;
	DirectoryTable directory_table;
	
	public OpenFontFormatReader (string file_name) {
		try {
			parse (file_name);
		} catch (Error e) {
			stderr.printf (e.message);
		}
	}
	
	void parse (string file_name) throws Error {
		File f = File.new_for_path (file_name);
		if (!f.query_exists ()) {
			throw new FileError.EXIST(@"OpenFontFormatReader: file does not exist. $((!) f.get_path ())");
		}
			
		dis = new OtfInputStream (f.read ());
		
		parse_index ();
		done ();
	}
	
	void done () {
		IdleSource idle = new IdleSource ();

		idle.set_callback (() => {
			Font f = Supplement.get_current_font ();
			f.loading_finished_callback ();
			return false;
		});

		idle.attach (null);		
	}
	
	void parse_index () throws Error {
		OffsetTable offset_table;
		
		directory_table = new DirectoryTable ();
		
		offset_table = new OffsetTable (directory_table);
		offset_table.parse (dis);
		
		directory_table = new DirectoryTable ();
		directory_table.set_offset_table (offset_table);
		directory_table.parse (dis);
		
		set_limits ();
	}

	public void set_limits () {
		IdleSource idle = new IdleSource ();

		idle.set_callback (() => {
			Font f = Supplement.get_current_font ();
			
			f.base_line = 0;
			f.top_position = -get_ascender ();
			f.top_limit = f.top_position - 5;
			f.bottom_position = -get_descender ();
			f.bottom_limit = f.bottom_position + 5;	

			return false;
		});

		idle.attach (null);
	}

	public double get_ascender () {
		return directory_table.hhea_table.get_ascender ();
	}
	
	public double get_descender () {
		return directory_table.hhea_table.get_descender ();
	}}

}
