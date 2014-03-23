/*
    Copyright (C) 2013 Johan Mattsson

    This library is free software; you can redistribute it and/or modify 
    it under the terms of the GNU Lesser General Public License as 
    published by the Free Software Foundation; either version 3 of the 
    License, or (at your option) any later version.

    This library is distributed in the hope that it will be useful, but 
    WITHOUT ANY WARRANTY; without even the implied warranty of 
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU 
    Lesser General Public License for more details.
*/
using Xml;

namespace BirdFont {

/** 
 * BirdFont file format. This class can parse both the old ffi format 
 * and the new bf format.
 */
class BirdFontFile {
	
	Font font;
	
	public BirdFontFile (Font f) {
		font = f;
	}

	/** Load a new .bf file.
	 * @param path path to a valid .bf file
	 */
	public bool load (string path) {
		TextReader tr;
		bool ok;
		
		Parser.init ();
		
		font.font_file = path;
		tr = new TextReader.filename (path);
		ok = load_xml (tr);
		
		Parser.cleanup ();
				
		return ok;
	}

	/** Load a new .bf file.
	 * @param xml_data data for a valid .bf file
	 */
	public bool load_data (string xml_data) {
		TextReader tr;
		bool ok;
		
		Parser.init ();
		font.font_file = "typeface.bf";
		tr = new TextReader.for_doc (xml_data, "");
		ok = load_xml (tr);
		
		Parser.cleanup ();
		
		return ok;
	}

	private bool load_xml (TextReader tr) {
		bool ok = true;
		Xml.Node* root;
		
		tr.read ();
		root = tr.expand ();

		if (is_null (root)) {
			warning ("No root element");
			tr.close ();
			return false;
		}

		create_background_files (root);
		ok = parse_file (root);
		
		tr.close ();
			
		return ok;
	}

	public bool write_font_file (string path, bool backup = false) {
		try {
			File file = File.new_for_path (path);
			uint num_kerning_pairs;
			uint progress;
			string range;
			
			if (file.query_file_type (0) == FileType.DIRECTORY) {
				warning (@"Can not save font. $path is a directory.");
				return false;
			}
			
			if (file.query_exists ()) {
				file.delete ();
			}
			
			DataOutputStream os = new DataOutputStream(file.create(FileCreateFlags.REPLACE_DESTINATION));
			
			os.put_string ("""<?xml version="1.0" encoding="utf-8" standalone="yes"?>""");
			os.put_string ("\n");
				
			os.put_string ("<font>\n");
			
			// this a backup of another font
			if (backup) {
				os.put_string ("\n");
				os.put_string (@"<!-- This is a backup of the following font: -->\n");	
				os.put_string (@"<backup>$((!) font.get_path ())</backup>\n");	
			}
		
			os.put_string ("\n");
			os.put_string (@"<postscript_name>$(font.postscript_name)</postscript_name>\n");
			os.put_string (@"<name>$(font.name)</name>\n");
			os.put_string (@"<subfamily>$(font.subfamily)</subfamily>\n");
			os.put_string (@"<bold>$(font.bold)</bold>\n");
			os.put_string (@"<italic>$(font.italic)</italic>\n");			
			os.put_string (@"<full_name>$(font.full_name)</full_name>\n");
			os.put_string (@"<unique_identifier>$(font.unique_identifier)</unique_identifier>\n");
			os.put_string (@"<version>$(font.version)</version>\n");
			os.put_string (@"<description>$(font.description)</description>\n");
			os.put_string (@"<copyright>$(font.copyright)</copyright>\n");
			
			os.put_string ("\n");
			os.put_string ("<horizontal>\n");
			os.put_string (@"\t<top_limit>$(font.top_limit)</top_limit>\n");
			os.put_string (@"\t<top_position>$(font.top_position)</top_position>\n");
			os.put_string (@"\t<x-height>$(font.xheight_position)</x-height>\n");
			os.put_string (@"\t<base_line>$(font.base_line)</base_line>\n");
			os.put_string (@"\t<bottom_position>$(font.bottom_position)</bottom_position>\n");
			os.put_string (@"\t<bottom_limit>$(font.bottom_limit)</bottom_limit>\n");
			os.put_string ("</horizontal>\n\n");

			foreach (string gv in font.grid_width) {
				os.put_string (@"<grid width=\"$(gv)\"/>\n");
			}
			
			if (GridTool.sizes.length () > 0) {
				os.put_string ("\n");
			}
			
			os.put_string (@"<background scale=\"$(font.background_scale)\" />\n");
			os.put_string ("\n");
			
			if (font.background_images.length () > 0) {
				os.put_string (@"<images>\n");
				
				foreach (string f in font.background_images) {
					os.put_string (@"\t<img src=\"$f\"/>\n");
				}
			
				os.put_string (@"</images>\n");
				os.put_string ("\n");
			}
			
			font.glyph_cache.for_each ((gc) => {
				if (is_null (gc)) {
					warning ("No glyph collection");
				}
				
				try {
					write_glyph_collection (gc, os);
				} catch (GLib.Error e) {
					warning (e.message);
				}
			});
		
			font.glyph_cache.for_each ((gc) => {
				GlyphBackgroundImage bg;
				
				try {
					string data;
					
					foreach (Glyph g in gc.get_version_list ().glyphs) {

						if (g.get_background_image () != null) {
							bg = (!) g.get_background_image ();
							data = bg.get_png_base64 ();
							
							if (!bg.is_valid ()) {
								continue;
							}
							
							os.put_string (@"<background-image sha1=\"");
							os.put_string (bg.get_sha1 ());
							os.put_string ("\" ");
							os.put_string (" data=\"");
							os.put_string (data);
							os.put_string ("\" />\n");	
						}
					}
				} catch (GLib.Error ef) {
					warning (@"Failed to save $path \n");
					warning (@"$(ef.message) \n");
				}
			});
			
			num_kerning_pairs = KerningClasses.get_instance ().classes_first.length ();
			progress = num_kerning_pairs;
			ProgressBar.set_progress (1);
			for (uint i = 0; i < num_kerning_pairs; i++) {
				
				range = KerningClasses.get_instance ().classes_first.nth (i).data.get_all_ranges ();
				
				os.put_string ("<kerning ");
				os.put_string ("left=\"");
				os.put_string (range);
				os.put_string ("\" ");
				
				range = KerningClasses.get_instance ().classes_last.nth (i).data.get_all_ranges ();
				
				os.put_string ("right=\"");
				os.put_string (range);
				os.put_string ("\" ");
				
				os.put_string ("hadjustment=\"");
				os.put_string (float_point (KerningClasses.get_instance ().classes_kerning.nth (i).data.val));
				os.put_string ("\" />\n");
				
				ProgressBar.set_progress (--progress / (double) num_kerning_pairs);
				Tool.yield ();
			}
			
			KerningClasses.get_instance ().get_single_position_pairs ((l, r, k) => {
				try {
					os.put_string ("<kerning ");
					os.put_string ("left=\"");
					os.put_string (l);
					os.put_string ("\" ");
					
					os.put_string ("right=\"");
					os.put_string (r);
					os.put_string ("\" ");
					
					os.put_string ("hadjustment=\"");
					os.put_string (float_point (k));
					os.put_string ("\" />\n");
					
					ProgressBar.set_progress (++progress / (double) num_kerning_pairs);
					Tool.yield ();
				} catch (GLib.Error e) {
					warning (@"$(e.message) \n");
				}
			});
			
			os.put_string ("</font>");
			
		} catch (GLib.Error e) {
			warning (@"Failed to save $path \n");
			warning (@"$(e.message) \n");
			return false;
		}
		
		return true;
	}

