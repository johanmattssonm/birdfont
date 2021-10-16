/*
	Copyright (C) 2013 2014 2015 2016 2017 Johan Mattsson

	This library is free software; you can redistribute it and/or modify 
	it under the terms of the GNU Lesser General Public License as 
	published by the Free Software Foundation; either version 3 of the 
	License, or (at your option) any later version.

	This library is distributed in the hope that it will be useful, but 
	WITHOUT ANY WARRANTY; without even the implied warranty of 
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU 
	Lesser General Public License for more details.
*/
using B;

namespace BirdFont {

/** 
 * BirdFont file format. This class can parse both the old ffi format 
 * and the new bf format.
 */
class BirdFontFile : GLib.Object {
	
	Font font;
	
	public const int FORMAT_MAJOR = 2;
	public const int FORMAT_MINOR = 2;
	
	public const int MIN_FORMAT_MAJOR = 0;
	public const int MIN_FORMAT_MINOR = 0;

	public bool has_svg_glyphs = false;	
		
	public BirdFontFile (Font f) {
		font = f;
	}

	/** Load a new .bf file.
	 * @param path path to a valid .bf file
	 */
	public bool load (string path) {
		string xml_data;
		XmlParser parser;
		bool ok = false;
	
		try {
			FileUtils.get_contents(path, out xml_data);
			
			font.background_images.clear ();
			font.font_file = path;
			
			parser = new XmlParser (xml_data);
			ok = load_xml (parser);
		} catch (GLib.FileError e) {
			warning (e.message);
		}
			
		return ok;
	}
	
	public bool load_part (string bfp_file) {
		string xml_data;
		XmlParser parser;
		bool ok = false;
	
		try {
			FileUtils.get_contents(bfp_file, out xml_data);
			parser = new XmlParser (xml_data);
			ok = load_xml (parser);
		} catch (GLib.FileError e) {
			warning (e.message);
		}
		
		return ok;
	}

	/** Load a new .bf file.
	 * @param xml_data data for a valid .bf file
	 */
	public bool load_data (string xml_data) {
		bool ok;
		XmlParser parser;
		
		font.font_file = "typeface.birdfont";
		parser = new XmlParser (xml_data);
		ok = load_xml (parser);
		
		return ok;
	}

	private bool load_xml (XmlParser parser) {
		bool ok = true;
		
		create_background_files (parser.get_root_tag ());
		ok = parse_file (parser.get_root_tag ());
		
		return ok;
	}

	public bool write_font_file (string path, bool backup = false) {
		try {
			DataOutputStream os;
			File file;
			
			file = File.new_for_path (path);
			
			if (file.query_file_type (0) == FileType.DIRECTORY) {
				warning (@"Can't save font. $path is a directory.");
				return false;
			}
			
			if (file.query_exists ()) {
				file.delete ();
			}

			os = new DataOutputStream (file.create (FileCreateFlags.REPLACE_DESTINATION));
			write_root_tag (os);
			
			// this a backup of another font
			if (backup) {
				os.put_string ("\n");
				os.put_string (@"<!-- This is a backup of the following font: -->\n");	
				os.put_string (@"<backup>$((!) font.get_path ())</backup>\n");	
			}
		
			os.put_string ("\n");
			write_description (os);
			
			os.put_string ("\n");
			write_lines (os);

			os.put_string ("\n");
			write_settings (os);
			
			os.put_string ("\n");
			
			font.glyph_cache.for_each ((gc) => {
				try {
					write_glyph_collection (gc, os);
				} catch (GLib.Error e) {
					warning (e.message);
				}
			});
			
			os.put_string ("\n");
			
			write_images (os);
			
			os.put_string ("\n");
			write_ligatures (os);
			
			font.glyph_cache.for_each ((gc) => {
				BackgroundImage bg;
				
				try {
					string data;
					foreach (Glyph g in gc.get_all_glyph_masters ()) {
						if (g.get_background_image () != null) {
							bg = (!) g.get_background_image ();
							data = bg.get_png_base64 ();
							
							if (!bg.is_valid ()) {
								continue;
							}	
							
							write_image (os, bg.get_sha1 (), data);
						}
					}
					
					foreach (BackgroundImage b in font.background_images) {
						write_image (os, b.get_sha1 (), b.get_png_base64 ());
					}
				} catch (GLib.Error ef) {
					warning (@"Failed to save $path \n");
					warning (@"$(ef.message) \n");
				}
			});
			
			os.put_string ("\n");
			write_spacing_classes (os);
			write_alternates (os);
			write_kerning (os);
			write_closing_root_tag (os);
			
			os.close ();
		} catch (GLib.Error e) {
			warning (@"Failed to save $path \n");
			warning (@"$(e.message) \n");
			return false;
		}
	
		return true;
	}

	public void write_alternates (DataOutputStream os) throws GLib.Error {
		foreach (Alternate alternate in font.alternates.alternates) {
			string glyph_name = alternate.glyph_name;
			string tag = alternate.tag;
			
			foreach (string alt in alternate.alternates) {
				os.put_string (@"<alternate ");
				os.put_string (@"glyph=\"$(encode (glyph_name))\" ");
				os.put_string (@"replacement=\"$(encode (alt))\" ");
				os.put_string (@"tag=\"$(tag)\" />\n");
			}
		}
	}
	
	public void write_images (DataOutputStream os) throws GLib.Error {
		string glyph_name;
		
		if (font.background_images.size > 0) {
			os.put_string (@"<images>\n");
			
			foreach (BackgroundImage b in font.background_images) {
				
				if (b.name == "") {
					warning ("No name.");
				}
				
				os.put_string ("\t<image ");
				os.put_string (@"name=\"$(b.name)\" ");
				os.put_string (@"sha1=\"$(b.get_sha1 ())\" ");
				os.put_string (@"x=\"$(b.img_x)\" ");
				os.put_string (@"y=\"$(b.img_y)\" ");
				os.put_string (@"scale_x=\"$(b.img_scale_x)\" ");
				os.put_string (@"scale_y=\"$(b.img_scale_y)\" ");
				os.put_string (@"rotation=\"$(b.img_rotation)\" ");
				os.put_string (">\n");
				
				foreach (BackgroundSelection selection in b.selections) {
					os.put_string ("\t\t<selection ");
					os.put_string (@"x=\"$(selection.x_img)\" ");
					os.put_string (@"y=\"$(selection.y_img)\" ");
					os.put_string (@"width=\"$(selection.width)\" ");
					os.put_string (@"height=\"$(selection.height)\" ");
					
					if (selection.assigned_glyph != null) {
						glyph_name = (!) selection.assigned_glyph;
						os.put_string (@"glyph=\"$(glyph_name)\" ");
					}
					
					os.put_string ("/>\n");
				}
				
				os.put_string (@"\t</image>\n");
			}
		
			os.put_string (@"</images>\n");
			os.put_string ("\n");
		}	
	}
	
