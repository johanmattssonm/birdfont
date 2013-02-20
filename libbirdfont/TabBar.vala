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

namespace BirdFont {

public class TabBar : GLib.Object {
	
	int width = 0;
	int height = 0;
	
	public List<Tab> tabs = new List<Tab> ();

	static const int NO_TAB = -1;
	static const int NEXT_TAB = -2;
	static const int PREVIOUS_TAB = -3;

	int first_tab = 0;
	int selected = 0;
	int over = NO_TAB;
	int over_close = NO_TAB;
	
	public signal void signal_tab_selected (Tab selected_tab);

	Tab? previous_tab = null;
	Tab? current_tab = null;

	ImageSurface? tab1_left = null;
	ImageSurface? tab1_right = null;

	ImageSurface? tab2_left = null;
	ImageSurface? tab2_right = null;

	ImageSurface? tab3_left = null;
	ImageSurface? tab3_right = null;
	
	ImageSurface? bar_background = null;
	ImageSurface next_tab;
	ImageSurface to_previous_tab;
			
	public TabBar () {
		tab1_left = Icons.get_icon ("tab1_left.png");
		tab1_right = Icons.get_icon ("tab1_right.png");

		tab2_left = Icons.get_icon ("tab2_left.png");
		tab2_right = Icons.get_icon ("tab2_right.png");

		tab3_left = Icons.get_icon ("tab3_left.png");
		tab3_right = Icons.get_icon ("tab3_right.png");
		
		bar_background = Icons.get_icon ("tabbar_background.png");
		
		next_tab = (!) Icons.get_icon ("next_tab.png");
		to_previous_tab = (!) Icons.get_icon ("previous_tab.png");
		
		return_if_fail (!is_null (next_tab));
	}
	
	public void motion (double x, double y) {
		is_over_close (x, y, out over, out over_close);
	}

	private void is_over_close (double x, double y, out int over, out int over_close) {
		int i = 0;
		double offset = 19;
		
		if (x < 19 && has_scroll ()) {
			over_close = NO_TAB;
			over = PREVIOUS_TAB;
			return;
		}
		
		foreach (Tab t in tabs) {
			
			if (i < first_tab) {
				i++;
				continue;
			}
			
			if (offset + t.get_width () + 3 > width && has_scroll ()) {
				over_close = NO_TAB;
				over = NEXT_TAB;
				return;
			}
			
			if (offset < x < offset + t.get_width ()) {
				over = i;
				
				if (8 < y < 20 && x > offset + t.get_width () - 16) {
					over_close =  i;
				} else {
					over_close =  NO_TAB;
				}
				
				return;
			}
			
			offset += t.get_width () + 3;
			i++;
		}

		over_close = NO_TAB;		
		over = NO_TAB;
	}	
	
	
	/** Select tab for a glyph by charcode or name.
	 * @return true if the tab was found
	 */
	public bool select_char (string s) {
		int i = 0;
		foreach (Tab t in tabs) {
			if (t.get_label () == s) {
				select_tab (i);
				return true;
			}
			i++;
		}
		
		return false;
	}

	public bool select_tab_name (string s) {
		return select_char (s);
	}

	public void select_overview () {
		select_tab_name ("Overview");
	}

	private void select_previous_tab () {
		Tab t;
		bool open;
		
		if (previous_tab == null) {
			return;
		}
		
		t = (!) previous_tab;
		open = selected_open_tab (t);
		
		if (!open) {
			select_tab ((int) tabs.length () - 1);
		}
	}
		
	public void close_display (FontDisplay f) {
		int i = -1;
		foreach (var t in tabs) {
			++i;
			
			if (t.get_display () == f) {
				close_tab (i) ;
				return;
			}
		}
		
		return_if_fail (i != -1);
	} 

	public void close_all_tabs () {
		for (int i = 0; i < get_length (); i++) {
			if (close_tab (i)) {
				close_all_tabs ();
			}
		}
	}

	public bool close_tab (int index, bool background_tab = false) {	
		unowned List<Tab?>? lt;
		Tab t;
		
		if (!(0 <= index < tabs.length ())) {
			return false;
		}
		
		lt = tabs.nth(index);
		
		if (lt == null || ((!) lt).data == null) {
			return false;
		}

		if (first_tab > 0) {
			first_tab--;
		}

		t = (!) ((!) lt).data;

		if (t.has_close_button ()) {
			tabs.delete_link (tabs.nth(index));
			
			if (!background_tab) {
				select_previous_tab ();
			}
			
			return true;
		}
		
		select_tab (index);
		return false;
	}
	
