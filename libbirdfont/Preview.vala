/*
    Copyright (C) 2012 Johan Mattsson

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

public class Preview : FontDisplay {	
	
	public Preview () {
	}
	
	public override string get_name () {
		return "Preview";
	}
	
	public override bool is_html_canvas () {
		return true;
	}

	public override void selected_canvas () {
	}

	public new File get_html_file () {
		Font font = BirdFont.get_current_font ();
		string path = @"$(font.get_name ()).html";
		File dir = font.get_folder ();
		File file = dir.get_child (path);
		
		if (!file.query_exists ()) {
			ExportTool.generate_html_document ((!)file.get_path (), font);				
		}
		
		return file;	
	}

	public override string get_uri () {
		return path_to_uri ((!) get_html_file ().get_path ());
	}
	
	public static string get_windows_uri () {
		Font font = BirdFont.get_current_font ();
		string html = @"$(font.get_name ()).html";
		File dir = font.get_folder ();
		File file = dir.get_child (html);
		return "file:///" + (!)	file.get_path ();
	}
}
}
