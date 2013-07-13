/*
    Copyright (C) 2012, 2013 Johan Mattsson

    This library is free software; you can redistribute it and/or modify 
    it under the terms of the GNU Lesser General Public License as 
    published by the Free Software Foundation; either version 3 of the 
    License, or (at your option) any later version.

    This library is distributed in the hope that it will be useful, but 
    WITHOUT ANY WARRANTY; without even the implied warranty of 
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU 
    Lesser General Public License for more details.
*/

namespace BirdFont {

class HmtxTable : Table {
	
	uint32 nmetrics;
	uint32 nmonospaced;
		
	uint16* advance_width = null;
	uint16* left_side_bearing = null;
	uint16* left_side_bearing_monospaced = null;
	
	public int16 max_advance = 0;
	public int16 max_extent = 0;
	public int16 min_lsb = 0; 
	public int16 min_rsb = 0;
			
	HeadTable head_table;
	GlyfTable glyf_table;
	
	public HmtxTable (HeadTable h, GlyfTable gt) {
		head_table = h;
		glyf_table = gt;
		id = "hmtx";
	}
	
	~HmtxTable () {
		if (advance_width != null) delete advance_width;
		if (left_side_bearing != null) delete left_side_bearing; 
	}

	public double get_advance (uint32 i) {
		if (i >= nmetrics) {
			warning (@"i >= nmetrics $i >= $nmetrics");
			return 0;
		}
		
		return_val_if_fail (advance_width != null, 0.0);
		
		return advance_width[i] * 1000 / head_table.get_units_per_em ();
	}
		
	/** Get left side bearing relative to xmin. */
	public double get_lsb (uint32 i) {
		return_val_if_fail (i < nmetrics, 0.0);
		return_val_if_fail (left_side_bearing != null, 0.0);
		
		return left_side_bearing[i] * 1000 / head_table.get_units_per_em ();
	}
			
	public new void parse (FontData dis, HheaTable hhea_table, LocaTable loca_table) throws GLib.Error {
		nmetrics = hhea_table.num_horizontal_metrics;
		nmonospaced = loca_table.size - nmetrics;
		
		dis.seek (offset);
		
		if (nmetrics > loca_table.size) {
			warning (@"(nmetrics > loca_table.size) ($nmetrics > $(loca_table.size))");
			return;
		}
		
		printd (@"nmetrics: $nmetrics\n");
		printd (@"loca_table.size: $(loca_table.size)\n");
		
		advance_width = new uint16[nmetrics];
		left_side_bearing = new uint16[nmetrics];
		left_side_bearing_monospaced = new uint16[nmonospaced];
		
		for (int i = 0; i < nmetrics; i++) {
			advance_width[i] = dis.read_ushort ();
			left_side_bearing[i] = dis.read_short ();
		}
		
		for (int i = 0; i < nmonospaced; i++) {
			left_side_bearing_monospaced[i] = dis.read_short ();
		}
	}
	
	public void process () {
		FontData fd = new FontData ();

		int16 advance;
		int16 extent;
		int16 rsb;
		int16 lsb;
		
		double xmin;
		double ymin;
		double xmax;
		double ymax;
		
		// advance and lsb
		foreach (Glyph g in glyf_table.glyphs) {
			g.boundries (out xmin, out ymin, out xmax, out ymax);
			lsb = (int16) (-1 * (g.left_limit - xmin) * UNITS);
			advance = (int16) ((g.right_limit - g.left_limit) * UNITS);
			extent = (int16) (lsb + (xmax - xmin) * UNITS);
			rsb = (int16) (advance - extent);
						
			fd.add_u16 (advance);
			fd.add_16 (lsb);
	
			if (advance > max_advance) {
				max_advance = advance;
			}
			
			if (extent > max_extent) {
				max_extent = extent;
			}
			
			if (rsb < min_rsb) {
				min_rsb = rsb;
			}

			if (lsb < min_lsb) {
				min_lsb = lsb;
			}
		}
		
		// monospaced lsb ...
		
		font_data = fd;
		
		warn_if_fail (max_advance != 0);
	}
}

}