	private string float_point (double d) {
		string s = @"$d";
		return s.replace (",", ".");
	}

	/** Get control points in BirdFont format. This function is uses a
	 * cartesian coordinate system with origo in the middle.
	 * 
	 * Instructions:
	 * S - Start point for a quadratic path
	 * B - Start point for a cubic path
	 * L - Line with quadratic control points
	 * M - Line with cubic control points
	 * Q - Quadratic Bézier path
	 * D - Two quadratic off curve points
	 * C - Cubic Bézier path
	 * 
	 * T - Tie handles for previous curve
	 * 
	 * O - Keep open (do not close path)
	 */
	public static string get_point_data (Path pl) {
		StringBuilder data = new StringBuilder ();
		EditPoint? n = null;
		EditPoint m;
		int i = 0;
		
		if (pl.points.length () == 0) {
			return data.str;
		}
		
		if (pl.points.length () == 1) {
			add_start_point (pl.points.first ().data, data);
			data.append (" ");
			add_next_point (pl.points.first ().data, pl.points.first ().data, data);

			if (pl.is_open ()) {
				data.append (" O");
			}
			
			return data.str;
		}
		
		if (pl.points.length () == 2) {
			add_start_point (pl.points.first ().data, data);
			data.append (" ");
			add_next_point (pl.points.first ().data, pl.points.last ().data, data);
			data.append (" ");
			add_next_point (pl.points.last ().data, pl.points.first ().data, data);
			
			if (pl.is_open ()) {
				data.append (" O");
			}
			
			return data.str;
		}
		
		pl.create_list ();
			
		foreach (EditPoint e in pl.points) {
			if (i == 0) {
				add_start_point (e, data);
				i++;
				n = e;
				continue;
			}
			
			m = (!) n;
			data.append (" ");
			add_next_point (m, e, data);

			n = e;			
			i++;
		}

		data.append (" ");
		m = pl.points.first ().data;	
		add_next_point ((!) n, m, data);
		
		if (pl.is_open ()) {
			data.append (" O");
		}
		
		return data.str;
	}
	
	private static void add_start_point (EditPoint e, StringBuilder data) {
		if (e.type == PointType.CUBIC || e.type == PointType.LINE_CUBIC) {
			add_cubic_start (e, data);
		} else {
			add_quadratic_start (e, data);
		}
	}
	
	private static void add_quadratic_start (EditPoint p, StringBuilder data) {
		data.append (@"S $(p.x),$(p.y)");
	}

	private static void add_cubic_start (EditPoint p, StringBuilder data) {
		data.append (@"B $(p.x),$(p.y)");
	}

	private static void add_line_to (EditPoint p, StringBuilder data) {
		data.append (@"L $(p.x),$(p.y)");
	}

	private static void add_cubic_line_to (EditPoint p, StringBuilder data) {
		data.append (@"M $(p.x),$(p.y)");
	}

	private static void add_quadratic (EditPoint start, EditPoint end, StringBuilder data) {
		EditPointHandle h = start.get_right_handle ();
		data.append (@"Q $(h.x ()),$(h.y ()) $(end.x),$(end.y)");
	}

	private static void add_double (EditPoint start, EditPoint end, StringBuilder data) {
		EditPointHandle h1 = start.get_right_handle ();
		EditPointHandle h2 = end.get_left_handle ();
		data.append (@"D $(h1.x ()),$(h1.y ()) $(h2.x ()),$(h2.y ()) $(end.x),$(end.y)");
	}

