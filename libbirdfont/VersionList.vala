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

public class VersionList : DropMenu {
	int versions = 1;
	int current_version = 0;
	public List<Glyph> glyphs = new List<Glyph> ();

	public VersionList (Glyph? g = null) {
		base ("version");
		set_direction (MenuDirection.POP_UP);
		
		MenuAction ma = add_item (_("New version"));
		ma.action = (self) => {
			return_if_fail (self.parent != null);
			return_if_fail (glyphs.length () > 0);
			
			BirdFont.get_current_font ().touch ();
			
			add_new_version ();
			current_version = (int) glyphs.length () - 1;
		};
		
		if (g != null) {
			add_glyph ((!) g);
		}
	}
	
	public Glyph get_current () {
		unowned List<Glyph> g;
		
		if (unlikely (!(0 <= current_version < glyphs.length ()))) {
			warning (@"current_version >= glyphs.length ($current_version >= $(glyphs.length ()))");
			return new Glyph ("");
		}
		
		g = glyphs.nth (current_version);
		
		if (unlikely (is_null (g.data))) {
			warning ("No data in glyph collection.");
			return new Glyph ("");
		}
		
		return g.data;
	}

	public void add_new_version () {
		Glyph g = get_current ();
		Glyph new_version = g.copy ();
		add_glyph (new_version);
	}
	
	private void set_selected_item (MenuAction ma) {
		int i = ma.index;
				
		return_if_fail (0 <= i < glyphs.length ());

		current_version = i;
		
		return_if_fail (ma.parent != null);
		
		((!)ma.parent).deselect_all ();
		ma.set_selected (true);
		
		reload_all_open_glyphs ();
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
				warning (@"display is null for tab $(tab.get_label ())");
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
		
		versions++;
		glyphs.append (new_version);

		ma = add_item (_("Version") + @" $(versions - 1)");
		ma.index = (int) glyphs.length () - 1;
		
		ma.action = (self) => {
			Font font;
			
			font = BirdFont.get_current_font ();
			set_selected_item (self);
			font.touch ();
		};

		if (selected) {
			set_selected_item (ma);
		}
	}

}

}
