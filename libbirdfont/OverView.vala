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

using Cairo;

namespace BirdFont {

/** A display with all glyphs present in this font. */
public class OverView : FontDisplay {
	public WidgetAllocation allocation = new WidgetAllocation ();
	
	int selected = 0;
	int first_visible = 0;
	int rows = 0;
	int items_per_row = 0;
	
	double view_offset_y = 0;
	double view_offset_x = 0;
	
	public signal void open_new_glyph_signal (unichar c);
	public signal void open_glyph_signal (GlyphCollection c);
	
	GlyphRange glyph_range;
	string search_query = "";
	
	List<OverViewItem> visible_items = new List<OverViewItem> ();
	List<GlyphCollection> deleted_glyphs = new List<GlyphCollection> ();
		
	bool all_available = true;
	
	/** Show unicode database info. */
	CharacterInfo? character_info = null;
	
	double scroll_size = 1;
	
	public OverView (GlyphRange? range = null) {
		GlyphRange gr;

		if (range == null) {
			gr = new GlyphRange ();
			set_glyph_range (gr);
		}

		reset_zoom ();

		this.open_glyph_signal.connect ((glyph_collection) => {
			TabBar tabs = MainWindow.get_tab_bar ();
			string n = glyph_collection.get_current ().name;
			bool selected = tabs.select_char (n);
			GlyphCanvas canvas;
			Glyph g = glyph_collection.get_current (); 
			
			if (!selected) {
				canvas = MainWindow.get_glyph_canvas ();
				tabs.add_tab (g);
				canvas.set_current_glyph (g);
				set_initial_zoom ();
				g.close_path ();
			}
		});

		this.open_new_glyph_signal.connect ((character) => {
			StringBuilder name = new StringBuilder ();
			TabBar tabs = MainWindow.get_tab_bar ();
			Font font = BirdFont.get_current_font ();
			bool selected;
			GlyphCollection? fg;
			Glyph glyph;
			GlyphCanvas canvas;
				
			name.append_unichar (character);
			selected = tabs.select_char (name.str);
					
			if (!selected) {
				if (all_available) {
					fg = font.get_glyph_collection_by_name (name.str);
				} else {
					fg = font.get_glyph_collection (name.str);
				}
				
				glyph = (fg == null) ? new Glyph (name.str, character) : ((!) fg).get_current ();
				font.add_glyph (glyph);
				tabs.add_tab (glyph);
				
				canvas = MainWindow.get_glyph_canvas ();
				canvas.set_current_glyph (glyph);
				
				glyph.close_path ();
				set_initial_zoom ();
			}
		});
		
		update_scrollbar ();
	}
	
	public static void search () {
		OverView ow = MainWindow.get_overview ();
		TextListener listener = new TextListener (_("Search"), ow.search_query, _("Filter"));
		
		listener.signal_text_input.connect ((text) => {
			OverView o = MainWindow.get_overview ();
			o.search_query = text;
		});
		
		listener.signal_submit.connect (() => {
			OverView o = MainWindow.get_overview ();
			GlyphRange r = CharDatabase.search (o.search_query);
			o.set_glyph_range (r);
			MainWindow.native_window.hide_text_input ();
			MainWindow.get_tab_bar ().select_tab_name ("Overview");
		});
		
		MainWindow.native_window.set_text_listener (listener);
	}
	
	public Glyph? get_current_glyph () 
	requires (selected > 0 && selected < visible_items.length ()) {
		OverViewItem oi = visible_items.nth (selected).data;
		if (oi.glyphs != null) {
			return ((!) oi.glyphs).get_current ();
		}
		return null;
	}
	
	private void set_initial_zoom () {
		Toolbox tools = MainWindow.get_toolbox ();
		ZoomTool z = (ZoomTool) tools.get_tool ("zoom_tool");
		z.store_current_view ();
		MainWindow.get_current_glyph ().default_zoom ();
		z.store_current_view ();
	}

	public double get_height () {
		double l;
		Font f;
		
		if (rows == 0) {
			return 0;
		}
				
		if (all_available) {
			f = BirdFont.get_current_font ();
			l = f.length ();
		} else {
			l = glyph_range.length ();
		}
				
		return 2.0 * OverViewItem.height * (l / rows);
	}

	public bool selected_char_is_visible () {
		return first_visible <= selected <= first_visible + items_per_row * rows;
	}

	public override bool has_scrollbar () {
		return true;
	}