	private static void add_cubic (EditPoint start, EditPoint end, StringBuilder data) {
		EditPointHandle h1 = start.get_right_handle ();
		EditPointHandle h2 = end.get_left_handle ();
		data.append (@"C $(h1.x ()),$(h1.y ()) $(h2.x ()),$(h2.y ()) $(end.x),$(end.y)");
	}

	private static void add_next_point (EditPoint start, EditPoint end, StringBuilder data) {
		if (start.right_handle.type == PointType.LINE_QUADRATIC && end.left_handle.type == PointType.LINE_QUADRATIC) {
			add_line_to (end, data);
		} else if (start.right_handle.type == PointType.LINE_DOUBLE_CURVE && end.left_handle.type == PointType.LINE_DOUBLE_CURVE) {
			add_line_to (end, data);
		} else if (start.right_handle.type == PointType.LINE_CUBIC && end.left_handle.type == PointType.LINE_CUBIC) {
			add_cubic_line_to (end, data);
		} else if (end.left_handle.type == PointType.DOUBLE_CURVE || start.right_handle.type == PointType.DOUBLE_CURVE) {
			add_double (start, end, data);
		} else if (end.left_handle.type == PointType.QUADRATIC || start.right_handle.type == PointType.QUADRATIC) {
			add_quadratic (start, end, data);
		} else if (end.left_handle.type == PointType.CUBIC || start.right_handle.type == PointType.CUBIC) {
			add_cubic (start, end, data);
		} else if (start.right_handle.type == PointType.LINE_CUBIC && end.left_handle.type == PointType.LINE_DOUBLE_CURVE) {
			add_line_to (end, data);
		} else if (start.right_handle.type == PointType.LINE_DOUBLE_CURVE && end.left_handle.type == PointType.LINE_CUBIC) {
			add_line_to (end, data);
		} else {
			warning (@"Unknown point type. \nStart handle: $(start.right_handle.type) \nStop handle: $(end.left_handle.type)");
			add_cubic (start, end, data);
		}

		if (end.tie_handles) {
			data.append (" ");
			data.append (@"T");
		}	
	}

	private void write_glyph_collection (GlyphCollection gc, DataOutputStream os)  throws GLib.Error {
		os.put_string (@"<collection unicode=\"$(Font.to_hex (gc.get_current ().unichar_code))\">\n");
		foreach (Glyph g in gc.get_version_list ().glyphs) {
			write_glyph (g, gc, os);
		}
		os.put_string ("</collection>\n");
	} 

	private void write_glyph (Glyph g, GlyphCollection gc, DataOutputStream os) throws GLib.Error {
		bool selected = (gc.get_current () == g);
		string data;
		
		os.put_string (@"\t<glyph left=\"$(g.left_limit)\" right=\"$(g.right_limit)\" selected=\"$selected\">\n");
		
		foreach (Path p in g.path_list) {
			data = get_point_data (p);
			if (data != "") {
				os.put_string (@"\t\t<path stroke=\"$(p.stroke)\" data=\"$(data)\" />\n");
			}
		}
		
		write_glyph_background (g, os);
		
		os.put_string ("\t</glyph>\n");
	}

	private void write_glyph_background (Glyph g, DataOutputStream os) throws GLib.Error {
		GlyphBackgroundImage? bg;
		GlyphBackgroundImage background_image;
		double pos_x, pos_y, scale_x, scale_y, rotation;
		
		bg = g.get_background_image ();
		
		if (bg != null) {
			background_image = (!) bg;

			pos_x = background_image.img_x;
			pos_y = background_image.img_y;
			
			scale_x = background_image.img_scale_x;
			scale_y = background_image.img_scale_y;
			
			rotation = background_image.img_rotation;
			
			if (background_image.is_valid ()) {
				os.put_string (@"\t\t<background sha1=\"$(background_image.get_sha1 ())\" x=\"$pos_x\" y=\"$pos_y\" scale_x=\"$scale_x\" scale_y=\"$scale_y\" rotation=\"$rotation\"/>\n");
			}
		}			
	}

	private bool parse_file (Xml.Node* root) {
		Xml.Node* node = root;
		
		for (Xml.Node* iter = node->children; iter != null; iter = iter->next) {
			
			printd (iter->name); // FIXME: delete
			printd ("\n");
	
			// this is a backup file set path to the original 
			if (iter->name == "backup") {
				font.font_file = iter->children->content;
			}
				
			// old glyph format
			if (iter->name == "glyph") {
				parse_ffi_glyph (iter);
			}
			
			// new glyph format
			if (iter->name == "collection") {
				parse_glyph_collection (iter);
			}

			// horizontal lines in the old format
			if (iter->name == "lines") {
				parse_font_boundaries (iter);
			}
			
			if (iter->name == "horizontal") {
				parse_horizontal_lines (iter);
			}			

			if (iter->name == "grid") {
				parse_grid (iter);
			}

			if (iter->name == "background") {
				parse_background (iter);
			}
			
			if (iter->name == "images") {
				parse_background_selection (iter);
			}

			if (iter->name == "postscript_name" && iter->children != null) {
				font.postscript_name = iter->children->content;
			}
			
			if (iter->name == "name" && iter->children != null) {
				font.name = iter->children->content;
			}

			if (iter->name == "subfamily" && iter->children != null) {
				font.subfamily = iter->children->content;
			}

			if (iter->name == "bold" && iter->children != null) {
				font.bold = bool.parse (iter->children->content);
			}
			
			if (iter->name == "italic" && iter->children != null) {
				font.italic = bool.parse (iter->children->content);
			}
			
			if (iter->name == "full_name" && iter->children != null) {
				font.full_name = iter->children->content;
			}
			
			if (iter->name == "unique_identifier" && iter->children != null) {
				font.unique_identifier = iter->children->content;
			}

			if (iter->name == "version" && iter->children != null) {
				font.version = iter->children->content;
			}

			if (iter->name == "description" && iter->children != null) {
				font.description = iter->children->content;
			}
			
			if (iter->name == "copyright" && iter->children != null) {
				font.copyright = iter->children->content;
			}
						
			if (iter->name == "hkern") {
				parse_old_kerning (iter);
			}

			if (iter->name == "kerning") {
				parse_kerning (iter);
			}
		}

		return true;
	}
	