	public bool close_by_name (string name, bool background_tab = false) {
		int i = 0;
		
		foreach (var t in tabs) {
			if (t.get_label () == name) {
				return close_tab (i, background_tab);
			}
			
			i++;
		}
		
		return false;
	}
	
	public void close_background_tab_by_name (string name) {
		close_by_name (name, true);
	}
	
	/** Select a tab and return true if it is open. */
	public bool selected_open_tab (Tab t) {
		int i = 0;
		foreach (var n in tabs) {
			if (n == t) {
				select_tab (i);
				return true;
			}
			
			i++;
		}
		
		return false;
	}

	public Tab? get_nth (int i) {
		if (!(0 <= i < get_length ())) {
			return null;
		}
		
		return tabs.nth (i).data;
	}

	public Tab? get_tab (string name) {
		foreach (var n in tabs) {
			if (n.get_label () == name) {
				return n;
			}
		}
		
		return null;
	}

	public bool selected_open_tab_by_name (string t) {
		int i = 0;
		foreach (var n in tabs) {
			if (n.get_label () == t) {
				select_tab (i);
				return true;
			}
			
			i++;
		}
		
		return false;
	}
	
	public Tab get_selected_tab () {
		return tabs.nth (get_selected ()).data;
	}
	
	public uint get_length () {
		return tabs.length ();
	}

	public int get_selected () {
		return selected;
	}
	
	public void select_tab (int index) {
		Tab t;

		if (index == NEXT_TAB) {
			selected++;
			
			if (selected >=  tabs.length ()) {
				selected = (int) tabs.length () - 1;
			}
			
			scroll_to_tab (selected);
			return;
		}
		
		if (index == PREVIOUS_TAB) {

			if (selected > 0) {
				selected--;
			}
			
			scroll_to_tab (selected);
			return;
		}
		
		if (!(0 <= index < tabs.length ())) {
			return;
		}

		selected = index;
		
		unowned List<Tab?>? lt = tabs.nth(index);
		
		return_if_fail(lt != null);
		t = (!) ((!) lt).data;
		
		previous_tab = current_tab;
		current_tab = t;

		scroll_to_tab (selected);
	}
	
	private bool has_scroll () {
		int i = 0;
		double offset = 19;
		
		if (first_tab > 0) {
			return true;
		}
		
		foreach (Tab t in tabs) {	
			if (i < first_tab) {
				i++;
				continue;
			}
			
			if (offset + t.get_width () + 3 > width - 19) {
				return true;
			}

			offset += t.get_width () + 3;
			i++;
		}
		
		return false;		
	}
	
	private void signal_selected (int index) {
		unowned List<Tab?>? lt;
		Tab t;
		
		lt = tabs.nth(index);
		return_if_fail(lt != null);		
		t = (!) ((!) lt).data;
		
		signal_tab_selected (t);		
	}
	
	private void scroll_to_tab (int index) {
		double offset = 19;
		int i = 0;
		
		if (index < first_tab) {
			first_tab = index;
			signal_selected (index);
			return;
		}
		
		foreach (Tab t in tabs) {
			
			if (i < first_tab) {
				i++;
				continue;
			}
			
			// out of view
			if (offset + t.get_width () + 3 > width - 19) {
				first_tab++;
				scroll_to_tab (index);
				return;
			}

			// in view
			if (i == index) {
				signal_selected (index);
				return;
			}

			offset += t.get_width () + 3;
			i++;
		}
		
		warning ("");
	}
	
	public void select_tab_click (double x, double y, int width, int height) {
		int over, close;
		
		if (MenuTab.suppress_event) {
			return;
		}
		
		this.width = width;
		this.height = height;
		
		is_over_close (x, y, out over, out close);

		if (over_close >= 0 && over == selected) {
			close_tab (over_close);
		} else {
			select_tab (over);
		}
	}
	
	public void add_tab (FontDisplay display_item, double tab_width = -1, bool always_open = false) {
		int s = (tabs.length () == 0) ? 0 : selected + 1;
		
		if (tab_width < 0) {
			//cr.text_extents (display_item.get_name (), out te); // this is not a good estimation, pango might solve it
			//tab_width = te.width + 30;
			
			tab_width = 9 * display_item.get_name ().char_count ();
			tab_width += 30;
		}
				
		tabs.insert (new Tab (display_item, tab_width, always_open), s);
		select_tab (s);
	}
	
