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

/** A display with all glyphs present in this font. */
public class OverView : FontDisplay {
	Allocation allocation;
	
	int rows = 0;
	int items_per_row = 0;
	uint32 first_character = 0;
	int64 first_visible = 0;
	uint32 selected = 0;
	
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

	Scrollbar scrollbar;
	
	bool all_avail = true;
	
	public OverView (GlyphRange? range = null) {
		GlyphRange gr;
		
		if (range == null) {
			gr = new GlyphRange ();
			set_glyph_range (gr);
		}
		
		reset_zoom ();

		this.open_glyph_signal.connect ((t, s) => {
			TabBar tabs = MainWindow.get_tab_bar ();
			Toolbox tools = MainWindow.get_toolbox ();
			bool selected = tabs.select_char (s);
			unichar new_char = s.get_char (0);
			Font f = Supplement.get_current_font ();
							
			if (!selected) {
				GlyphCollection? fg = f.get_glyph_collection (s);
				Glyph g = (fg == null) ? new Glyph (s, new_char) : ((!) fg).get_current ();
				ZoomTool z = (ZoomTool) tools.get_tool ("zoom_tool");
				
				stdout.printf (@"Open '%s' %u (%s)\n", s, new_char, Font.to_hex (new_char));
				
				z.store_current_view ();
				f.add_glyph (g);
				tabs.add_tab (g);
				
				MainWindow.get_glyph_canvas ().set_current_glyph (g);
				
				g.close_path ();
				g.default_zoom ();
				z.store_current_view ();
			}
		});
		
		scrollbar = new Scrollbar ();
		scrollbar.signal_scroll.connect ((delta, delta_last, absolute) => {
			if (absolute <= 0.002) {
				first_character = 0;
				first_visible = 0;
				selected = 0;
				scroll_top ();
			} else if (absolute >= 1) {
				scroll_bottom ();
			} else {
				scroll_to (absolute);
			}		
			
			redraw_area (0, 0, allocation.width, allocation.height);
		});
		
		update_scrollbar ();
	}
	
	void scroll_bottom () {
		Font f;
		
		if (all_avail) {
			f = Supplement.get_current_font ();
			scroll_to_position (f.length () - items_per_row * (rows - 1));
		} else {
			scroll_to_position (glyph_range.length () - items_per_row * (rows - 1));
		}
	}
	
	public double get_height () {
		double l;
		Font f;
		
		if (rows == 0) {
			return 0;
		}
				
		if (all_avail) {
			f = Supplement.get_current_font ();
			l = f.length ();
		} else {
			l = glyph_range.length ();
		}
				
		return 2.0 * nail_height * (l / rows);
	}

	public bool selected_char_is_visible () {
		return first_visible <= selected <= first_visible + items_per_row * rows;
	}

	public override void scroll_wheel_up (double x, double y) {
		key_up ();
		close_menus ();
		redraw_area (0, 0, allocation.width, allocation.height);
	}
	
