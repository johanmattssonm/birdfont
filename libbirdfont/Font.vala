/*
	Copyright (C) 2012 2013 2014 2015 Johan Mattsson

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
	
	/** List of alternate glyphs. */
	public AlternateSets alternates;
	
	public Gee.ArrayList<BackgroundImage> background_images;
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
	
	/** Custom guides. */
	public Gee.ArrayList<Line> custom_guides = new Gee.ArrayList<Line> ();
	
	public string? font_file = null;
	
	bool modified = false;
	
	// name table strings
	public string postscript_name;
	public string name;
	public string subfamily;
	public string full_name;
	public string unique_identifier;
	public string version;
	public string description;
	public string copyright;
	public string license;
	public string license_url;
	public string trademark;
	public string manufacturer;
	public string designer;
	public string vendor_url;
	public string designer_url;

	public bool bold = false;
	public bool italic = false;
	public int weight = 400;

	public bool initialised = true;

	OpenFontFormatReader otf;
	bool otf_font = false;

	/** Grid sizes. */
	public Gee.ArrayList<string> grid_width;
	
	/** File format. */
	public FontFormat format = FontFormat.BIRDFONT;
	
	public SpacingData spacing;
	
	bool read_only = false;
	
	/** Save font as many small .bfp files instead of one big .bf file */
	bool bfp = false;
	BirdFontPart bfp_file;
	
	/** File names of deleted glyphs in bfp directories. */
	public Gee.ArrayList<string> deleted_glyphs;

	public Ligatures ligature_substitution;
	
	public static string? default_license = null; 
	public static string? default_license_url = null; 
	
	public FontSettings settings;
	public KerningStrings kerning_strings;
	
	public signal void font_deleted ();
	
	public static Font empty;
	
	public int format_major = 0;
	public int format_minor = 0;
	
	public int units_per_em = 1024;

	public Font () {
		KerningClasses kerning_classes;
		
		postscript_name = "Typeface";
		name = "Typeface";
		subfamily = "Regular";
		full_name = "Typeface";
		unique_identifier = "Typeface";
		version = "Version 1.0";
		description = "";
		copyright = "";
		license = "";
		license_url = "";
		trademark = "";
		manufacturer = "";
		designer = "";
		vendor_url = "";
		designer_url = "";
			
		if (default_license != null) {
			copyright = (!) default_license;
			license = (!) default_license;
		}

		if (default_license_url != null) {
			license_url = (!) default_license_url;
		}
				
		glyph_cache = new GlyphTable ();
		glyph_name = new GlyphTable ();
		ligature = new GlyphTable ();
	
		grid_width = new Gee.ArrayList<string> ();
	
		kerning_classes = new KerningClasses (this);
		spacing = new SpacingData (kerning_classes);

		top_limit = 84 ;
		top_position = 72;
		xheight_position = 56;
		base_line = 0;
		bottom_position = -20;
		bottom_limit = -27;
		
		bfp_file = new BirdFontPart (this);
		
		deleted_glyphs = new Gee.ArrayList<string> ();
		ligature_substitution = new Ligatures (this);
		
		background_images = new Gee.ArrayList<BackgroundImage> ();
		
		settings = new FontSettings ();
		kerning_strings = new KerningStrings ();
		
		alternates = new AlternateSets ();
	}

	~Font () {
		font_deleted ();
	}

	public void add_default_characters () {
		add_glyph_collection (get_notdef_character ());
		add_glyph_collection (get_space ());
	}
	
	public Alternate? get_alternate (string glyph_name, string tag) {
		Gee.ArrayList<Alternate> alt = alternates.get_alt (tag);
		
		foreach (Alternate a in alt) {
			if (a.glyph_name == glyph_name) {
				return a;
			}
		}
		
		return null;
	}

	public void add_new_alternate (GlyphCollection glyph,
		GlyphCollection alternate, string tag) {

		Alternate  a;
		Alternate? alt = get_alternate (glyph.get_name (), tag);
		
		if (alt == null) {
			a = new Alternate (glyph.get_name (), tag);
			alternates.add (a);
		} else {
			a = (!) alt;
		}
		
		a.add (alternate.get_name ());
		glyph_name.insert (alternate.get_name (), alternate);
		glyph_cache.insert (alternate.get_name (), alternate);
	}

	public void add_alternate (string glyph_name, string alternate, 
		string tag) {
			
		Alternate  a;
		Alternate? alt = get_alternate (glyph_name, tag);
		
		if (alt == null) {
			a = new Alternate (glyph_name, tag);
			alternates.add (a);
		} else {
			a = (!) alt;
		}
		
		a.add (alternate);
	}

	public bool has_compatible_format () {
		return !newer_format () && !older_format ();
	}

	public bool older_format () {
		if (format_major < BirdFontFile.MIN_FORMAT_MAJOR) {
			return true;
		}

		if (format_major == BirdFontFile.MIN_FORMAT_MAJOR 
			&& format_minor < BirdFontFile.MIN_FORMAT_MINOR) {
			return true;
		}
		
		return false;
	}
		
	public bool newer_format () {
		if (format_major > BirdFontFile.FORMAT_MAJOR) {
			return true;
		}
		
		if (BirdFontFile.FORMAT_MAJOR == format_major 
			&& format_minor > BirdFontFile.FORMAT_MINOR) {
			return true;
		}
		
		return false;
	}

	public static void set_default_license (string license, string url) {
		default_license = license;
		default_license_url = url;
	}

	public Ligatures get_ligatures () {
		return ligature_substitution;
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
		return spacing.get_kerning_classes ();
	}

	public SpacingData get_spacing () {
		return spacing;
	}
		
	public File get_backgrounds_folder () {
		string fn = @"$(get_name ()) backgrounds";
		File f = get_child (BirdFont.get_settings_directory (), fn);
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
		File file;
		
		if (font_file != null) {
			fn = (!) font_file;
			
			// assume only absolute paths are used on windows
			if (BirdFont.win32) {
				return fn;
			} else {
				file = File.new_for_path (fn);
				return (!) file.resolve_relative_path ("").get_path ();
			}
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
	
	/** @return an absolute path to the font folder. */
	public File get_folder () {
		string p = get_folder_path ();
		File fp = File.new_for_path (p);
		
		if (BirdFont.win32) {
			if (p.index_of (":\\") == -1) {
				p = (!) fp.resolve_relative_path ("").get_path ();
			}
		} else {
			if (!p.has_prefix ("/")) {
				p = (!) fp.resolve_relative_path ("").get_path ();
			}
		}
		
		return File.new_for_path (p);
	}
	
	/** @return a path to the font folder, it can be relative. */
	public string get_folder_path () {
		string p = get_path ();
		int i = p.last_index_of ("/");
		
		if (i == -1) {
			i = p.last_index_of ("\\");
		}
		
		if (i == -1) {
			warning (@"Can not find folder in $p.");
			p = ".";
		} else {
			p = p.substring (0, i);
		}
			
		if (p.index_of (":") != -1 && p.char_count () == 2) {
			p += "\\";
		}
		
		return p;
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

	public GlyphCollection get_nonmarking_return () {
		Glyph g;
		GlyphCollection gc;
		GlyphCollection? non_marking;
		
		if (has_glyph ("nonmarkingreturn")) {
			non_marking = get_glyph_collection ("nonmarkingreturn");
			
			if (non_marking == null) {
				warning ("Non marking return not created.");
			} else {
				return (!)non_marking;
			}
		}
		
		gc = new GlyphCollection ('\r', "nonmarkingreturn");
		
		g = new Glyph ("nonmarkingreturn", '\r');
		g.left_limit = 0;
		g.right_limit = 0;
		g.remove_empty_paths ();
		
		gc.set_unassigned (false);
		
		GlyphMaster master = new GlyphMaster ();
		master.add_glyph (g);
		gc.add_master (master);
		
		return gc;
	}
		
	public GlyphCollection get_null_character () {
		Glyph n;
		GlyphCollection gc;
		GlyphCollection? none;		
		
		if (has_glyph ("null")) {
			none = get_glyph_collection ("null");
			
			if (none == null) {
				warning("Null character not created.");
			} else {
				return (!) none;
			}
		}
		
		gc = new GlyphCollection ('\0', "null");
		n = new Glyph ("null", '\0');
		
		GlyphMaster master = new GlyphMaster ();
		master.add_glyph (n);
		gc.add_master (master);

		gc.set_unassigned (false);
		
		n.left_limit = 0;
		n.right_limit = 0;
		n.remove_empty_paths ();
		
		return gc;
	}
	
	public GlyphCollection get_space () {
		Glyph n;
		GlyphCollection gc;		
		GlyphCollection? space = null;
		
		if (has_glyph (" ")) {
			space = get_glyph_collection (" ");
		}

		if (has_glyph ("space")) {
			space = get_glyph_collection ("space");
		}

		if (space != null) {
			return (!) space;			
		}
		
		gc = new GlyphCollection (' ', "space");
			
		n = new Glyph (" ", ' ');
		n.left_limit = 0;
		n.right_limit = 27;
		n.remove_empty_paths ();
		
		GlyphMaster master = new GlyphMaster ();
		master.add_glyph (n);
		gc.add_master (master);
		
		gc.set_unassigned (false);
		
		return gc;		
	}
	
	public GlyphCollection get_notdef_character () {
		Glyph g;
		GlyphCollection gc;

		Path p;
		Path i;
		
		if (has_glyph (".notdef")) {
			return (!) get_glyph_collection (".notdef");
		}
		
		gc = new GlyphCollection ('\0', ".notdef");
		g = new Glyph (".notdef", 0);
		p = new Path ();
		i = new Path ();
		
		gc.set_unassigned (true);
		
		GlyphMaster master = new GlyphMaster ();
		master.add_glyph (g);
		gc.add_master (master);
		
		g.left_limit = -20;
		g.right_limit = 33;
		
		g.add_help_lines ();
		
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

		i.recalculate_linear_handles ();
		p.recalculate_linear_handles ();

		return gc;
	}

	public void add_glyph_collection (GlyphCollection glyph_collection) {
		GlyphCollection? gc;
		
		if (unlikely (glyph_collection.get_name () == "")) {
			warning ("Refusing to add glyph with name \"\", null character should be named null.");
			return;
		}
		
		gc = glyph_name.get (glyph_collection.get_name ());
		if (unlikely (gc != null)) {
			GlyphCollection added_glyph = (!) gc;
			warning (@"glyph has already been added $(added_glyph.get_name ())");
			return;
		}
	
		glyph_name.insert (glyph_collection.get_name (), glyph_collection);			
		
		if (glyph_collection.get_unicode () !=  "") {
			glyph_cache.insert ((!) glyph_collection.get_unicode (), glyph_collection);
		} else {
			glyph_cache.insert ((!) glyph_collection.get_name (), glyph_collection);
		}
		
		if (glyph_collection.is_unassigned ()) {
			ligature.insert (glyph_collection.get_name (), glyph_collection);
		}
	}
	
	public static string get_name_for_character (unichar c) {
		StringBuilder sb;
		
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
		glyph_cache.remove (glyph.get_name ());
		glyph_name.remove (glyph.get_name ());
		ligature.remove (glyph.get_current ().get_name ());
		
		foreach (Alternate a in alternates.alternates) {
			a.remove (glyph);
		}
		
		foreach (GlyphMaster master in glyph.glyph_masters) {
			foreach (Glyph g in master.glyphs) {
				add_deleted_glyph (g, master);
			}
		}
	}
	
	public void add_deleted_glyph (Glyph g, GlyphMaster master) {
		string file_name;
		file_name = BirdFontPart.get_glyph_base_file_name (g, master) + ".bfp";
		deleted_glyphs.add (file_name);		
	}

	// FIXME: the order of ligature substitutions
	public GlyphCollection? get_ligature (uint index) {
		return ligature.nth (index);
	}
	
	/** Obtain all versions and alterntes for this glyph. */
	public GlyphCollection? get_glyph_collection (string unichar_code) {
		GlyphCollection? gc = null;
		gc = glyph_cache.get (unichar_code);
		return gc;
	}

	/** Get glyph collection by name. */
	public GlyphCollection? get_glyph_collection_by_name (string? glyph) {
		GlyphCollection? gc = null;
		
		if (glyph != null) {
			gc = glyph_name.get ((!) glyph);
		}
		
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
		
	public Glyph? get_glyph (string name) {
		GlyphCollection? gc = null;
		gc = glyph_name.get (name);

		if (gc == null || ((!)gc).length () == 0) {
			return null;
		}
		
		return ((!)gc).get_current ();
	}
	
	public GlyphCollection? get_glyph_collection_index (unichar glyph_index) {
		if (!(0 <= glyph_index < glyph_name.length ())) {
			return null;
		}
		
		return glyph_name.nth (glyph_index);
	}
	
	public Glyph? get_glyph_index (unichar glyph_index) {
		GlyphCollection? gc;
		
		gc = get_glyph_collection_index (glyph_index);
		
		if (gc != null) {
			return ((!) gc).get_current ();
		}
		
		return null;
	}
	
	public void add_background_image (BackgroundImage image) {
		background_images.add (image);
	}
	
	/** Delete temporary rescue files. */
	public void delete_backup () {
		File dir = BirdFont.get_backup_directory ();
		File? new_file = null;
		File file;
		string backup_file;
		
		new_file = get_child (dir, @"$(name).bf");
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

		temp_file = get_child (dir, @"$(name).bf");
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
		
		settings.save (get_file_name ());
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
	}

	public void set_font_file (string path) {
		font_file = path;
		modified = false;
	}

	/** Number of glyphs in this font. */
	public uint length () {
		return glyph_name.length ();
	}

	public bool is_empty () {
		return (glyph_name.length () == 0);
	}

	public void set_file (string path) {
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
		
		if (path.has_suffix (".svg") || path.has_suffix (".SVG")) {
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

		if (path.has_suffix (".bf") || path.has_suffix (".BF")) {
			loaded = parse_bf_file (path);
			format = FontFormat.BIRDFONT;
		}

		if (path.has_suffix (".bfp") || path.has_suffix (".BFP")) {
			loaded = parse_bfp_file (path);
			format = FontFormat.BIRDFONT_PART;
		}		
		
		if (path.has_suffix (".ttf") || path.has_suffix (".TTF")) {
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

		if (path.has_suffix (".otf") || path.has_suffix (".OTF")) {
			loaded = parse_freetype_file (path);
						
			if (!loaded) {
				warning ("Failed to load OTF font.");
			}
			
			format = FontFormat.FREETYPE;
			
			font_file = null;
		}
		
		if (loaded) {
			settings.load (get_file_name ());
			kerning_strings.load (this);
			add_default_characters ();
		}
		
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
		
		if (!parsed) {
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

	/** 
	 * @param glyphs Name of glyphs or unicode values separated by space.
	 * @return glyph names
	 */
	public Gee.ArrayList<string> get_names (string glyphs) {
		 return get_names_order (glyphs, false);
	}

	public Gee.ArrayList<string> get_names_in_reverse_order (string glyphs) {
		return get_names_order (glyphs, true);
	}
		
	public Gee.ArrayList<string> get_names_order (string glyphs, bool reverse) {
		Gee.ArrayList<string> names = new Gee.ArrayList<string> ();
		string[] parts = glyphs.strip ().split (" ");
								
		foreach (string p in parts) {		
			if (p.has_prefix ("U+") || p.has_prefix ("u+")) {
				p = (!) to_unichar (p).to_string ();
			}
			
			if (p == "space") {
				p = " ";
			}

			if (p == "divis") {
				p = "-";
			}
			
			if (!has_glyph (p)) {
				warning (@"The character $p does not have a glyph in " + get_file_name ());
				p = ".notdef";
			}
			
			if (p != "") {
				if (reverse) {
					names.insert (0, p);
				} else {
					names.add (p);
				}
			}
		}
		
		return names;
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
