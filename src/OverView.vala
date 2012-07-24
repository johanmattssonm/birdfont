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
using Gtk;
using Gdk;

namespace Supplement {

/** A display with all glyphs present in this font. */
class OverView : FontDisplay {
	Allocation allocation;
	
	int rows = 0;
	int items_per_row = 0;
	unichar first_character = 1;
	unichar first_visible = 1;
	unichar selected = 1;
	
	double view_offset_y = 0;
	double view_offset_x = 0;
	
	int nail_height = 0;
	int nail_width = 0;

	double nail_zoom_height = 0;
	double nail_zoom_width = 0;
	
	public signal void open_glyph_signal (string c);

	GlyphRange glyph_range;

	List<GlyphCollection> visible_characters = new List<GlyphCollection> ();

	List<unichar> zoom_list = new List<unichar> ();
	int zoom_list_index = 0;

	List<GlyphCollection> deleted_glyphs = new List<GlyphCollection> ();

	public OverView (GlyphRange? range = null) {
		if (range == null) {
			glyph_range = new GlyphRange ();
			glyph_range.use_default_range ();
		}
		
		reset_zoom ();

		this.open_glyph_signal.connect ((t, s) => {
			TabBar tabs = MainWindow.get_tab_bar ();
			Toolbox tools = MainWindow.get_toolbox ();
			bool selected = tabs.select_char (s);
			unichar new_char = s.get_char (0);
			Font f = Supplement.get_current_font ();
			
			stdout.printf ("Open '%s' character: %u (%s)\n", s, new_char, Font.to_hex (new_char));
			
			if (f.get_glyph_collection (s) == null) print ("NO GLYPH \n");
					
			if (!selected) {
				GlyphCollection? fg = f.get_glyph_collection (s);
				Glyph g = (fg == null) ? new Glyph (s, new_char) : ((!) fg).get_current ();
				ZoomTool z = (ZoomTool) tools.get_tool ("zoom_tool");
				
				z.store_current_view ();
				f.add_glyph (g);
				tabs.add_tab (g);
				
				MainWindow.get_glyph_canvas ().set_current_glyph (g);
				
				g.default_zoom ();
				z.store_current_view ();
			}
		});

	}

	public override void scroll_wheel_up (Gdk.EventScroll e) {
		key_up ();
		close_menus ();
		redraw_area (0, 0, allocation.width, allocation.height);
	}
	
	public override void scroll_wheel_down (Gdk.EventScroll e) {
		key_down ();
		close_menus ();
		redraw_area (0, 0, allocation.width, allocation.height);
	}
	
	public override void selected_canvas () {
		redraw_area (0, 0, allocation.width, allocation.height);
		KeyBindings.singleton.set_require_modifier (true);
	}
	
	public override void zoom_min () {
		int minw = 26 * 2;
		int minh = 46 * 2;
		
		if (zoom_value_in_range (minw, minh)) {
			nail_width = minw;
			nail_height = minh;
				
			nail_zoom_height = minw; 
			nail_zoom_width = minh;		
		
			adjust_scroll ();
			redraw_area (0, 0, allocation.width, allocation.height);
		} else {
			warn_if_reached ();
		}	
	}
	
	public override void reset_zoom () {
		nail_height = 210;
		nail_width = 150;
		
		nail_zoom_height = nail_height; 
		nail_zoom_width = nail_width;
		
		adjust_scroll ();
		redraw_area (0, 0, allocation.width, allocation.height);
	}

	public override void zoom_max () {
		if (zoom_value_in_range (allocation.width, allocation.height)) {
			nail_width = allocation.width;
			nail_height = allocation.height;
				
			nail_zoom_height = allocation.height; 
			nail_zoom_width = allocation.width;		
		
			adjust_scroll ();
			redraw_area (0, 0, allocation.width, allocation.height);
		} else {
			warn_if_reached ();
		}
	}
	
