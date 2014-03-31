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

namespace BirdFont {

public class VersionList : DropMenu {
	int current_version_id = -1;
	public List<Glyph> glyphs;

	public VersionList (Glyph? g = null) {
		base ("version");
		glyphs = new List<Glyph> ();
		
		set_direction (MenuDirection.POP_UP);
		
		MenuAction ma = add_item (t_("New version"));
		ma.has_delete_button = false;
		ma.action = (self) => {
			return_if_fail (self.parent != null);
			return_if_fail (glyphs.length () > 0);
			
			BirdFont.get_current_font ().touch ();
			
			add_new_version ();
			current_version_id = glyphs.last ().data.version_id;
		};
		
		signal_delete_item.connect ((index) => {
			unowned List<Glyph> gl;
			int current_version;
			
			index--; // first item is the add new action
			return_if_fail (0 <= index < glyphs.length ());
			gl = glyphs.nth (index);
			glyphs.remove_link (gl);
			
			recreate_index ();
			
			current_version = get_current_version_index ();
			if (index == current_version) {
				set_selected_item (get_action_no2 ()); // select the first glyph if the current glyph is deleted
			} else if (index < current_version) {
				return_if_fail (0 <= current_version - 1 < glyphs.length ());
				current_version_id = glyphs.nth (current_version - 1).data.version_id;
			}
		});
		
		if (g != null) {
			add_glyph ((!) g);
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
		return i;
	}

	public void set_selected_version (int version_id) {
		current_version_id = version_id;
		update_selection ();
	}
	
	public Glyph get_current () {
		foreach (Glyph g in glyphs) {
			if (g.version_id == current_version_id) {
				return g;
			}
		}
		
		warning (@"Can not find current glyph for id $current_version_id");
		
		if (glyphs.length () > 0) {
			set_selected_version (glyphs.last ().data.version_id);
			return glyphs.last ().data;
		}
		
		return new Glyph ("");
	}

	public void add_new_version () {
		Glyph g = get_current ();
		Glyph new_version = g.copy ();
		new_version.version_id = get_last_id () + 1;
		add_glyph (new_version);
	}
	
	private int get_last_id () {
		return_val_if_fail (glyphs.length () > 0, 1);
		return glyphs.last ().data.version_id;
	}
	
	private void set_selected_item (MenuAction ma) {
		int i = ma.index;
		Glyph current_glyph = MainWindow.get_current_glyph ();
		unowned List<Glyph> g;
				
		return_if_fail (0 <= i < glyphs.length ());
		g = glyphs.nth (i);
		
		current_version_id = g.data.version_id;
		
		return_if_fail (ma.parent != null);
		
		((!)ma.parent).deselect_all ();
		ma.set_selected (true);
		
		reload_all_open_glyphs ();

		if (unlikely (is_null (g.data))) {
			warning ("No data in glyph collection.");
		} else {
			g.data.set_allocation (current_glyph.allocation);
			g.data.default_zoom ();
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
			updated_glyph.close_path ();
		}
	}
	
	public void add_glyph (Glyph new_version, bool selected = true) {
		MenuAction ma;
		int v;
		
		v = new_version.version_id;
		glyphs.append (new_version);

		ma = add_item (t_("Version") + @" $v");
		ma.index = (int) glyphs.length () - 1;
		
		ma.action = (self) => {
			Font font = BirdFont.get_current_font ();
			set_selected_item (self);
			font.touch ();
		};

		if (selected) {
			set_selected_item (ma);
		}
		
		update_selection ();
	}
	
	bool has_version (int id) {
		foreach (Glyph g in glyphs) {
			if (g.version_id == id) {
				return true;
			}
		}
		return false;
	}
	
	void update_selection () {
		if (has_version (current_version_id)) {
			set_selected_item (get_action_index (get_current_version_index () + 1)); // the first item is the "new version"
		}
	}

}

}