	private void create_background_files (Xml.Node* root) requires (root != null) {
		while (font.background_images.length () > 0) {
			font.background_images.remove_link (font.background_images.first ());
		}
	
		for (Xml.Node* iter = root->children; iter != null; iter = iter->next) {
			
			if (iter->name == "name" && iter->children != null) {
				font.set_name (iter->children->content);
			}
			
			if (iter->name == "background-image") {
				parse_background_image (iter);
			}
		}
	}

	public static string unserialize (string s) {
		StringBuilder b;
		string r;
		r = s.replace ("quote", "\"");
		r = r.replace ("ampersand", "&");
		
		if (s.has_prefix ("U+")) {
			b = new StringBuilder ();
			b.append_unichar (Font.to_unichar (s));
			r = @"$(b.str)";
		}
		
		return r;
	}
	
	public static string serialize_unichar (unichar c) {
		return GlyphRange.get_serialized_char (c);
	}
	
	private void parse_kerning (Xml.Node* node) {
		string attr_name;
		string attr_content;
		GlyphRange range_left, range_right;
		double hadjustment = 0;
		KerningRange kerning_range;
		
		try {
			range_left = new GlyphRange ();
			range_right = new GlyphRange ();
				
			for (Xml.Attr* prop = node->properties; prop != null; prop = prop->next) {
				attr_name = prop->name;
				attr_content = prop->children->content;
				
				if (attr_name == "left") {
					range_left.parse_ranges (unserialize (attr_content));
				}

				if (attr_name == "right") {
					range_right.parse_ranges (unserialize (attr_content));
				}

				if (attr_name == "hadjustment") {
					hadjustment = double.parse (attr_content);
				}
				
				ProgressBar.set_progress (0);
			}
			
			if (range_left.get_length () > 1) {
				kerning_range = new KerningRange ();
				kerning_range.set_ranges (range_left.get_all_ranges ());
				KerningTools.add_unique_class (kerning_range);
			}

			if (range_right.get_length () > 1) {
				kerning_range = new KerningRange ();
				kerning_range.set_ranges (range_right.get_all_ranges ());
				KerningTools.add_unique_class (kerning_range);
			}

			KerningClasses.get_instance ().set_kerning (range_left, range_right, hadjustment);
			
		} catch (MarkupError e) {
			warning (e.message);
		}
	}
		
	private void parse_old_kerning (Xml.Node* node) {
		string attr_name;
		string attr_content;
		string left = "";
		string right = "";
		string kern = "";
		GlyphRange grr, grl;

		StringBuilder b;
		
		for (Xml.Attr* prop = node->properties; prop != null; prop = prop->next) {
			attr_name = prop->name;
			attr_content = prop->children->content;
			
			if (attr_name == "left") {
				b = new StringBuilder ();
				b.append_unichar (Font.to_unichar (attr_content));
				left = @"$(b.str)";
			}

			if (attr_name == "right") {
				b = new StringBuilder ();
				b.append_unichar (Font.to_unichar (attr_content));
				right = @"$(b.str)";
			}
			
			if (attr_name == "kerning") {
				kern = attr_content;
			}
		}

		try {
			grl = new GlyphRange ();
			grl.parse_ranges (left);

			grr = new GlyphRange ();
			grr.parse_ranges (right);
			
			KerningClasses.get_instance ().set_kerning (grl, grr, double.parse (kern));	
		} catch (MarkupError e) {
			warning (e.message);
		}
	}
	
	private void parse_background_image (Xml.Node* node) 
		requires (node != null)
	{
		string attr_name;
		string attr_content;
		
		string file = "";
		string data = "";
		
		File img_dir;
		File img_file;
		FileOutputStream file_stream;
		DataOutputStream png_stream;
		
		for (Xml.Attr* prop = node->properties; prop != null; prop = prop->next) {
			return_if_fail (!is_null (prop->name));
			return_if_fail (!is_null (prop->children));
			return_if_fail (!is_null (prop->children->content));
			
			attr_name = prop->name;
			attr_content = prop->children->content;
			
			if (attr_name == "sha1") {
				file = attr_content;
			}
			
			if (attr_name == "data") {
				data = attr_content;
			}
		}

		if (!font.get_backgrounds_folder ().query_exists ()) {
			DirUtils.create ((!) font.get_backgrounds_folder ().get_path (), 0xFFFFFF);
		}
		
		img_dir = font.get_backgrounds_folder ().get_child ("parts");

		if (!img_dir.query_exists ()) {
			DirUtils.create ((!) img_dir.get_path (), 0xFFFFFF);
		}
	
		img_file = img_dir.get_child (@"$(file).png");
		
		if (img_file.query_exists ()) {
			return;
		}
		
		try {
			file_stream = img_file.create (FileCreateFlags.REPLACE_DESTINATION);
			png_stream = new DataOutputStream (file_stream);

			png_stream.write (Base64.decode (data));
			png_stream.close ();	
		} catch (GLib.Error e) {
			warning (e.message);
		}
	}
	
