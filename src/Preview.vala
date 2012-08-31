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

using WebKit;

namespace Supplement {

class Preview : FontDisplay {	
	
	public Preview () {
	}
	
	public override string get_name () {
		return "Preview";
	}
	
	public override bool is_html_canvas () {
		return true;
	}

	public override void selected_canvas () {
		WebView w = MainWindow.get_webview ();
		string uri = get_uri ();

		ExportTool.export_all ();
		
		w.open (uri);
		w.reload_bypass_cache ();
	}

	public override string get_uri () {
		Font font = Supplement.get_current_font ();
		string path = @"$(font.get_name ()).html";
		File dir = font.get_folder ();
		File file = dir.get_child (path);
		
		if (!file.query_exists ()) {
			ExportTool.generate_html_document ((!)file.get_path (), font);				
		}
		
		return path_to_uri ((!)file.get_path ());
	}
}
}
