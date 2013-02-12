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

using Cairo;
using Math;

namespace BirdFont {

public class Expander : GLib.Object {
	
	public double x = 7;
	public double y = 5;

	public double w = 6;
	public double h = 5;
	
	public double margin = 0;
	
	protected double rotation = 0;
	protected double opacity = 0.5;
	
	protected bool active = false;
	protected bool open = false;

	public List<Tool> tool;

	bool persist = false;
	bool unique = false;
	
	public Expander () {
	}

	/** Returns true if tools can be used with the current canvas after
	 * they have been selectes and false if they are a commands to be executed.
	 */
	public bool is_persistent () {
		return persist;
	}

	/** Returns true if all other tools in thid expander should be deselected 
	 * when a tool is selected.
	 */
	public bool is_unique () {
		return unique;
	}

	public void set_persistent (bool p) {
		persist = p;
	}

	public void set_unique (bool u) {
		unique = u;
	}
	
	private void update_tool_position () {
		int i = 0;
		double xt = x + 10;
		double yt = y - 4;
		foreach (var t in tool) {
			t.set_properties (xt, yt, w, h);
			
			if (i == 3) {
				yt += 31;
				i = 0;
				xt = x + 10;
			} else {
				i++;
				xt += w + 3 + 25;
			}
		}
	}
	
	public void set_offset (double ty) {
		y = ty;
		
		if (open) {
			update_tool_position ();
		}
	}
	
	public void add_tool (Tool t) {
		tool.append (t);
		update_tool_position ();
		
		t.select_action.connect ((selected) => {
				if (!selected.new_selection) {
					if (is_persistent ()) {
						selected.set_selected (true);
					} else {
						selected.set_selected (false);
					}
				}
			
				MainWindow.get_toolbox ().redraw ((int) x, (int) y, (int) w  + 300, (int) (h + margin));
			
				if (is_unique ()) {
					foreach (var deselected in tool) {
						if (selected.get_id () != deselected.get_id ()) {
							deselected.set_selected (false);
						}
					}
				}

				if (!is_persistent ()) {
						var time = new TimeoutSource(200);
						time.set_callback(() => {
							selected.set_selected (false);
							MainWindow.get_toolbox ().redraw ((int) x, (int) y, (int) w  + 300, (int) (h + margin));
							return false;
						});
						time.attach(null);
				}

				selected.new_selection = false;
			});
	}
	
	public bool is_over (double xp, double yp) {	
		return (x - 7/2.0 <= xp <= x + w  + 7/2.0 && y - 7/2.0<= yp <= y + w + 7/2.0);  
	}
	
	public bool set_active (bool a) {
		bool r = (active != a);
		opacity = (a) ? 1 : 0;
		active = a;
		return r;
	}
	
	public bool is_open () {
		return open;
	}
	
	public virtual bool set_open (bool o) {
		bool r = (open != o);
		rotation = (o) ? Math.PI_2 : 0;
		
		if (o) {
			margin = 35 * (int)((tool.length () / 4.0) + 1) ;
			rotation = Math.PI_2;			
			if (tool.length () % 4 == 0) {
				margin -= 35;
			}
		} else {
			margin = 0;
			rotation = 0; 
		}
		
		open = o;
		return r;
	}
	
	public void draw (int wd, int hd, Context cr) {
		double lx, ly;
		double ih2 = 5.4 / 2;
		double iw2 = 5.4 / 2;
		
		// box
		cr.save ();
		cr.set_line_join (LineJoin.ROUND);
		cr.set_line_width(7);
		cr.set_source_rgba (176/255.0, 211/255.0, 230/255.0, opacity);
		cr.rectangle (x, y, w, h);
		cr.stroke ();
		cr.restore ();
		
		// arrow
		cr.save ();
		
		cr.translate (x + w/2, y + h/2);
		cr.rotate (rotation);

		cr.set_line_width (1);
		cr.set_source_rgba (0, 0, 0, opacity);

		cr.new_path ();
		cr.move_to (-iw2, -ih2);
		cr.line_to (iw2, 0);	
		cr.line_to (-iw2, +ih2);

		cr.close_path();
		cr.stroke ();
		cr.restore ();
		
		// separator
		cr.save ();
		lx = x + w + 7;
		ly = y + ih2;
		if (lx < wd) {
			cr.set_line_width(1);
			cr.set_source_rgba (0, 0, 0, 0.2);
			cr.move_to (lx, ly);
			cr.line_to (wd - w - x + 4, ly);	
			cr.stroke ();
		}
		cr.restore ();

	}
	
	public void draw_content (int w, int h, Context cr) {
		if (open) {
			cr.save ();
			foreach (var t in tool) {
				t.draw (cr);
			}
			cr.restore ();
		}
	}
	
}

}