	private void parse_background (Xml.Node* node) 
		requires (node != null)
	{
		string attr_name;
		string attr_content;
				
		for (Xml.Attr* prop = node->properties; prop != null; prop = prop->next) {
			
			return_if_fail (!is_null (prop->name));
			return_if_fail (!is_null (prop->children));
			return_if_fail (!is_null (prop->children->content));
			
			attr_name = prop->name;
			attr_content = prop->children->content;
			
			if (attr_name == "scale") {
				font.background_scale = attr_content;
			}
		}
	}
	
	private void parse_background_selection (Xml.Node* node) {
		string attr_name = "";
		string attr_content;
		
		return_if_fail (node != null);
				
		for (Xml.Node* iter = node->children; iter != null; iter = iter->next) {
			if (iter->name == "img") {
				for (Xml.Attr* prop = iter->properties; prop != null; prop = prop->next) {
					attr_name = prop->name;
					attr_content = prop->children->content;
					
					if (attr_name == "src") {
						font.background_images.append (attr_content);
					}
				}
			}
		}
	}
	
	private void parse_grid (Xml.Node* node) {
		for (Xml.Attr* prop = node->properties; prop != null; prop = prop->next) {
			string attr_name = prop->name;
			string attr_content = prop->children->content;
			
			if (attr_name == "width") {
				font.grid_width.append (attr_content);
			}
		}		
	}
	
	private void parse_horizontal_lines (Xml.Node* node) {
		for (Xml.Node* iter = node->children; iter != null; iter = iter->next) {
			if (iter->name == "top_limit" && "" != iter->children->content) {
				font.top_limit = parse_double_from_node (iter);
			}
			
			if (iter->name == "top_position" && "" != iter->children->content) {
				font.top_position = parse_double_from_node (iter);
			}
			
			if (iter->name == "x-height" && "" != iter->children->content) {
				font.xheight_position = parse_double_from_node (iter);
			}
			
			if (iter->name == "base_line" && "" != iter->children->content) {
				font.base_line = parse_double_from_node (iter);
			}
			
			if (iter->name == "bottom_position" && "" != iter->children->content) {
				font.bottom_position = parse_double_from_node (iter);
			}
			
			if (iter->name == "bottom_limit" && "" != iter->children->content) {
				font.bottom_limit = parse_double_from_node (iter);
			}
		}	
	}
	
	/** @deprecated horizontal in older .bf files */
	private void parse_font_boundaries (Xml.Node* node) {
		for (Xml.Node* iter = node->children; iter != null; iter = iter->next) {
			if (iter->name == "top_limit" && "" != iter->children->content) {
				font.top_limit = -parse_double_from_node (iter);
			}
			
			if (iter->name == "top_position" && "" != iter->children->content) {
				font.top_position = -parse_double_from_node (iter);
			}
			
			if (iter->name == "x-height" && "" != iter->children->content) {
				font.xheight_position = -parse_double_from_node (iter);
			}
			
			if (iter->name == "base_line" && "" != iter->children->content) {
				font.base_line = -parse_double_from_node (iter);
			}
			
			if (iter->name == "bottom_position" && "" != iter->children->content) {
				font.bottom_position = -parse_double_from_node (iter);
			}
			
			if (iter->name == "bottom_limit" && "" != iter->children->content) {
				font.bottom_limit = -parse_double_from_node (iter);
			}
		}			
	}
	
	private double parse_double_from_node (Xml.Node* iter) {
		double d;
		bool r = double.try_parse (iter->children->content, out d);
		
		if (unlikely (!r)) {
			string? s = iter->content;
			if (s == null) {
				warning (@"Content is null for node $(iter->name)\n");
			} else {
				warning (@"Failed to parse double for \"$(iter->content)\"\n");
			}
		}
		
		return (r) ? d : 0.0;
	}

	/** Parse the new glyph format */
	private void parse_glyph_collection (Xml.Node* node) {
		unichar unicode = 0;
		GlyphCollection gc = new GlyphCollection ();
		string attr_name;
		string attr_content;
		StringBuilder b;
		string name = "";
				
		for (Xml.Attr* prop = node->properties; prop != null; prop = prop->next) {
			attr_name = prop->name;
			attr_content = prop->children->content;
			
			if (attr_name == "unicode") {
				unicode = Font.to_unichar (attr_content);
				b = new StringBuilder ();
				b.append_unichar (unicode);
				name = b.str;
				
				if (name == "") {
					name = ".null";
				}
			}
		}
		
		for (Xml.Node* iter = node->children; iter != null; iter = iter->next) {
			if (iter->name == "glyph") {
				parse_glyph (iter, gc, name, unicode);
			}
		}
		
		font.add_glyph_collection (gc);
	}

