/*
    Copyright (C) 2012, 2013 Johan Mattsson

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

class GposTable : Table {
	
	public GposTable () {
		id = "GPOS";
	}
	
	public override void parse (FontData dis) throws Error {
		// Not implemented, freetype2 is used for loading fonts
	}

	public void process (KernTable kern_table) throws GLib.Error {
		FontData fd = new FontData ();
		uint16 num_kerning_values = (uint16) kern_table.kernings.length ();
		int i;
		int size_of_pair;
		
		if (num_kerning_values == 0) {
			warning ("No kerning to add to gpos table.");
		}
		
		printd (@"Adding $num_kerning_values kerning pairs to gpos table.\n");
		
		fd.add_ulong (0x00010000); // table version
		fd.add_ushort (10); // offset to script list
		fd.add_ushort (30); // offset to feature list
		fd.add_ushort (44); // offset to lookup list
		
		// script list ?
		fd.add_ushort (1);   // number of items in script list
		fd.add_tag ("DFLT"); // default script
		fd.add_ushort (8);	 // offset to script table from script list
		
		// script table
		fd.add_ushort (4); // offset to default language system
		fd.add_ushort (0); // number of languages
		
		// LangSys table 
		fd.add_ushort (0); // reserved
		fd.add_ushort (0); // required features (0xFFFF is none)
		fd.add_ushort (1); // number of features
		fd.add_ushort (0); // feature index
		
		// feature table
		fd.add_ushort (1); // number of features
		
		fd.add_tag ("kern"); // feature tag
		fd.add_ushort (8); // offset to feature
		
		fd.add_ushort (0); // feature prameters (null)
		fd.add_ushort (1); // number of lookups
		fd.add_ushort (0); // lookup indice
		
		// lookup table
		fd.add_ushort (1); // number of lookups
		fd.add_ushort (4); // offset to lookup 1
		
		fd.add_ushort (2); // lookup type // FIXME	
		fd.add_ushort (0); // lookup flags
		fd.add_ushort (1); // number of subtables
		fd.add_ushort (8); // array of offsets to subtables
		
		// MarkFilteringSet 
		
		// the kerning pair table
		size_of_pair = 6;
		fd.add_ushort (1); // position format
		// offset to coverage table from beginning of kern pair table
		fd.add_ushort (10 + 2 * num_kerning_values + size_of_pair * num_kerning_values);  
		fd.add_ushort (0x0004); // ValueFormat1 (0x0004 is x advance)
		fd.add_ushort (0); // ValueFormat2 (0 is null)
		fd.add_ushort (num_kerning_values); // n pairs
		
		// pair offsets orderd by coverage index
		i = 0;
		foreach (Kern k in kern_table.kernings) {
			fd.add_ushort (10 + 2 * num_kerning_values + i * size_of_pair);
			i++;
		}
		
		// pair table 
		i = 0;
		
		foreach (Kern k in kern_table.kernings) {
			// pair value record
			fd.add_ushort (1); // n pair vaules
			fd.add_ushort (k.right); // gid to second glyph
			fd.add_short (k.kerning); // value of ValueFormat1, horizontal adjustment for advance			
			// value of ValueFormat2 is null
			
			ProgressBar.set_progress ((double) (num_kerning_values - ++i) / num_kerning_values);
		}
		
		ProgressBar.set_progress (0); // reset progress bar
		
		// coverage
		fd.add_ushort (1); // format
		fd.add_ushort (num_kerning_values); // number of gid
		foreach (Kern k in kern_table.kernings) {
			fd.add_ushort (k.left); // gid
		}
		
		fd.pad ();	
		this.font_data = fd;
	}

}

}
