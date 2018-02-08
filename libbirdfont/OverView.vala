/*
	Copyright (C) 2012 - 2016 Johan Mattsson

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
	
	public OverViewItem selected_item = new OverViewItem ();

	public Gee.ArrayList<GlyphCollection> copied_glyphs = new Gee.ArrayList<GlyphCollection> ();
	public Gee.ArrayList<GlyphCollection> selected_items = new Gee.ArrayList<GlyphCollection> ();	
	
	int selected = 0;
	int first_visible = 0;
	int rows = 0;
	int items_per_row = 0;
	
	double view_offset_y = 0;
	double view_offset_x = 0;
	
	public signal void open_new_glyph_signal (unichar c);
	public signal void open_glyph_signal (GlyphCollection c);
	
	public GlyphRange glyph_range {
		get {
			return _glyph_range;
		}
		
		set {
			_glyph_range = value;
		}
	}
	
	GlyphRange _glyph_range;
	
	string search_query = "";
	
	public Gee.ArrayList<OverViewItem> visible_items = new Gee.ArrayList<OverViewItem> ();
	
	/** List of undo commands. */
	public Gee.ArrayList<OverViewUndoItem> undo_items = new Gee.ArrayList<OverViewUndoItem> ();
	public Gee.ArrayList<OverViewUndoItem> redo_items = new Gee.ArrayList<OverViewUndoItem> ();
	
	/** Show all characters that has been drawn. */
	public bool all_available {
		set {
			_all_available = value;
			update_item_list ();
		}
		
		get {
			return _all_available;
		}
	}
	
	bool _all_available = false;
	
	/** Show unicode database info. */
	CharacterInfo? character_info = null;
	
	double scroll_size = 1;
	const double UCD_LINE_HEIGHT = 17 * 1.3;

	private bool update_scheduled = true;

	public OverView (GlyphRange? range = null,
		bool open_selected = true, bool default_character_set = true) {
			
		GlyphRange gr;
		
		if (range == null) {
			gr = new GlyphRange ();
			set_current_glyph_range (gr);
		}

		if (open_selected) {
			this.open_glyph_signal.connect ((glyph_collection) => {
				TabBar tabs = MainWindow.get_tab_bar ();
				string n = glyph_collection.get_current ().name;
				bool selected = tabs.select_char (n);
				GlyphTab glyph_tab;
				
				if (!selected) {
					glyph_tab = new GlyphTab (glyph_collection);
					tabs.add_tab (glyph_tab, true, glyph_collection);
					set_glyph_zoom (glyph_collection);
					PenTool.update_orientation ();
				}
			});

			this.open_new_glyph_signal.connect ((character) => {
				// ignore control characters
				if (character <= 0x1F || character == 0xFFFF) { 
					return;
				}
				
				create_new_glyph (character);
			});
		}

		if (default_character_set) {
			IdleSource idle = new IdleSource ();

			idle.set_callback (() => {
				use_default_character_set ();
				selected_canvas ();
				return false;
			});
			
			idle.attach (null);
		}
						
		update_item_list ();
		update_scrollbar ();
		reset_zoom ();
		
		string? zoom = Preferences.get ("overview_zoom");
		
		if (zoom != null) {
			string z = (!) zoom;
			
			if (z != "") {
				set_zoom (double.parse (z));
			}			
		}
	}

	public void reset_cache () {
		foreach (OverViewItem i in visible_items) {
			i.clear_cache ();
		}
	}

	public Glyph? get_selected_glyph () {
		if (selected_items.size == 0) {
			return null;
		}
		
		return selected_items.get (0).get_current ();
	}
	
	public void select_all_glyphs () {
		Font f;
		GlyphCollection? glyphs;
		
		f = BirdFont.get_current_font ();
		
		for (int index = 0; index < f.length (); index++) {
			glyphs = f.get_glyph_collection_index ((uint32) index);
			return_if_fail (glyphs != null);
			
			selected_items.add ((!) glyphs);
		}
		
		foreach (OverViewItem item in visible_items) {
			item.selected = item.glyphs != null;
		}
		
		GlyphCanvas.redraw ();
	}
	
	public void use_default_character_set () {
		GlyphRange gr = new GlyphRange ();
		all_available = false;
		DefaultCharacterSet.use_default_range (gr);
		set_current_glyph_range (gr);
		OverviewTools.update_overview_characterset ();
		FontDisplay.dirty_scrollbar = true;
	}
	
	public GlyphCollection create_new_glyph (unichar character) {
		StringBuilder name = new StringBuilder ();
		TabBar tabs = MainWindow.get_tab_bar ();
		bool selected;
		Glyph glyph;
		GlyphCollection glyph_collection;
		GlyphCanvas canvas;
		GlyphTab glyph_tab; 
		
		glyph_collection = MainWindow.get_current_glyph_collection ();
		name.append_unichar (character);
		selected = tabs.select_char (name.str);
				
		if (!selected) {
			glyph_collection = add_character_to_font (character);
			glyph_tab = new GlyphTab (glyph_collection);
			glyph = glyph_collection.get_current ();
			glyph.layers.add_layer (new Layer ());
			tabs.add_tab (glyph_tab, true, glyph_collection);
			
			selected_items.add (glyph_collection);
			
			canvas = MainWindow.get_glyph_canvas ();
			canvas.set_current_glyph_collection (glyph_collection);
			
			set_glyph_zoom (glyph_collection);
		} else {
			warning ("Glyph is already open");
		}
		
		OverviewTools.update_overview_characterset ();
		return glyph_collection;
	}
		
	public GlyphCollection add_empty_character_to_font (unichar character, bool unassigned, string name) {
		return add_character_to_font (character, true, unassigned);
	}
	
	public GlyphCollection add_character_to_font (unichar character, bool empty = false,
			bool unassigned = false, string glyph_name = "") {
		StringBuilder name = new StringBuilder ();
		Font font = BirdFont.get_current_font ();
		GlyphCollection? fg;
		Glyph glyph;
		GlyphCollection glyph_collection;

		if (glyph_name == "") {
			name.append_unichar (character);
		} else {
			name.append (glyph_name);
		}
		
		if (all_available) {
			fg = font.get_glyph_collection_by_name (name.str);
		} else {
			fg = font.get_glyph_collection (name.str);
		}

		if (fg != null) {
			glyph_collection = (!) fg;
		} else {
			glyph_collection = new GlyphCollection (character, name.str);
			
			if (!empty) {
				glyph = new Glyph (name.str, !unassigned ? character : '\0');
				glyph_collection.add_master (new GlyphMaster ());
				glyph_collection.insert_glyph (glyph, true);
			}
			
			font.add_glyph_collection (glyph_collection);
		}
		
		glyph_collection.set_unassigned (unassigned);
		
		return glyph_collection;
	}
	
	public static void search () {
		OverView ow = MainWindow.get_overview ();
		TextListener listener = new TextListener (t_("Search"), ow.search_query, t_("Filter"));
		
		listener.signal_text_input.connect ((text) => {
			OverView o = MainWindow.get_overview ();
			o.search_query = text;
		});
		
		listener.signal_submit.connect (() => {
			OverView o = MainWindow.get_overview ();
			string q = o.search_query;
			
			if (q.char_count () > 1) {
				q = q.down ();
			}
			
			GlyphRange r = CharDatabase.search (q);
			o.set_current_glyph_range (r);
			MainWindow.get_tab_bar ().select_tab_name ("Overview");
	
			TextListener tl = new TextListener (t_("Search"), o.search_query, t_("Filter"));
			TabContent.show_text_input (tl);
		});
		
		TabContent.show_text_input (listener);
	}
	
	public Glyph? get_current_glyph () {
		OverViewItem oi = selected_item;
		if (oi.glyphs != null) {
			return ((!) oi.glyphs).get_current ();
		}
		return null;
	}
	
	public void set_glyph_zoom (GlyphCollection glyphs) {
		GlyphCanvas canvas;
		canvas = MainWindow.get_glyph_canvas ();
		canvas.set_current_glyph_collection (glyphs);
		Toolbox tools = MainWindow.get_toolbox ();
		ZoomTool z = (ZoomTool) tools.get_tool ("zoom_tool");
		z.store_current_view ();
		glyphs.get_current ().default_zoom ();
		z.store_current_view ();
		OverViewItem.reset_label ();
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

	public bool all_characters_in_view () {
		double length;
		Font f;
		
		if (all_available) {
			f = BirdFont.get_current_font ();
			length = f.length ();
		} else {
			length = glyph_range.length ();
		}
		
		return length < items_per_row * rows;
	}
	
	public void move_up () {
		first_visible -= items_per_row;
		selected += items_per_row;
		
		if (first_visible < 0) {
			selected -= items_per_row;
			first_visible = 0;
			view_offset_y = 0;
		}
	}

	public void move_down () {
		if (!at_bottom ()) {
			first_visible += items_per_row;
			selected -= items_per_row;
		}
	}
	
	public override void scroll_wheel (double x, double y, double dx, double dy) {
		double pixel_delta = 3 * dy;
		
		if (dy > 0) {
			view_offset_y += pixel_delta;
			
			while (view_offset_y > 0) {
				view_offset_y -= OverViewItem.height;
				move_up ();
			}						
		} else {
			if (at_bottom ()) {
				if (view_offset_y > -2 * OverViewItem.height && !all_characters_in_view ()) {
					view_offset_y += pixel_delta;
				}
			} else {
				view_offset_y += pixel_delta;
				while (view_offset_y < -OverViewItem.height) {
					view_offset_y += OverViewItem.height;
					move_down ();
				}
			}
		}
				
		if (view_offset_y < -2 * OverViewItem.height) {
			view_offset_y = -2 * OverViewItem.height;
		}
		
		update_item_list ();
		update_scrollbar ();
		hide_menu ();	
		GlyphCanvas.redraw ();
	}
	
	public override void selected_canvas () {
		OverviewTools.update_overview_characterset ();
		KeyBindings.set_require_modifier (true);
		update_scrollbar ();
		update_zoom_bar ();
		OverViewItem.glyph_scale = 1;
		update_item_list ();
		selected_item = get_selected_item ();
		GlyphCanvas.redraw ();
	}
	
	public void update_zoom_bar () {
		double z = OverViewItem.width / OverViewItem.DEFAULT_WIDTH - 0.5;
		Toolbox.overview_tools.zoom_bar.set_zoom (z);
		Toolbox.redraw_tool_box ();
		update_item_list ();
	}
	
	public void set_zoom (double zoom) {
		double z = zoom + 0.5;
		OverViewItem.glyph_scale = 1;
		OverViewItem.width = OverViewItem.DEFAULT_WIDTH * z;
		OverViewItem.height = OverViewItem.DEFAULT_HEIGHT * z;
		OverViewItem.margin = OverViewItem.DEFAULT_MARGIN * z;
		update_item_list ();
		OverViewItem.reset_label ();
		Preferences.set ("overview_zoom", @"$zoom");

		Font font = BirdFont.get_current_font ();
		for (int index = 0; index < font.length (); index++) {
			GlyphCollection? glyphs = font.get_glyph_collection_index ((uint32) index);
			return_if_fail (glyphs != null);
			GlyphCollection g = (!) glyphs;
			g.get_current ().overview_thumbnail = null;
		}
		
		GlyphCanvas.redraw ();
	}
	
	public override void zoom_min () {
		OverViewItem.width = OverViewItem.DEFAULT_WIDTH * 0.5;
		OverViewItem.height = OverViewItem.DEFAULT_HEIGHT * 0.5;
		OverViewItem.margin = OverViewItem.DEFAULT_MARGIN * 0.5;
		update_item_list ();
		OverViewItem.reset_label ();
		GlyphCanvas.redraw ();
		update_zoom_bar ();
	}
	
	public override void reset_zoom () {
		OverViewItem.width = OverViewItem.DEFAULT_WIDTH;
		OverViewItem.height = OverViewItem.DEFAULT_HEIGHT;
		OverViewItem.margin = OverViewItem.DEFAULT_MARGIN;
		update_item_list ();
		OverViewItem.reset_label ();
		GlyphCanvas.redraw ();
		update_zoom_bar ();
	}

	public override void zoom_max () {
		OverViewItem.width = allocation.width;
		OverViewItem.height = allocation.height;
		update_item_list ();
		OverViewItem.reset_label ();
		GlyphCanvas.redraw ();
	}
	
	public override void zoom_in () {
		OverViewItem.width *= 1.1;
		OverViewItem.height *= 1.1;
		OverViewItem.margin *= 1.1;
		update_item_list ();
		OverViewItem.reset_label ();
		GlyphCanvas.redraw ();
		update_zoom_bar ();
	}
	
	public override void zoom_out () {
		OverViewItem.width *= 0.9;
		OverViewItem.height *= 0.9;
		OverViewItem.margin *= 0.9;
		update_item_list ();
		OverViewItem.reset_label ();
		GlyphCanvas.redraw ();
		update_zoom_bar ();
	}

	public override void store_current_view () {
	}
	
	public override void restore_last_view () {
	}

	public override void next_view () {
	}

	public override string get_label () {
		return t_("Overview");
	}
	
	public override string get_name () {
		return "Overview";
	}
	
	public void display_all_available_glyphs () {
		all_available = true;

		view_offset_y = 0;
		first_visible = 0;
		selected = 0;
		
		update_item_list ();
		selected_item = get_selected_item ();
		GlyphCanvas.redraw ();
	}
	
	OverViewItem get_selected_item () {
		if (visible_items.size == 0) {
			return new OverViewItem ();
		}
		
		if (!(0 <= selected < visible_items.size)) { 
			return selected_item;
		}

		OverViewItem item = visible_items.get (selected);
		item.selected = true;
		return item;
	}
	
	int get_items_per_row () {
		int i = 1;
		double tab_with = allocation.width - 30; // 30 px for the scroll bar
		OverViewItem.margin = OverViewItem.width * 0.1;
		double l = OverViewItem.margin + OverViewItem.full_width ();
		
		while (l <= tab_with) {
			l += OverViewItem.full_width ();
			i++;
		}
		
		return i - 1;
	}
	
	public void update_item_list () {
		update_scheduled = true;
	}
	
	public void process_item_list_update () {
		string character_string;
		Font f = BirdFont.get_current_font ();
		GlyphCollection? glyphs = null;
		uint32 index;
		OverViewItem item;
		double x, y;
		unichar character;
		Glyph glyph;
		double tab_with;
		int item_list_length;
		int visible_size;
		
		tab_with = allocation.width - 30; // scrollbar
		
		items_per_row = get_items_per_row ();
		rows = (int) (allocation.height /  OverViewItem.full_height ()) + 2;
		
		item_list_length = items_per_row * rows;
		visible_items.clear ();
		
		index = (uint32) first_visible;
		x = OverViewItem.margin;
		y = OverViewItem.margin;
		
		if (all_available) {
			uint font_length = f.length ();
			
			for (int i = 0; i < item_list_length && index < font_length; i++) {
				glyphs = f.get_glyph_collection_index ((uint32) index);
				return_if_fail (glyphs != null);
				
				glyph = ((!) glyphs).get_current ();
				character_string = glyph.name;
				character = glyph.unichar_code;
				
				item = new OverViewItem ();
				item.set_character (character);
				item.set_glyphs (glyphs);
				item.x = x;
				item.y = y;
				visible_items.add (item);
				index++;
			}
		} else {
			uint32 glyph_range_size = glyph_range.get_length ();
			
			uint max_length = glyph_range.length () - first_visible;
			
			if (item_list_length > max_length) {
				item_list_length = (int) max_length;
			}
			
			for (int i = 0; i < item_list_length && index < glyph_range_size; i++) {			
				item = new OverViewItem ();
				visible_items.add (item);
			}
			
			index = (uint32) first_visible;
			visible_size = visible_items.size;
			for (int i = 0; i < visible_size; i++) {
				item = visible_items.get (i);
				character = glyph_range.get_character ((uint32) index);
				item.set_character (character);
				index++;
			}

			visible_size = visible_items.size;
			for (int i = 0; i < visible_size; i++) {
				item = visible_items.get (i);
				glyphs = f.get_glyph_collection_by_name ((!) item.character.to_string ());
				item.set_glyphs (glyphs);
			}
		}
		
		x = OverViewItem.margin;
		y = OverViewItem.margin;
		
		visible_size = visible_items.size;
		int selected_index;
		bool selected_item;
		double full_width = OverViewItem.full_width ();
		
		for (int i = 0; i < visible_size; i++) {
			item = visible_items.get (i);

			selected_item = false;
	
			if (all_available) {
				glyphs = f.get_glyph_collection_index ((uint32) i);
			} else {			
				glyphs = f.get_glyph_collection_by_name ((!) item.character.to_string ());
			}
			
			if (glyphs != null) {
				selected_index = selected_items.index_of ((!) glyphs);
				selected_item = (selected_index != -1);
			}
						
			selected_item |= (i == selected);
			item.selected = selected_item;
			
			item.x = x + view_offset_x;
			item.y = y + view_offset_y;
			
			x += full_width;
			
			if (x + full_width >= tab_with) {
				x = OverViewItem.margin;
				y += OverViewItem.full_height ();
			}
		}
		
		update_scheduled = false;
	}
	
	public override void draw (WidgetAllocation allocation, Context cr) {
		if (update_scheduled
			|| this.allocation.width != allocation.width
			|| this.allocation.height != allocation.height
			|| this.allocation.width == 0) {
			this.allocation = allocation;
			process_item_list_update ();
		}
		
		this.allocation = allocation;
		
		// clear canvas
		cr.save ();
		Theme.color (cr, "Background 1");
		cr.rectangle (0, 0, allocation.width, allocation.height);
		cr.fill ();
		cr.restore ();
		
		foreach (OverViewItem i in visible_items) {
			i.draw (allocation, cr);
		}
		
		if (unlikely (visible_items.size == 0)) {
			draw_empty_canvas (allocation, cr);
		}
		
		if (unlikely (character_info != null)) {
			draw_character_info (cr);
		}
	}
		
	void draw_empty_canvas (WidgetAllocation allocation, Context cr) {
		Text t;
		
		cr.save ();
		t = new Text (t_("No glyphs in this view."), 24);
		Theme.text_color (t, "Text Foreground");
		t.widget_x = 40;
		t.widget_y = 30;
		t.draw (cr);
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
	
	void scroll_to_position (int64 r) {
		if (r < 0) {
			scroll_top ();
			return;
		}
		
		selected -= (int) (r - first_visible);
		first_visible = (int) r;
		update_item_list ();
	}
	
	public override void scroll_to (double position) requires (items_per_row > 0) {
		double r;
		int nrows;
		Font f;
		
		if (all_available) {
			f = BirdFont.get_current_font ();
			nrows = (int) (f.length () / items_per_row);
		} else {
			nrows = (int) (glyph_range.length () / items_per_row);
		}
		
		view_offset_y = 0;
		r = (int64) (position * (nrows - rows + 3)); // 3 invisible rows
		r *= items_per_row;
		
		scroll_to_position ((int64) r);
		update_item_list ();
		GlyphCanvas.redraw ();
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
		
		update_item_list ();
	}
	
	public void scroll_top () {
		first_visible = 0;
		view_offset_y = 0;
		
		update_item_list ();
		
		if (visible_items.size != 0) {
			selected_item = get_selected_item ();
		}
	}

	/** Returns true if the selected glyph is at the last row. */
	private bool last_row () {
		return visible_items.size - selected <= items_per_row;
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
		
		if (selected >= visible_items.size) { 
			selected = (int) (visible_items.size - 1); 
		}

		selected_item = get_selected_item ();
		update_item_list ();
	}

	public void key_right () {
		Font f = BirdFont.get_current_font ();
		int64 len = (all_available) ? f.length () : glyph_range.length ();

		if (at_bottom () && first_visible + selected + 1 >= len) {
			selected = (int) (visible_items.size - 1);
			selected_item = get_selected_item ();
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
			selected_item = get_selected_item ();
		}
		update_item_list ();
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
		update_item_list ();
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
		update_item_list ();
	}
	
	public string get_selected_char () {
		Font f;
		Glyph? g;
		
		if (all_available) {
			f = BirdFont.get_current_font ();
			g = f.get_glyph_index (selected);
			return_val_if_fail (g != null, "".dup ());
			return ((!) g).get_name ();
		}
		
		return glyph_range.get_char (selected);
	}
	
	public override void key_press (uint keyval) {
		hide_menu ();
		update_item_list ();
		GlyphCanvas.redraw ();

		if (KeyBindings.has_ctrl () || KeyBindings.has_logo ()) {
			return;
		}

		switch (keyval) {
			case Key.ENTER:
				open_current_glyph ();
				return;
			
			case Key.UP:
				get_selected_item ().selected = false;
			
				key_up ();
				selected_item = get_selected_item ();
				
				selected_items.clear ();
				if (selected_item.glyphs != null) {
					selected_items.add ((!) selected_item.glyphs);
				}
				
				update_scrollbar ();
				return;
				
			case Key.RIGHT:
				get_selected_item ().selected = false;
			
				key_right ();
				selected_item = get_selected_item ();
				
				selected_items.clear ();
				if (selected_item.glyphs != null) {
					selected_items.add ((!) selected_item.glyphs);
				}
				
				update_scrollbar ();
				return;
				
			case Key.LEFT:
				get_selected_item ().selected = false;
				
				key_left ();
				selected_item = get_selected_item ();
				
				selected_items.clear ();
				if (selected_item.glyphs != null) {
					selected_items.add ((!) selected_item.glyphs);
				}
				
				update_scrollbar();
				return;
				
			case Key.DOWN:
				get_selected_item ().selected = false;
				
				key_down ();
				selected_item = get_selected_item ();
				
				selected_items.clear ();
				if (selected_item.glyphs != null) {
					selected_items.add ((!) selected_item.glyphs);
				}
				
				update_scrollbar ();
				return;
				
			case Key.PG_UP:
				get_selected_item ().selected = false;
				
				for (int i = 0; i < rows; i++) {
					key_up ();
				}
				selected_item = get_selected_item ();
				
				selected_items.clear ();
				if (selected_item.glyphs != null) {
					selected_items.add ((!) selected_item.glyphs);
				}
				
				update_scrollbar ();
				return;
				
			case Key.PG_DOWN:
				get_selected_item ().selected = false;
				
				for (int i = 0; i < rows; i++) {
					key_down ();
				}
				selected_item = get_selected_item ();

				selected_items.clear ();
				if (selected_item.glyphs != null) {
					selected_items.add ((!) selected_item.glyphs);
				}
				
				update_scrollbar ();
				return;
				
			case Key.DEL:
				delete_selected_glyph ();
				selected_item = get_selected_item ();
				return;
				
			case Key.BACK_SPACE:
				delete_selected_glyph ();
				selected_item = get_selected_item ();
				return;
		}

		if (!KeyBindings.has_ctrl () && !KeyBindings.has_logo ()) {
			scroll_to_char (keyval);
		}
		
		selected_item = get_selected_item ();

		selected_items.clear ();
		if (selected_item.glyphs != null) {
			selected_items.add ((!) selected_item.glyphs);
		}
		
		update_item_list ();
		GlyphCanvas.redraw ();
	}
	
	public void delete_selected_glyph () {
		Font font = BirdFont.get_current_font ();
		OverViewUndoItem undo_item = new OverViewUndoItem ();
		
		undo_item.alternate_sets = font.alternates.copy ();
		
		foreach (GlyphCollection g in selected_items) {
			undo_item.glyphs.add (g.copy ());
		}
		store_undo_items (undo_item);

		foreach (GlyphCollection glyph_collection in selected_items) {
			font.delete_glyph (glyph_collection);
			string name = glyph_collection.get_name ();
			MainWindow.get_tab_bar ().close_background_tab_by_name (name);
		}

		update_item_list ();
		GlyphCanvas.redraw ();
	}
	
	public override void undo () {
		Font font = BirdFont.get_current_font ();
		OverViewUndoItem previous_collection;
		
		if (undo_items.size == 0) {
			return;
		}
		
		previous_collection = undo_items.get (undo_items.size - 1);
		redo_items.add (get_current_state (previous_collection));
		
		// remove the old glyph and add the new one
		foreach (GlyphCollection g in previous_collection.glyphs) {
			font.delete_glyph (g);
			
			if (g.length () > 0) {
				font.add_glyph_collection (g);
			}

			TabBar tabs = MainWindow.get_tab_bar ();
			Tab? tab = tabs.get_tab (g.get_name ());
			
			if (tab != null) {
				Tab t = (!) tab;
				set_glyph_zoom (g);
				t.set_glyph_collection (g);
				t.set_display (new GlyphTab (g));
			}
		}
		
		Font f = BirdFont.get_current_font ();
		f.alternates = previous_collection.alternate_sets.copy ();

		undo_items.remove_at (undo_items.size - 1);
		update_item_list ();
		GlyphCanvas.redraw ();
	}
	
	public override void redo () {
		Font font = BirdFont.get_current_font ();
		OverViewUndoItem previous_collection;

		if (redo_items.size == 0) {
			return;
		}
		
		previous_collection = redo_items.get (redo_items.size - 1);
		undo_items.add (get_current_state (previous_collection));

		// remove the old glyph and add the new one
		foreach (GlyphCollection g in previous_collection.glyphs) {
			font.delete_glyph (g);
			font.add_glyph_collection (g);

			TabBar tabs = MainWindow.get_tab_bar ();
			Tab? tab = tabs.get_tab (g.get_name ());
			
			if (tab != null) {
				Tab t = (!) tab;
				set_glyph_zoom (g);
				t.set_glyph_collection (g);
				t.set_display (new GlyphTab (g));
			}
		}
		font.alternates = previous_collection.alternate_sets.copy ();

		redo_items.remove_at (redo_items.size - 1);
		GlyphCanvas.redraw ();
	}	
	
	public OverViewUndoItem get_current_state (OverViewUndoItem previous_collection) {
		GlyphCollection? gc;
		OverViewUndoItem ui = new OverViewUndoItem ();
		Font font = BirdFont.get_current_font ();
		
		ui.alternate_sets = font.alternates.copy ();
		
		foreach (GlyphCollection g in previous_collection.glyphs) {
			gc = font.get_glyph_collection (g.get_name ());
			
			if (gc != null) {
				ui.glyphs.add (((!) gc).copy ());
			} else {
				ui.glyphs.add (new GlyphCollection (g.get_unicode_character (), g.get_name ()));
			}
		}
		
		return ui;		
	}
	
	public void store_undo_state (GlyphCollection gc) {
		OverViewUndoItem i = new OverViewUndoItem ();
		Font f = BirdFont.get_current_font ();
		i.alternate_sets = f.alternates.copy ();
		i.glyphs.add (gc);
		store_undo_items (i);
	}

	public void store_undo_items (OverViewUndoItem i) {
		undo_items.add (i);
		redo_items.clear ();
	}
	
	bool select_visible_glyph (string name) {
		int i = 0;
		
		foreach (OverViewItem o in visible_items) {
			if (o.get_name () == name) {
				selected = i;
				selected_item = get_selected_item ();

				if (selected_item.y > allocation.height - OverViewItem.height) {
					view_offset_y -= (selected_item.y + OverViewItem.height) - allocation.height;
				}

				if (selected_item.y < 0) {
					view_offset_y = 0;
				}		

				return true;
			}
			
			if (i > 1000) {
				warning ("selected character not found");
				return true;
			}
			
			i++;
		}
		
		return false;
	}
	
	public void scroll_to_char (unichar c) {
		StringBuilder s = new StringBuilder ();

		if (is_modifier_key (c)) {
			return;
		}
		
		s.append_unichar (c);
		scroll_to_glyph (s.str);
	}
		
	public void scroll_to_glyph (string name) {
		GlyphRange gr = glyph_range;
		int i, r, index;
		string ch;
		Font font = BirdFont.get_current_font ();
		GlyphCollection? glyphs = null;
		Glyph glyph;
		
		index = -1;
		
		if (items_per_row <= 0) {
			return;
		}

		ch = name;

		// selected char is visible
		if (select_visible_glyph (ch)) {
			return;
		}
		
		// scroll to char
		if (all_available) {
			
			// don't search for glyphs in huge CJK fonts 
			if (font.length () > 500) {
				r = 0;
			} else {
				// FIXME: too slow
				for (r = 0; r < font.length (); r += items_per_row) {
					for (i = 0; i < items_per_row && i < font.length (); i++) {
						glyphs = font.get_glyph_collection_index ((uint32) r + i);
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
			}
		} else {
			
			if (ch.char_count () > 1) {
				warning ("Can't scroll to ligature in this view");
				return;
			}
			
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
			process_item_list_update ();
			update_item_list ();
			select_visible_glyph (ch);
		}
	}
	
	public override void double_click (uint button, double ex, double ey) 
		requires (!is_null (visible_items) && !is_null (allocation)) {
		
		return_if_fail (!is_null (this));
		
		foreach (OverViewItem i in visible_items) {
			if (i.double_click (button, ex, ey)) {
				open_overview_item (i);
			}
		}
	
		GlyphCanvas.redraw ();
	}

	public void open_overview_item (OverViewItem i) {
		return_if_fail (!is_null (i));
		
		if (i.glyphs != null) {
			open_glyph_signal ((!) i.glyphs);
			GlyphCollection gc = (!) i.glyphs;
			gc.get_current ().close_path ();
		} else {
			open_new_glyph_signal (i.character);
		}
	}
	
	public void set_character_info (CharacterInfo i) {
		character_info = i;
	}

	public int get_selected_index () {
		GlyphCollection gc;
		int index = 0;
		
		if (selected_items.size == 0) {
			return 0;
		}
		
		gc = selected_items.get (0);
		
		foreach (OverViewItem i in visible_items) {
			if (i.glyphs != null && gc == ((!) i.glyphs)) {
				break;
			}
			
			index++;
		}
		
		return index;
	}

	public void hide_menu () {
		foreach (OverViewItem i in visible_items) {
			i.hide_menu ();
		}	
	}

	public override void button_press (uint button, double x, double y) {
		OverViewItem i;
		int index = 0;
		int selected_index = -1;
		bool update = false;
		
		if (character_info != null) {
			character_info = null;
			GlyphCanvas.redraw ();
			return;
		}
		
		if (!KeyBindings.has_shift ()) {
			selected_items.clear ();
		}
		
		for (int j = 0; j < visible_items.size; j++) {
			i = visible_items.get (j);
			
			if (i.click (button, x, y)) {
				selected = index;
				selected_item = get_selected_item ();
				
				if (KeyBindings.has_shift ()) {
					if (selected_item.glyphs != null) {
						
						selected_index = selected_items.index_of ((!) selected_item.glyphs);
						if (selected_index == -1) {
							selected_items.add ((!) selected_item.glyphs);
						} else {
							return_if_fail (0 <= selected_index < selected_items.size);
							selected_items.remove_at (selected_index);
							selected = get_selected_index ();
							selected_item = get_selected_item ();
						}
					}
				} else {
					selected_items.clear ();
					if (selected_item.glyphs != null) {
						selected_items.add ((!) selected_item.glyphs);
					}
				}
				
				if (!is_null (i.version_menu)) {
					update = !((!)i).version_menu.menu_visible;
				} else {
					update = true;
				}
			}
			index++;
		}
	
		if (update) {
			update_item_list ();
		}
		
		GlyphCanvas.redraw ();
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

	public void set_current_glyph_range (GlyphRange range) {
		GlyphRange? current = glyph_range;
		string c;
		
		if (current != null) {
			c = glyph_range.get_char (selected);
		}
		
		all_available = false;
		
		glyph_range = range;
		scroll_top ();

		// TODO: scroll down to c
		update_item_list ();
		selected_item = get_selected_item ();

		GlyphCanvas.redraw ();
	}

	public void select_next_glyph () {
		key_right ();
	}
	
	public void open_current_glyph () {
		// keep this object even if open_glyph_signal closes the display
		this.ref ();
		 
		selected_item = get_selected_item ();
		if (selected_item.glyphs != null) {
			open_glyph_signal ((!) selected_item.glyphs);
			GlyphCollection gc = (!) selected_item.glyphs;
			gc.get_current ().close_path ();
		} else {
			open_new_glyph_signal (selected_item.character);
		}
		
		this.unref ();
	}

	public override void update_scrollbar () {
		Font f;
		double nrows = 0;
		double pos = 0;
		double size;
		double visible_rows;
		
		if (rows == 0) {
			MainWindow.set_scrollbar_size (0);
			MainWindow.set_scrollbar_position (0);
		} else {
			if (all_available) {
				f = BirdFont.get_current_font ();
				nrows = Math.floor ((f.length ()) / rows);
				size = f.length ();
			} else {
				nrows = Math.floor ((glyph_range.length ()) / rows);
				size = glyph_range.length ();
			}
			
			if (nrows <= 0) {
				nrows = 1;
			}
			
			visible_rows = allocation.height / OverViewItem.height;
			scroll_size = visible_rows / nrows;
			MainWindow.set_scrollbar_size (scroll_size);
			pos = first_visible / (nrows * items_per_row - visible_rows * items_per_row);
			MainWindow.set_scrollbar_position (pos);
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
		string name;
		string[] lines;
		double character_start;
		double character_height;
		
		entry = ((!)character_info).get_entry ();

		lines = entry.split ("\n");
		
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
			x = 2;
		}
		
		// background	
		cr.save ();
		Theme.color_opacity (cr, "Background 1", 0.98);
		cr.rectangle (x, y, w, h);
		cr.fill ();
		cr.restore ();

		cr.save ();
		Theme.color_opacity (cr, "Foreground 1", 0.98);
		cr.set_line_width (2);
		cr.rectangle (x, y, w, h);
		cr.stroke ();
		cr.restore ();

		// database entry
		
		if (((!)character_info).is_ligature ()) {
			name = ((!)character_info).get_name ();
			draw_info_line (name, cr, x, y, 0);
		} else {
			i = 0;
			foreach (string line in lines) {
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
							draw_info_line (t_("See also:"), cr, x, y, i);
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
			
			character_start = y + 10 + i * UCD_LINE_HEIGHT;
			character_height = h - character_start;

			draw_fallback_character (cr, x, character_start, character_height);
		}
	}
	
	/** Fallback character in UCD info. */
	void draw_fallback_character (Context cr, double x, double y, double height)
	requires (character_info != null) {
		unichar c = ((!)character_info).unicode;

		if (height < 0) {
			return;
		}

		cr.save ();
		Text character = new Text ();
		character.set_use_cache (false);
		Theme.text_color (character, "Foreground 1");
		character.set_text ((!) c.to_string ());
		character.set_font_size (height);
		character.draw_at_top (cr, x + 10, y);
		cr.restore ();
	}

	void draw_info_line (string line, Context cr, double x, double y, int row) {
		Text ucd_entry = new Text (line);
		cr.save ();
		Theme.text_color (ucd_entry, "Foreground 1");
		ucd_entry.widget_x = 10 + x;
		ucd_entry.widget_y = 10 + y + row * UCD_LINE_HEIGHT;
		ucd_entry.draw (cr);
		cr.restore ();		
	}
	
	public void paste () {
		GlyphCollection gc;
		GlyphCollection? c;
		Glyph glyph;
		uint32 index;
		int i;
		int skip = 0;
		int s;
		string character_string;
		Gee.ArrayList<GlyphCollection> glyps;
		Font f;
		OverViewUndoItem undo_item;
		
		f = BirdFont.get_current_font ();
		gc = new GlyphCollection ('\0', "");
		glyps = new Gee.ArrayList<GlyphCollection> ();
		
		copied_glyphs.sort ((a, b) => {
			return (int) ((GlyphCollection) a).get_unicode_character () 
				- (int) ((GlyphCollection) b).get_unicode_character ();
		});

		index = (uint32) first_visible + selected;
		for (i = 0; i < copied_glyphs.size; i++) {
			if (all_available) {
				if (f.length () == 0) {
					c = add_empty_character_to_font (copied_glyphs.get (i).get_unicode_character (),
						copied_glyphs.get (i).is_unassigned (), 
						copied_glyphs.get (i).get_name ());
				} else if (index >= f.length ()) {
					// FIXME: duplicated unicodes?
					c = add_empty_character_to_font (copied_glyphs.get (i).get_unicode_character (),
						copied_glyphs.get (i).is_unassigned (), 
						copied_glyphs.get (i).get_name ());
				} else {
					c = f.get_glyph_collection_index ((uint32) index);
				}
				
				if (c == null) {
					c = add_empty_character_to_font (copied_glyphs.get (i).get_unicode_character (),
						copied_glyphs.get (i).is_unassigned (),
						copied_glyphs.get (i).get_name ());
				}
				
				return_if_fail (c != null);
				gc = (!) c; 
			} else {			
				if (i != 0) {
					s = (int) copied_glyphs.get (i).get_unicode_character ();
					s -= (int) copied_glyphs.get (i - 1).get_unicode_character ();
					s -= 1;
					skip += s;
				}

				character_string = glyph_range.get_char ((uint32) (index + skip));
				c = f.get_glyph_collection_by_name (character_string);
				
				if (c == null) {
					gc = add_empty_character_to_font (character_string.get_char (), 
						copied_glyphs.get (i).is_unassigned (),
						copied_glyphs.get (i).get_name ());
				} else {
					gc = (!) c;
				}
			}
			
			glyps.add (gc);
			index++;
		}

		undo_item = new OverViewUndoItem ();
		undo_item.alternate_sets = f.alternates.copy ();
		foreach (GlyphCollection g in glyps) {
			undo_item.glyphs.add (g.copy ());
		}
		store_undo_items (undo_item);

		if (glyps.size != copied_glyphs.size) {
			warning ("glyps.size != copied_glyphs.size");
			return;
		}

		if (copied_glyphs.size < i) {
			warning ("Array index out of bounds.");
			return;
		}
		
		i = 0;
		foreach (GlyphCollection g in glyps) {
			glyph = copied_glyphs.get (i).get_current ().copy ();
			glyph.version_id = (glyph.version_id == -1 || g.length () == 0) ? 1 : g.get_last_id () + 1;
			glyph.unichar_code = g.get_unicode_character ();

			if (!g.is_unassigned ()) {
				glyph.name = (!) glyph.unichar_code.to_string ();
			} else {
				glyph.name = g.get_name ();
			}
			
			g.insert_glyph (glyph, true);
			i++;
		}
		
		f.touch ();
		
		update_item_list ();
		GlyphCanvas.redraw ();
	}

	public override bool needs_modifier () {
		return true;
	}
	
	public class OverViewUndoItem {
		public AlternateSets alternate_sets = new AlternateSets ();
		public Gee.ArrayList<GlyphCollection> glyphs = new Gee.ArrayList<GlyphCollection> ();
	}
}

}