	private void parse_glyph (Xml.Node* node, GlyphCollection gc, string name, unichar unicode) {	
		string attr_name;
		string attr_content;
		Glyph glyph = new Glyph (name, unicode);
		Path path;
		bool selected = false;
		
		for (Xml.Attr* prop = node->properties; prop != null; prop = prop->next) {
			attr_name = prop->name;
			attr_content = prop->children->content;
			
			if (attr_name == "left") {
				glyph.left_limit = double.parse (attr_content);
			}
			
			if (attr_name == "right") {
				glyph.right_limit = double.parse (attr_content);
			}
			
			if (attr_name == "selected") {
				selected = bool.parse (attr_content);
			}
		}
		
		for (Xml.Node* iter = node->children; iter != null; iter = iter->next) {
			if (iter->name == "path") {
				path = parse_path (iter);
				glyph.add_path (path);
			}
			
			if (iter->name == "background") {
				parse_background_scale (glyph, iter);
			}
		}
		
		gc.insert_glyph (glyph, selected);
	}

	private Path parse_path (Xml.Node* node) {	
		string attr_name;
		string attr_content;
		Path path = new Path ();
		
		for (Xml.Attr* prop = node->properties; prop != null; prop = prop->next) {
			attr_name = prop->name;
			attr_content = prop->children->content;
			
			if (attr_name == "data") {
				path = parse_path_data (attr_content);
			}
		}

		for (Xml.Attr* prop = node->properties; prop != null; prop = prop->next) {
			attr_name = prop->name;
			attr_content = prop->children->content;

			if (attr_name == "stroke") {
				path.set_stroke (double.parse (attr_content));
			}
		}		
		if (path.points.length () == 0) {
			warning ("Empty path");
		}
		
		return path;	
	}
	
	private static void line (Path path, string px, string py) {
		EditPoint ep;
		
		path.add (parse_double (px), parse_double (py));
		ep = path.points.last ().data;
		ep.get_right_handle ().type = PointType.LINE_DOUBLE_CURVE;
		ep.get_left_handle ().type = PointType.LINE_DOUBLE_CURVE;
		ep.type = PointType.LINE_DOUBLE_CURVE;
		ep.recalculate_linear_handles ();			
	}

	private static void cubic_line (Path path, string px, string py) {
		EditPoint ep;

		path.add (parse_double (px), parse_double (py));
		ep = path.points.last ().data;
		ep.get_right_handle ().type = PointType.LINE_CUBIC;
		ep.type = PointType.LINE_CUBIC;
		ep.recalculate_linear_handles ();
	}

	private static void quadratic (Path path, string px0, string py0, string px1, string py1) {
		EditPoint ep1, ep2;
		
		double x0 = parse_double (px0);
		double y0 = parse_double (py0);
		double x1 = parse_double (px1);
		double y1 = parse_double (py1);

		if (is_null (path.points.last ().data)) {
			warning ("No point.");
			return;
		}
		
		ep1 = path.points.last ().data;
		ep1.recalculate_linear_handles ();
		ep1.get_right_handle ().type = PointType.QUADRATIC;
		ep1.get_right_handle ().move_to_coordinate (x0, y0);	
		ep1.type = PointType.QUADRATIC;

		path.add (x1, y1);

		ep2 = path.points.last ().data;
		ep2.recalculate_linear_handles ();
		ep2.get_left_handle ().type = PointType.QUADRATIC;
		ep2.get_left_handle ().move_to_coordinate (x0, y0);
		ep2.type = PointType.QUADRATIC;
	}

	private static void cubic (Path path, string px0, string py0, string px1, string py1, string px2, string py2) {
		EditPoint ep1, ep2;
		
		double x0 = parse_double (px0);
		double y0 = parse_double (py0);
		double x1 = parse_double (px1);
		double y1 = parse_double (py1);
		double x2 = parse_double (px2);
		double y2 = parse_double (py2);
		
		double lx, ly;
				
		if (is_null (path.points.last ().data)) {
			warning ("No point");
			return;
		}

		// start with line handles
		ep1 = path.points.last ().data;
		ep1.get_right_handle ().type = PointType.LINE_CUBIC;
		
		lx = ep1.x + ((x2 - ep1.x) / 3);
		ly = ep1.y + ((y2 - ep1.y) / 3);
						
		ep1.get_right_handle ().move_to_coordinate (lx, ly);
		ep1.recalculate_linear_handles ();
		
		// set curve handles
		ep1 = path.points.last ().data;
		ep1.recalculate_linear_handles ();
		ep1.get_right_handle ().type = PointType.CUBIC;
		ep1.get_right_handle ().move_to_coordinate (x0, y0);				
		ep1.type = PointType.CUBIC;
	
		path.add (x2, y2);
						
		ep2 = path.points.last ().data;
		ep2.recalculate_linear_handles ();
		ep2.get_left_handle ().type = PointType.CUBIC;
		ep2.get_left_handle ().move_to_coordinate (x1, y1);
		ep2.type = PointType.CUBIC;
		
		ep1.recalculate_linear_handles ();
	}
	
	/** Two quadratic off curve points. */
	private static void double_curve (Path path, string px0, string py0, string px1, string py1, string px2, string py2) {
		EditPoint ep1, ep2;
		
		double x0 = parse_double (px0);
		double y0 = parse_double (py0);
		double x1 = parse_double (px1);
		double y1 = parse_double (py1);
		double x2 = parse_double (px2);
		double y2 = parse_double (py2);
		
		double lx, ly;
				
		if (is_null (path.points.last ().data)) {
			warning ("No point");
			return;
		}

		// start with line handles
		ep1 = path.points.last ().data;
		ep1.get_right_handle ().type = PointType.LINE_DOUBLE_CURVE;
		
		lx = ep1.x + ((x2 - ep1.x) / 4);
		ly = ep1.y + ((y2 - ep1.y) / 4);
						
		ep1.get_right_handle ().move_to_coordinate (lx, ly);
		ep1.recalculate_linear_handles ();
		
		// set curve handles
		ep1 = path.points.last ().data;
		ep1.recalculate_linear_handles ();
		ep1.get_right_handle ().type = PointType.DOUBLE_CURVE;
		ep1.get_right_handle ().move_to_coordinate (x0, y0);				
		ep1.type = PointType.DOUBLE_CURVE;
		
		path.add (x2, y2);
						
		ep2 = path.points.last ().data;
		ep2.recalculate_linear_handles ();
		ep2.get_left_handle ().type = PointType.DOUBLE_CURVE;
		ep2.get_left_handle ().move_to_coordinate (x1, y1);
		ep2.type = PointType.DOUBLE_CURVE;
		
		ep1.recalculate_linear_handles ();
	}
	