	public override void zoom_in () {
		double w = (1.1 * nail_width);
		double h = (1.1 * nail_height);
		int nw = (int) w;
		int nh = (int) h;
		
		if (zoom_value_in_range (nw, nh)) {
			nail_width = nw;
			nail_height = nh;
			
			nail_zoom_height = h; 
			nail_zoom_width = w;
			
			adjust_scroll ();
			redraw_area (0, 0, allocation.width, allocation.height);
		}
	}
	
	public override void zoom_out () {
		double w = (nail_width / 1.1);
		double h = (nail_height / 1.1);
		int nw = (int) w;
		int nh = (int) h;
		
		if (zoom_value_in_range (nw, nh)) {
			nail_width = nw;
			nail_height = nh;

			nail_zoom_height = h; 
			nail_zoom_width = w;
			
			adjust_scroll ();		
			redraw_area (0, 0, allocation.width, allocation.height);
		}
	}
	
	private bool zoom_value_in_range (int w, int h) {
		return (25 < w <= allocation.width && 45 < h <= allocation.height);
	}

	public override void store_current_view () {
		if (zoom_list_index + 1 < zoom_list.length ()) {
			unowned List<unichar> n = zoom_list.nth (zoom_list_index);
			while (n != zoom_list.last ()) zoom_list.delete_link (zoom_list.last ());
		}
		
		zoom_list.append (selected);
		zoom_list_index = (int) zoom_list.length () - 1;
		
		if (zoom_list.length () > 50) zoom_list.delete_link (zoom_list.first ());
	}
	
	public override void restore_last_view () 
		requires (zoom_list.length () > 0)
	{		
		if (zoom_list_index - 1 < 0 || zoom_list.length () == 0)
			return;
		
		zoom_list_index--;
	}

	public override void next_view () 
		requires (zoom_list.length () > 0)
	{
		if (zoom_list_index + 1 >= zoom_list.length ())
			return;
		
		zoom_list_index++;
	}

	
	public override string get_name () {
		return "Overview";
	}
	
	private unowned List<GlyphCollection> get_visible_glyphs () {
		return visible_characters;
	}
	
	public void draw_caption (int row, double width, Context cr, double y, unichar index_begin) {
		string character_string;
		double left_margin, x, caption_y; // for glyph caption
		unichar index = index_begin;
		int i = row * items_per_row;
		cr.save ();
		cr.set_line_width (1);
		
		x = 20;
		
		cr.set_font_size (14);

		left_margin = 0;
		
		if (nail_width >= 70)
			left_margin = 14;
		else if (nail_width >= 60)
			left_margin = 9;
		else if (nail_width >= 36)
			left_margin = -2;
		else if (nail_width >= 26)
			left_margin = -8;
		else
			warning ("Max zoom level reached");
					
		while (x < width) {
			if (index > glyph_range.get_length ()) {
				break;
			}
			
			character_string = glyph_range.get_char (index);
			
			cr.save ();
			draw_thumbnail (cr, character_string, x, y);
			cr.restore ();

			cr.save ();
						
			if (index == selected) {
				cr.set_source_rgba (142/255.0, 158/255.0, 190/255.0, 1);
			} else {
				cr.set_source_rgba (164/255.0, 185/255.0, 215/255.0, 1);
			}
			
			cr.set_line_join (LineJoin.ROUND);
			cr.set_line_width(12);
			
			cr.rectangle (x, y + nail_height - 20, nail_width - 30, 10);			
			cr.stroke ();
			cr.restore ();
			
			draw_menu (cr, character_string, x, y);
			
			caption_y = y + 10 + nail_height - 20;
			
			cr.move_to (x, caption_y);
			cr.show_text (character_string);
			
			x += nail_width;
			index++;
			i++;
		}
		
		cr.stroke();
	}
		
	private void draw_menu (Context cr, string name, double x, double y) {
		GlyphCollection? gl = Supplement.get_current_font ().get_glyph_collection (name);
		GlyphCollection g;
		DropMenu menu;
		
		if (gl == null) {
			return;
		}
		
		g = (!) gl;
		
		menu = g.get_version_list ();
		menu.set_position (x + nail_width - 40, y + nail_height - 21);
		menu.draw_icon (cr);
		menu.draw_menu (cr);
		
		visible_characters.append (g);
	}
		
