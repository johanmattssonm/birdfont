/*
    Copyright (C) 2013 Johan Mattsson

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

/** Display functions for a unicode character database entry. */
public class CharacterInfo : GLib.Object {

	static ImageSurface? info_icon = null;
	double x = 0;
	double y = 0;
	unichar unicode;
	
	public CharacterInfo (unichar c) {
		unicode = c;
		
		if (info_icon == null) {
			info_icon = Icons.get_icon ("info_icon.png");
		}
	}
	
	public string get_entry () {
		return CharDatabase.get_unicode_database_entry (unicode);
	}
	
	public void set_position (double x, double y) {
		this.x = x;
		this.y = y;
	}
	
	public bool is_over_icon (double px, double py) {
		return (x <= px <= x + 12) && (y <= py <= y + 12);
	}
	
	public void draw_icon (Context cr) {	
		ImageSurface i = (!) info_icon;
		
		// info icon			
		if (likely (info_icon != null && i.status () == Cairo.Status.SUCCESS)) {
			cr.save ();
			cr.set_source_surface (i, x, y);
			cr.paint ();
			cr.restore ();
		} else {
			warning ("Failed to load icon.");
		}		
	}
}

}