	public override void scroll_wheel_up (double x, double y) {
		key_up ();
		update_scrollbar ();
		redraw_area (0, 0, allocation.width, allocation.height);
	}
	
	public override void scroll_wheel_down (double x, double y) {
		key_down ();
		update_scrollbar ();
		redraw_area (0, 0, allocation.width, allocation.height);
	}
	
	public override void selected_canvas () {
		redraw_area (0, 0, allocation.width, allocation.height);
		KeyBindings.singleton.set_require_modifier (true);
		update_scrollbar ();
	}
	
	public override void zoom_min () {
		OverViewItem.width = OverViewItem.DEFAULT_WIDTH * 0.5;
		OverViewItem.height = OverViewItem.DEFAULT_HEIGHT * 0.5;
		OverViewItem.margin = OverViewItem.DEFAULT_MARGIN * 0.5;
		
		redraw_area (0, 0, allocation.width, allocation.height);
	}
	
	public override void reset_zoom () {
		OverViewItem.width = OverViewItem.DEFAULT_WIDTH;
		OverViewItem.height = OverViewItem.DEFAULT_HEIGHT;
		OverViewItem.margin = OverViewItem.DEFAULT_MARGIN;
		
		redraw_area (0, 0, allocation.width, allocation.height);
	}

	public override void zoom_max () {
		OverViewItem.width = allocation.width;
		OverViewItem.height = allocation.height;
		redraw_area (0, 0, allocation.width, allocation.height);
	}
	
	public override void zoom_in () {
		OverViewItem.width *= 1.1;
		OverViewItem.height *= 1.1;
		OverViewItem.margin *= 1.1;		
		redraw_area (0, 0, allocation.width, allocation.height);
	}
	
	public override void zoom_out () {
		OverViewItem.width *= 0.9;
		OverViewItem.height *= 0.9;
		OverViewItem.margin *= 0.9;	
		redraw_area (0, 0, allocation.width, allocation.height);
	}

	public override void store_current_view () {
	}
	
	public override void restore_last_view () {
	}

	public override void next_view () {
	}

	public override string get_label () {
		return _("Overview");
	}
	
	public override string get_name () {
		return "Overview";
	}
	
	public void display_all_available_glyphs () {
		all_available = true;

		first_visible = 0;
		selected = 0;
	}
	
	OverViewItem get_selected_item () {
		return_val_if_fail (0 <= selected < visible_items.length (), 
			new OverViewItem (null, '\0', 0, 0));
			
 		return visible_items.nth (selected).data;
	}
	
	int get_items_per_row () {
		int i = 1;
		double l = OverViewItem.full_width ();
		while (l < allocation.width) {
			l += OverViewItem.full_width ();
			i++;
		}
		return i - 1;
	}
		
	void update_item_list () {
		string character_string;
		Font f = BirdFont.get_current_font ();
		GlyphCollection? glyphs = null;
		uint32 index;
		OverViewItem item;
		double x, y;
		unichar character;
		Glyph glyph;

		OverViewItem.margin = OverViewItem.width * 0.1;
		items_per_row = get_items_per_row ();
		rows = (int) (allocation.height /  OverViewItem.full_height ()) + 2;
		
		while (visible_items.length () > 0) {
			visible_items.remove_link (visible_items.first ());
		}
		
		visible_items = new List<OverViewItem> ();
		
		// update item list
		index = (uint32) first_visible;
		x = OverViewItem.margin;
		y = OverViewItem.margin;
		for (int i = 0; i < items_per_row * rows; i++) {
			if (all_available) {
				if (! (0 <= index < f.length ())) {
					break;
				}
				
				glyphs = f.get_glyph_collection_indice ((uint32) index);
				return_if_fail (glyphs != null);
				
				glyph = ((!) glyphs).get_current ();
				character_string = glyph.name;
				character = glyph.unichar_code;
			} else {
				if (!(0 <= index < glyph_range.get_length ())) {
					break;
				}
				
				character_string = glyph_range.get_char ((uint32) index);
				glyphs = f.get_glyph_collection_by_name (character_string);
				character = character_string.get_char (0);
			}
			
			item = new OverViewItem (glyphs, character, x, y);
			x += OverViewItem.full_width ();
			
			if (x + OverViewItem.full_width () >= allocation.width) {
				x = OverViewItem.margin;
				y += OverViewItem.full_height ();
			}
			
			item.selected = (i == selected);
			
			visible_items.append (item);
			index++;
		}
		
		// offset 
		item = get_selected_item ();
		if (item.y + OverViewItem.height > allocation.height) {
			view_offset_y = allocation.height - (item.y + OverViewItem.height);
		}

		if (item.y + view_offset_y < 0) {
			view_offset_y = 0;
		}
		
		foreach (OverViewItem i in visible_items) {
			i.y += view_offset_y;
			i.x += view_offset_x;
		}
	}
	
