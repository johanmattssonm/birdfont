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

using Cairo;

namespace BirdFont {

public enum FontFormat {
	BIRDFONT,
	FFI,
	SVG,
	FREETYPE
}

public class Font : GLib.Object {
	
	/** Table with glyphs sorted by their unicode value. */
	public GlyphTable glyph_cache = new GlyphTable ();
	
	/** Table with glyphs sorted by their name. */
	public GlyphTable glyph_name = new GlyphTable ();

	/** Table with ligatures. */
	public GlyphTable ligature = new GlyphTable ();
	
	public List <string> background_images = new List <string> ();
	public string background_scale = "1";
		
	/** Top margin */
	public double top_limit;
		
	/** Height of upper case letters. */
	public double top_position;

	/** x-height upper bearing from origo. */
	public double xheight_position;

	/** Base line coordinate from origo. */
	public double base_line;
	
	/** Descender position */
	public double bottom_position;
	
	/** Bottom margin */
	public double bottom_limit;
	
	public string? font_file = null;
	
	bool modified = false;
	
	// name table descriptions
	public string postscript_name = "Typeface";
	public string name = "Typeface";
	public string subfamily = "Regular";
	public string full_name = "Typeface";
	public string unique_identifier = "Typeface";
	public string version = "Version 1.0";
	public string description = "";
	public string copyright = "";

	public bool initialised = true;

	OpenFontFormatReader otf;
	bool otf_font = false;
	
	public List<string> grid_width = new List<string> ();
	
	/** File format. */
	public FontFormat format = FontFormat.BIRDFONT;
	
	KerningClasses kerning_classes;
	
	public Font () {
		// positions in pixels at first zoom level
		// default x-height should be 60 in 1:1
		top_limit = -84 ;
		top_position = -72;
		xheight_position = -56;
		base_line = 0;
		bottom_position = 20;
		bottom_limit = 27;
		
		kerning_classes = new KerningClasses ();
	}

	public void touch () {
		modified = true;
	}

	public File get_backgrounds_folder () {
		string fn = @"$(get_name ()) backgrounds";
		File f = BirdFont.get_settings_directory ().get_child (fn);
		return f;
	}

	/** Retuns true if the current font has be modified */
	public bool is_modified () {
		return modified;
	}

	/** Full path to this font file. */
	public string get_path () {
		int i = 0;
		
		if (font_file != null) {
			return (!) font_file;
		}
		
		StringBuilder sb = new StringBuilder ();
		sb.append (Environment.get_home_dir ());
		sb.append (@"/$(get_name ()).bf");
		
		File f = File.new_for_path (sb.str);

		while (f.query_exists ()) {
			sb.erase ();
			sb.append (Environment.get_home_dir ());
			sb.append (@"/$(get_name ())$(++i).bf");
			f = File.new_for_path (sb.str);
		}
		
		return sb.str;
	}

	public string get_file_name () {
		string p = get_path ();
		int i = p.last_index_of ("/");
		
		if (i == -1) {
			i = p.last_index_of ("\\");
		}
		
		p = p.substring (i + 1);
		
		return p;
	}
		
	public File get_folder () {
		string p = get_path ();
		int i = p.last_index_of ("/");
		
		if (i == -1) {
			i = p.last_index_of ("\\");
		}
		
		p = p.substring (0, i);
		
		return File.new_for_path (p);
	}
	
	public double get_height () {
		double r = base_line - top_position;
		return (r > 0) ? r : -r;
	}
		
	public void set_name (string name) {
		string n = name;
		this.name = n;
	}
	
	public string get_name () {
		return name;
	}

	public void print_all () {
		stdout.printf ("Unicode:\n");		
		glyph_cache.for_each((g) => {
			stdout.printf (@"$(g.get_unicode ())\n");
		});
		
		stdout.printf ("Names:\n");	
		glyph_name.for_each((g) => {
			stdout.printf (@"$(g.get_name ())\n");
		});
	}