	private bool draw_thumbnail (Context cr, string name, double x, double y) {
		Glyph? gl = Supplement.get_current_font ().get_glyph (name);
		Glyph g;
		double gx, gy;
		
		double x1, x2, y1, y2;
		
		double scale = nail_zoom_width / 150.0;
		
		if (gl == null) {
			return false;
		}
		
		g = (!) gl;
			
		g.boundries (out x1, out y1, out x2, out y2);
		
		/*
		if (x1 < -8500) return false; 
		if (x2 > 8500) return false;
		if (y1 < -7600) return false;
		if (y2 > 7600) return false;
		*/
		
		gx = x + nail_width / 2.0 - g.get_width () / 2.0;
		gy = y + nail_height;
		
		gx /= scale;
		gy /= scale;

		gx -= 20;
		gy -= 80;
		
		Svg.draw_svg_path (cr, g.get_svg_data (), gx, gy, scale);

		return true;
	}

	// 150 * 190 px
	public override void draw (Allocation allocation, Context cr) {
		double width;
		double y;
		unichar t;
		int i;

		while (visible_characters.length () > 9) {
			visible_characters.remove_link (visible_characters.first ());
		}

		this.allocation = allocation;
		
		cr.save ();
		cr.set_source_rgba (1, 1, 1, 1);
		cr.rectangle (0, 0, allocation.width, allocation.height + nail_height);
		cr.fill ();
		cr.restore ();
		
		int n_items = (allocation.width / nail_width);
		rows = (allocation.height / nail_height);
				
		if (items_per_row != n_items) {
				
			if (items_per_row == 0) {
				items_per_row = n_items;
				first_visible = first_character;
			}	else {
				items_per_row = n_items;
				first_visible = first_character;
				
				while (selected < first_visible)
					scroll (-nail_height);
					
				while (selected < first_visible + rows * n_items)
					scroll (nail_height);
					
			}
			
			scroll_top ();
			
			while (first_visible <= selected) {
				scroll_rows (1);
			}
			scroll_rows (-2);
		}

		width = nail_width * items_per_row;
		view_offset_x = (allocation.width - width) / 2.0;
		
		cr.translate(view_offset_x, view_offset_y);
	
		y = 0;
		t = first_visible;
		i = 0;
		while (y < allocation.height + nail_height) {
			draw_caption (i, width, cr, y, t);

			t += (allocation.width / nail_width);
			y += nail_height;
			i++;
		}
		
		draw_menus (allocation, cr);
	}

	private void draw_menus (Allocation allocation, Context cr) {
	}

	private void close_menus () {
	}
	
	public void scroll_rows (int row_adjustment) {
		for (int i = 0; i < row_adjustment; i++) {
			scroll (-nail_height);
		}
		
		for (int i = 0; i > row_adjustment; i--) {
			scroll (nail_height);
		}
	}
	
	public void scroll (int pixel_adjustment) {
		view_offset_y += pixel_adjustment;
		
		if (view_offset_y >= 0) {			
			view_offset_y = -nail_height;
			first_visible -= items_per_row;
		}
		
		if (view_offset_y < -nail_height) {
			view_offset_y = 0;
			first_visible += items_per_row;
		}
	}
	
	public void scroll_top () {
		first_visible = first_character;
		view_offset_y = 0;
	}
	
	private int selected_offset_y (unichar item) {
		if (unlikely (items_per_row == 0)) return 0;
		return (int) (view_offset_y + (((item - first_visible) / items_per_row) * nail_height));
	}

	/** Make selected item fully visible if it partly off screen. */
	private void adjust_scroll ()  {
		int off =  selected_offset_y (selected);

		if (off < 0)  {
			close_menus ();
			scroll (-1 * off);
		} else if (off > allocation.height - nail_height) {
			scroll ((allocation.height - nail_height) - off);
		}
	}

