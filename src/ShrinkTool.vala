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

using Gtk;

namespace Supplement {

// TODO contrast

class ShrinkTool : Tool {

	public ShrinkTool (string n) {
		base (n, "shrink path");

		select_action.connect((self) => {
			Glyph g = MainWindow.get_current_glyph ();
		
			foreach (Path p in g.path_list) {
				shrink_copy (p, 0.25);
			}
			
			MainWindow.get_glyph_canvas ().redraw ();
		});

		select_action.connect((self) => {
		});
			
		press_action.connect((self, b, x, y) => {
		});

		move_action.connect((self, x, y) => {
		});
	}
	
	public static int path_index (Path p) {
		Glyph g = MainWindow.get_current_glyph ();
		int i = 0;
		
		foreach (Path pt in g.path_list) {
			if (p == pt) {
				return i;
			}
			i++;
		}
		
		return -1;
	}
	
	public static void shrink_copy (Path px, double step) {		
		Path p = px.copy ();
		shrink (px, step);
		p.set_editable (true);
	}	
	
	public static void shrink (Path p, double step) {		
		if (p.points.length () < 3) return;

		p.create_list ();
		
		EditPoint ep;

		p.create_list ();

		foreach (EditPoint pep in p.points) {
			unowned List<EditPoint>? lep = pep.get_next ();
			
			if (unlikely (lep == null)) {
				warning ("Bad list.");
				stderr.printf (@"No links in path $(path_index (p)). Length: $(p.points.length ())\n");
				p.print_boundries ();
				continue;
			}
			
			ep = ((!)lep).data;
			move_point (p, pep, ep, step);
		}
		
		move_point (p, p.points.last ().data, p.points.first ().data, step);
		
		p.set_editable (true);
	}
	
	static void move_point (Path p, EditPoint pep, EditPoint ep, double step) {	
		double istep = 1 - step;
		
		double mx = ep.get_right_handle ().x () / 2 + ep.get_left_handle ().x () / 2;
		double my = ep.get_right_handle ().y () / 2 + ep.get_left_handle ().y () / 2;
			
		ep.x = mx * step + ep.x * istep;
		ep.y = my * step + ep.y * istep;

	}
	
	public override bool test () {
		test_select_action ();
		return true;
	}

}
	
}