	public override void draw (WidgetAllocation allocation, Context cr) {
		this.allocation = allocation;
		
		update_item_list ();
		
		// clear canvas
		cr.save ();
		cr.set_source_rgba (1, 1, 1, 1);
		cr.rectangle (0, 0, allocation.width, allocation.height);
		cr.fill ();
		cr.restore ();
		
		// FIXME: cr.translate (view_offset_x, view_offset_y);
		foreach (OverViewItem i in visible_items) {
			i.draw (cr);
		}
		
		if (visible_items.length () == 0) {
			draw_empty_canvas (allocation, cr);
		}
		
		if (character_info != null) {
			draw_character_info (cr);
		}
	}
		
	void draw_empty_canvas (WidgetAllocation allocation, Context cr) {
		cr.save ();
		cr.set_source_rgba (156/255.0, 156/255.0, 156/255.0, 1);
		cr.move_to (30, 40);
		cr.set_font_size (18);
		cr.show_text (_("No glyphs in this view."));
		cr.restore ();
	}
	
	public void scroll_rows (int row_adjustment) {
		for (int i = 0; i < row_adjustment; i++) {
			scroll (-OverViewItem.height);
		}
		
		for (int i = 0; i > row_adjustment; i--) {
			scroll (OverViewItem.height);
		}
	}
	
