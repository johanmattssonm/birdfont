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
using Math;

namespace Supplement {

class VersionList : DropMenu {
	int versions = 1;
	int current_version = 0;
	public List<Glyph> glyphs = new List<Glyph> ();

	public VersionList (Glyph? g = null) {
		base ("version");
		set_direction (MenuDirection.POP_UP);
		
		MenuAction ma = add_item ("New version");
		ma.action = (self) => {
			return_if_fail (self.parent != null);
			return_if_fail (glyphs.length () > 0);
			
			Supplement.get_current_font ().touch ();
			
			add_new_version ();
			current_version = (int) glyphs.length () - 1;
		};
		
		if (g != null) {
			add_glyph ((!) g);
		}
	}
	
	public Glyph get_current () {
		if (unlikely (current_version >= glyphs.length ())) {
			warning (@"current_version >= glyphs.length ($current_version >= $(glyphs.length ()))");
			return new Glyph ("");
		}
		
		return glyphs.nth (current_version).data;
	}

	public void add_new_version () {
		Glyph g = get_current ();
		Glyph new_version = g.copy ();
		add_glyph (new_version);
	}
	
	private void set_selected_item (MenuAction ma) {
		Glyph g = get_current ();
		int i = ma.index;
		
		return_if_fail (0 <= i < glyphs.length ());

		current_version = i;
		
		return_if_fail (ma.parent != null);
		
		((!)ma.parent).deselect_all ();
		ma.set_selected (true);		
	}
	
	public void add_glyph (Glyph new_version, bool selected = true) {
		MenuAction ma;
		
		versions++;
		glyphs.append (new_version);

		ma = add_item (@"Version $(versions - 1)");
		ma.index = (int) glyphs.length () - 1;
		ma.action = (self) => {
			Font font = Supplement.get_current_font ();
			set_selected_item (self);
			font.touch ();
		};
		
		if (selected) {
			set_selected_item (ma);
		}
	}

}

}