	/** Returns true if the new item was added to the bar. */
	public bool add_unique_tab (FontDisplay display_item, double tab_width = -1, bool always_open = false) {
		bool i = select_tab_name (display_item.get_name ());

		if (!i) {
			add_tab (display_item, tab_width, always_open);
			return true;
		}
		
		return false;
	}
	
	public void draw (Context cr, int width, int height) {
		this.width = width;
		this.height = height;
		
		cr.save ();
		cr.rectangle (0, 0, width, height);
		cr.set_line_width (0);
		cr.set_source_rgba (230/255.0, 229/255.0, 228/255.0, 1);
		cr.fill_preserve ();
		cr.stroke ();
		cr.restore ();

		for (int j = 0; j < width; j++) {
			cr.set_source_surface ((!) bar_background, j, 0);
			cr.paint ();
		}

		if (has_scroll ()) {
			// left arrow
			cr.set_source_surface (to_previous_tab, 3, (height - to_previous_tab.get_height ()) / 2.0);
			cr.paint ();

			// right arrow
			cr.set_source_surface (next_tab, width - 19, (height - next_tab.get_height ()) / 2.0);
			cr.paint ();
		}
		
		draw_tabs (cr);
		
	}
	
	// this can be removed when tabs are not referenced by name
	string translate (string s) {
		switch (s) {
			case "Overview":
				return _("Overview");
			case "Kerning":
				return _("Kerning");
			case "Menu":
				return _("Menu");
			default:
				return s;
		}
	}
	
	private void draw_tabs (Context cr) {
		double close_opacity;
		double offset = 19;
		int i = 0;
		
		foreach (Tab t in tabs) {
			
			if (i < first_tab) {
				i++;
				continue;
			}

			cr.save ();
			cr.translate (offset, 0);
						
			if (offset + t.get_width () + next_tab.get_width () + 3 > width) {
				break;
			}
		
			// background
			if (i == selected) {
				for (int j = 0; j < t.get_width (); j++) {
					cr.set_source_surface ((!) tab3_right, j, 2);
					cr.paint ();
				}							
			} else if (i == over) {
				for (int j = 0; j < t.get_width (); j++) {
					cr.set_source_surface ((!) tab2_right, j, 2);
					cr.paint ();
				}				
			} else {
				for (int j = 0; j < t.get_width (); j++) {
					cr.set_source_surface ((!) tab1_right, j, 2);
					cr.paint ();
				}
			}
			
			// close
			if (t.has_close_button ()) {
				cr.set_line_width (1);
				
				close_opacity = (over_close == i) ? 1 : 0.2; 
				cr.set_source_rgba (0, 0, 0, close_opacity);
				
				cr.move_to (t.get_width () - 5, 11);
				cr.line_to (t.get_width () - 10, 16);

				cr.move_to (t.get_width () - 10, 11);
				cr.line_to (t.get_width () - 5, 16);
				
				cr.stroke ();	
			}

			cr.set_source_rgba (0, 0, 0, 1);
			cr.set_font_size (14);
			cr.move_to (8, 18);
			cr.show_text (translate (t.get_label ()));
			cr.stroke ();
			
			// edges
			if (tab1_left != null  && tab1_right != null && tab2_left != null  && tab2_right != null && tab3_left != null  && tab3_right != null) {
				if (i == selected) {
					cr.set_source_surface ((!) tab3_left, 0, 2);
					cr.paint ();
					
					cr.set_source_surface ((!) tab3_right, t.get_width () - 2, 2);
					cr.paint ();
				} else if (i == over) {
					cr.set_source_surface ((!) tab2_left, 0, 2);
					cr.paint ();

					cr.set_source_surface ((!) tab2_right, t.get_width () - 2, 2);
					cr.paint ();
				} else {
					cr.set_source_surface ((!) tab1_left, 0, 2);
					cr.paint ();

					cr.set_source_surface ((!) tab1_right, t.get_width () - 2, 2);
					cr.paint ();
				}
			}

			cr.restore ();
			
			offset += t.get_width () + 3;
			i++;
		}
	}
}

}