	public static void close (Path path) {
		EditPoint ep1, ep2;
		
		if (path.points.length () < 2) {
			warning ("Less  than two points in path.");
			return;
		}
		
		// last point is first
		ep1 = path.points.last ().data;
		ep2 = path.points.first ().data;
		
		path.points.remove_link (path.points.last ());
		
		ep2.tie_handles = ep1.tie_handles;
		ep2.left_handle.angle = ep1.left_handle.angle;
		ep2.left_handle.length = ep1.left_handle.length;
		ep2.left_handle.type = ep1.left_handle.type;
		
		path.close ();
	}
	
	public static Path parse_path_data (string data) {
		string[] d = data.split (" ");
		string[] p, p1, p2;
		int i = 0;
		Path path = new Path ();
		string instruction = "";
		bool open = false;

		if (data == "") {
			return path;
		}
		
		return_val_if_fail (d.length > 1, path);
		
		if (!(d[0] == "S" || d[0] == "B")) {
			warning ("No start point.");
			return path;
		}
		
		instruction = d[i++];
		
		if (instruction == "S") {
			p = d[i++].split (",");
			return_val_if_fail (p.length == 2, path);
			line (path, p[0], p[1]);
		}

		if (instruction == "B") {
			p = d[i++].split (",");
			return_val_if_fail (p.length == 2, path);
			cubic_line (path, p[0], p[1]);
		}
		
		while (i < d.length) {
			instruction = d[i++];
			
			if (instruction == "") {
				warning (@"No instruction at index $i.");
				return path;
			}
			
			if (instruction == "L") {
				return_val_if_fail (i < d.length, path);
				p = d[i++].split (",");
				return_val_if_fail (p.length == 2, path);
				line (path, p[0], p[1]);
			}else if (instruction == "M") {
				return_val_if_fail (i < d.length, path);
				p = d[i++].split (",");
				return_val_if_fail (p.length == 2, path);
				cubic_line (path, p[0], p[1]);
			} else if (instruction == "Q") {
				return_val_if_fail (i + 1 < d.length, path);
				
				p = d[i++].split (",");
				p1 = d[i++].split (",");
				
				return_val_if_fail (p.length == 2, path);
				return_val_if_fail (p1.length == 2, path);
				
				quadratic (path, p[0], p[1], p1[0], p1[1]);
			} else if (instruction == "D") {
				return_val_if_fail (i + 2 < d.length, path);
				
				p = d[i++].split (",");
				p1 = d[i++].split (",");
				p2 = d[i++].split (",");

				return_val_if_fail (p.length == 2, path);
				return_val_if_fail (p1.length == 2, path);
				return_val_if_fail (p2.length == 2, path);
				
				double_curve (path, p[0], p[1], p1[0], p1[1], p2[0], p2[1]);
			} else if (instruction == "C") {
				return_val_if_fail (i + 2 < d.length, path);
				
				p = d[i++].split (",");
				p1 = d[i++].split (",");
				p2 = d[i++].split (",");

				return_val_if_fail (p.length == 2, path);
				return_val_if_fail (p1.length == 2, path);
				return_val_if_fail (p2.length == 2, path);
				
				cubic (path, p[0], p[1], p1[0], p1[1], p2[0], p2[1]);
			} else if (instruction == "T") {
				path.points.last ().data.tie_handles = true;
			} else if (instruction == "O") {
				open = true;
			} else {
				warning (@"invalid instruction $instruction");
				return path;
			}
		}

		if (!open) {
			close (path);
		} else {
			path.points.remove_link (path.points.last ());
			
			if (!path.is_open ()) {
				warning ("Closed path.");
			}
		}
		
		path.update_region_boundaries ();
		
		return path;	
	}
	
	private static double parse_double (string p) {
		double d;
		if (double.try_parse (p, out d)) {
			return d;
		}
		
		warning (@"failed to parse $p");
		return 0;
	}
	
	/** Parse one glyph in the old ffi format. */
	private void parse_ffi_glyph (Xml.Node* node) {
		string name = "";
		int left = 0;
		int right = 0;
		unichar uni = 0;
		int version = 0;
		bool selected = false;
		Glyph g;
		GlyphCollection? gc;
		
		for (Xml.Attr* prop = node->properties; prop != null; prop = prop->next) {
			string attr_name = prop->name;
			string attr_content = prop->children->content;
			StringBuilder b;
			
			if (attr_name == "unicode") {
				uni = Font.to_unichar (attr_content);
				b = new StringBuilder ();
				b.append_unichar (uni);
				name = b.str;
			}

			if (attr_name == "left") {
				left = int.parse (attr_content);
			}
			
			if (attr_name == "right") {
				right = int.parse (attr_content);
			}
			
			if (attr_name == "version") {
				version = int.parse (attr_content);
			}
			
			if (attr_name == "selected") {
				selected = bool.parse (attr_content);
			}
		}

		g = new Glyph (name, uni);
		
		g.left_limit = left;
		g.right_limit = right;

		parse_content (g, node);
		
		gc = font.get_glyph_collection (g.get_name ());
		
		if (g.get_name () == "") {
			warning ("No name set for glyph.");
		}
				
		if (gc == null) {
			gc = new GlyphCollection (g);
			font.add_glyph_collection ((!) gc);
		} else {
			((!)gc).insert_glyph (g, selected);
		}
	}
	
