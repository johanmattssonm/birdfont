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

using Cairo;

namespace BirdFont {

public enum FontFormat {
	BIRDFONT,
	BIRDFONT_PART,
	FFI,
	SVG,
	FREETYPE
}

public class Font : GLib.Object {
	
	/** Table with glyphs sorted by their unicode value. */
	public GlyphTable glyph_cache;
	
	/** Table with glyphs sorted by their name. */
	public GlyphTable glyph_name;

	/** Table with ligatures. */
	public GlyphTable ligature;
	
	public Gee.ArrayList<string> background_images = new Gee.ArrayList<string> ();
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
	public string postscript_name;
	public string name;
	public string subfamily;
	public string full_name;
	public string unique_identifier;
	public string version;
	public string description;
	public string copyright;

	public bool bold = false;
	public bool italic = false;
	public int weight = 400;

	public bool initialised = true;

	OpenFontFormatReader otf;
	bool otf_font = false;
	
	public Gee.ArrayList<string> grid_width;
	
	/** File format. */
	public FontFormat format = FontFormat.BIRDFONT;
	
	KerningClasses kerning_classes;
	
	bool read_only = false;
	
	/** Save font as many .bfp files instead of one big .bf */
	bool bfp = false;
	BirdFontPart bfp_file;
	
	public Font () {
		postscript_name = "Typeface";
		name = "Typeface";
		subfamily = "Regular";
		full_name = "Typeface";
		unique_identifier = "Typeface";
		version = "Version 1.0";
		description = "";
		copyright = "";
	
		glyph_cache = new GlyphTable ();
		glyph_name = new GlyphTable ();
		ligature = new GlyphTable ();
	
		grid_width = new Gee.ArrayList<string> ();
	
		kerning_classes = new KerningClasses ();
		
		top_limit = 84 ;
		top_position = 72;
		xheight_position = 56;
		base_line = 0;
		bottom_position = -20;
		bottom_limit = -27;
		
		bfp_file = new BirdFontPart (this);
	}

	public void set_weight (string w) {
		int wi = int.parse (w);
		
		if (wi > 0) {
			weight = wi;
		}
	}

	public string get_weight () {
		return @"$weight";
	}

	public void touch () {
		modified = true;
	}

	public KerningClasses get_kerning_classes () {
		return kerning_classes;
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
		string fn;
		File f;
		
		if (font_file != null) {
			fn = (!) font_file;
			
			if (fn.index_of ("/") == -1 && fn.index_of ("\\") == -1) {
				warning ("Relative path.");
			}
			
			return fn;
		}
		
		StringBuilder sb = new StringBuilder ();
		sb.append (Environment.get_home_dir ());
		sb.append (@"/$(get_name ()).bf");
		
		f = File.new_for_path (sb.str);

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
		
		if (i == -1) {
			warning (@"Can not find folder in $p.");
		}
		
		p = p.substring (0, i);
		
		return File.new_for_path (p);
	}
	
	public double get_height () {
		double r = top_position - base_line;
		return (r > 0) ? r : -r;
	}
		
	public void set_name (string name) {
		string n = name;
		this.name = n;
	}
	
	public string get_full_name () {
		return full_name;
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
		
		assert (ret.path_list.size == 0);
		
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
		
		assert (n.path_list.size == 0);
		
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
		
		assert (n.path_list.size == 0);
		
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
		
		p.add (-20, top_position - 5);
		p.add (20, top_position - 5);
		p.add (20, base_line + 5);
		p.add (-20, base_line + 5);
		p.close ();
		
		i.add (-15, top_position - 10);
		i.add (15, top_position - 10);
		i.add (15, base_line + 10);
		i.add (-15, base_line + 10);
		i.reverse ();
		i.close ();

		g.add_path (i);
		g.add_path (p);

		return g;
	}

	public void add_glyph_collection (GlyphCollection glyph_collection) {
		GlyphCollection? gc;
		
		if (unlikely (glyph_collection.get_name () == "")) {
			warning ("Refusing to add glyph with name \"\", null character should be named null.");
			return;
		}
		
		gc = glyph_name.get (glyph_collection.get_name ());
		if (unlikely (gc != null)) {
			warning ("glyph has already been added");
			return;
		}
		
		if (glyph_collection.get_unicode () != "") {
			glyph_name.insert (glyph_collection.get_name (), glyph_collection);			
		}
		
		glyph_cache.insert (glyph_collection.get_unicode (), glyph_collection);
	}
	