	private void key_down () {
		if (glyph_range.length () == 0) return;
	
		if (at_bottom ()) {
			int len = (int) glyph_range.get_length ();
			int s = (int) selected;
			
			if (len - items_per_row >= s) {
				selected += items_per_row; 
			} else if (s < len) {
				selected++;
			}
			
			if (selected > len) {
				selected = len;
			}
			
			adjust_scroll ();
			
			return;
		}
		
		selected += items_per_row;
		
		if (selected > rows * items_per_row + first_visible) {
				scroll (-nail_height);
		}
		
		adjust_scroll ();
	}

	private void key_up () {
		
		if (glyph_range.length () == 0) return;
				
		if (selected < first_character + items_per_row) {
			return;
		}
		
		if (selected - items_per_row >= first_character) {
			selected -= items_per_row;
			if (selected < first_visible) {
				scroll (-nail_height);
			}
		} 
		
		if (first_visible < first_character) {
			selected = first_character;
		}
		
		adjust_scroll ();
	}	
	
	public void open_current_glyph () {
		EventKey e = { 0 };
		e.type = EventType.KEY_PRESS;
		e.keyval = Key.ENTER;
		key_press (e);
	}

	public void select_next_glyph () {
		EventKey e = { 0 };
		e.type = EventType.KEY_PRESS;
		e.keyval = Key.RIGHT;
		key_press (e);
	}

	public void key_right () {		
		int len = (int) glyph_range.get_length ();
		
		if (len == 0) return;
		
		selected++;
		
		if (selected > len) {
			selected = len;
		}

		if (selected_offset_y (selected) > allocation.height - nail_height) {
			selected -= items_per_row;
			key_down ();
		}		
	}
	
	public void key_left () {
		if (selected > first_character && glyph_range.length () != 0) {
			selected--;					
			if (selected_offset_y (selected) < 0) {
				selected -= items_per_row;
				key_up ();
			}
		}
	}
	
	public string get_selected_char () {
		return glyph_range.get_char (selected);
	}
	
	public override void key_press (EventKey e) {
		redraw_area (0, 0, allocation.width, allocation.height);
		close_menus ();
	
		if (e.type != EventType.KEY_PRESS) {
			return;
		}

		if (KeyBindings.modifier == CTRL) {
			return;
		}

		switch (e.keyval) {
			case Key.ENTER:
				open_glyph_signal (get_selected_char ());
				return;
			
			case Key.UP:
				key_up ();
				return;
				
			case Key.RIGHT:
				key_right ();
				return;
				
			case Key.LEFT:
				key_left ();
				return;
				
			case Key.DOWN:
				key_down ();
				return;
				
			case Key.PG_UP:
				for (int i = 0; i++ < rows; i++) {
					key_up ();
				}
				return;
				
			case Key.PG_DOWN:
				for (int i = 0; i++ < rows; i++) {
					key_down ();
				}
				return;
				
			case Key.DEL:
				delete_selected_glyph ();
				return;
		}

		scroll_to_char (e.keyval);
	}

	public void delete_selected_glyph () {
		delete_glyph (glyph_range.get_char (selected));
	}
		
	public void delete_glyph (string g) {
		GlyphCollection? gc;
		Font f = Supplement.get_current_font ();
		
		gc = f.get_glyph_collection (g);

		if (gc != null) {
			deleted_glyphs.append ((!) gc);
		}

		select_next_glyph ();
		f.delete_glyph (g);
		MainWindow.get_tab_bar ().close_by_name (g);
		set_glyph_range (glyph_range);
		f.touch ();
	}
	
	public override void undo () {
		Font f = Supplement.get_current_font ();
		
		if (deleted_glyphs.length () == 0) {
			return;
		}
		
		f.add_glyph_collection (deleted_glyphs.last ().data);
		deleted_glyphs.remove_link (deleted_glyphs.last ());
	}
	