	/** Parse visual objects and paths 
	 * @deprecated ffi format use bf
	 */
	private void parse_content (Glyph g, Xml.Node* node) {
		Xml.Node* i;
		return_if_fail (node != null);
		
		for (Xml.Node* iter = node->children; iter != null; iter = iter->next) {
			if (iter->name == "object") {
				Path p = new Path ();
				
				for (i = iter->children; i != null; i = i->next) {
					if (i->name == "point") {
						parse_point (p, i);
					}					
				}

				p.close ();
				g.add_path (p);
			}
			
			if (iter->name == "background") {
				parse_background_scale (g, iter);
			}
		}
	}
	
	private void parse_background_scale (Glyph g, Xml.Node* node) {
		GlyphBackgroundImage img;
		GlyphBackgroundImage? new_img = null;
		
		string attr_name = "";
		string attr_content;
		
		File img_file = font.get_backgrounds_folder ().get_child ("parts");
		
		for (Xml.Attr* prop = node->properties; prop != null; prop = prop->next) {
			attr_name = prop->name;
			attr_content = prop->children->content;
			
			if (attr_name == "sha1") {
				img_file = img_file.get_child (attr_content + ".png");

				if (!img_file.query_exists ()) {
					warning (@"Background file has not been created yet. $((!) img_file.get_path ())");
				}
				
				new_img = new GlyphBackgroundImage ((!) img_file.get_path ());
				g.set_background_image ((!) new_img);
			}
		}
		
		if (unlikely (new_img == null)) {
			warning (@"No source for image found for $attr_name in $(g.name)");
			return;
		}
	
		img = (!) new_img;
	
		for (Xml.Attr* prop = node->properties; prop != null; prop = prop->next) {
			attr_name = prop->name;
			attr_content = prop->children->content;
							
			if (attr_name == "x") {
				img.img_x = double.parse (attr_content);
			}
			
			if (attr_name == "y") {
				img.img_y = double.parse (attr_content);
			}	

			if (attr_name == "scale_x") {
				img.img_scale_x = double.parse (attr_content);
			}

			if (attr_name == "scale_y") {
				img.img_scale_y = double.parse (attr_content);
			}
						
			if (attr_name == "rotation") {
				img.img_rotation = double.parse (attr_content);
			}
		}
		
		img.set_position(img.img_x, img.img_y);	
	}
	
	private void parse_point (Path p, Xml.Node* iter) {
		double x = 0;
		double y = 0;
		
		double angle_right = 0;
		double angle_left = 0;
		
		double length_right = 0;
		double length_left = 0;
		
		PointType type_right = PointType.LINE_CUBIC;
		PointType type_left = PointType.LINE_CUBIC;
		
		bool tie_handles = false;
		
		EditPoint ep;
		
		for (Xml.Attr* prop = iter->properties; prop != null; prop = prop->next) {
			string attr_name = prop->name;
			string attr_content = prop->children->content;
						
			if (attr_name == "x") x = double.parse (attr_content);
			if (attr_name == "y") y = double.parse (attr_content);

			if (attr_name == "right_type" && attr_content == "linear") {
				type_right = PointType.LINE_CUBIC;
			}	

			if (attr_name == "left_type" && attr_content == "linear") {
				type_left = PointType.LINE_CUBIC;
			}	

			if (attr_name == "right_type" && attr_content == "quadratic") {
				type_right = PointType.QUADRATIC;
			}	

			if (attr_name == "left_type" && attr_content == "quadratic") {
				type_left = PointType.QUADRATIC;
			}

			if (attr_name == "right_type" && attr_content == "cubic") {
				type_right = PointType.CUBIC;
			}	

			if (attr_name == "left_type" && attr_content == "cubic") {
				type_left = PointType.CUBIC;
			}
			
			if (attr_name == "right_angle") angle_right = double.parse (attr_content);
			if (attr_name == "right_length") length_right = double.parse (attr_content);
			if (attr_name == "left_angle") angle_left = double.parse (attr_content);
			if (attr_name == "left_length") length_left = double.parse (attr_content);
			
			if (attr_name == "tie_handles") tie_handles = bool.parse (attr_content);
		}
	
		// backward compabtility
		if (type_right == PointType.LINE_CUBIC && length_right != 0) {
			type_right = PointType.CUBIC;
		}

		if (type_left == PointType.LINE_CUBIC && length_left != 0) {
			type_left = PointType.CUBIC;
		}
		
		ep = new EditPoint (x, y);
					
		ep.right_handle.angle = angle_right;
		ep.right_handle.length = length_right;
		ep.right_handle.type = type_right;
		
		ep.left_handle.angle = angle_left;
		ep.left_handle.length = length_left;
		ep.left_handle.type = type_left;
		
		ep.tie_handles = tie_handles;
		
		ep.type = type_right;
		
		p.add_point (ep);
	}
}

}
