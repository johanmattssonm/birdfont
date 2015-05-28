/*
    Copyright (C) 2012, 2014 Johan Mattsson

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
using Math;

public enum MenuDirection {
	DROP_DOWN,
	POP_UP;
}

namespace BirdFont {

public class VersionList : GLib.Object {
	public int current_version_id = -1;
	GlyphCollection glyph_collection;
	
	public Gee.ArrayList<Glyph> glyphs;

	public delegate void Selected (MenuAction self);
	public signal void selected (VersionList self);
	
	double x = -1;
	double y = -1;
	double width = 0;
	
	double menu_x = -1;	
	public bool menu_visible = false;
	Gee.ArrayList <MenuAction> actions = new Gee.ArrayList <MenuAction> ();
	const int item_height = 25;
	MenuDirection direction = MenuDirection.DROP_DOWN;
	
	public signal void signal_delete_item  (int item_index);
	public signal void add_glyph_item  (Glyph item);

	public VersionList (GlyphCollection gc) {
		MenuAction ma = add_item (t_("New version"));
		ma.has_delete_button = false;
		ma.action.connect ((self) => {
			return_if_fail (glyphs.size > 0);
			
			BirdFont.get_current_font ().touch ();
			
			add_new_version ();
			current_version_id = glyphs.get (glyphs.size - 1).version_id;
		});
	
		// delete one version
		signal_delete_item.connect ((index) => {
			delete_item (index);
		});

		this.glyph_collection = gc;
		glyphs = new Gee.ArrayList<Glyph> ();
		set_direction (MenuDirection.POP_UP);
		
		glyphs = new Gee.ArrayList<Glyph> ();
		
		foreach (Glyph g in gc.glyphs) {
			add_glyph (g, false);
		}
		
		set_selected_version (gc.get_current ().version_id, false);
	}
	
	private void delete_item (int index) {
		int current_version;
		Font font = BirdFont.get_current_font ();
		OverView over_view = MainWindow.get_overview ();
		
		font.touch ();
		
		index--; // first item adds new glyphs to the list
		
		// delete the entire glyph if the last remaining version is removed
		if (glyphs.size == 1) {
			over_view.store_undo_state (glyph_collection.copy ());
			font.delete_glyph (glyph_collection);
			return;
		}
		
		return_if_fail (0 <= index < glyphs.size);
		
		font.deleted_glyphs.add (glyph_collection.get_current ());
		over_view.store_undo_state (glyph_collection.copy ());
		
		glyphs.remove_at (index);
		glyph_collection.remove (index);
		
		recreate_index ();
		
		current_version = get_current_version_index ();
		if (index == current_version) {
			set_selected_item (get_action_no2 ()); // select the first glyph if the current glyph is deleted
		} else if (index < current_version) {
			return_if_fail (0 <= current_version - 1 < glyphs.size);
			current_version_id = glyphs.get (current_version - 1).version_id;
			int i = get_current_version_index ();
			set_selected_item (get_action_index (i));
		}
	}

	private int get_current_version_index () {
		int i = 0;
		foreach (Glyph g in glyphs) {
			if (g.version_id == current_version_id) {
				return i;
			}
			i++;
		}
		
		warning ("No index for menu item.");
		return 0;
	}

	public void set_selected_version (int version_id, bool update_loaded_glyph) {
		current_version_id = version_id;
		update_selection (update_loaded_glyph);
	}
	
	public Glyph get_current () {
		Glyph? gl = null;
		
		foreach (Glyph g in glyphs) {
			if (g.version_id == current_version_id) {
				return g;
			}
		}
		
		if (unlikely (glyphs.size > 0)) {
			warning (@"Can not find current glyph for id $current_version_id");
			gl = glyphs.get (glyphs.size - 1);
			set_selected_version (((!) gl).version_id, false);
			return (!) gl;
		}
		
		if (unlikely (glyphs.size == 0 && current_version_id == -1)) {
			warning (@"No glyphs added to collection");
			gl = new Glyph.no_lines ("", '\0');
		}
		
		return (!) gl;
	}

	public void add_new_version () {
		Glyph g = get_current ();
		Glyph new_version = g.copy ();
		new_version.version_id = get_last_id () + 1;
		add_glyph (new_version);
		add_glyph_item (new_version);
	}
	
	public int get_last_id () {
		return_val_if_fail (glyphs.size > 0, 1);
		return glyphs.get (glyphs.size - 1).version_id;
	}
	
	private void set_selected_item (MenuAction ma, bool update_loaded_glyph = true) {
		int i = ma.index;
		Glyph current_glyph;
		Glyph g;
				
		return_if_fail (0 <= i < glyphs.size);
		g = glyphs.get (i);
		
		current_version_id = g.version_id;
		deselect_all ();
		ma.set_selected (true);
		
		glyph_collection.set_selected (g);
		
		reload_all_open_glyphs ();

		if (update_loaded_glyph && !is_null (BirdFont.current_glyph_collection)) {
			current_glyph = MainWindow.get_current_glyph ();
			g.set_allocation (current_glyph.allocation);
			g.close_path ();
			g.reset_zoom ();
		}		
	}
	
	/** Reload a glyph when a new version is selected. Updates the path
	 * in glyph view, not from disk but from the glyph table.
	 */
	void reload_all_open_glyphs () {
		TabBar b;
		Tab tab;
		Tab? tn;
		Glyph glyph;
		Glyph updated_glyph;
		Glyph? ug;
		Font font = BirdFont.get_current_font ();
		StringBuilder uni = new StringBuilder ();
		
		if (is_null (MainWindow.get_tab_bar ())) {
			return;
		}
		
		b = MainWindow.get_tab_bar ();
		
		for (int i = 0; i < b.get_length (); i++) {
			tn = b.get_nth (i);
			
			if (tn == null) {
				warning ("tab is null");
				return;
			}

			tab = (!) tn;

			if (! (tab.get_display () is Glyph)) {
				continue; 
			}
			
			glyph = (Glyph) tab.get_display ();
			uni.truncate (0);
			uni.append_unichar (glyph.unichar_code);
			ug = font.get_glyph (uni.str);
			
			if (ug == null) {
				return;
			}

			updated_glyph = (!) ug;
			tab.set_display (updated_glyph);
			updated_glyph.view_zoom = glyph.view_zoom;
			updated_glyph.view_offset_x = glyph.view_offset_x;
			updated_glyph.view_offset_y = glyph.view_offset_y;
		}
	}
	
	public void add_glyph (Glyph new_version, bool selected = true) {
		MenuAction ma;
		int v;
		
		v = new_version.version_id;
		glyphs.add (new_version);

		ma = add_item (t_("Version") + @" $(v - 1)");
		ma.index = (int) glyphs.size - 1;
		
		ma.action.connect ((self) => {
			Font font = BirdFont.get_current_font ();
			set_selected_item (self);
			font.touch ();
		});

		if (selected) {
			set_selected_item (ma);
		}
		
		if (selected) {
			update_selection ();
		}
	}
	
	bool has_version (int id) {
		foreach (Glyph g in glyphs) {
			if (g.version_id == id) {
				return true;
			}
		}
		return false;
	}
	
	void update_selection (bool update_loaded_glyph = true) {
		int index;
		
		if (has_version (current_version_id)) {
			index = get_current_version_index ();
			set_selected_item (get_action_index (index + 1), update_loaded_glyph); // the first item is the "new version"
		}
	}

	public MenuAction get_action_index (int index) {
		if (!(0 <= index < actions.size)) {
			warning (@"No action for index $index. (actions.size: $(actions.size))");
			return new MenuAction ("None");
		}
		return actions.get (index);
	}
	
	public void recreate_index () {
		int i = -1;
		foreach (MenuAction a in actions) {
			a.index = i;
			i++;
		}
	}
	
	public MenuAction get_action_no2 () {
		if (actions.size < 2) {
			warning ("No such action");
			return new MenuAction ("None");
		}
		
		return actions.get (1);
	}
	
	public void deselect_all () {
		foreach (MenuAction m in actions) {
			m.set_selected (false);
		}
	}
	
	public void set_direction (MenuDirection d) {
		direction = d;
	}
	
	public void close () {
		menu_visible = false;
	}
	
	public MenuAction add_item (string label) {
		MenuAction m = new MenuAction (label);
		add_menu_item (m);
		return m;
	}
	
	public void add_menu_item (MenuAction m) {
		actions.add (m);
	}
		
	public bool is_over_icon (double px, double py) {
		if (x == -1 || y == -1) {
			return false;
		}
		
		return x - 12 < px <= x && y - 5 < py < y + 12 + 5;
	}

	public bool menu_item_action (double px, double py) {
		MenuAction? action;
		MenuAction a;
		MenuAction ma;
		int index;
		
		if (menu_visible) {
			action = get_menu_action_at (px, py);
			
			if (action != null) {
				a = (!) action;
				
				// action for the delete button
				if (a.has_delete_button && menu_x + width - 13 < px <= menu_x + width) { 
					index = 0;
					ma = actions.get (0);
					while (true) {
						if (a == ma) {
							actions.remove_at (index);
							signal_delete_item (index);
							break;
						}
						
						if (ma == actions.get (actions.size - 1)) {
							break;
						} else {
							ma = actions.get (index + 1);
							index++;
						}
					}
					return false;
				} else {
					a.action (a);
					selected (this);
					menu_visible = false;
				}
				
				return true;
			}
		}
		
		return false;
	}
	
	public bool menu_icon_action (double px, double py) {		
		menu_visible = is_over_icon (px, py);
		return menu_visible;
	}
	
	MenuAction? get_menu_action_at (double px, double py) {
		double n = 0;
		double ix, iy;
		
		foreach (MenuAction item in actions) {
			ix = menu_x - 6;
			
			if (direction == MenuDirection.DROP_DOWN) {
				iy = y + 12 + n * item_height;
			} else {
				iy = y - 24 - n * item_height;
			}
	
			if (ix <= px <= ix + width && iy <= py <= iy + item_height) {
				return item;
			}
			
			n++;			
		}

		return null;
	}
	
	public void set_position (double px, double py) {
		x = px;
		y = py;

		foreach (MenuAction item in actions) {
			item.text = new Text (item.label);
			if (item.text.get_sidebearing_extent () + 25 > width) {
				width = item.text.get_sidebearing_extent () + 25;
			}
		}
				
		if (x - width + 19 < 0) {
			menu_x = 30;
		} else {
			menu_x = x - width;
		}
	}
	
	public void draw_menu (Context cr) {
		double ix, iy;
		int n;
	
		if (likely (!menu_visible)) {
			return;
		}
		
		cr.save ();
		Theme.color (cr, "Default Background");
		cr.rectangle (menu_x, y - actions.size * item_height, width, actions.size * item_height);
		
		cr.fill_preserve ();
		cr.stroke ();
		cr.restore ();
		
		cr.save ();
		
		n = 0;
		foreach (MenuAction item in actions) {
			item.width = width;
			
			iy = y - 8 - n * item_height;
			ix = menu_x + 2;
			
			item.draw (ix, iy, cr);
			n++;
		}
		
		cr.restore ();
	}
}

}