	public void write_image (DataOutputStream os, string sha1, string data) throws GLib.Error {
		os.put_string (@"<background-image sha1=\"");
		os.put_string (sha1);
		os.put_string ("\" ");
		os.put_string (" data=\"");
		os.put_string (data);
		os.put_string ("\" />\n");
	}
	
	public void write_root_tag (DataOutputStream os) throws GLib.Error {
		string program_version = get_version ();
		string operating_system = get_os ();

		os.put_string ("""<?xml version="1.0" encoding="utf-8" standalone="yes"?>""");
		os.put_string ("\n");
		os.put_string ("<font>\n");
		os.put_string (@"<format>$FORMAT_MAJOR.$FORMAT_MINOR</format>\n");
		os.put_string (@"<program version=\"$program_version\" os=\"$operating_system\" />\n");
	}
	
	public void write_closing_root_tag (DataOutputStream os) throws GLib.Error {
		os.put_string ("</font>\n");
	}
	
	public void write_spacing_classes (DataOutputStream os)  throws GLib.Error {
		SpacingData s = font.get_spacing ();
		
		foreach (SpacingClass sc in s.classes) {
				os.put_string ("<spacing ");
				os.put_string ("first=\"");
				
				if (sc.first.char_count () == 1) {
					os.put_string (Font.to_hex (sc.first.get_char ()));
				} else {
					os.put_string ("name:");
					os.put_string (encode (sc.first));
				}
				
				os.put_string ("\" ");
				
				os.put_string ("next=\"");
				
				if (sc.next.char_count () == 1) {
					os.put_string (Font.to_hex (sc.next.get_char ()));
				} else {
					os.put_string ("name:");
					os.put_string (encode (sc.next));
				}
				
				os.put_string ("\" ");
				
				os.put_string ("/>\n");
		}
	}
		
	public void write_kerning (DataOutputStream os)  throws GLib.Error {
			uint num_kerning_pairs;
			string range;
			KerningClasses classes = font.get_kerning_classes ();
			
			num_kerning_pairs = classes.classes_first.size;

			for (int i = 0; i < num_kerning_pairs; i++) {
				range = classes.classes_first.get (i).get_all_ranges ();
				
				os.put_string ("<kerning ");
				os.put_string ("left=\"");
				os.put_string (encode (range));
				os.put_string ("\" ");
				
				range = classes.classes_last.get (i).get_all_ranges ();
				
				os.put_string ("right=\"");
				os.put_string (encode (range));
				os.put_string ("\" ");
				
				os.put_string ("hadjustment=\"");
				os.put_string (round (classes.classes_kerning.get (i).val));
				os.put_string ("\" />\n");
			}
			
			classes.get_single_position_pairs ((l, r, k) => {
				try {
					os.put_string ("<kerning ");
					os.put_string ("left=\"");
					os.put_string (encode (l));
					os.put_string ("\" ");
					
					os.put_string ("right=\"");
					os.put_string (encode (r));
					os.put_string ("\" ");
					
					os.put_string ("hadjustment=\"");
					os.put_string (round (k));
					os.put_string ("\" />\n");
				} catch (GLib.Error e) {
					warning (@"$(e.message) \n");
				}
			});
	}
	
	public void write_settings (DataOutputStream os) throws GLib.Error {
		foreach (string gv in font.grid_width) {
			os.put_string (@"<grid width=\"$(gv)\"/>\n");
		}
		
		if (GridTool.sizes.size > 0) {
			os.put_string ("\n");
		}
		
		os.put_string (@"<background scale=\"$(font.background_scale)\" />\n");	
	}

	public void write_description (DataOutputStream os) throws GLib.Error {
		os.put_string (@"<postscript_name>$(Markup.escape_text (font.postscript_name))</postscript_name>\n");
		os.put_string (@"<name>$(Markup.escape_text (font.name))</name>\n");
		os.put_string (@"<subfamily>$(Markup.escape_text (font.subfamily))</subfamily>\n");
		os.put_string (@"<bold>$(font.bold)</bold>\n");
		os.put_string (@"<italic>$(font.italic)</italic>\n");			
		os.put_string (@"<full_name>$(Markup.escape_text (font.full_name))</full_name>\n");
		os.put_string (@"<unique_identifier>$(Markup.escape_text (font.unique_identifier))</unique_identifier>\n");
		os.put_string (@"<version>$(Markup.escape_text (font.version))</version>\n");
		os.put_string (@"<description>$(Markup.escape_text (font.description))</description>\n");
		os.put_string (@"<copyright>$(Markup.escape_text (font.copyright))</copyright>\n");
		os.put_string (@"<license>$(Markup.escape_text (font.license))</license>\n");
		os.put_string (@"<license_url>$(Markup.escape_text (font.license_url))</license_url>\n");
		os.put_string (@"<weight>$(font.weight)</weight>\n");
		os.put_string (@"<units_per_em>$(font.units_per_em)</units_per_em>\n");
		os.put_string (@"<trademark>$(Markup.escape_text (font.trademark))</trademark>\n");
		os.put_string (@"<manufacturer>$(Markup.escape_text (font.manufacturer))</manufacturer>\n");
		os.put_string (@"<designer>$(Markup.escape_text (font.designer))</designer>\n");
		os.put_string (@"<vendor_url>$(Markup.escape_text (font.vendor_url))</vendor_url>\n");
		os.put_string (@"<designer_url>$(Markup.escape_text (font.designer_url))</designer_url>\n");
		
	}

