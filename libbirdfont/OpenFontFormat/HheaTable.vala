/*
	Copyright (C) 2012 2013 2015 Johan Mattsson

	This library is free software; you can redistribute it and/or modify 
	it under the terms of the GNU Lesser General Public License as 
	published by the Free Software Foundation; either version 3 of the 
	License, or (at your option) any later version.

	This library is distributed in the hope that it will be useful, but 
	WITHOUT ANY WARRANTY; without even the implied warranty of 
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU 
	Lesser General Public License for more details.
*/

using Math;

namespace BirdFont {

public class HheaTable : OtfTable {

	public int16 ascender;
	public int16 descender;
	public int16 line_gap;
	
	Fixed version;

	uint16 max_advance;
	int16 min_lsb;
	int16 min_rsb;
	int16 xmax_extent;
	int16 carret_slope;
	int16 carret_slope_run;
	int16 carret_offset;
	
	int16 metric_format;
	public int16 num_horizontal_metrics;
		
	GlyfTable glyf_table;
	HeadTable head_table;
	HmtxTable hmtx_table;
	
	int16 winAscent = 0;
	int16 winDescent = 0;
	
	public HheaTable (GlyfTable g, HeadTable h, HmtxTable hm) {
		glyf_table = g;
		head_table = h;
		hmtx_table = hm;
		id = "hhea";
	}

	public int16 get_winascent () {
		if (winAscent != 0) {
			return winAscent;
		}
		
		foreach (GlyfData glyph in glyf_table.glyf_data) {
			if (glyph.bounding_box_ymax > winAscent) {
				winAscent = glyph.bounding_box_ymax;
			}
		}
		
		return winAscent;
	}
	
	public int16 get_windescent () {
		if (winDescent != 0) {
			return winDescent;
		}

		foreach (GlyfData glyph in glyf_table.glyf_data) {
			if (glyph.bounding_box_ymin < winDescent) {
				winDescent = glyph.bounding_box_ymin;
			}
		}
		
		return winDescent;
	}
	
	public override void parse (FontData dis) throws GLib.Error {
		dis.seek (offset);
		
		version = dis.read_fixed ();
		
		if (!version.equals (1, 0)) {
			warning (@"wrong version in hhea table $(version.get_string ())");
		}
		
		ascender = dis.read_short ();
		descender = dis.read_short ();
		line_gap = dis.read_short ();
		max_advance = dis.read_ushort ();
		min_lsb = dis.read_short ();
		min_rsb = dis.read_short ();
		xmax_extent = dis.read_short ();
		carret_slope = dis.read_short ();
		carret_slope_run = dis.read_short ();
		carret_offset = dis.read_short ();
		
		// reserved x 4
		dis.read_short ();
		dis.read_short ();
		dis.read_short ();
		dis.read_short ();
		
		metric_format = dis.read_short ();
		num_horizontal_metrics = dis.read_short ();
	}
	
	public void process () throws GLib.Error {
		FontData fd = new FontData ();
		Fixed version = 1 << 16;
		Font font = OpenFontFormatWriter.get_current_font ();
		int upm, total_height;
		
		fd.add_fixed (version); // table version
		
		ascender = (int16) rint (font.top_limit * HeadTable.UNITS);
		ascender -= (int16) rint (font.base_line * HeadTable.UNITS);
		
		descender = (int16) rint (font.bottom_limit * HeadTable.UNITS);
		descender -= (int16) rint (font.base_line * HeadTable.UNITS);

		upm = HeadTable.units_per_em;
		total_height = get_winascent () - get_windescent ();
		ascender = (int16) rint (upm * get_winascent () / (double) total_height);
		descender = (int16) (ascender - upm);
		line_gap = (int16) rint (total_height - upm);
				
		fd.add_16 (ascender); // Ascender
		fd.add_16 (descender); // Descender
		fd.add_16 (line_gap); // LineGap
				
		fd.add_u16 (hmtx_table.max_advance); // maximum advance width value in 'hmtx' table.
		
		fd.add_16 (hmtx_table.min_lsb); // min left side bearing
		fd.add_16 (hmtx_table.min_rsb); // min right side bearing
		fd.add_16 (hmtx_table.max_extent); // x max extent Max(lsb + (xMax - xMin))
		
		fd.add_16 (1); // caretSlopeRise
		fd.add_16 (0); // caretSlopeRun
		fd.add_16 (0); // caretOffset
		
		// reserved
		fd.add_16 (0);
		fd.add_16 (0);
		fd.add_16 (0);
		fd.add_16 (0);
		
		fd.add_16 (0); // metricDataFormat 0 for current format.
		
		// numberOfHMetrics Number of hMetric entries in 'hmtx' table
		fd.add_u16 ((uint16) glyf_table.glyphs.size); 

		// padding
		fd.pad ();
		this.font_data = fd;
	}
}

}
