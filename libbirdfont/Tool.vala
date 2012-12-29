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

namespace Supplement {

public class Tool : GLib.Object {
	
	public double x = 0;
	public double y = 0;
	public double w = 0;
	public double h = 0;

	protected bool active = false;
	protected bool selected = false;
	
	double r_default_selected = 131/255.0;
	double g_default_selected = 179/255.0;
	double b_default_selected = 231/255.0;
	double a_default_selected = 1;
	
	double r_default = 185/255.0;
	double g_default = 207/255.0;
	double b_default = 231/255.0;
	double a_default = 1;
	
	double r;
	double g;
	double b;
	double a;
	
	ImageSurface? icon = null;
		
	public signal void select_action (Tool selected);
	public signal void deselect_action (Tool selected);
	
	public signal void press_action (Tool selected, int button, int x, int y);
	public signal void double_click_action (Tool selected, int button, int x, int y);
	public signal void move_action (Tool selected, int x, int y);
	public signal void release_action (Tool selected, int button, int x, int y);
	
	public signal void key_press_action (Tool selected, uint32 keyval);
	public signal void key_release_action (Tool selected, uint32 keyval);
	
	public signal void panel_press_action (Tool selected, uint button, double x, double y);
	public signal void panel_release_action (Tool selected, uint button, double x, double y);
	public signal void panel_move_action (Tool selected, double x, double y);
	
	public signal void draw_action (Tool selected, Context cr, Glyph glyph);
	
	protected string name = "";
	
	static int next_id = 1;
	
	int id;
	
	public bool new_selection = false;
	
	bool show_bg = true;
	
	string tip = "";

	// keyboard bindings
	public uint modifier_flag;
	public unichar key;
	
	private static ImageSurface? selected_button = null;
	private static ImageSurface? active_selected_button = null;
	private static ImageSurface? deselected_button = null;
	private static ImageSurface? active_deselected_button = null;
	
	/** Create tool with a certain name and load icon "name".png */
	public Tool (string? name = null, string tip = "", unichar key = '\0', uint modifier_flag = 0) {
		this.tip = tip;
		
		if (selected_button == null) {
			selected_button = Icons.get_icon ("tool_button_selected.png");
			active_selected_button = Icons.get_icon ("tool_button_selected_active.png");
			deselected_button = Icons.get_icon ("tool_button_deselected.png");
			active_deselected_button = Icons.get_icon ("tool_button_deselected_active.png");
		}
		
		if (name != null) {
			set_icon ((!) name);
			this.name = (!) name;
		}
		
		this.key = key;
		this.modifier_flag = modifier_flag;
				
		id = next_id;
		next_id++;
		
		panel_press_action.connect ((self, button, x, y) => {
			MainWindow.get_tool_tip ().set_text_from_tool ();
		});
		
		r = r_default;
		g = g_default;
		b = b_default;
		a = a_default;
	}
	
	public void set_icon (string name) {
		StringBuilder n = new StringBuilder ();
		n.append ((!) name);
		n.append (".png");
		icon = Icons.get_icon (n.str);
	}
	
	public bool is_active () {
		return active;
	}
	
	public void set_show_background (bool bg) {
		show_bg = bg;
	}
	
	public int get_id () {
		return id;
	}

	public string get_name () {
		return name;
	}

	public bool is_selected () {
		return selected;
	}
		
	public virtual void set_properties (double tx, double ty, double tw, double th) {
		x = tx;
		y = ty;
		w = tw;
		h = th;
	}

	public string get_tip () {
		return tip;
	}

	public bool is_over (double xp, double yp) {	
		return (x <= xp <= x + w  + 12 + 15 && y + 15 <= yp <= y + w + 12 + 30);  
	}
	
	public bool set_selected (bool a) {
		TooltipArea? tpa = null;					
		tpa = MainWindow.get_tool_tip ();
							
		new_selection = true;
		selected = a;
		set_active (a);
		
		if (!a) {
			deselect_action (this);
		} else {
			((!)tpa).update_text ();
		}
		
		return true;
	}
	
