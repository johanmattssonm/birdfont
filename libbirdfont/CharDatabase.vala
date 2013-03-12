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

class CharDatabase {

	public CharDatabase () {
	}

	public static bool has_ascender (unichar c) {
		if (!c.islower()) return true;
		
		// todo: their derrivatives
		switch (c) {
			case 'b': return true;
			case 'd': return true;
			case 'f': return true;
			case 'h': return true;
			case 'i': return true;
			case 'j': return true;
			case 'k': return true;
			case 'l': return true;	
		}
		
		if ('à' <= c <= 'å') return true;
		if ('è' <= c <= 'ö') return true;
		if ('ù' <= c <= 'ă') return true;
		if ('ć' <= c <= 'ė') return true;

		return false;
	}

	public static bool has_descender (unichar c) {
		// todo: their derrivatives
		switch (c) {
			case 'g': return true;
			case 'j': return true;
			case 'p': return true;
			case 'q': return true;
			case 'y': return true;
		}
		
		return false;		
	}
	
}

}