	public void write_lines (DataOutputStream os) throws GLib.Error {
		os.put_string ("<horizontal>\n");
		os.put_string (@"\t<top_limit>$(round (font.top_limit))</top_limit>\n");
		os.put_string (@"\t<top_position>$(round (font.top_position))</top_position>\n");
		os.put_string (@"\t<x-height>$(round (font.xheight_position))</x-height>\n");
		os.put_string (@"\t<base_line>$(round (font.base_line))</base_line>\n");
		os.put_string (@"\t<bottom_position>$(round (font.bottom_position))</bottom_position>\n");
		os.put_string (@"\t<bottom_limit>$(round (font.bottom_limit))</bottom_limit>\n");
		
		foreach (Line guide in font.custom_guides) {
			os.put_string (@"\t<custom_guide label=\"$(encode (guide.label))\">$(round (guide.pos))</custom_guide>\n");
		}
		
		os.put_string ("</horizontal>\n");
	}

	public void write_glyph_collection_start (GlyphCollection gc, GlyphMaster master, DataOutputStream os)  throws GLib.Error {
		os.put_string ("<collection ");
		
		if (gc.is_unassigned ()) {
			os.put_string (@"name=\"$(encode (gc.get_name ()))\"");
		} else {
			os.put_string (@"unicode=\"$(Font.to_hex (gc.get_unicode_character ()))\"");
		}
		
		if (gc.is_multimaster ()) {
			os.put_string (" ");
			os.put_string (@"master=\"$(master.get_id ())\"");
		}
		
		os.put_string (">\n");
	}

	public void write_glyph_collection_end (DataOutputStream os)  throws GLib.Error {
		os.put_string ("</collection>\n\n");
	}

	public void write_selected (GlyphMaster master, DataOutputStream os)  throws GLib.Error {
		Glyph? g = master.get_current ();
		Glyph glyph;
		
		if (g != null) {
			glyph = (!) g;
			os.put_string (@"\t<selected id=\"$(glyph.version_id)\"/>\n");
		}
	}

	public void write_glyph_collection (GlyphCollection gc, DataOutputStream os)  throws GLib.Error {
		foreach (GlyphMaster master in gc.glyph_masters) {
			write_glyph_collection_start (gc, master, os);
			write_selected (master, os);
			write_glyph_master (master, os);
			write_glyph_collection_end (os);
		}
	}

	public void write_glyph_master (GlyphMaster master, DataOutputStream os)  throws GLib.Error {
		foreach (Glyph g in master.glyphs) {
			write_glyph (g, os);
		}
	} 

	public void write_glyph (Glyph g, DataOutputStream os) throws GLib.Error {
		os.put_string (@"\t<glyph id=\"$(g.version_id)\" left=\"$(double_to_string (g.left_limit))\" right=\"$(double_to_string (g.right_limit))\">\n");
		
		foreach (Layer layer in g.layers.subgroups) {
			write_layer (layer, os);
		}

		write_glyph_background (g, os);
		os.put_string ("\t</glyph>\n");
	}

	void write_layer (Layer layer, DataOutputStream os) throws GLib.Error {
		string data;
		
		// FIXME: name etc.
		os.put_string (@"\t\t<layer name= \"$(layer.name)\" visible=\"$(layer.visible)\">\n");

		PathList all_paths = layer.get_all_paths ();
			
		foreach (Path p in all_paths.paths) {
			data = get_point_data (p);
			if (data != "") {
				os.put_string (@"\t\t\t<path ");
				
				if (p.stroke != 0) {
					os.put_string (@"stroke=\"$(double_to_string (p.stroke))\" ");
				}
				
				if (p.line_cap != LineCap.BUTT) {
					if (p.line_cap == LineCap.ROUND) {
						os.put_string (@"cap=\"round\" ");
					} else if (p.line_cap == LineCap.SQUARE) {
						os.put_string (@"cap=\"square\" ");
					}
				}
				
				if (p.skew != 0) {
					os.put_string (@"skew=\"$(double_to_string (p.skew))\" ");
				}
				
				os.put_string (@"data=\"$(data)\" />\n");
			}
		}
		
		os.put_string ("\t\t</layer>\n");	
	}