	public bool has_glyph (string n) {
		return get_glyph (n) != null;
	}

	public Glyph get_nonmarking_return () {
		Glyph ret;
		
		if (has_glyph ("nonmarkingreturn")) {
			return (!) get_glyph ("nonmarkingreturn");
		}
				
		ret = new Glyph ("nonmarkingreturn", '\r');
		ret.set_unassigned (false);
		ret.left_limit = 0;
		ret.right_limit = 0;
		ret.remove_empty_paths ();
		
		assert (ret.path_list.length () == 0);
		
		return ret;
	}
		
	public Glyph get_null_character () {
		Glyph n;
		
		if (has_glyph ("null")) {
			return (!) get_glyph ("null");
		}
		
		n = new Glyph ("null", '\0');
		n.set_unassigned (false);
		n.left_limit = 0;
		n.right_limit = 0;
		n.remove_empty_paths ();
		
		assert (n.path_list.length () == 0);
		
		return n;
	}
	
	public Glyph get_space () {
		Glyph n;
		
		if (has_glyph (" ")) {
			return (!) get_glyph (" ");
		}

		if (has_glyph ("space")) {
			return (!) get_glyph ("space");
		}
				
		n = new Glyph ("space", ' ');
		n.set_unassigned (false);
		n.left_limit = 0;
		n.right_limit = 27;
		n.remove_empty_paths ();
		
		assert (n.path_list.length () == 0);
		
		return n;		
	}
	
	public Glyph get_not_def_character () {
		Glyph g;

		Path p;
		Path i;
		
		if (has_glyph (".notdef")) {
			return (!) get_glyph (".notdef");
		}
		
		g = new Glyph (".notdef", 0);
		p = new Path ();
		i = new Path ();
		
		g.set_unassigned (true);
		g.left_limit = -33;
		g.right_limit = 33;
		
		p.add (-20, -top_position - 5);
		p.add (20, -top_position - 5);
		p.add (20, -base_line + 5);
		p.add (-20, -base_line + 5);
		p.close ();
		
		i.add (-15, -top_position - 10);
		i.add (15, -top_position - 10);
		i.add (15, -base_line + 10);
		i.add (-15, -base_line + 10);
		i.reverse ();
		i.close ();

		g.add_path (i);
		g.add_path (p);

		return g;
	}
		
	public void add_glyph (Glyph glyph) {
		GlyphCollection? gc = get_glyph_collection (glyph.get_name ());

		if (gc == null) {
			add_glyph_collection (new GlyphCollection (glyph));
		}
	}

	public void add_glyph_collection (GlyphCollection glyph_collection) {
		GlyphCollection? gc;
		
		if (glyph_collection.get_name () == "") {
			warning ("Refusing to insert glyph with name \"\", null character should be named null.");
			return;
		}
		
		gc = glyph_name.get (glyph_collection.get_name ());
		if (gc != null) {
			warning ("glyph has already been added");
			return;
		}
		
		if (glyph_collection.get_unicode () != "") {
			glyph_name.insert (glyph_collection.get_name (), glyph_collection);			
		}
		
		glyph_cache.insert (glyph_collection.get_unicode (), glyph_collection);
	}
	
	public string get_name_for_character (unichar c) {
		// if some glyph is already mapped to unichar, return it's name
		uint i = 0;
		Glyph? gl;
		Glyph g;
		StringBuilder sb;
		
		while ((gl = get_glyph_indice (i++)) != null) {
			g = (!) gl;
			
			if (g.unichar_code == c) {
				return g.name;
			}
		}
						
		// otherwise return some default name, possibly from unicode database
		if (c == 0) {
			return ".null".dup ();
		}
		
		sb = new StringBuilder ();
		sb.append_unichar (c);
		return sb.str;		
	}
	
	public bool has_name (string name) {
		return glyph_name.has_key (name);
	}
	