	public bool set_active (bool ac) {
		bool ret = (active != ac);

		if (selected) {
			if (ac) {
				r = r_default_selected;
				g = g_default_selected;
				b = b_default_selected;
				a = a_default_selected * 0.5;
			} else {
				r = r_default_selected;
				g = g_default_selected;
				b = b_default_selected;
				a = a_default_selected;
			}			
		} else {
			if (ac) {
				r = r_default;
				g = g_default;
				b = b_default;
				a = a_default * 0.2;
			} else {
				r = r_default;
				g = g_default;
				b = b_default;
				a = a_default;
			}
		}

		active = ac;
		return ret;
	}
		
	public virtual void draw (Context cr) {
		double xt = x + 3 + w;
		double yt = y + h + 17;

		double bgx, bgy;
		
		bgx = xt - 6;
		bgy = yt - 7;

		cr.save ();

		// Button in four states
		if (selected && selected_button != null) {
			cr.set_source_surface ((!) selected_button, bgx, bgy);
			cr.paint ();
		}

		if (selected && active && active_selected_button != null) {
			cr.set_source_surface ((!) active_selected_button, bgx, bgy);
			cr.paint ();
		}

		if (!selected && deselected_button != null) {
			cr.set_source_surface ((!) deselected_button, bgx, bgy);
			cr.paint ();
		}

		if (!selected && active && active_deselected_button != null) {
			cr.set_source_surface ((!) active_deselected_button, bgx, bgy);
			cr.paint ();
		}
				
		if (icon != null) {
			ImageSurface i = (!) icon;
			
			if (likely (i.status () == Cairo.Status.SUCCESS)) {
				cr.set_source_surface (i, xt + (15 - i.get_width () / 2) - 5.7, yt + (15 - i.get_height ()) / 2.0);
				cr.paint ();
			} else {
				warning (@"Falied to load icon for $name");
			}
		}
		
		cr.restore ();
	}

	/** Run a test case for this tool. */
	public virtual bool test () {
		stderr.printf (@"$(get_name ()) does not have a test case, implement one by overriding test method in Tool base class.");
		return false;
	}
	
	/** Help function to test button press actions. */
	public void test_click_action (int b, int x, int y) {
		Tool.yield ();
		press_action (this, b, x, y);
		
		Tool.yield ();
		release_action (this, b, x, y);
	}

	/** Help function to test select action for this tool. */
	public void test_select_action () {
		Tool.yield ();
		MainWindow.get_toolbox ().select_tool (this);
	}

	public void test_move_action (int x, int y) {
		Tool.yield ();
		move_action (this, x, y);
	}

	public void test_press_action (int b, int x, int y) {
		Tool.yield ();
		press_action (this, b, x, y);
	}

	public void test_release_action (int b, int x, int y) {
		Tool.yield ();
		release_action (this, b, x, y);
	}

	public static void test_open_next_glyph () {
		Tool.yield ();
		OverView o = MainWindow.get_overview ();
		
		MainWindow.get_tab_bar ().select_overview ();
		MainWindow.get_toolbox ().select_tool_by_name ("utf_8");
		
		o.select_next_glyph ();
		Tool.yield ();
		
		o.open_current_glyph ();
		Tool.yield ();
	}
	
	/** Run pending events in main loop before continue. */
	public static void @yield () {
		int t = 0;
		var time = new TimeoutSource(500);
		bool timeout;

		if (TestSupplement.is_slow_test ()) {
			timeout = false;
			
			time.set_callback(() => {
				timeout = true;
				return false;
			});

			time.attach(null);		
		} else {
			timeout = true;
		}
    
		unowned MainContext c = MainContext.default ();
		bool a = c.acquire ();
		
		while (unlikely (!a)) {
			warning ("Failed to acquire main loop.\n");
			return;
		}

		while (c.pending () || TestSupplement.is_slow_test ()) {
			c.iteration (true);
			t++;

			if (!c.pending () && TestSupplement.is_slow_test ()) {
				if (timeout) break;
			}
						
			if (unlikely (t > 100000)) {
				assert (false);
				break;
			}
		}
		
		c.release ();
	}
	
}

}
