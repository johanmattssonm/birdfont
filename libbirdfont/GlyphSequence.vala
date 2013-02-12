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
namespace BirdFont {
	
class GlyphSequence {
	
	/** A list of all letters */
	public List <Glyph?> glyph;
	
	/** A list of all letters with ligature substitution. */
	public List <Glyph?> glyph_with_ligatures;

	public GlyphSequence () {
		glyph = new List <Glyph?> ();
		glyph_with_ligatures = new List <Glyph?> ();
	}
	
	/** Do ligature substitution. */
	public void process_ligatures () {
		while (glyph_with_ligatures.length () > 0) {
			glyph_with_ligatures.remove_link (glyph_with_ligatures.first ());
		}
		
		foreach (Glyph? g in glyph) {
			glyph_with_ligatures.append (g);
		}
	}
	
	int index_of_needle () {
		return -1;
	}
}

}
