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
using Xml;

namespace Supplement {
	
public class ImportSvg {
	public ImportSvg () {
	}
	
	public static void import () {
		Xml.Doc* doc;
		Xml.Node* root = null;
		Xml.Node* node;
		string? p;
		string path;
		
		p = MainWindow.file_chooser ("Import");

		if (p == null) {
			return;
		}

		path = (!) p;

		Parser.init ();

		doc = Parser.parse_file (path);
		root = doc->get_root_element ();
				
		if (root == null) {
			delete doc;
			return;
		}

		node = root;
		
		for (Xml.Node* iter = node->children; iter != null; iter = iter->next) {
			if (iter->name == "g") {
				parse_layer (iter);
			}
		}
				
		delete doc;
		Parser.cleanup ();				
	}
	
	private static void parse_layer (Xml.Node* node) {
		string attr_name = "";
		string attr_content;
		
		return_if_fail (node != null);
				
		for (Xml.Node* iter = node->children; iter != null; iter = iter->next) {
			if (iter->name == "path") {
				parse_path (iter);
			}
		}
	}
	
	private static void parse_path (Xml.Node* node) {
		string attr_name = "";
		string attr_content;
		
		for (Xml.Attr* prop = node->properties; prop != null; prop = prop->next) {
			attr_name = prop->name;
			attr_content = prop->children->content;
			
			if (attr_name == "d") {
				parse_svg_data (attr_content);
			}
		}
	}
	
	private static void parse_svg_data (string data) {
	}
	
	static void parse_c (string[] data, int index, Path p, double posx, double posy) {
	}
}

}