	public void delete_glyph (GlyphCollection glyph) {
		glyph_cache.remove (glyph.get_unicode ());
		glyph_name.remove (glyph.get_name ());
		ligature.remove (glyph.get_current ().get_ligature_string ());
	}

	// FIXME: order of ligature substitutions is important
	public GlyphCollection? get_ligature (uint indice) {
		return ligature.nth (indice);
	}
	
	/** Obtain all versions and alterntes for this glyph. */
	public GlyphCollection? get_glyph_collection (string glyph) {
		GlyphCollection? gc = get_cached_glyph_collection (glyph);
		Glyph? g;
		
		if (gc == null && otf_font) {
			// load it from otf file if we need to
			g = otf.read_glyph (glyph);
			
			if (g != null) {
				add_glyph_callback ((!) g);
				return get_cached_glyph_collection (glyph);
			}
		}
			
		return gc;
	}

	/** Get glyph collection by unichar code. */
	public GlyphCollection? get_cached_glyph_collection (string unichar_code) {
		GlyphCollection? gc = null;
		gc = glyph_cache.get (unichar_code);
		return gc;
	}

	/** Get glyph collection by name. */
	public GlyphCollection? get_glyph_collection_by_name (string glyph) {
		// TODO: load from disk here if needed.
		GlyphCollection? gc = null;
		gc = glyph_name.get (glyph);		
		return gc;
	}

	/** Get glyph by name. */	
	public Glyph? get_glyph_by_name (string glyph) {
		GlyphCollection? gc = get_glyph_collection_by_name (glyph);
		
		if (gc == null) {
			return null;
		}
		
		return ((!)gc).get_current ();
	}
		
	public Glyph? get_glyph (string unicode) {
		GlyphCollection? gc = null;
		gc = glyph_cache.get (unicode);

		if (gc == null) {
			return null;
		}
		
		return ((!)gc).get_current ();
	}
	
	public GlyphCollection? get_glyph_collection_indice (unichar glyph_indice) {
		if (!(0 <= glyph_indice < glyph_name.length ())) {
			return null;
		}
		
		return glyph_name.nth (glyph_indice);
	}
	
	public Glyph? get_glyph_indice (unichar glyph_indice) {
		GlyphCollection? gc;
		
		gc = get_glyph_collection_indice (glyph_indice);
		
		if (gc != null) {
			return ((!) gc).get_current ();
		}
		
		return null;
	}
	
	public void add_background_image (string file) {
		background_images.append (file);
	}
	
	/** Delete temporary rescue files. */
	public void delete_backup () {
		File dir = BirdFont.get_backup_directory ();
		File? new_file = null;
		File file;
		string backup_file;
		
		new_file = dir.get_child (@"$(name).bf");
		backup_file = (!) ((!) new_file).get_path ();
		
		try {
			file = File.new_for_path (backup_file);
			if (file.query_exists ()) {
				file.delete ();	
			}
		} catch (GLib.Error e) {
			stderr.printf (@"Failed to delete backup\n");
			warning (@"$(e.message) \n");
		}
	}
	
	/** Returns path to backup file. */
	public string save_backup () {
		File dir = BirdFont.get_backup_directory ();
		File? temp_file = null;
		string backup_file;
		BirdFontFile birdfont_file = new BirdFontFile (this);

		temp_file = dir.get_child (@"$(name).bf");
		backup_file = (!) ((!) temp_file).get_path ();
		backup_file = backup_file.replace (" ", "_");
		birdfont_file.write_font_file (backup_file, true);
		
		return backup_file;
	}
	
	public bool save (string path) {
		Font font;
		BirdFontFile birdfont_file = new BirdFontFile (this);
		bool file_written = birdfont_file.write_font_file (path);
		
		if (!path.has_suffix (".bf")) {
			warning ("Expecting .bf format.");
			return false;
		}
		
		if (file_written) {
			font_file = path;
			
			// delete backup when font is saved
			font = BirdFont.get_current_font ();
			font.delete_backup ();
		}
		
		modified = false;
		add_thumbnail ();
		Preferences.add_recent_files (get_path ());
		
		return file_written;
	}

