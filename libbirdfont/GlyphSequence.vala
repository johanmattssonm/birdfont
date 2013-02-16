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
	
public class GlyphSequence {
	
	/** A list of all glyphs */
	public List <Glyph?> glyph;

	public GlyphSequence () {
		glyph = new List <Glyph?> ();
	}
	
	/** Do ligature substitution.
	 * @return a new sequence with ligatures
	 */
	public GlyphSequence process_ligatures () {
		GlyphSequence ligatures = new GlyphSequence ();
		Font font = BirdFont.get_current_font ();
		Glyph liga;
		GlyphCollection? gc;
		
		foreach (Glyph? g in glyph) {
			ligatures.glyph.append (g);
		}
		
		for (uint i = 0; ; i++) {
			gc = font.get_ligature (i);
			
			if (gc == null) {
				break;
			}
			
			// FIXME: DELETE
			print (@"LIGA: $(((!) gc).get_current ().get_ligature_string ())\n");
			
			liga = ((!) gc).get_current ();		
			ligatures.replace (liga.get_ligature (), liga);
			i++;
		}
		
		return ligatures;
	}
	
	void replace (GlyphSequence old, Glyph replacement) {
		int i = 0;
		while (i < glyph.length ()) {
			if (starts_with (old, i)) {
				substitute (i, old.glyph.length (), replacement);
				i = 0;
			} else {
				i++;
			}
		}
	}
	
	bool starts_with (GlyphSequence old, uint index) {
		unowned List<Glyph?>? gl;
		
		foreach (Glyph? g in old.glyph) {
			gl = glyph.nth (index);
			
			if (gl == null) {
				return false;
			}
			
			if (g != ((!) gl).data) {
				return false;
			}
			
			index++;
		}
		
		return true;
	}
	
	void substitute (uint index, uint length, Glyph substitute) {
		List<Glyph?> new_list = new List<Glyph?> ();
		int i = 0;
		
		foreach (Glyph? g in glyph) {
			if (i == index) {
				new_list.append (substitute);
			}

			if (!(i >= index && i < index + length)) {
				new_list.append (g);
			}

			i++;
		}
		
		// remove all links in order to prevent the g_list to delete all items
		// when the list is deleted.
		while (glyph.length () > 0) { 
			glyph.remove_link (glyph.first ());
		}
		
		glyph = new_list.copy ();
		
		while (new_list.length () > 0) {
			new_list.remove_link (new_list.first ());
		}
				
	}
}

}