	public static string double_to_string (double n) {
		string d = @"$n";
		return d.replace (",", ".");
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
		
		if (pl.points.size == 0) {
			return data.str;
		}
		
		if (pl.points.size == 1) {
			add_start_point (pl.points.get (0), data);
			data.append (" ");
			add_next_point (pl.points.get (0), pl.points.get (0), data);

			if (pl.is_open ()) {
				data.append (" O");
			}
			
			return data.str;
		}
		
		if (pl.points.size == 2) {
			add_start_point (pl.points.get (0), data);
			data.append (" ");
			add_next_point (pl.points.get (0), pl.points.get (pl.points.size - 1), data);
			data.append (" ");
			add_next_point (pl.points.get (pl.points.size - 1), pl.points.get (0), data);
			
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
		m = pl.points.get (0);	
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

	private static string round (double d) {
		char[] b = new char [22];
		unowned string s = d.format (b, "%.10f");
		string n = s.dup ();

		n = n.replace (",", ".");

		if (n == "-0.0000000000") {
			n = "0.0000000000";
		}
		
		return n;
	}
		
	private static void add_quadratic_start (EditPoint p, StringBuilder data) {
		string x, y;
		
		x = round (p.x);
		y = round (p.y);
		
		data.append (@"S $(x),$(y)");
	}

	private static void add_cubic_start (EditPoint p, StringBuilder data) {
		string x, y;
		
		x = round (p.x);
		y = round (p.y);
		
		data.append (@"B $(x),$(y)");
	}

	private static void add_line_to (EditPoint p, StringBuilder data) {
		string x, y;
		
		x = round (p.x);
		y = round (p.y);
		
		data.append (@"L $(x),$(y)");
	}

	private static void add_cubic_line_to (EditPoint p, StringBuilder data) {
		string x, y;
		
		x = round (p.x);
		y = round (p.y);
		
		data.append (@"M $(x),$(y)");
	}

	private static void add_quadratic (EditPoint start, EditPoint end, StringBuilder data) {
		EditPointHandle h = start.get_right_handle ();
		string x0, y0, x1, y1;
		
		x0 = round (h.x);
		y0 = round (h.y);
		x1 = round (end.x);
		y1 = round (end.y);
	
		data.append (@"Q $(x0),$(y0) $(x1),$(y1)");
	}

	private static void add_double (EditPoint start, EditPoint end, StringBuilder data) {
		EditPointHandle h1 = start.get_right_handle ();
		EditPointHandle h2 = end.get_left_handle ();
		string x0, y0, x1, y1, x2, y2;

		x0 = round (h1.x);
		y0 = round (h1.y);
		x1 = round (h2.x);
		y1 = round (h2.y);
		x2 = round (end.x);
		y2 = round (end.y);

		data.append (@"D $(x0),$(y0) $(x1),$(y1) $(x2),$(y2)");
	}

	private static void add_cubic (EditPoint start, EditPoint end, StringBuilder data) {
		EditPointHandle h1 = start.get_right_handle ();
		EditPointHandle h2 = end.get_left_handle ();
		string x0, y0, x1, y1, x2, y2;

		x0 = round (h1.x);
		y0 = round (h1.y);
		x1 = round (h2.x);
		y1 = round (h2.y);
		x2 = round (end.x);
		y2 = round (end.y);

		data.append (@"C $(x0),$(y0) $(x1),$(y1) $(x2),$(y2)");
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
	
	private void write_glyph_background (Glyph g, DataOutputStream os) throws GLib.Error {
		BackgroundImage? bg;
		BackgroundImage background_image;
		double pos_x, pos_y, scale_x, scale_y, rotation;
		
		bg = g.get_background_image ();
		
		// FIXME: use the coordinate system
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

	private bool parse_file (Tag tag) {
		foreach (Tag t in tag) {
			// this is a backup file, but with a path to the original file
			if (t.get_name () == "backup") {
				font.font_file = t.get_content ();
			}

			// file format version
			if (t.get_name () == "format") {
				parse_format (t);
			}
						
			// glyph format
			if (t.get_name () == "collection") {
				parse_glyph_collection (t);
			}
			
			// horizontal lines in the new format
			if (t.get_name () == "horizontal") {
				parse_horizontal_lines (t);
			}			
			
			// grid buttons
			if (t.get_name () == "grid") {
				parse_grid (t);
			}

			if (t.get_name () == "background") {
				parse_background (t);
			}

			if (t.get_name () == "postscript_name") {
				font.postscript_name = decode (t.get_content ());
			}
			
			if (t.get_name () == "name") {
				font.name = decode (t.get_content ());
			}

			if (t.get_name () == "subfamily") {
				font.subfamily = decode (t.get_content ());
			}

			if (t.get_name () == "bold") {
				font.bold = bool.parse (t.get_content ());
			}
			
			if (t.get_name () == "italic") {
				font.italic = bool.parse (t.get_content ());
			}
			
			if (t.get_name () == "full_name") {
				font.full_name = decode (t.get_content ());
			}
			
			if (t.get_name () == "unique_identifier") {
				font.unique_identifier = decode (t.get_content ());
			}

			if (t.get_name () == "version") {
				font.version = decode (t.get_content ());
			}

			if (t.get_name () == "description") {
				font.description = decode (t.get_content ());
			}
			
			if (t.get_name () == "copyright") {
				font.copyright = decode (t.get_content ());
			}

			if (t.get_name () == "license") {
				font.license = decode (t.get_content ());
			}
			
			if (t.get_name () == "license_url") {
				font.license_url = decode (t.get_content ());
			}

			if (t.get_name () == "trademark") {
				font.trademark = decode (t.get_content ());
			}
			
			if (t.get_name () == "manufacturer") {
				font.manufacturer = decode (t.get_content ());
			}
			
			if (t.get_name () == "designer") {
				font.designer = decode (t.get_content ());
			}
			
			if (t.get_name () == "vendor_url") {
				font.vendor_url = decode (t.get_content ());
			}
			
			if (t.get_name () == "designer_url") {
				font.designer_url = decode (t.get_content ());
			}
			
			if (t.get_name () == "kerning") {
				parse_kerning (t);
			}

			if (t.get_name () == "spacing") {
				parse_spacing_class (t);
			}

			if (t.get_name () == "ligature") {
				parse_ligature (t);
			}

			if (t.get_name () == "contextual") {
				parse_contectual_ligature (t);
			}
			
			if (t.get_name () == "weight") {
				font.weight = int.parse (t.get_content ());
			}

			if (t.get_name () == "units_per_em") {
				font.units_per_em = int.parse (t.get_content ());
			}
						
			if (t.get_name () == "images") {
				parse_images (t);
			}

			if (t.get_name () == "alternate") {
				parse_alternate (t);
			}
		}
		
		return true;
	}
	
	public void parse_alternate (Tag tag) {
		string glyph_name = "";
		string alt = "";
		string alt_tag = "";
		
		foreach (Attribute attribute in tag.get_attributes ()) {
			if (attribute.get_name () == "glyph") {
				glyph_name = unserialize (decode (attribute.get_content ()));
			}
			
			if (attribute.get_name () == "replacement") {
				alt = unserialize (decode (attribute.get_content ()));
			}

			if (attribute.get_name () == "tag") {
				alt_tag = attribute.get_content ();
			}
		}
		
		if (glyph_name == "") {
			warning ("No name for source glyph in alternate.");
			return;
		}

		if (alt == "") {
			warning ("No name for alternate.");
			return;
		}

		if (alt_tag == "") {
			warning ("No tag for alternate.");
			return;
		}
		
		font.add_alternate (glyph_name, alt, alt_tag);
	}
	
	public void parse_format (Tag tag) {
		string[] v = tag.get_content ().split (".");
		
		if (v.length != 2) {
			warning ("Bad format string.");
			return;
		}
		
		font.format_major = int.parse (v[0]);
		font.format_major = int.parse (v[1]);
	}
	
	public void parse_images (Tag tag) {
		BackgroundImage? new_img;
		BackgroundImage img;
		string name;
		File img_file;
		double x, y, scale_x, scale_y, rotation;
		
		foreach (Tag t in tag) {
			if (t.get_name () == "image") {
				name = "";
				new_img = null;
				img_file = get_child (font.get_backgrounds_folder (), "parts");

				x = 0;
				y = 0;
				scale_x = 0;
				scale_y = 0;
				rotation = 0;
				
				foreach (Attribute attr in t.get_attributes ()) {
					if (attr.get_name () == "sha1") {
						img_file = get_child (img_file, attr.get_content () + ".png");

						if (!img_file.query_exists ()) {
							warning (@"Background file has not been created yet. $((!) img_file.get_path ())");
						}
						
						new_img = new BackgroundImage ((!) img_file.get_path ());
					}
					
					if (attr.get_name () == "name") {
						name = attr.get_content ();
					}
					
					if (attr.get_name () == "x") {
						x = parse_double (attr.get_content ());
					}

					if (attr.get_name () == "y") {
						y = parse_double (attr.get_content ());
					}
					
					if (attr.get_name () == "scale_x") {
						scale_x = parse_double (attr.get_content ());
					}

					if (attr.get_name () == "scale_y") {
						scale_y = parse_double (attr.get_content ());
					}

					if (attr.get_name () == "rotation") {
						rotation = parse_double (attr.get_content ());
					}
				}
				
				if (new_img != null && name != "") {
					img = (!) new_img;
					img.name = name;
					
					Toolbox.background_tools.add_image (img);
					parse_image_selections (img, t);
					
					img.img_x = x;
					img.img_y = y;
					img.img_scale_x = scale_x;
					img.img_scale_y = scale_y;
					img.img_rotation = rotation;
				} else {
					warning (@"No image found, name: $name");				
				}
			}
		}
	}
	
	private void parse_image_selections (BackgroundImage image, Tag tag) {
		double x, y, w, h;
		string? assigned_glyph;
		BackgroundSelection s;
		
		foreach (Tag t in tag) {
			if (t.get_name () == "selection") {
				
				x = 0;
				y = 0;
				w = 0;
				h = 0;
				assigned_glyph = null;
				
				foreach (Attribute attr in t.get_attributes ()) {
					if (attr.get_name () == "x") {
						x = parse_double (attr.get_content ());
					}

					if (attr.get_name () == "y") {
						y = parse_double (attr.get_content ());
					}

					if (attr.get_name () == "width") {
						w = parse_double (attr.get_content ());
					}
					
					if (attr.get_name () == "height") {
						h = parse_double (attr.get_content ());
					}

					if (attr.get_name () == "glyph") {
						assigned_glyph = attr.get_content ();
					}
				}
				
				s = new BackgroundSelection.absolute (null, image, x, y, w, h);
				s.assigned_glyph = assigned_glyph;
				
				image.selections.add (s);
			}
		}
	}
	
	private void create_background_files (Tag root) {
		foreach (Tag child in root) {
			if (child.get_name () == "name") {
				font.set_name (child.get_content ());
			}

			if (child.get_name () == "background-image") {
				parse_background_image (child);
			}			
		}
	}

	public static string serialize_attribute (string s) {
		string n = s.replace ("\"", "quote");
		n = n.replace ("&", "ampersand");								
		return n;
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
	
	private void parse_spacing_class (Tag tag) {
		string first, next;
		string name;
		SpacingData spacing = font.get_spacing ();
		
		first = "";
		next = "";
		
		foreach (Attribute attr in tag.get_attributes ()) {
			if (attr.get_name () == "first") {
				if (attr.get_content ().has_prefix ("U+")) {
					first = (!) Font.to_unichar (attr.get_content ()).to_string ();
				} else if (attr.get_content ().has_prefix ("name:")) {
					name = attr.get_content ().substring ("name:".length);
					first = decode (name);
				}
			}

			if (attr.get_name () == "next") {
				if (attr.get_content ().has_prefix ("U+")) {
					next = (!) Font.to_unichar (attr.get_content ()).to_string ();
				} else if (attr.get_content ().has_prefix ("name:")) {
					name = attr.get_content ().substring ("name:".length);
					next = decode (name);
				}
			}		
		}
		
		spacing.add_class (first, next);
	}
	
	private void parse_kerning (Tag tag) {
		GlyphRange range_left, range_right;
		double hadjustment = 0;
		KerningRange kerning_range;
		
		try {
			range_left = new GlyphRange ();
			range_right = new GlyphRange ();
			
			foreach (Attribute attr in tag.get_attributes ()) {
				if (attr.get_name () == "left") {

					range_left.parse_ranges (unserialize (decode (attr.get_content ())));
				}

				if (attr.get_name () == "right") {
					range_right.parse_ranges (unserialize (decode (attr.get_content ())));
				}

				if (attr.get_name () == "hadjustment") {
					hadjustment = double.parse (attr.get_content ());
				}				
			}
			
			if (range_left.get_length () > 1) {
				kerning_range = new KerningRange (font);
				kerning_range.set_ranges (range_left.get_all_ranges ());
				KerningTools.add_unique_class (kerning_range);
			}

			if (range_right.get_length () > 1) {
				kerning_range = new KerningRange (font);
				kerning_range.set_ranges (range_right.get_all_ranges ());
				KerningTools.add_unique_class (kerning_range);
			}

			font.get_kerning_classes ().set_kerning (range_left, range_right, hadjustment);
			
		} catch (MarkupError e) {
			warning (e.message);
		}
	}
	
	private void parse_background_image (Tag tag) {
		string file = "";
		string data = "";
		
		File img_dir;
		File img_file;
		FileOutputStream file_stream;
		DataOutputStream png_stream;
		
		tag.reparse ();
		foreach (Attribute attr in tag.get_attributes ()) {
			if (attr.get_name () == "sha1") {
				file = attr.get_content ();
			}

			if (attr.get_name () == "data") {
				data = attr.get_content ();
			}
		}

		if (!font.get_backgrounds_folder ().query_exists ()) {
			DirUtils.create ((!) font.get_backgrounds_folder ().get_path (), 0755);
		}
		
		img_dir = get_child (font.get_backgrounds_folder (), "parts");

		if (!img_dir.query_exists ()) {
			DirUtils.create ((!) img_dir.get_path (), 0755);
		}
	
		img_file = get_child (img_dir, @"$(file).png");
		
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
	
	private void parse_background (Tag tag) {
		foreach (Attribute attr in tag.get_attributes ()) {
			if (attr.get_name () == "scale") {
				font.background_scale = attr.get_content ();
			}
		}
	}
		
	private bool has_grid (string v) {
		foreach (string g in font.grid_width) {
			if (g == v) {
				return true;
			}
		}
		
		return false;
	}
	
	private void parse_grid (Tag tag) {
		foreach (Attribute attr in tag.get_attributes ()) {
			string v = attr.get_content ();
			
			if (attr.get_name () == "width" && !has_grid (v)) {
				font.grid_width.add (v);
			}
		}		
	}
	
	private void parse_horizontal_lines (Tag tag) {
		Line line;
		string label;
		double position;
		
		foreach (Tag t in tag) {
			if (t.get_name () == "top_limit" && t.get_content () != "") {
				font.top_limit = parse_double_from_node (t);
			}
			
			if (t.get_name () == "top_position" && t.get_content () != "") {
				font.top_position = parse_double_from_node (t);
			}
			
			if (t.get_name () == "x-height" && t.get_content () != "") {
				font.xheight_position = parse_double_from_node (t);
			}
			
			if (t.get_name () == "base_line" && t.get_content () != "") {
				font.base_line = parse_double_from_node (t);
			}
			
			if (t.get_name () == "bottom_position" && t.get_content () != "") {
				font.bottom_position = parse_double_from_node (t);
			}
			
			if (t.get_name () == "bottom_limit" && t.get_content () != "") {
				font.bottom_limit = parse_double_from_node (t);
			}
			
			if (t.get_name () == "custom_guide" && t.get_content () != "") {
				position = parse_double_from_node (t);
				
				label = "";
				foreach (Attribute attr in t.get_attributes ()) {
					if (attr.get_name () == "label") {
						label = decode (attr.get_content ());
					}
				}
				
				line = new Line (label, label, position);
				
				font.custom_guides.add (line);
			}
		}	
	}
	
	private double parse_double_from_node (Tag tag) {
		double d;
		bool r = double.try_parse (tag.get_content (), out d);
		string s;
		
		if (unlikely (!r)) {
			s = tag.get_content ();
			if (s == "") {
				warning (@"No content for node\n");
			} else {
				warning (@"Failed to parse double for \"$(tag.get_content ())\"\n");
			}
		}
		
		return (r) ? d : 0.0;
	}

	/** Parse the new glyph format */
	private void parse_glyph_collection (Tag tag) {
		unichar unicode = 0;
		GlyphCollection gc;
		GlyphCollection? current_gc;
		bool new_glyph_collection;
		StringBuilder b;
		string name = "";
		int selected_id = -1;
		bool unassigned = false;
		string master_id = "";
		GlyphMaster master;
		
		foreach (Attribute attribute in tag.get_attributes ()) {			
			if (attribute.get_name () == "unicode") {
				unicode = Font.to_unichar (attribute.get_content ());
				b = new StringBuilder ();
				b.append_unichar (unicode);
				name = b.str;
				
				if (name == "") {
					name = ".null";
				}
				
				unassigned = false;
			}

			// set name because either name or unicode is set in the bf file
			if (attribute.get_name () == "name") { 
				unicode = '\0';
				name = decode (attribute.get_content ());
				unassigned = true;
			}

			if (attribute.get_name () == "master") {
				master_id = attribute.get_content ();
			}
		}

		current_gc = font.get_glyph_collection_by_name (name);
		new_glyph_collection = (current_gc == null);
		
		if (!new_glyph_collection) {
			gc =  (!) current_gc;
		} else {
			gc = new GlyphCollection (unicode, name);
		}
		
		if (gc.has_master (master_id)) {
			master = gc.get_master (master_id);
		} else {
			master = new GlyphMaster.for_id (master_id);
			gc.add_master (master);
		}
		
		foreach (Tag t in tag) {			
			if (t.get_name () == "selected") {
				selected_id = parse_selected (t);
				master.set_selected_version (selected_id);
			}
		}
			
		foreach (Tag t in tag) {			
			if (t.get_name () == "glyph") {
				parse_glyph (t, gc, master, name, unicode, selected_id, unassigned);
			}
		}
		
		if (new_glyph_collection) {
			font.add_glyph_collection (gc);
		}
	}

	private int parse_selected (Tag tag) {
		int id = 1;
		bool has_selected_tag = false;
		
		foreach (Attribute attribute in tag.get_attributes ()) {
			if (attribute.get_name () == "id") {
				id = int.parse (attribute.get_content ());
				has_selected_tag = true;
				break;
			}
		}
		
		if (unlikely (!has_selected_tag)) {
			warning ("No selected tag.");
		}

		return id;
	}

	public void parse_glyph (Tag tag, GlyphCollection gc, GlyphMaster master,
			string name, unichar unicode, int selected_id, bool unassigned) {
		Glyph glyph = new Glyph (name, unicode);
		Path path;
		bool selected = false;
		bool has_id = false;
		int id = 1;
		Layer layer;
		
		foreach (Attribute attr in tag.get_attributes ()) {
			if (attr.get_name () == "left") {
				glyph.left_limit = double.parse (attr.get_content ());
			}
			
			if (attr.get_name () == "right") {
				glyph.right_limit = double.parse (attr.get_content ());
			}

			// id is unique within the glyph collection
			if (attr.get_name () == "id") {
				id = int.parse (attr.get_content ());
				has_id = true;
			}

			// old way of selecting a glyph in the version list
			if (attr.get_name () == "selected") {
				selected = bool.parse (attr.get_content ());
			}
		}
		
		foreach (Tag t in tag) {
			if (t.get_name () == "layer") {
				layer = parse_layer (t);
				glyph.layers.add_layer (layer);
			}
		}

		// parse paths without layers in old versions of the format
		foreach (Tag t in tag) {
			if (t.get_name () == "path") {
				path = parse_path (t);
				glyph.add_path (path);
			}			
		}

		foreach (Tag t in tag) {
			if (t.get_name () == "background") {
				parse_background_scale (glyph, t);
			}
		}

		foreach (Path p in glyph.get_all_paths ()) {
			p.reset_stroke ();
		}

		glyph.version_id = (has_id) ? id : (int) gc.length () + 1;
		gc.set_unassigned (unassigned);
		
		master.insert_glyph (glyph, selected || selected_id == id);
	}

	Layer parse_layer (Tag tag) {
		Layer layer = new Layer ();
		Path path;
		
		foreach (Attribute a in tag.get_attributes ()) {
			if (a.get_name () == "visible") {
				layer.visible = bool.parse (a.get_content ());
			}
			
			if (a.get_name () == "name") {
				layer.name = a.get_content ();
			}
		}
		
		foreach (Tag t in tag) {
			if (t.get_name () == "path") {
				path = parse_path (t);
				layer.add_path (path);
			}
			
			if (t.get_name () == "embedded") {
				font.has_svg = true;
			}
		}
		
		return layer;
	}

	private Path parse_path (Tag tag) {	
		Path path = new Path ();
		
		foreach (Attribute attr in tag.get_attributes ()) {
			if (attr.get_name () == "data") {
				path.point_data = attr.get_content ();
				path.control_points = null;
			}
		}

		foreach (Attribute attr in tag.get_attributes ()) {
			if (attr.get_name () == "stroke") {
				path.stroke = double.parse (attr.get_content ());
			}

			if (attr.get_name () == "skew") {
				path.skew = double.parse (attr.get_content ());
			}
			
			if (attr.get_name () == "cap") {
				if (attr.get_content () == "round") {
					path.line_cap = LineCap.ROUND;
				} else if (attr.get_content () == "square") {
					path.line_cap = LineCap.SQUARE;
				}
			}
		}
		
		return path;	
	}
	
	private static void line (Path path, string px, string py) {
		EditPoint ep;
		
		path.add (parse_double (px), parse_double (py));
		ep = path.get_last_point ();
		ep.get_right_handle ().type = PointType.LINE_DOUBLE_CURVE;
		ep.get_left_handle ().type = PointType.LINE_DOUBLE_CURVE;
		ep.type = PointType.LINE_DOUBLE_CURVE;
		path.recalculate_linear_handles_for_point (ep);
	}

	private static void cubic_line (Path path, string px, string py) {
		EditPoint ep;
		
		path.add (parse_double (px), parse_double (py));
		ep = path.points.get (path.points.size - 1);
		ep.get_right_handle ().type = PointType.LINE_CUBIC;
		ep.type = PointType.LINE_CUBIC;
		path.recalculate_linear_handles_for_point (ep);
	}

	private static void quadratic (Path path, string px0, string py0, string px1, string py1) {
		EditPoint ep1, ep2;
		
		double x0 = parse_double (px0);
		double y0 = parse_double (py0);
		double x1 = parse_double (px1);
		double y1 = parse_double (py1);

		if (path.points.size == 0) {
			warning ("No point.");
			return;
		}
		
		ep1 = path.points.get (path.points.size - 1);
		path.recalculate_linear_handles_for_point (ep1);
		ep1.get_right_handle ().type = PointType.QUADRATIC;
		ep1.get_right_handle ().move_to_coordinate (x0, y0);	
		ep1.type = PointType.QUADRATIC;

		path.add (x1, y1);

		ep2 = path.points.get (path.points.size - 1);
		path.recalculate_linear_handles_for_point (ep2);
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
				
		if (path.points.size == 0) {
			warning ("No point");
			return;
		}

		// start with line handles
		ep1 = path.points.get (path.points.size - 1);
		ep1.get_right_handle ().type = PointType.LINE_CUBIC;
		
		lx = ep1.x + ((x2 - ep1.x) / 3);
		ly = ep1.y + ((y2 - ep1.y) / 3);
						
		ep1.get_right_handle ().move_to_coordinate (lx, ly);
		path.recalculate_linear_handles_for_point (ep1);
		
		// set curve handles
		ep1 = path.points.get (path.points.size - 1);
		path.recalculate_linear_handles_for_point (ep1);
		ep1.get_right_handle ().type = PointType.CUBIC;
		ep1.get_right_handle ().move_to_coordinate (x0, y0);				
		ep1.type = PointType.CUBIC;
	
		path.add (x2, y2);
						
		ep2 = path.points.get (path.points.size - 1);
		path.recalculate_linear_handles_for_point (ep2);
		ep2.get_left_handle ().type = PointType.CUBIC;
		ep2.get_left_handle ().move_to_coordinate (x1, y1);
		ep2.type = PointType.CUBIC;
		
		path.recalculate_linear_handles_for_point (ep2);
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
				
		if (path.points.size == 0) {
			warning ("No point");
			return;
		}

		// start with line handles
		ep1 = path.points.get (path.points.size - 1);
		ep1.get_right_handle ().type = PointType.LINE_DOUBLE_CURVE;
		
		lx = ep1.x + ((x2 - ep1.x) / 4);
		ly = ep1.y + ((y2 - ep1.y) / 4);
						
		ep1.get_right_handle ().move_to_coordinate (lx, ly);
		path.recalculate_linear_handles_for_point (ep1);
		
		// set curve handles
		ep1 = path.points.get (path.points.size - 1);
		path.recalculate_linear_handles_for_point (ep1);
		ep1.get_right_handle ().type = PointType.DOUBLE_CURVE;
		ep1.get_right_handle ().move_to_coordinate (x0, y0);				
		ep1.type = PointType.DOUBLE_CURVE;
		
		ep2 = path.add (x2, y2);
		path.recalculate_linear_handles_for_point (ep2);
		ep2.get_left_handle ().type = PointType.DOUBLE_CURVE;
		ep2.get_left_handle ().move_to_coordinate (x1, y1);
		ep2.type = PointType.DOUBLE_CURVE;
		
		path.recalculate_linear_handles_for_point (ep1);
	}
	
	public static void close (Path path) {
		EditPoint ep1, ep2;
		
		if (path.points.size < 2) {
			warning ("Less  than two points in path.");
			return;
		}
		
		// last point is first
		ep1 = path.points.get (path.points.size - 1);
		ep2 = path.points.get (0);
		
		path.points.remove_at (path.points.size - 1);
		
		if (ep1.type != PointType.QUADRATIC || ep2.type != PointType.QUADRATIC) {
			ep2.tie_handles = ep1.tie_handles;
			ep2.left_handle.angle = ep1.left_handle.angle;
			ep2.left_handle.length = ep1.left_handle.length;
			ep2.left_handle.type = ep1.left_handle.type;
		}
		
		path.close ();
	}
	
	public static void parse_path_data (string data, Path path) {
		string[] d = data.split (" ");
		string[] p, p1, p2;
		int i = 0;
		string instruction = "";
		bool open = false;

		if (data == "") {
			return;
		}
		
		return_if_fail (d.length > 1);
		
		if (!(d[0] == "S" || d[0] == "B")) {
			warning ("No start point.");
			return;
		}
		
		instruction = d[i++];
		
		if (instruction == "S") {
			p = d[i++].split (",");
			return_if_fail (p.length == 2);
			line (path, p[0], p[1]);
		}

		if (instruction == "B") {
			p = d[i++].split (",");
			return_if_fail (p.length == 2);
			cubic_line (path, p[0], p[1]);
		}
		
		while (i < d.length) {
			instruction = d[i++];
			
			if (instruction == "") {
				warning (@"No instruction at index $i.");
				return;
			}
			
			if (instruction == "L") {
				return_if_fail (i < d.length);
				p = d[i++].split (",");
				return_if_fail (p.length == 2);
				line (path, p[0], p[1]);
			}else if (instruction == "M") {
				return_if_fail (i < d.length);
				p = d[i++].split (",");
				return_if_fail (p.length == 2);
				cubic_line (path, p[0], p[1]);
			} else if (instruction == "Q") {
				return_if_fail (i + 1 < d.length);
				
				p = d[i++].split (",");
				p1 = d[i++].split (",");
				
				return_if_fail (p.length == 2);
				return_if_fail (p1.length == 2);
				
				quadratic (path, p[0], p[1], p1[0], p1[1]);
			} else if (instruction == "D") {
				return_if_fail (i + 2 < d.length);
				
				p = d[i++].split (",");
				p1 = d[i++].split (",");
				p2 = d[i++].split (",");

				return_if_fail (p.length == 2);
				return_if_fail (p1.length == 2);
				return_if_fail (p2.length == 2);
				
				double_curve (path, p[0], p[1], p1[0], p1[1], p2[0], p2[1]);
			} else if (instruction == "C") {
				return_if_fail (i + 2 < d.length);
				
				p = d[i++].split (",");
				p1 = d[i++].split (",");
				p2 = d[i++].split (",");

				return_if_fail (p.length == 2);
				return_if_fail (p1.length == 2);
				return_if_fail (p2.length == 2);
				
				cubic (path, p[0], p[1], p1[0], p1[1], p2[0], p2[1]);
			} else if (instruction == "T") {
				path.points.get (path.points.size - 1).tie_handles = true;
			} else if (instruction == "O") {
				open = true;
			} else {
				warning (@"invalid instruction $instruction");
				return;
			}
		}

		if (!open) {
			close (path);
		} else {
			path.points.remove_at (path.points.size - 1);
			
			if (!path.is_open ()) {
				warning ("Closed path.");
			}
		}
		
		path.update_region_boundaries (); 
	}
	
	private static double parse_double (string p) {
		double d;
		if (double.try_parse (p, out d)) {
			return d;
		}
		
		warning (@"failed to parse $p");
		return 0;
	}
	
	private void parse_background_scale (Glyph g, Tag tag) {
		BackgroundImage img;
		BackgroundImage? new_img = null;
		
		File img_file = get_child (font.get_backgrounds_folder (), "parts");
		
		foreach (Attribute attr in tag.get_attributes ()) {
			if (attr.get_name () == "sha1") {
				img_file = get_child (img_file, attr.get_content () + ".png");

				if (!img_file.query_exists ()) {
					warning (@"Background file has not been created yet. $((!) img_file.get_path ())");
				}
				
				new_img = new BackgroundImage ((!) img_file.get_path ());
				g.set_background_image ((!) new_img);
			}
		}
		
		if (unlikely (new_img == null)) {
			warning ("No source for image found.");
			return;
		}
	
		img = (!) new_img;
	
		foreach (Attribute attr in tag.get_attributes ()) {
			if (attr.get_name () == "x") {
				img.img_x = double.parse (attr.get_content ());
			}
			
			if (attr.get_name () == "y") {
				img.img_y = double.parse (attr.get_content ());
			}	

			if (attr.get_name () == "scale_x") {
				img.img_scale_x = double.parse (attr.get_content ());
			}

			if (attr.get_name () == "scale_y") {
				img.img_scale_y = double.parse (attr.get_content ());
			}
						
			if (attr.get_name () == "rotation") {
				img.img_rotation = double.parse (attr.get_content ());
			}
		}
		
		img.set_position (img.img_x, img.img_y);	
	}
	
	public void write_ligatures (DataOutputStream os) {
		Ligatures ligatures = font.get_ligatures ();

		ligatures.get_ligatures ((subst, liga) => {
			try {
				string lig = serialize_attribute (liga);
				string sequence = serialize_attribute (encode (subst));
				os.put_string (@"<ligature sequence=\"$(encode (sequence))\" replacement=\"$(encode (lig))\"/>\n");
			} catch (GLib.IOError e) {
				warning (e.message);
			}
		});
		
		try {
			foreach (ContextualLigature c in ligatures.contextual_ligatures) {
				os.put_string (@"<contextual "
					+ @"ligature=\"$(c.ligatures)\" "
					+ @"backtrack=\"$(c.backtrack)\" "
					+ @"input=\"$(c.input)\" "
					+ @"lookahead=\"$(c.lookahead)\" />\n");
			}
		} catch (GLib.Error e) {
			warning (e.message);
		}
	}
	
	public void parse_contectual_ligature (Tag t) {
		string ligature = "";
		string backtrack = "";
		string input = "";
		string lookahead = "";
		Ligatures ligatures;
		
		foreach (Attribute a in t.get_attributes ()) {
			if (a.get_name () == "ligature") {
				ligature = decode (a.get_content ());
			}

			if (a.get_name () == "backtrack") {
				backtrack = decode (a.get_content ());
			}

			if (a.get_name () == "input") {
				input = decode (a.get_content ());
			}
			
			if (a.get_name () == "lookahead") {
				lookahead = decode (a.get_content ());
			}
		}
		
		ligatures = font.get_ligatures ();
		ligatures.add_contextual_ligature (ligature, backtrack, input, lookahead);
	}
	
	public void parse_ligature (Tag t) {
		string sequence = "";
		string ligature = "";
		Ligatures ligatures;
		
		foreach (Attribute a in t.get_attributes ()) {
			if (a.get_name () == "sequence") {
				sequence = decode (a.get_content ());
			}

			if (a.get_name () == "replacement") {
				ligature = decode (a.get_content ());
			}
		}
		
		ligatures = font.get_ligatures ();
		ligatures.add_ligature (sequence, ligature);
	}
	
	public static string decode (string s) {
		string t;
		t = s.replace ("&quot;", "\"");
		t = t.replace ("&apos;", "'");
		t = t.replace ("&lt;", "<");
		t = t.replace ("&gt;", ">");
		t = t.replace ("&amp;", "&");
		return t;
	}

	/**
	 * Replace ", ' < > and & with encoded characters.
	 */
	public static string encode (string s) {
		string t;
		t = s.replace ("&", "&amp;");
		t = t.replace ("\"", "&quot;");
		t = t.replace ("'", "&apos;");
		t = t.replace ("<", "&lt;");
		t = t.replace (">", "&gt;");	
		return t;
	}
}

}