	public void set_font_file (string path) {
		font_file = path;
		modified = false;
	}

	public uint length () {
		return glyph_name.length ();
	}

	public bool is_empty () {
		return (glyph_name.length () == 0);
	}

	public bool load (string path, bool recent = true) {
		bool loaded = false;
		initialised = true;
		otf_font = false;

		while (grid_width.length () > 0) {
			grid_width.remove_link (grid_width.first ());
		}
	
		// empty cache and fill it with new glyphs from disk
		glyph_cache.remove_all ();
		glyph_name.remove_all ();
		ligature.remove_all ();
		
		if (path.has_suffix (".svg")) {
			Toolbox.select_tool_by_name ("cubic_points");
			font_file = path;
			loaded = parse_svg_file (path);
					
			if (!loaded) {
				warning ("Failed to load SVG font.");
			}
			
			format = FontFormat.SVG;
		}
		
		if (path.has_suffix (".ffi")) {
			font_file = path;
			loaded = parse_bf_file (path);
			format = FontFormat.FFI;
		}

		if (path.has_suffix (".bf")) {
			font_file = path;
			loaded = parse_bf_file (path);
			format = FontFormat.BIRDFONT;
		}
		
		if (path.has_suffix (".ttf")) {
			font_file = path;
			loaded = parse_freetype_file (path);
			
			if (!loaded) {
				warning ("Failed to load TTF font.");
			}
			
			format = FontFormat.FREETYPE;
			
			// DELETE
			OpenFontFormatReader or = new OpenFontFormatReader ();
			or.parse_index (path);
		}			

		if (path.has_suffix (".otf")) {
			font_file = path;
			loaded = parse_freetype_file (path);
						
			if (!loaded) {
				warning ("Failed to load OTF font.");
			}
			
			format = FontFormat.FREETYPE;
		}	
					
		/* // TODO: Remove the old way of loading ttfs when testing of the OTF writer is complete.
		if (BirdFont.experimental) {
			if (path.has_suffix (".ttf")) {
				font_file = path;
				loaded = parse_otf_file (path);
			}
		}*/
		
		if (recent) {
			add_thumbnail ();
			Preferences.add_recent_files (get_path ());
		}
					
		return loaded;
	}
	
	private bool parse_bf_file (string path) {
		BirdFontFile font = new BirdFontFile (this);
		return font.load (path);
	}

	private bool parse_freetype_file (string path) {
		string font_data;
		StringBuilder? data;
		int error;
		bool parsed;
		BirdFontFile bf_font = new BirdFontFile (this);
		
		data = load_freetype_font (path, out error);
		
		if (error != 0) {
			warning ("Failed to load freetype font.");
			return false;
		}
		
		if (data == null) {
			warning ("No svg data.");
			return false;
		}
		
		font_data = ((!) data).str;
		parsed = bf_font.load_data (font_data);
		
		if (parsed) {
			Preferences.add_recent_files (path);
		} else {
			warning ("Failed to parse loaded freetype font.");	
		}
		
		return parsed;
	}

	private bool parse_svg_file (string path) {
		SvgFont svg_font = new SvgFont (this);
		svg_font.load (path);
		return true;
	}