	public void scroll_to_char (unichar c) {
		GlyphRange gr = glyph_range;
		GlyphRange full = new GlyphRange ();
		
		if (is_modifier_key (c)) {
			return;
		}
		
		full.use_full_unicode_range ();
		
		set_glyph_range (full);
		selected = c + 1;
		set_glyph_range (gr);
	}
		
	public override void motion_notify (EventMotion e) {
	}
	
	public override void button_release (EventButton event) {
	}
	
	public override void leave_notify (EventCrossing e) {
	}
	
	private void selection_click (EventButton e) {
		double x = view_offset_x;
		double y = view_offset_y;

		unichar current = selected;

		// click in margin
		int n_items = (allocation.width / nail_width);
		double m = (allocation.width - (n_items * nail_width)) / 2.0;
		
		bool menu_action = false;
	
		foreach (GlyphCollection g in get_visible_glyphs ()) {
			bool a;

			a = g.get_version_list ().menu_item_action (e.x - view_offset_x, e.y - view_offset_y); // select one item on the menu
			
			if (a) {
				return;
			}
						
			a = g.get_version_list ().menu_icon_action (e.x - view_offset_x, e.y - view_offset_y); // open menu
			
			if (a) {
				menu_action = true;
			}
		}
		
		if (e.x < m) {
			e.x = m + 1;
		}
		
		if (e.x > allocation.width - m) {
			e.x = allocation.width - m - 1;
		}
		
		if (e.y < 5) {
			e.y = 5;
		}
		
		if (e.y > allocation.height - 5) {
			e.y = allocation.height - 5;
		}
			
		// empty set
		if (glyph_range.length () == 0) return;

		// scroll to the selected glyph
		selected = first_visible;

		while (y < e.y < allocation.height) {
			selected += items_per_row;
			y += nail_height;
		}
		selected -= items_per_row;

		while (x < e.x < allocation.width) {
			selected++;
			x += nail_width;
		}
		
		selected--;
		
		if (current == selected && !menu_action) {
			open_glyph_signal (glyph_range.get_char (selected));
		}
		
		adjust_scroll ();
		adjust_scroll ();
		
		redraw_area (0, 0, allocation.width, allocation.height);
	}
	
	public override void button_press (EventButton e) {
		selection_click (e);
	}

	/** Returns true if overview shows the last character. */
	private bool at_bottom () {
		return (rows * items_per_row + items_per_row + first_visible > glyph_range.length ());
	}

	public void set_glyph_range (GlyphRange range) {
		string c = glyph_range.get_char (selected);
		bool done = false;
		unichar i;
		unichar len;
		
		glyph_range = range;
		
		// Todo: optimized search when full range is selected.
		
		// scroll to the selected character
		if (c == "") {
			print (@"No glyph.. \"$c\" move to a\n");
			c = "a";
		}
		
		if (items_per_row == 0) {
			return;
		}
		
		scroll_top ();

		// Skip scroll if this is a unassigned character
		if (c.char_count () > 1) {
			return;
		}

		while (true) {
			for (i = first_visible; i < first_visible + items_per_row * (rows + 1); i++) {
				if (range.get_char (i) == c) {
					selected = i;
					done = true;
					break;
				}
			}
			
			if (done) break;
			if (at_bottom ()) break;

			scroll_rows (rows);
		}

		if (unlikely (!done)) {
			print (@"No glyph.. \"$c\"\n");
			selected = 0;
		}
		
		//scroll_rows (-1);
		adjust_scroll ();
		
		if (at_bottom ()) {
			while (c != glyph_range.get_char (selected) && glyph_range.get_length () > items_per_row) {
				key_right ();	
				if (selected > glyph_range.get_length () - items_per_row) {
					break;
				}
			}

			len = glyph_range.get_length ();
			for (i = selected; i < len; i++) {
				if (c == glyph_range.get_char (i)) {
					break;
				}
			}

			if (i == len) {
				selected = first_character;
				scroll_top ();
			}
		}
		
		redraw_area (0, 0, allocation.width, allocation.height);
	}

}

}
