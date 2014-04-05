/*
    Copyright (C) 2012, 2013, 2014 Johan Mattsson

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

public class GlyfTable : Table {
	// Flags for composite glyph
	static const uint16 BOTH_ARE_WORDS = 1 << 0;
	static const uint16 BOTH_ARE_XY_VALUES = 1 << 1;
	static const uint16 ROUND_TO_GRID = 1 << 2;
	static const uint16 SCALE = 1 << 3;
	static const uint16 RESERVED = 1 << 4;
	static const uint16 MORE_COMPONENTS = 1 << 5;
	static const uint16 SCALE_X_Y = 1 << 6;
	static const uint16 SCALE_WITH_ROTATTION = 1 << 7;
	static const uint16 INSTRUCTIONS = 1 << 8;

	public int16 xmin = int16.MAX;
	public int16 ymin = int16.MAX;
	public int16 xmax = int16.MIN;
	public int16 ymax = int16.MIN;

	public FontData dis;
	public HeadTable head_table;
	public HmtxTable hmtx_table;
	public LocaTable loca_table;
	public CmapTable cmap_table; // cmap and post is null when inistialized and set in parse method
	public PostTable post_table;
	public KernTable kern_table;
	
	public List<uint32> location_offsets; 

	// a list of glyphs sorted in the order we expect to find them in a
	// ttf font. notdef is the firs glyph followed by null and nonmarkingreturn.
	// after that will all assigned glyphs appear in sorted (unicode) order, all 
	// remaining unassigned glyphs will be added in the last section of the file.	
	public List<Glyph> glyphs;
	
	uint16 max_points = 0;
	uint16 max_contours = 0;

	public GlyfTable (LocaTable l) {
		id = "glyf";
		loca_table = l;
		location_offsets = new List<uint32> ();
		glyphs = new List<Glyph> ();
	}	

	public int get_gid (string name) {
		int i = 0;
		
		foreach (Glyph g in glyphs) {
			if (g.name == name) {
				return i;
			}
			i++;
		}
		
		warning (@"Glyph $name not found in font.");
		return -1;
	}

	public uint16 get_max_contours () {
		return max_contours;
	}

	public uint16 get_max_points () {
		return max_points;
	}

	public uint16 get_first_char () {
		return 32; // space
	}
	
	public uint16 get_last_char () {
		unowned List<Glyph> gl = glyphs.last ();
		Glyph g = (!) gl.data;
		
		while (gl != glyphs.first ()) {
			g = (!) gl.data;
			
			if (!g.is_unassigned ()) {
				break;
			}
			
			gl = gl.prev;
		}
		
		return (uint16)g.unichar_code; 
	}

	public void process () throws GLib.Error {
		FontData fd = new FontData ();
		uint last_len = 0;
		uint i = 0;
		uint num_glyphs;
		
		create_glyph_table ();
		
		num_glyphs = glyphs.length ();
		
		if (glyphs.length () == 0) {
			warning ("No glyphs in glyf table.");
		}
		
		foreach (Glyph g in glyphs) {
			// set values for loca table
			assert (fd.length () % 4 == 0);
			location_offsets.append (fd.length ());
			process_glyph (g, fd);

			printd (@"adding glyph: $(g.name)\n");
			printd (@"glyf length: $(fd.length () - last_len)\n");
			printd (@"loca fd.length (): $(fd.length ())\n");

			last_len = fd.length ();
		}

		location_offsets.append (fd.length ()); // last entry in loca table is special
		
		// every glyph is padded, no padding to be done here
		assert (fd.length () % 4 == 0);

		font_data = fd;	
	}

	// necessary in order to have glyphs sorted according to ttf specification
	public void create_glyph_table () {
		Glyph? gl;
		Glyph g;
		Font font = OpenFontFormatWriter.get_current_font ();
		uint32 indice;
		List<Glyph> unassigned_glyphs;
		uint32 num_glyphs = font.length ();
		uint32 i = 0;
		// add notdef. character at index zero + other special chars first
		glyphs.append (font.get_not_def_character ());
		glyphs.append (font.get_null_character ());
		glyphs.append (font.get_nonmarking_return ());
		glyphs.append (font.get_space ());
		
		unassigned_glyphs = new List<Glyph> ();
		
		if (font.get_glyph_indice (0) == null) {
			warning ("No glyphs in font.");
		}
				
		// add glyphs, first all assigned then the unassigned ones
		for (indice = 0; (gl = font.get_glyph_indice (indice)) != null; indice++) {		
			g = ((!) gl).copy ();
			
			if (g.unichar_code <= 27) { // skip control characters
				continue;
			}

			if (g.unichar_code == 32) { // skip space
				continue;
			}
						
			if (g.name == ".notdef") {
				continue;
			}
			
			g.remove_empty_paths ();

			if (!g.is_unassigned ()) {
				glyphs.append (g);
			} else {
				printd ("Adding unassigned glyph.");
				unassigned_glyphs.append (g);
			}
		}
		
		foreach (Glyph ug in unassigned_glyphs) {
			// FIXME: ligatures
			// glyphs.append (ug);
		}
		
	}

	public void process_glyph (Glyph g, FontData fd) throws GLib.Error {
		uint16 end_point;
		uint16 npoints;
		int16 ncontours;
		int16 nflags;
		int glyph_offset;
		uint len; 
		uint coordinate_length;
		GlyfData glyf_data;
		
		fd.seek_end (); // append glyph
		
		glyph_offset = (int) fd.length ();
		
		printd (@"glyph_offset: $(glyph_offset)\n");
		
		g.remove_empty_paths ();
		glyf_data = new GlyfData (g);
		
		if (g.path_list.length () == 0 || glyf_data.paths.length () == 0 || glyf_data.get_ncontours () == 0) {
			// location_offsets will be equal to location_offset + 1 for
			// all empty glyphs
			g.set_empty_ttf (true);
			return;
		}
		
		g.set_empty_ttf (false);

		if (glyf_data.get_ncontours () == 0) {
			warning (@"No paths in $(g.get_name ()) ($(g.get_hex ())) can be exported.");
		}
		
		ncontours = (int16) glyf_data.paths.length ();
		fd.add_short (ncontours);

		// bounding box
		fd.add_16 (glyf_data.bounding_box_xmin);
		fd.add_16 (glyf_data.bounding_box_ymin);
		fd.add_16 (glyf_data.bounding_box_xmax);
		fd.add_16 (glyf_data.bounding_box_ymax);

		// end points
		foreach (uint16 end in glyf_data.end_points) {
			fd.add_u16 (end);
		}

		fd.add_u16 (0); // instruction length 
		
		uint glyph_header = 12 + ncontours * 2;
		
		printd (@"next glyf: $(g.name) ($((uint32)g.unichar_code))\n");
		printd (@"glyf header length: $(glyph_header)\n");
				
		end_point = glyf_data.get_end_point ();
		ncontours = glyf_data.get_ncontours ();
		npoints = (ncontours > 0) ? end_point : 0; // +1?
		
		if (npoints > max_points) {
			max_points = npoints;
		}
		
		if (ncontours > max_contours) {
			max_contours = ncontours;
		}
		
		// flags		
		nflags = glyf_data.get_nflags ();
		if (unlikely (nflags != npoints)) {
			print ("glyf table data:\n");
			fd.dump ();
			warning (@"(nflags != npoints)  ($nflags != $npoints) in glyph $(g.name). ncontours: $ncontours");
		}
		assert (nflags == npoints);
	
		foreach (uint8 flag in glyf_data.flags) {
			fd.add_byte (flag);
		}

		printd (@"flags: $(nflags)\n");
		
		// x coordinates
		foreach (int16 x in glyf_data.coordinate_x) {
			fd.add_16 (x);
		}	

		// y coordinates
		foreach (int16 y in glyf_data.coordinate_y) {
			fd.add_16 (y);
		}
	
		len = fd.length ();
		coordinate_length = fd.length () - nflags - glyph_header;
		printd (@"coordinate_length: $(coordinate_length)\n");
		printd (@"fd.length (): $(fd.length ())\n");
		assert (fd.length () > nflags + glyph_header);
		
		printd (@"glyph_offset: $(glyph_offset)\n");
		printd (@"len: $(len)\n");

		// save bounding box for head table
		if (glyf_data.bounding_box_xmin < this.xmin) {
			this.xmin = glyf_data.bounding_box_xmin;
		}
		
		if (glyf_data.bounding_box_ymin < this.ymin) {
			this.ymin = glyf_data.bounding_box_ymin;
		}
		
		if (glyf_data.bounding_box_xmax > this.xmax) {
			this.xmax = glyf_data.bounding_box_xmax;
		}
		
		if (glyf_data.bounding_box_ymax > this.ymax) {
			this.ymax = glyf_data.bounding_box_ymax;
		}
		
		printd (@"length before padding: $(fd.length ())\n");
		
		// all glyphs needs padding for loca table to be correct
		while (fd.length () % 4 != 0) {
			fd.add (0);
		}
		printd (@"length after padding: $(fd.length ())\n");
	}

	public Glyph? read_glyph (string name) throws GLib.Error {
		Glyph? glyph;
		int i;
		
		i = post_table.get_gid (name);
		
		if (i == -1) {
			return null;
		}
		
		glyph = parse_index (i, dis, loca_table, hmtx_table, head_table, post_table);
		return glyph;
	}
	
	public new void parse (FontData dis, CmapTable cmap_table, LocaTable loca, HmtxTable hmtx_table, HeadTable head_table, PostTable post_table, KernTable kern_table) throws GLib.Error {
		this.cmap_table = cmap_table;
		this.post_table = post_table;
		this.loca_table = loca;
		this.hmtx_table = hmtx_table;
		this.head_table = head_table;
		this.kern_table = kern_table;
		this.dis = dis;
	}
	
	Glyph parse_index (int index, FontData dis, LocaTable loca, HmtxTable hmtx_table, HeadTable head_table, PostTable post_table) throws GLib.Error {
		Glyph glyph = new Glyph ("");
		double xmin, xmax;
		double units_per_em = head_table.get_units_per_em ();
		unichar character = 0;
		string name;
		
		character = cmap_table.get_char (index);
		name = post_table.get_name (index);
		
		if (name == "") {
			StringBuilder name_c = new StringBuilder ();
			name_c.append_unichar (character);
			name = name_c.str;
		}

		printd (@"name: $(name)\n");

		if (!loca.is_empty (index)) {	
			glyph = parse_next_glyf (dis, character, index, out xmin, out xmax, units_per_em);
			
			glyph.left_limit = xmin - hmtx_table.get_lsb (index);
			glyph.left_limit = 0;
			glyph.right_limit = glyph.left_limit + hmtx_table.get_advance (index);
		} else {
			// add empty glyph
			glyph = new Glyph (name, character);
			glyph.left_limit = -hmtx_table.get_lsb (index);
			glyph.right_limit = hmtx_table.get_advance (index) - hmtx_table.get_lsb (index);				
		}
		
		glyph.name = name;

		if (character == 0) {
			glyph.set_unassigned (true);
		}
		
		if (character == 0 && name != "") {
			stderr.printf (@"Got null character\n");
			stderr.printf (@"gid: $index\n");
			stderr.printf (@"char: $((uint) character)\n");
			stderr.printf (@"name: $(name)\n");
		}
		
		return glyph;
	}
	
	Glyph parse_next_composite_glyf (FontData dis, unichar character, int pgid) throws Error {
		uint16 component_flags = 0;
		uint16 glyph_index;
		int16 arg1 = 0;
		int16 arg2 = 0;

		F2Dot14 scale;
		
		F2Dot14 scalex;
		F2Dot14 scaley;
		
		F2Dot14 scale01;
		F2Dot14 scale10;

		Glyph glyph, linked_glyph;
		List<int> x = new List<int> ();
		List<int> y = new List<int> ();
		List<int> gid = new List<int> ();
		
		double xmin, xmax;
		double units_per_em = head_table.get_units_per_em ();
		
		int glid;
		
		StringBuilder name = new StringBuilder ();
		name.append_unichar (character);
		
		glyph = new Glyph (name.str, character);
		
		do {
			component_flags = dis.read_ushort ();
			glyph_index = dis.read_ushort ();
			
			if ((component_flags & BOTH_ARE_WORDS) > 0) {
				arg1 = dis.read_short ();
				arg2 = dis.read_short ();			
			} else if ((component_flags & BOTH_ARE_XY_VALUES) > 0) {
				arg1 = dis.read_byte ();
				arg2 = dis.read_byte ();
			}
			
			gid.append (glyph_index);
			x.append (arg1);
			y.append (arg2);

			// if ((component_flags & RESERVED) > 0)
			
			if ((component_flags & SCALE) > 0) {
				scale = dis.read_f2dot14 ();
			} else if ((component_flags & SCALE_X_Y) > 0) {
				scalex = dis.read_f2dot14 ();
				scaley = dis.read_f2dot14 ();
			} else if ((component_flags & SCALE_WITH_ROTATTION) > 0) {
				scalex = dis.read_f2dot14 ();
				scale01 = dis.read_f2dot14 ();
				scale10 = dis.read_f2dot14 ();
				scaley = dis.read_f2dot14 ();
			}
			
		} while ((component_flags & MORE_COMPONENTS) > 0);
	
		
		for (int i = 0; i < gid.length (); i++) {
			// compensate xmax ymax with coordinate
			glid = gid.nth (i).data;

			if (glid == pgid) {
				warning ("Cannot link a glyph to it self.");
				continue;
			}

			linked_glyph = parse_next_glyf (dis, character, glid, out xmin, out xmax, units_per_em);
		}
		
		return glyph;
	}
	
	Glyph parse_next_glyf (FontData dis, unichar character, int gid, out double xmin, out double xmax, double units_per_em) throws Error {
		uint16* end_points = null;
		uint8* instructions = null;
		uint8* flags = null;
		int16* xcoordinates = null;
		int16* ycoordinates = null;
		
		int npoints = 0;
		
		int16 ncontours;
		int16 ixmin; // set boundaries
		int16 iymin;
		int16 ixmax;
		int16 iymax;
		uint16 ninstructions;

		int16 rxmin = int16.MAX; // real xmin
		int16 rymin = int16.MAX;;
		int16 rxmax = int16.MIN;
		int16 rymax = int16.MIN;
				
		int nflags;
		
		Error? error = null;
		
		uint start, end, len;
		
		StringBuilder name = new StringBuilder ();
		name.append_unichar (character);

		xmin = 0;
		xmax = 0;

		start = loca_table.get_offset (gid);
		end = loca_table.get_offset (gid + 1);
		len = start - end;

		dis.seek (offset + start);
		
		ncontours = dis.read_short ();
		
		return_val_if_fail (start < end, new Glyph (""));

		if (ncontours == 0) {
			warning (@"Zero contours in glyph $(name.str).");

			// should skip body
		}
				
		if (ncontours == -1) {
			return parse_next_composite_glyf (dis, character, gid);
		}

		return_val_if_fail (ncontours < len, new Glyph (""));
						
		if (ncontours < -1) {
			warning (@"$ncontours contours in glyf table.");
			error = new BadFormat.PARSE ("Invalid glyf");
			throw error;
		}
		
		ixmin = dis.read_short ();
		iymin = dis.read_short ();
		ixmax = dis.read_short ();
		iymax = dis.read_short ();

		end_points = new uint16[ncontours + 1];
		for (int i = 0; i < ncontours; i++) {
			end_points[i] = dis.read_ushort (); // FIXA: mind shot vector is negative
			
			if (i > 0 && end_points[i] < end_points[i -1]) {
				warning (@"Next endpoint has bad value in $(name.str). (end_points[i] > end_points[i -1])  ($(end_points[i]) > $(end_points[i -1])) i: $i ncontours: $ncontours");
			}
		}
		
		if (ncontours > 0) {
			npoints = end_points[ncontours - 1] + 1;
		} else {
			npoints = 0;
		}
		
		return_val_if_fail (npoints < len, new Glyph.no_lines (""));
		
		ninstructions = dis.read_ushort ();
		
		return_val_if_fail (ninstructions < len, new Glyph.no_lines (""));
		
		instructions = new uint8[ninstructions + 1];
		uint8 repeat;
		for (int i = 0; i < ninstructions; i++) {
			instructions[i] = dis.read_byte ();
		}

		nflags = 0;
		flags = new uint8[npoints + 1];
		for (int i = 0; i < npoints; i++) {
			flags[i] = dis.read_byte ();
			
			if ((flags[i] & CoordinateFlags.REPEAT) > 0) {
				repeat = dis.read_byte ();
				
				if (i + repeat >= npoints) {
					error = new BadFormat.PARSE ("Too many flags in glyf in glyph $(name.str). (i >= ninstructions).");
					break;
				}
				
				for (int j = 0; j < repeat; j++) {
					flags[j + i + 1] = flags[i];
				}
				
				nflags += repeat;
				i += repeat;
			}
			
			nflags++;
		}
		
		if (nflags != npoints) {
			warning (@"(nflags != npoints) ($nflags != $npoints) in $(name.str)");
			error = new BadFormat.PARSE (@"Wrong number of flags in glyph $(name.str). (nflags != npoints) ($nflags != $npoints)");
		}
		
		warn_if_fail (nflags == npoints);

		printd (@"npoints: $npoints\n");
		printd (@"ncontours: $ncontours\n");
		printd (@"ninstructions: $ninstructions\n");
		printd (@"nflags: $nflags\n");
				
		int16 last = 0;
		xcoordinates = new int16[npoints + 1];
		for (int i = 0; i < npoints; i++) {
			if ((flags[i] & CoordinateFlags.X_SHORT_VECTOR) > 0) {	
				if ((flags[i] & CoordinateFlags.X_SHORT_VECTOR_POSITIVE) > 0) {
					xcoordinates[i] = last + dis.read_byte ();
				} else {
					xcoordinates[i] = last - dis.read_byte ();
				}
			} else {
				if ((flags[i] & CoordinateFlags.X_IS_SAME) > 0) {
					xcoordinates[i] = last;
				} else {
					xcoordinates[i] = last + dis.read_short ();
				}
			}
			
			last = xcoordinates[i];
			
			if (last > rxmax) rxmax = last;
			if (last < rxmin) rxmin = last;
			
			if (!(ixmin <= last <= ixmax))	{
				stderr.printf (@"x is out of bounds in glyph $(name.str). ($ixmin <= $last <= $ixmax) char $((uint)character)\n");
			}
			
			if (!(head_table.xmin <= last <= head_table.xmax))	{
				stderr.printf (@"x is outside of of font bounding box in glyph $(name.str). ($(head_table.xmin) <= $last <= $(head_table.xmax)) char $((uint)character)\n");
			}			
		}
		
		last = 0;
		ycoordinates = new int16[npoints + 1];
		for (int i = 0; i < npoints; i++) {
			if ((flags[i] & CoordinateFlags.Y_SHORT_VECTOR) > 0) {	
				if ((flags[i] & CoordinateFlags.Y_SHORT_VECTOR_POSITIVE) > 0) {
					ycoordinates[i] = last + dis.read_byte ();
				} else {
					ycoordinates[i] = last - dis.read_byte ();
				}
			} else {
				if ((flags[i] & CoordinateFlags.Y_IS_SAME) > 0) {
					ycoordinates[i] = last;
				} else {
					ycoordinates[i] = last + dis.read_short ();
				}
			}
			
			last = ycoordinates[i];

			if (last > rymax) rymax = last;
			if (last < rymin) rymin = last;
			
			if (!(iymin <= last <= iymax))	{
				stderr.printf (@"y is out of bounds in glyph $(name.str). ($iymin <= $last <= $iymax) char $((uint)character)\n");
			}
			
			if (!(head_table.ymin <= last <= head_table.ymax))	{
				stderr.printf (@"y is outside of of font bounding box in glyph $(name.str). ($(head_table.ymin) <= $last <= $(head_table.ymax)) char $((uint)character)\n");
			}
		}
		
		if (rymin != iymin || rxmin != ixmin || rxmax != ixmax || rymax != iymax) {
			warning (@"Warning real boundry for glyph does not match boundry set in glyph header for glyph $(name.str).");
			stderr.printf (@"ymin: $rymin header: $iymin\n");
			stderr.printf (@"xmin: $rxmin header: $ixmin\n");
			stderr.printf (@"ymax: $rymax header: $iymax\n");
			stderr.printf (@"xmax: $rxmax header: $ixmax\n");
		} 
		
		int j = 0;
		int first_point;
		int last_point = 0;
		Glyph glyph;
		double x, y;

		glyph = new Glyph (name.str, character);
		
		xmin = ixmin * 1000.0 / units_per_em;
		xmax = ixmax * 1000.0 / units_per_em;
		
		for (int i = 0; i < ncontours; i++) {
			x = 0;
			y = 0;
			
			Path path = new Path ();
			EditPoint edit_point = new EditPoint ();
			bool prev_is_curve = false;
			
			first_point = j;
			last_point = end_points[i];
			for (; j <= end_points[i]; j++) {

				if (j >= npoints) {
					warning (@"j >= npoints in glyph $(name.str). (j: $j, end_points[i]: $(end_points[i]), npoints: $npoints)");
					break;
				}
								
				x = xcoordinates[j] * 1000.0 / units_per_em; // in proportion to em width
				y = ycoordinates[j] * 1000.0 / units_per_em;
				
				if ((flags[j] & CoordinateFlags.ON_PATH) > 0) {
					// Point
					edit_point = new EditPoint ();
					edit_point.set_position (x, y);
					path.add_point (edit_point);
					
					if (prev_is_curve) {
						edit_point.get_left_handle ().set_point_type (PointType.NONE);
						edit_point.get_left_handle ().length = 0;
					} else {
						edit_point.recalculate_linear_handles ();
					}
					
					prev_is_curve = false;
				} else {
									
					if (prev_is_curve) {
						x = x - (x - edit_point.right_handle.x ()) / 2;
						y = y - (y - edit_point.right_handle.y ()) / 2;

						edit_point = new EditPoint ();
						edit_point.set_position (x, y);
						path.add_point (edit_point);
					}

					x = xcoordinates[j] * 1000.0 / units_per_em; // in proportion to em width
					y = ycoordinates[j] * 1000.0 / units_per_em;

					edit_point.get_left_handle ().set_point_type (PointType.NONE);
					edit_point.get_left_handle ().length = 0;
						
					edit_point.type = PointType.CUBIC;
					edit_point.get_right_handle ().set_point_type (PointType.CUBIC);
					edit_point.get_right_handle ().move_to_coordinate (x, y);
					
					prev_is_curve = true;
				} 
			}
			
			// last to first point
			if (prev_is_curve) {
				x = xcoordinates[first_point] * 1000.0 / units_per_em; // in proportion to em width
				y = ycoordinates[first_point] * 1000.0 / units_per_em;
				
				x = x - (x - edit_point.right_handle.x ()) / 2;
				y = y - (y - edit_point.right_handle.y ()) / 2;
				
				edit_point = new EditPoint ();
				edit_point.set_position (x, y);
				path.add_point (edit_point);
				
				x = xcoordinates[first_point] * 1000.0 / units_per_em; // in proportion to em width
				y = ycoordinates[first_point] * 1000.0 / units_per_em;

				edit_point.get_left_handle ().set_point_type (PointType.CUBIC);
				edit_point.get_left_handle ().length = 0;
					
				edit_point.type = PointType.CUBIC;
				edit_point.get_right_handle ().set_point_type (PointType.CUBIC);
				edit_point.get_right_handle ().move_to_coordinate (x, y);
			}
			
			// curve last to first
			x = xcoordinates[first_point] * 1000.0 / units_per_em; // in proportion to em width
			y = ycoordinates[first_point] * 1000.0 / units_per_em;
			edit_point.type = PointType.CUBIC;
			edit_point.get_right_handle ().set_point_type (PointType.CUBIC);
			edit_point.get_right_handle ().move_to_coordinate (x, y);
			
			path.close ();
			
			glyph.add_path (path);
		}
		
		// glyphs with no bounding boxes
		if (ixmax <= ixmin) {
			warning (@"Bounding box is bad. (xmax == xmin) ($xmax == $xmin)");
			
			if (glyph.path_list.length () > 0) {
				
				Path ps = ((!) glyph.path_list.first ()).data;
				
				ps.update_region_boundaries ();
				xmin = ps.xmin;
				xmax = ps.xmax;

				foreach (Path p in glyph.path_list) {
					p.update_region_boundaries ();
					
					if (p.xmin < xmin) {
						xmin = p.xmin;
					}
					
					if (p.xmax > xmax) {
						xmax = p.xmax;
					}
				}
				
			}
		}
						
		if (end_points != null) {
			delete end_points;
		}
		
		if (instructions != null) {
			delete instructions;
		}
		
		if (flags != null) {
			delete flags;
		}
		
		if (xcoordinates != null) {
			delete xcoordinates;
		}
		
		if (ycoordinates != null) {
			delete ycoordinates;
		}
		
		if (error != null) {
			warning ("Failed to parse glyph");
			throw (!) error;
		}
		
		return glyph;
	}
}

}
