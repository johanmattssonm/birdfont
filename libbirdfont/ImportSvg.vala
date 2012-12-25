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

		parse_svg_file (root);
				
		delete doc;
		Parser.cleanup ();
	}
	
	public static void import_svg (string data) {
		Xml.Doc* doc;
		Xml.Node* root = null;
		
		Parser.init ();
		
		doc = Parser.parse_doc (data);
		root = doc->get_root_element ();
				
		if (root == null) {
			delete doc;
			return;
		}

		parse_svg_file (root);		
		
		delete doc;
		Parser.cleanup ();
	}
	
	private static void parse_svg_file (Xml.Node* root) {
		Xml.Node* node;
		
		node = root;
		
		for (Xml.Node* iter = node->children; iter != null; iter = iter->next) {
			if (iter->name == "g") {
				parse_layer (iter);
			}
			
			if (iter->name == "path") {
				parse_path (iter);
			}
		}		
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
	
	private static void parse_svg_data (string d) {
		string[] c;
		string[] cp;
		string[] command;
		int ci = 0;
		double px = 0;
		double py = 0;
		double cx = 0;
		double cy = 0;
		double[] p;
		int pi = 0;
		string data = d;
		Glyph glyph = MainWindow.get_current_glyph ();
		Font font = Supplement.get_current_font ();
		
		// add separators
		data = data.replace (",", " ");
		data = data.replace ("m", "m ");
		data = data.replace ("M", "M ");
		data = data.replace ("l", "l ");
		data = data.replace ("L", "L ");
		data = data.replace ("c", "c ");
		data = data.replace ("C", "C ");
		data = data.replace ("zM", "z M ");
		data = data.replace ("zm", "z m ");
		data = data.replace ("  ", " ");
		
		c = data.split (" ");
		p = new double[2 * c.length];
		command = new string[2 * c.length];
		
		// parse path
		for (int i = 0; i < c.length; i++) {
			if (c[i] == "m") {
				while (is_point (c[i + 1])) {
					command[ci++] = "M";

					px += double.parse (c[++i]);
					py += -double.parse (c[++i]);
					
					p[pi++] = px;
					p[pi++] = py;
				}
			}

			if (c[i] == "M") {
				while (is_point (c[i + 1])) {
					command[ci++] = "M";

					px = double.parse (c[++i]);
					py = -double.parse (c[++i]);
					
					p[pi++] = px;
					p[pi++] = py;
				}
			}

			if (c[i] == "l") {
				while (is_point (c[i + 1])) {
					command[ci++] = "L";
					
					cx = px + double.parse (c[++i]);
					cy = py + -double.parse (c[++i]);
					p[pi++] = cx;
					p[pi++] = cy;
					
					px = cx;
					py = cy;
				}
			}
			
			if (c[i] == "L") {
				while (is_point (c[i + 1])) {
					command[ci++] = "L";
					
					cx = double.parse (c[++i]);
					cy = -double.parse (c[++i]);
					p[pi++] = cx;
					p[pi++] = cy;
					
					px = cx;
					py = cy;					
				}	
			}
			
			if (c[i] == "c") {
				while (is_point (c[i + 1])) {
					command[ci++] = "C";
					
					cx = px + double.parse (c[++i]);
					cy = py + -double.parse (c[++i]);
					p[pi++] = cx;
					p[pi++] = cy;
					
					cx = px + double.parse (c[++i]);
					cy = py + -double.parse (c[++i]);
					p[pi++] = cx;
					p[pi++] = cy;
					
					cx = px + double.parse (c[++i]);
					cy = py + -double.parse (c[++i]);
					p[pi++] = cx;
					p[pi++] = cy;
					
					px = cx;
					py = cy;
				}
			}
			
			if (c[i] == "C") {
				while (is_point (c[i + 1])) {
					command[ci++] = "C";
					
					cx = double.parse (c[++i]);
					cy = -double.parse (c[++i]);
					p[pi++] = cx;
					p[pi++] = cy;
					
					cx = double.parse (c[++i]);
					cy = -double.parse (c[++i]);
					p[pi++] = cx;
					p[pi++] = cy;
					
					cx = double.parse (c[++i]);
					cy = -double.parse (c[++i]);
					p[pi++] = cx;
					p[pi++] = cy;
					
					px = cx;
					py = cy;					
				}	
			}
			
			if (c[i] == "z") {
				command[ci++] = "z";
			}
		}

		Path path = new Path ();
		
		// move
		for (int i = 0; i < pi; i += 2) {
			p[i] += glyph.left_limit;
			p[i+1] -= font.top_position;
		}	
		
		// add points
		int ic = 0;
		double x0, x1, x2;
		double y0, y1, y2;
		EditPoint ep1, ep2;
		for (int i = 0; i < ci; i++) {
			if (is_null (command[i])) {
				warning ("Parser error.");
				return;
			}
			
			if (command[i] == "M") {
				path.add (p[ic++], p[ic++]);
			}
			
			if (command[i] == "L") {
				path.add (p[ic++], p[ic++]);
			}
						
			if (command[i] == "C") {
				x0 = p[ic++];
				y0 = p[ic++];
				x1 = p[ic++];
				y1 = p[ic++];
				x2 = p[ic++];
				y2 = p[ic++];
				
				if (is_null (path.points.last ().data)) {
					warning ("Paths must begin with M");
					return;
				}
			
				ep1 = path.points.last ().data;
				ep1.get_right_handle ().type = PointType.CURVE;
				ep1.get_right_handle ().move_to_coordinate (x0, y0);
			
				path.add (x2, y2);
				
				ep2 = path.points.last ().data;
				ep2.get_left_handle ().type = PointType.CURVE;
				ep2.get_left_handle ().move_to_coordinate (x1, y1);
			}
			
			if (command[i] == "z") {
				// last point is first
				ep1 = path.points.last ().data;
				path.points.remove_link (path.points.last ());
				ep2 = path.points.first ().data;

				ep2.left_handle.angle = ep1.left_handle.angle;
				ep2.left_handle.length = ep1.left_handle.length;
				ep2.left_handle.type = ep1.left_handle.type;

				glyph.add_path (path);
				path = new Path ();
			}
		}
	}
	
	static bool is_point (string s) {
		return double.try_parse (s);
	}
	
	static void parse_c (string[] data, int index, Path p, double posx, double posy) {
	}
}

}