	private void add_thumbnail () {
		File f = BirdFont.get_thumbnail_directory ().get_child (@"$((!) get_file_name ()).png");
		Glyph? gl = get_glyph ("a");
		Glyph g;
		ImageSurface img;
		ImageSurface img_scale;
		Context cr;
		double scale;
		
		if (gl == null) {
			gl = get_glyph_indice (4);
		}		
		
		if (gl == null) {
			gl = get_not_def_character ();
		}
		
		g = (!) gl;

		img = g.get_thumbnail ();
		scale = 70.0 / img.get_width ();
		
		if (scale > 70.0 / img.get_height ()) {
			scale = 70.0 / img.get_height ();
		}
		
		if (scale > 1) {
			scale = 1;
		}

		img_scale = new ImageSurface (Format.ARGB32, (int) (scale * img.get_width ()), (int) (scale * img.get_height ()));
		cr = new Context (img_scale);
		
		cr.scale (scale, scale);

		cr.save ();
		cr.set_source_surface (img, 0, 0);
		cr.paint ();
		cr.restore ();
		
		img_scale.write_to_png ((!) f.get_path ());
	}

	/** Callback function for loading glyph in a separate thread. */
	public void add_glyph_callback (Glyph g) {
		GlyphCollection? gcl;
		GlyphCollection gc;
		string liga;
							
		gcl = get_cached_glyph_collection (g.get_name ());
		
		if (gcl != null) {
			warning (@"glyph \"$(g.get_name ())\" does already exist");
		}
				
		if (g.is_unassigned ()) {
			gc = new GlyphCollection (g);
		}

		gc = new GlyphCollection (g);
		add_glyph_collection (gc);

		if (g.is_ligature ()) {
			liga = g.get_ligature_string ();
			ligature.insert (liga, gc);
		}
	}

	public bool parse_otf_file (string path) throws GLib.Error {
		otf = new OpenFontFormatReader ();
		otf_font = true;
		otf.parse_index (path);
		return true;
	}

	public static unichar to_unichar (string unicode) {
		int index = 2;
		int i = 0;
		unichar c;
		unichar rc = 0;
		bool r;
		
		if (unlikely (!unicode.has_prefix ("U+"))) {
			warning (@"All unicode values must begin with U+ ($unicode)");
			return '\0';
		}
		
		while (r = unicode.get_next_char (ref index, out c)) {
			rc <<= 4;
			rc += hex_to_oct (c);
			
			return_val_if_fail (++i <= 6, '\0');
		}

		return rc;
	}
	
	private static string oct_to_hex (uint8 o) {
		switch (o) {
			case 10: return "a";
			case 11: return "b";
			case 12: return "c";
			case 13: return "d";
			case 14: return "e";
			case 15: return "f";
		}

		return_val_if_fail (0 <= o <= 9, "-".dup ());
		
		return o.to_string ();
	}

	private static uint8 hex_to_oct (unichar o) {
		StringBuilder s = new StringBuilder ();
		s.append_unichar (o);
	
		switch (o) {
			case 'a': return 10;
			case 'b': return 11;
			case 'c': return 12;
			case 'd': return 13;
			case 'e': return 14;
			case 'f': return 15;
		}
		
		return_val_if_fail ('0' <= o <= '9', 0);
		
		return (uint8) (o - '0');
	}

	public static string to_hex (unichar ch) {
		StringBuilder s = new StringBuilder ();
		s.append ("U+");
		s.append (to_hex_code (ch));
		return s.str;
	}

	public static string to_hex_code (unichar ch) {
		StringBuilder s = new StringBuilder ();
		
		uint8 a = (uint8)(ch & 0x00000F);
		uint8 b = (uint8)((ch & 0x0000F0) >> 4 * 1);
		uint8 c = (uint8)((ch & 0x000F00) >> 4 * 2);
		uint8 d = (uint8)((ch & 0x00F000) >> 4 * 3);
		uint8 e = (uint8)((ch & 0x0F0000) >> 4 * 4);
		uint8 f = (uint8)((ch & 0xF00000) >> 4 * 5);
		
		if (e != 0 || f != 0) {
			s.append (oct_to_hex (f));
			s.append (oct_to_hex (e));
		}
		
		if (c != 0 || d != 0) {
			s.append (oct_to_hex (d));
			s.append (oct_to_hex (c));
		}
				
		s.append (oct_to_hex (b));
		s.append (oct_to_hex (a));
		
		return s.str;
	}
}

}
