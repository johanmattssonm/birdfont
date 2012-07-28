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

class GlyphCollection : GLib.Object {
	VersionList versions;
	
	public GlyphCollection (Glyph? current = null) {
		versions = new VersionList (current);
	}
	
	public VersionList get_version_list () {
		return versions;
	}
	
	public Glyph get_current () {
		return versions.get_current ();
	}
	
	public void insert_glyph (Glyph g, bool selected) {
		versions.add_glyph (g, selected);
		
		print (@"insert $(g.get_name ()) at $(versions.glyphs.length ())\n");
		assert (versions.glyphs.length () > 0);
	}
	
	public uint length () {
		return versions.glyphs.length ();
	}
	
	public string get_name () {
		return get_current ().get_name ();
	}
}
	
}