	public string get_name_for_character (unichar c) {
		StringBuilder sb;
		
		// FIXME: this is too slow
		/*
		while ((gl = get_glyph_indice (i++)) != null) {
			g = (!) gl;
			
			if (g.unichar_code == c) {
				return g.name;
			}
		}
		*/
		
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

	// FIXME: the order of ligature substitutions
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

		if (gc == null || ((!)gc).length () == 0) {
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
		background_images.add (file);
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
		
		if (get_path () == backup_file) {
			warning ("Refusing to write backup of a backup.");
			return backup_file;
		}
		
		birdfont_file.write_font_file (backup_file, true);
		return backup_file;
	}
	
	public void init_bfp (string directory) {
		try {
			bfp_file = new BirdFontPart (this);
			bfp_file.create_directory (directory);
			bfp_file.save ();
			this.bfp = true;
			Preferences.add_recent_files (bfp_file.get_path ());
		} catch (GLib.Error e) {
			warning (e.message);
			// FIXME: notify user
		}
	}

	public void set_bfp (bool bfp) {
		this.bfp = bfp;
	}

	public bool is_bfp () {
		return bfp;
	}
	
	public void save () {
		if (is_bfp ()) {
			save_bfp ();
		} else {
			save_bf ();
		}
	}
	
	public bool save_bfp () {
		return bfp_file.save ();
	}
	
	public void save_bf () {
		Font font;
		BirdFontFile birdfont_file = new BirdFontFile (this);
		string path;
		bool file_written;
		
		if (font_file == null) {
			warning ("File name not set.");
			return;
		}
		
		path = (!) font_file;
		file_written = birdfont_file.write_font_file (path);

		if (read_only) {
			warning (@"$path is write protected.");
			TooltipArea.show_text (t_("The file is write protected."));
			return;			
		}
				
		if (!path.has_suffix (".bf")) {
			warning ("Expecting .bf format.");
			return;
		}
		
		if (file_written) {
			// delete the backup when the font is saved
			font = BirdFont.get_current_font ();
			font.delete_backup ();
		}
		
		modified = false;
		Preferences.add_recent_files (get_path ());
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

	public void set_file (string path, bool recent = true) {
		font_file = path;
	}

	public bool load () {
		string path;
		bool loaded = false;
		
		initialised = true;
		otf_font = false;

		if (font_file == null) {
			warning ("No file name.");
			return false;
		}

		path = (!) font_file;

		grid_width.clear ();
	
		// empty cache and fill it with new glyphs from disk
		glyph_cache.remove_all ();
		glyph_name.remove_all ();
		ligature.remove_all ();
		
		if (path.has_suffix (".svg")) {
			Toolbox.select_tool_by_name ("cubic_points");
			loaded = parse_svg_file (path);
					
			if (!loaded) {
				warning ("Failed to load SVG font.");
			}
			
			format = FontFormat.SVG;
		}
		
		if (path.has_suffix (".ffi")) {
			loaded = parse_bf_file (path);
			format = FontFormat.FFI;
		}

		if (path.has_suffix (".bf")) {
			loaded = parse_bf_file (path);
			format = FontFormat.BIRDFONT;
		}

		if (path.has_suffix (".bfp")) {
			loaded = parse_bfp_file (path);
			format = FontFormat.BIRDFONT_PART;
		}		
		
		if (path.has_suffix (".ttf")) {
			loaded = parse_freetype_file (path);
			
			if (!loaded) {
				warning ("Failed to load TTF font.");
			}
			
			format = FontFormat.FREETYPE;
			
			// run the old parser for debugging puposes
			if (BirdFont.has_argument ("--test")) {
				try {
					OpenFontFormatReader or = new OpenFontFormatReader ();
					or.parse_index (path);
				} catch (GLib.Error e) {
					warning (e.message);
				}
			}
			
			font_file = null; // make sure BirdFont asks where to save the file
		}			

		if (path.has_suffix (".otf")) {
			loaded = parse_freetype_file (path);
						
			if (!loaded) {
				warning ("Failed to load OTF font.");
			}
			
			format = FontFormat.FREETYPE;
			
			font_file = null;
		}	

		Preferences.add_recent_files (get_path ());
		
		return loaded;
	}
	
	private bool parse_bfp_file (string path) {
		return bfp_file.load (path);
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

	public bool parse_otf_file (string path) throws GLib.Error {
		otf = new OpenFontFormatReader ();
		otf_font = true;
		otf.parse_index (path);
		return true;
	}

	public void set_read_only (bool r) {
		read_only = r;
	}

	public static unichar to_unichar (string unicode) {
		int index = 2;
		int i = 0;
		unichar c;
		unichar rc = 0;
		bool r;
		
		if (unlikely (!unicode.has_prefix ("U+") && !unicode.has_prefix ("u+"))) {
			warning (@"All unicode values must begin with U+ ($unicode)");
			return '\0';
		}
		
		try {
			while (r = unicode.get_next_char (ref index, out c)) {
				rc <<= 4;
				rc += hex_to_oct (c);
				
				if (++i > 6) {
					throw new ConvertError.FAILED ("i > 6");
				}
			}
		} catch (ConvertError e) {
			warning (@"unicode: $unicode\n");
			warning (e.message);
			rc = '\0';
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

	private static uint8 hex_to_oct (unichar o) 
	throws ConvertError {
		StringBuilder s = new StringBuilder ();
		s.append_unichar (o);
	
		switch (o) {
			case 'a': return 10;
			case 'b': return 11;
			case 'c': return 12;
			case 'd': return 13;
			case 'e': return 14;
			case 'f': return 15;
			case 'A': return 10;
			case 'B': return 11;
			case 'C': return 12;
			case 'D': return 13;
			case 'E': return 14;
			case 'F': return 15;
		}
		
		if (!('0' <= o <= '9')) {
			throw new ConvertError.FAILED (@"Expecting a number ($(s.str)).");
		}
		
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