	public void scroll_adjustment (double pixel_adjustment) {
		double l;
		Font f;
				
		if (all_available) {
			f = BirdFont.get_current_font ();
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
		
		if (all_available) {
			f = BirdFont.get_current_font ();
			l = f.length ();
		} else {
			l = glyph_range.length ();
		}
		
		if (r < 0) {
			scroll_top ();
			return;
		}
		
		default_position ();
		
		first_visible = (int) r;
	}
	
	public override void scroll_to (double position) requires (items_per_row > 0) {
		int64 r;
		double nrows;
		Font f;

		position = position / (1 - scroll_size);
		
		if (all_available) {
			f = BirdFont.get_current_font ();
			nrows = Math.ceil (f.length () / items_per_row);
		} else {
			nrows = Math.ceil (glyph_range.length () / items_per_row);
		}
		
		r = (int64) (Math.ceil (position * nrows) * items_per_row);
		scroll_to_position (r);
		
		redraw_area (0, 0, allocation.width, allocation.height);
	}
		
	private void scroll (double pixel_adjustment) {
		if (first_visible < 0 && pixel_adjustment < 0) {
			scroll_top ();
			return;
		}
				
		view_offset_y += pixel_adjustment;
		
		if (view_offset_y >= 0) {
			while (view_offset_y > OverViewItem.height) {			
				view_offset_y -= OverViewItem.height;
				first_visible -= items_per_row;
			}

			first_visible -= items_per_row;
			view_offset_y -= OverViewItem.height;
		} else if (view_offset_y < -OverViewItem.height) {
			view_offset_y = 0;
			first_visible += items_per_row;
		}
	}
	
	public void scroll_top () {
		selected = 0;
		first_visible = 0;
	}

	/** Returns true if the selected glyph is at the last row. */
	private bool last_row () {
		return visible_items.length () - selected <= items_per_row;
	}

	public void key_down () {
		Font f = BirdFont.get_current_font ();
		int64 len = (all_available) ? f.length () : glyph_range.length ();
		
		if (at_bottom () && last_row ()) {
			return;
		}
		
		selected += items_per_row;
		
		if (selected >= items_per_row * rows) {
			first_visible += items_per_row;
			selected -= items_per_row;
		}
		
		if (first_visible + selected >= len) {
			selected = (int) (len - first_visible - 1);
			
			if (selected < items_per_row * (rows - 1)) {
				first_visible -= items_per_row;
				selected += items_per_row;
			}
		}
		
		if (selected >= visible_items.length ()) { 
			selected = (int) (visible_items.length () - 1); 
		} 
	}

	public void key_right () {
		Font f = BirdFont.get_current_font ();
		int64 len = (all_available) ? f.length () : glyph_range.length ();

		if (at_bottom () && first_visible + selected + 1 >= len) {
			selected = (int) (visible_items.length () - 1);
			return;
		}
		
		selected += 1;
		
		if (selected >= items_per_row * rows) {
			first_visible += items_per_row;
			selected -= items_per_row;
			selected -= 1;
		}		

		if (first_visible + selected > len) {
			first_visible -= items_per_row;
			selected = (int) (len - first_visible - 1);
		}
	}
	
	public void key_up () {
		selected -= items_per_row;
		
		if (selected < 0) {
			first_visible -= items_per_row;
			selected += items_per_row;			
		}
		
		if (first_visible < 0) {
			first_visible = 0;		
		}	
	}
	
	public void key_left () {
		selected -= 1;

		if (selected < 0) {
			first_visible -= items_per_row;
			selected += items_per_row;
			selected += 1;			
		}

		if (first_visible < 0) {
			scroll_top ();
		}
	}
	
	public string get_selected_char () {
		Font f;
		Glyph? g;
		
		if (all_available) {
			f = BirdFont.get_current_font ();
			g = f.get_glyph_indice (selected);
			return_val_if_fail (g != null, "".dup ());
			return ((!) g).get_name ();
		}
		
		return glyph_range.get_char (selected);
	}
	
	public override void key_press (uint keyval) {
		redraw_area (0, 0, allocation.width, allocation.height);

		if (KeyBindings.modifier == CTRL) {
			return;
		}

		switch (keyval) {
			case Key.ENTER:
				open_current_glyph ();
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
				for (int i = 0; i < rows; i++) {
					key_up ();
				}
				return;
				
			case Key.PG_DOWN:
				for (int i = 0; i < rows; i++) {
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
		Font font = BirdFont.get_current_font ();
		string glyph_name;
		GlyphCollection? glyphs;

		if (all_available) {
			glyphs = font.get_glyph_collection_indice (selected);
		} else {
			glyph_name = glyph_range.get_char (selected);
			glyphs = font.get_glyph_collection (glyph_name);
		}
		
		if (glyphs != null) {
			deleted_glyphs.append ((!) glyphs);
			font.delete_glyph ((!) glyphs);
			MainWindow.get_tab_bar ().close_by_name (((!)glyphs).get_name ());
		}
		
		font.touch ();
	}
	
	public override void undo () {
		Font f = BirdFont.get_current_font ();
		
		if (deleted_glyphs.length () == 0) {
			return;
		}
			
		f.add_glyph_collection (deleted_glyphs.last ().data);
		deleted_glyphs.remove_link (deleted_glyphs.last ());
	}
	
	public void scroll_to_char (unichar c) {
		GlyphRange gr = glyph_range;
		int i, r, index;
		StringBuilder s = new StringBuilder ();
		string ch;
		Font font = BirdFont.get_current_font ();
		GlyphCollection? glyphs = null;
		Glyph glyph;
		
		index = -1;
		
		if (is_modifier_key (c)) {
			return;
		}
		
		s.append_unichar (c);
		ch = s.str;

		// selected char is visible
		i = 0;
		foreach (OverViewItem o in visible_items) {
			if (o.character == c) {
				selected = i;
				return;
			}
			i++;
		}
		
		// scroll to char
		if (all_available) {
			for (r = 0; r < font.length (); r += items_per_row) {
				for (i = 0; i < items_per_row; i++) {
					glyphs = font.get_glyph_collection_indice ((uint32) r + i);
					return_if_fail (glyphs != null);
					glyph = ((!) glyphs).get_current ();
					
					if (glyph.name == ch) {
						index = i;
					}
				}
				
				if (index > -1) {
					break;
				}
			}			
		} else {
			for (r = 0; r < gr.length (); r += items_per_row) {
				for (i = 0; i < items_per_row; i++) {
					if (gr.get_char (r + i) == ch) {
						index = i;
					}
				}
				
				if (index > -1) {
					break;
				}
			}
		}
		
		if (index > -1) {
			first_visible = r;
			selected = index;
		}
	}
	
	public override void double_click (uint button, double ex, double ey) {
		foreach (OverViewItem i in visible_items) {
			i.double_click (button, ex, ey);
		}
	
		redraw_area (0, 0, allocation.width, allocation.height);
	}

	public void set_character_info (CharacterInfo i) {
		character_info = i;
	}

	public override void button_press (uint button, double x, double y) {
		// DELETE selection_click (button, x, y);
		int index = 0;
		
		if (character_info != null) {
			character_info = null;
			redraw_area (0, 0, allocation.width, allocation.height);
			return;
		}
		
		foreach (OverViewItem i in visible_items) {
			if (i.click (button, x, y)) {
				selected = index;
			}
			
			index++;
		}
	
		redraw_area (0, 0, allocation.width, allocation.height);
	}

	/** Returns true if overview shows the last character. */
	private bool at_bottom () {
		Font f;
		double t = rows * items_per_row + first_visible;
		
		if (all_available) {
			f = BirdFont.get_current_font ();
			return t >= f.length ();
		}
		
		return t >= glyph_range.length ();
	}

	public void set_glyph_range (GlyphRange range) {
		GlyphRange? current = glyph_range;
		string c;
		
		if (current != null) {
			c = glyph_range.get_char (selected);
		}
		
		all_available = false;
		
		glyph_range = range;
		scroll_top ();

		// TODO: scroll down to c

		redraw_area (0, 0, allocation.width, allocation.height);
	}

	public void select_next_glyph () {
		key_right ();
	}
	
	public void open_current_glyph () 
	requires (0 <= selected < visible_items.length ())  {
		OverViewItem o = visible_items.nth (selected).data;
		o.edit_glyph ();
	}

	public void update_scrollbar () {
		Font f;
		double nrows = 0;
		
		if (rows == 0) {
			MainWindow.set_scrollbar_size (0);
			MainWindow.set_scrollbar_position (0);
		} else {
			if (all_available) {
				f = BirdFont.get_current_font ();
				nrows = Math.floor ((f.length ()) / rows);
			} else {
				nrows = Math.floor ((glyph_range.length ()) / rows);
			}
			
			if (nrows <= 0) {
				nrows = 1;
			}
			
			scroll_size = rows / nrows;
			MainWindow.set_scrollbar_size (scroll_size);
			MainWindow.set_scrollbar_position ((first_visible / rows) / nrows);
		}
	}

	/** Display one entry from the Unicode Character Database. */
	void draw_character_info (Context cr) 
	requires (character_info != null) {
		double x, y, w, h;
		int i;
		string unicode_value, unicode_description;
		string[] column;
		string entry;
		int len = 0;
		int length = 0;
		bool see_also = false;
		WidgetAllocation allocation = MainWindow.get_overview ().allocation;
		
		entry = ((!)character_info).get_entry ();
		
		foreach (string line in entry.split ("\n")) {
			len = line.char_count ();
			if (len > length) {
				length = len;
			}
		}
		
		x = allocation.width * 0.1;
		y = allocation.height * 0.1;
		w = allocation.width * 0.9 - x; 
		h = allocation.height * 0.9 - y;
		
		if (w < 8 * length) {
			w = 8 * length;
			x = (allocation.width - w) / 2.0;
		}
		
		if (x < 0) {
			x = 0;
		}
		
		// background	
		cr.save ();
		cr.set_source_rgba (1, 1, 1, 0.98);
		cr.rectangle (x, y, w, h);
		cr.fill ();
		cr.restore ();

		cr.save ();
		cr.set_source_rgba (0, 0, 0, 0.98);
		cr.set_line_width (2);
		cr.rectangle (x, y, w, h);
		cr.stroke ();
		cr.restore ();

		// database entry
		i = 0;
		foreach (string line in entry.split ("\n")) {
			if (i == 0) {
				column = line.split ("\t");
				return_if_fail (column.length == 2);
				unicode_value = "U+" + column[0];
				unicode_description = column[1];

				draw_info_line (unicode_description, cr, x, y, i);
				i++;

				draw_info_line (unicode_value, cr, x, y, i);
				i++;			
			} else {
				
				if (line.has_prefix ("\t*")) {
					draw_info_line (line.replace ("\t*", "•"), cr, x, y, i);
					i++;					
				} else if (line.has_prefix ("\tx (")) {
					if (!see_also) {
						i++;
						draw_info_line (_("See also:"), cr, x, y, i);
						i++;
						see_also = true;
					}
					
					draw_info_line (line.replace ("\tx (", "•").replace (")", ""), cr, x, y, i);
					i++;
				} else {

					i++;
				}
			}
		}
	}

	void draw_info_line (string line, Context cr, double x, double y, int row) {
		cr.save ();
		cr.set_font_size (12);
		cr.set_source_rgba (0, 0, 0, 1);
		cr.move_to (x + 10, y + 28 + row * 18 * 1.2);
		cr.show_text (line);
		cr.restore ();		
	}
}

}
