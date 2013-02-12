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

namespace BirdFont {

using Cairo;	

public class Icons {
	
	public static ImageSurface? get_icon (string? name) {
		ImageSurface? img = null;
		File f;
		
		if (name == null) {
			warning ("Can't find a file for name \"null\".");
			return null;
		}

		f = find_icon ((!) name);
		
		if (!f.query_exists ()) {
			warning (@"Can't load icon: $((!)f.get_path ())");
			return null;
		}
		
		img = new ImageSurface.from_png ((!)f.get_path ());
		
		return img;
	}

	public static File find_icon (string name) {
		return FontDisplay.find_file ("icons", name);
	}
}
	
}