	public override void scroll_wheel_down (double x, double y) {
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
	
	public void display_all_available_glyphs () {
		all_avail = true;
		
		first_character = 0;
		first_visible = 0;
		selected = 0;
	}
	
	private unowned List<GlyphCollection> get_visible_glyphs () {
		return visible_characters;
	}
	
	public void draw_caption (int row, double width, Context cr, double y, uint64 index_begin) {
		string character_string;
		double left_margin, x, caption_y; // for glyph caption
		uint64 index = index_begin;
		int i = row * items_per_row;
		Font f = Supplement.get_current_font ();
		
		cr.save ();
		cr.set_line_width (1);
		
		x = 0;
		
		cr.set_font_size (14);

		left_margin = 0;
			
		for (int j = 0; j < items_per_row; j++) {
			
			if (all_avail) {
				if (! (0 <= index < f.length ())) {
					break;
				}
				
				character_string = ((!) f.get_glyph_indice ((uint32) index)).get_name ();
			} else {
				if (!(0 <= index < glyph_range.get_length ())) {
					break;
				}
				
				character_string = glyph_range.get_char ((uint32) index);
			}
			
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
		double w, h;

		w = nail_width  - 19;
		h = nail_height - 22;
		
		scale = nail_zoom_height / (210.0 - 15.0);
		
		if (gl == null) {
			return false;
		}
		
		g = (!) gl;
		g.boundries (out x1, out y1, out x2, out y2);

		gx = 0;
		gy = h / scale - 40;
		
		Surface s = new Surface.similar (cr.get_target (), Content.COLOR_ALPHA, (int) w, (int) h);
		Context c = new Context (s);
		
		c.scale (scale, scale);				
		Svg.draw_svg_path (c, g.get_svg_data (), gx, gy);
		
		cr.save ();
		cr.set_source_surface (s, x - 6, y);
		cr.paint ();
		cr.restore ();

		return true;
	}

	// 150 * 190 px
	public override void draw (Allocation allocation, Context cr) {
		double width;
		double y;
		uint64 t;
		int i;
		int n_items;
		Font font = Supplement.get_current_font ();
					
		while (visible_characters.length () > 9) {
			visible_characters.remove_link (visible_characters.first ());
		}

		this.allocation = allocation;
		
		cr.save ();
		cr.set_source_rgba (1, 1, 1, 1);
		cr.rectangle (0, 0, allocation.width, allocation.height + nail_height);
		cr.fill ();
		cr.restore ();

		if (all_avail && font.length () == 0) {
			draw_empty_canvas (allocation, cr);
		}
		
		if (Supplement.experimental) {
			scrollbar.draw (cr, allocation);
		}
		
		n_items = ((allocation.width - 40) / nail_width);
		rows = (allocation.height / nail_height);

		if (items_per_row != n_items) { 	
			if (items_per_row == 0) {
				items_per_row = n_items;
				first_visible = first_character;
			
				key_down ();
				key_up ();
			}	else {
				items_per_row = n_items;
				first_visible = first_character;
			}
		}

		width = nail_width * items_per_row;
		view_offset_x = (allocation.width - width) / 2.0;
		
		cr.translate(view_offset_x, view_offset_y);
	
		y = 0;
		t = first_visible;
		i = 0;
		for (int j = 0; j < rows + 1; j++) {
			draw_caption (i, width, cr, y, t);

			t += items_per_row;
			y += nail_height;
			i++;
		}
		
	}

	void draw_empty_canvas (Allocation allocation, Context cr) {
		cr.save ();
		cr.set_source_rgba (156/255.0, 156/255.0, 156/255.0, 1);
		cr.move_to (30, 40);
		cr.set_font_size (18);
		cr.show_text (_("No glyphs in this view."));
		cr.restore ();
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
	
	public void scroll_adjustment (double pixel_adjustment) {
		double l;
		Font f;
				
		if (all_avail) {
			f = Supplement.get_current_font ();
			l = f.length ();
		} else {
			l = glyph_range.length ();
		}
		
		if (first_visible <= 0) {
			return;
		}

		if (first_visible + rows * items_per_row >= l) {
			return;
		}
		
		scroll ((int64) pixel_adjustment);
	}
	
	void default_position () {
		scroll_top ();
		scroll_rows (1);
	}
	
	void scroll_to_position (int64 r) {
		int64 l;
		Font f;
		
		if (all_avail) {
			f = Supplement.get_current_font ();
			l = f.length ();
		} else {
			l = glyph_range.length ();
		}
		
		// bottom
		if (r > l - items_per_row * rows) {
			return;
		}
		
		if (r < 0) {
			scroll_top ();
			return;
		}
		
		default_position ();

		first_visible = r;
		selected = (uint32) r;
		
		adjust_scroll ();
	}
	
	public void scroll_to (double percent) {
		int64 r;
		double l;
		Font f;
		
		if (all_avail) {
			f = Supplement.get_current_font ();
			l = f.length ();
		} else {
			l = glyph_range.length ();
		}
		
		l /= rows;
		r = (int64) (percent * l * items_per_row);
		scroll_to_position (r);
	}
		
	private void scroll (int64 pixel_adjustment) {

		if (first_visible < 0 && pixel_adjustment < 0) {
			scroll_top ();
			return;
		}
				
		view_offset_y += pixel_adjustment;
		
		if (view_offset_y >= 0) {
			while (view_offset_y > nail_height) {			
				view_offset_y -= nail_height;
				first_visible -= items_per_row;
			}

			first_visible -= items_per_row;
			view_offset_y -= nail_height;
		} else if (view_offset_y < -nail_height) {
			view_offset_y = 0;
			first_visible += items_per_row;
		}
		
	}
	
	public void scroll_top () {
		first_visible = first_character;
		view_offset_y = 0;
	}
	
	private int selected_offset_y (unichar item) {
		int64 di;
		int64 a, b;
		if (unlikely (items_per_row == 0)) return 0;
		
		a = (int64) item;
		b = (int64) first_visible;
		di = (a - b);
		
		return (int) (view_offset_y + ((di / items_per_row) * nail_height));
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

	public void key_down () {
		double l;
		Font f;
				
		if (all_avail) {
			f = Supplement.get_current_font ();
			l = f.length ();
		} else {
			l = glyph_range.length ();
		}
		
		update_scrollbar ();
		
		if (l == 0) return;
	
		if (at_bottom ()) {
			int len = (int) l;
			int s = (int) selected;
			
			if (len - items_per_row >= s) {
				selected += items_per_row; 
			} else if (s < len) {
				selected++;
			}
			
			if (selected >= len) {
				selected = len - 1;
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

	public void key_up () {
		update_scrollbar ();

		if (selected < first_character) {		
			warn_if_reached ();
		}
		
		if (selected < first_character + items_per_row) {
			scroll_top ();
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

		if (first_visible < first_character) {
			scroll_top ();
		}
	}	
	
	public void open_current_glyph () {
		key_press (Key.ENTER);
	}

	public void select_next_glyph () {
		key_press (Key.RIGHT);
	}

	public void key_right () {		
		uint len;
		Font f;
		
		if (all_avail) {
			f = Supplement.get_current_font ();
			len = f.length ();
		} else {
			len = glyph_range.length ();
		}
		
		if (len == 0) return;
		
		selected++;
		
		if (selected >= len) {
			selected = len - 1;
		}

		if (selected_offset_y (selected) > allocation.height - nail_height) {
			selected -= items_per_row;
			key_down ();
		}
	}
	
	public void key_left () {
		if (selected > first_character) {
			selected--;					
			if (selected_offset_y (selected) < 0) {
				selected -= items_per_row;
				key_up ();
			}
		}
	}
	
	public string get_selected_char () {
		Font f;
		Glyph? g;
		
		if (all_avail) {
			f = Supplement.get_current_font ();
			g = f.get_glyph_indice (selected);
			return_val_if_fail (g != null, "".dup ());
			return ((!) g).get_name ();
		}
		
		return glyph_range.get_char (selected);
	}
	
	public override void key_press (uint keyval) {
		redraw_area (0, 0, allocation.width, allocation.height);
		close_menus ();

		if (KeyBindings.modifier == CTRL) {
			return;
		}

		switch (keyval) {
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

		scroll_to_char (keyval);
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
		selected = c;
		set_glyph_range (gr);
	}
		
	public override void motion_notify (double x, double y) {
		if (x > allocation.x - 10) {
			scrollbar.motion_notify ((int) x, (int) y);
		}
	}
	
	public override void button_release (int button, double ex, double ey) {
		if (ex > allocation.x - 10) {
			scrollbar.button_release (button, ex, ey);
		}
	}
	
	public override void double_click (uint button, double ex, double ey) {
		selection_click (button, ex, ey);
		open_glyph_signal (get_selected_char ());
	}
	
	private void selection_click (uint button, double ex, double ey) {
		double x = view_offset_x;
		double y = view_offset_y;

		// click in margin
		int n_items = (allocation.width - 40 / nail_width);
		double m = (allocation.width - 40 - (n_items * nail_width)) / 2.0;
		
		bool menu_action = false;
		
		Font f;
		uint len;

		redraw_area (0, 0, allocation.width, allocation.height);

		if (all_avail) {
			f = Supplement.get_current_font ();
			len = f.length ();
		} else {
			len = glyph_range.length ();
		}
		
		foreach (GlyphCollection g in get_visible_glyphs ()) {
			bool a;

			a = g.get_version_list ().menu_item_action (ex - view_offset_x, ey - view_offset_y); // select one item on the menu
			
			if (a) {
				return;
			}
						
			a = g.get_version_list ().menu_icon_action (ex - view_offset_x, ey - view_offset_y); // open menu
			
			if (a) {
				menu_action = true;
			}
		}
		
		if (ex < m) {
			ex = m + 1;
		}
		
		if (ex > allocation.width - m) {
			ex = allocation.width - m - 1;
		}
		
		if (ey < 5) {
			ey = 5;
		}
		
		if (ey > allocation.height - 5) {
			ey = allocation.height - 5;
		}
			
		// empty set
		if (len == 0) return;

		// scroll to the selected glyph
		selected = (uint32) first_visible;

		while (y < ey < allocation.height) {
			selected += items_per_row;
			y += nail_height;
		}
		selected -= items_per_row;

		while (x < ex < allocation.width) {
			selected++;
			x += nail_width;
		}
		
		selected--;
	
		if (at_bottom () && selected >= len) {
			selected = len - 1;
		}
		
		adjust_scroll ();
		
		adjust_scroll ();
		adjust_scroll ();
	}
	
	public override void button_press (uint button, double x, double y) {
		if (x > allocation.width - 10) {
			if (Supplement.experimental) {
				scrollbar.button_press (button, x, y);
			}
		} else {
			selection_click (button, x, y);
		}
	}

	/** Returns true if overview shows the last character. */
	private bool at_bottom () {
		Font f;
		double t = rows * items_per_row + items_per_row + first_visible;
		
		if (all_avail) {
			f = Supplement.get_current_font ();
			return t >= f.length ();
		}
		
		return t >= glyph_range.length ();
	}

	public void set_glyph_range (GlyphRange range) {
		GlyphRange? current = glyph_range;
		string c = "";
		bool done = false;
		uint32 i;
		uint32 len = 0;
		
		if (current != null) {
			c = glyph_range.get_char (selected);
		}
		
		all_avail = false;
		
		glyph_range = range;

		// Todo: optimized search when full range is selected.
		
		// scroll to the selected character
		if (c == "") {
			c = glyph_range.get_char (0);
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
			for (i = (uint32) first_visible; i < first_visible + items_per_row * (rows + 1); i++) {
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
			Toolbox.select_tool_by_name ("custom_character_set");
			warning (@"No glyph \"$c\"\n");
			return;
		}
		
		adjust_scroll ();
		
		if (at_bottom ()) {
			while (c != glyph_range.get_char (selected) && glyph_range.get_length () >= items_per_row) {
				key_right ();	
				if (selected >= glyph_range.get_length () - items_per_row) {
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

		update_scrollbar ();
		redraw_area (0, 0, allocation.width, allocation.height);
	}

	public void update_scrollbar () {
		double len;
		Font f;
		
		if (all_avail) {
			f = Supplement.get_current_font ();
			len = f.length ();
		} else {
			len = glyph_range.get_length ();
		}
		
		scrollbar.set_handle_size (items_per_row * rows / len);
		scrollbar.set_handle_position (first_visible / len);
	}
}

}
