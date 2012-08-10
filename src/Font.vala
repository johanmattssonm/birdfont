/*
    Copyright (C) 2012 Johan Mattsson

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

using Cairo;
using Xml;

namespace Supplement {

class Font : GLib.Object {
	
	GlyphTable glyph_cache = new GlyphTable ();
	
	/** Glyphs that not are tied to a unichar value. */
	GlyphTable unassigned_glyphs = new GlyphTable ();

	List<string> glyph_names = new List<string> ();

	/** Last unassigned index */
	int next_unindexed = 0;
		
	public HashTable <string, Kerning> kerning = new HashTable <string, Kerning> (str_hash, str_equal);
	
	public List <string> background_images = new List <string> ();
	
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
	
	/** Bottom margon */
	public double bottom_limit;
	
	public string? backup_file = null;
	public string? font_file = null;
	
	bool modified = false;
	
	private string name = "typeface";
	
	bool ttf_export = true;
	bool svg_export = true;

	bool loading = false;
	OpenFontFormatReader otf;
	
	public Font () {
		// positions in pixels at first zoom level
		// default x-height should be 60 in 1:1
		top_limit = -66 * Glyph.SCALE;
		top_position = -54 * Glyph.SCALE;
		xheight_position = -38 * Glyph.SCALE;
		base_line = 18 * Glyph.SCALE;
		bottom_position = 38 * Glyph.SCALE;
		bottom_limit = 45 * Glyph.SCALE;
	}

	public void touch () {
		modified = true;
	}

	public bool get_ttf_export () {
		return ttf_export;
	}

	public bool get_svg_export () {
		return svg_export;
	}

	public void set_ttf_export (bool d) {
		ttf_export = d;
	}

	public void set_svg_export (bool d) {
		svg_export = d;
	}

	public File get_backgrounds_folder () {
		string fn = @"$(get_name ()) backgrounds";
		File f = Supplement.get_settings_directory ().get_child (fn);
		return f;
	}

	public uint get_length () {
		return glyph_names.length ();
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
		sb.append (@"/$(get_name ()).ffi");
		
		File f = File.new_for_path (sb.str);

		while (f.query_exists ()) {
			sb.erase ();
			sb.append (Environment.get_home_dir ());
			sb.append (@"/$(get_name ())$(++i).ffi");
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
	
	bool is_valid_thumbnail (Glyph? g) {
		Glyph glyph;
		double x1, x2, y1, y2;

		if (g == null) {
			return false;
		}
		
		glyph = (!) g;
		
		glyph.boundries (out x1, out y1, out x2, out y2);
		
		if (x1 < -120) return false;
		if (x2 > 120) return false;
		if (y1 < -76) return false;
		if (y2 > 76) return false;
		
		if (x1 == 0 && x2 == 0 && y1 == 0 && y2 == 0) return false;
		
		return true;
	}
	
	public double get_height () {
		double r = base_line - top_position;
		return (r > 0) ? r : -r;
	}
		
	public void set_name (string name) {
		this.name = name;
	}
	
	public string get_name () {
		return name;
	}

	public GlyphRange get_available_glyph_ranges () {
		GlyphRange gr = new GlyphRange ();
		gr.unassigned = glyph_names;
		return gr;
	}

	public void print_all () {
		stdout.printf ("Assigned:\n");		
		glyph_cache.for_each((g) => {
			stdout.printf (@"$(g.get_name ())\n");
		});

		stdout.printf ("\n");
		stdout.printf ("Unssigned:\n");		
		unassigned_glyphs.for_each ((g) => {
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
				
		ret = new Glyph ("nonmarkingreturn");
		ret.set_unassigned (true);
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
		
		n = new Glyph ("null");
		n.set_unassigned (true);
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
				
		n = new Glyph ("space");
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
		
		if (has_glyph ("notdef")) {
			return (!) get_glyph ("notdef");
		}
		
		g = new Glyph ("notdef", 0);
		p = new Path ();
		i = new Path ();
		
		g.set_unassigned (true);
		g.left_limit = -33;
		g.right_limit = 33;
		
		p.add (-20, 20);
		p.add (20, 20);
		p.add (20, -20);
		p.add (-20, -20);
		p.close ();
		
		i.add (-15, 15);
		i.add (15, 15);
		i.add (15, -15);
		i.add (-15, -15);
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
		GlyphCollection? gc = get_cached_glyph_collection (glyph_collection.get_name ());
		unowned List<string>? nl;
		
		print (@"Adding: $(glyph_collection.get_name ())\n");
		
		if (glyph_collection.get_name () == "") {
			warning ("Refusing to insert glyph with name \"\", null character should be named null.");
			return;
		}
		
		if (gc != null) {
			warning ("glyph has already been added");
			return;
		}
		
		if (glyph_collection.get_current ().is_unassigned ()) {
			unassigned_glyphs.insert (glyph_collection);
		} else {
			glyph_cache.insert (glyph_collection);
		}

		if (!has_name (glyph_collection.get_name ())) {
			glyph_names.append (glyph_collection.get_name ());
			glyph_names.sort (strcmp);
		}
	}
	
	bool has_name (string name) {
		foreach (string n in glyph_names) {
			if (n == name) {
				return true;
			}
		}
		
		return false;
	}
	
	public void delete_glyph (string glyph) {
		glyph_names.remove_all (glyph);
		glyph_cache.remove (glyph);
	}
	
	/** Obtain all versions and alterntes for this glyph. */
	public GlyphCollection? get_glyph_collection (string glyph) {
		GlyphCollection? gc = get_cached_glyph_collection (glyph);
		Glyph? g;
		
		if (gc == null) {
			// load it from otf file if we need to
			g = otf.read_glyph (glyph);
			
			if (g != null) {
				add_glyph_callback ((!) g);
				return get_cached_glyph_collection (glyph);
			}
		}
			
		return gc;
	}

	public GlyphCollection? get_cached_glyph_collection (string glyph) {
		GlyphCollection? gc = null;
		Glyph? new_glyph;
		
		gc = glyph_cache.get (glyph);
		
		if (gc == null) {
			gc = unassigned_glyphs.get (glyph);
		}
		
		return gc;
	}
	
	public Glyph? get_glyph_from_unichar (unichar glyph) {
		StringBuilder name = new StringBuilder ();
		name.append_unichar (glyph);
		return get_glyph (name.str);
	}
	
	public Glyph? get_glyph (string glyph) {
		GlyphCollection? gc = get_glyph_collection (glyph);
		
		if (gc == null) {
			return null;
		}
		
		return ((!)gc).get_current ();
	}
	
	public Glyph? get_glyph_indice (unichar glyph_indice) {
		GlyphCollection? gc;
		string n;
		
		if (!(0 <= glyph_indice < glyph_names.length ())) {
			warning ("glyph_indice is out of range");
			return null;
		}
		
		n = glyph_names.nth (glyph_indice).data;
		gc = get_glyph_collection (n);
		
		if (gc != null) {
			return ((!) gc).get_current ();
		}
		
		return null;
	}
	
	public void add_background_image (string file) {
		background_images.append (file);
	}

	public double get_kerning (string a, string b) {
		Kerning? kern;
		StringBuilder key = new StringBuilder ();
		
		key.append (a);
		key.append (b);
		
		kern = kerning.lookup (key.str);
		
		if (kern != null) {
			return ((!) kern).val;
		}
		
		return 0;
	}

	public void set_kerning (string a, string b, double val) {
		Kerning? kern;
		Kerning k;
		StringBuilder key = new StringBuilder ();
		
		key.append (a);
		key.append (b);
		
		kern = kerning.lookup (key.str);
		
		if (kern != null) {
			k = (!) kern;
			k.val = val;
		} else {
			k = new Kerning (a, b, val);
			kerning.insert (key.str, k);
		}
	}
		
	public void save_backup () {
		File dir = Supplement.get_backup_directory ();
		File temp_file;
		int i = 0;

		if (backup_file == null) {
			temp_file = dir.get_child (@"current_font_$i.ffs");
			
			while (temp_file.query_exists ()) {
				i++;
				temp_file = dir.get_child (@"current_font_$i.ffs");
			}
			
			backup_file = temp_file.get_path ();
		}
		
		write_font_file ((!) backup_file);
	}
	
	public bool save (string path) {
		bool r = write_font_file (path);
		
		if (r) {
			font_file = path;
		}
		
		modified = false;
		add_thumbnail ();
		Preferences.add_recent_files (get_path ());
		
		return r;
	}

	public bool write_font_file (string path) {
		try {
			File file = File.new_for_path (path);

			if (file.query_file_type (0) == FileType.DIRECTORY) {
				stderr.printf (@"Can not save font. $path is a directory.");
				return false;
			}
			
			if (file.query_exists ()) {
				file.delete ();
			}
			
			DataOutputStream os = new DataOutputStream(file.create(FileCreateFlags.REPLACE_DESTINATION));
			
			os.put_string ("""<?xml version="1.0" encoding="utf-8" standalone="yes"?>""");
			os.put_string ("\n");
				
			os.put_string ("<font>\n");
			
			os.put_string ("\n");
			os.put_string (@"<name>$(get_name ())</name>\n");
			
			os.put_string ("\n");
			os.put_string (@"<ttf-export>$(ttf_export)</ttf-export>\n");

			os.put_string ("\n");
			os.put_string (@"<svg-export>$(svg_export)</svg-export>\n");
			
			os.put_string ("\n");
			os.put_string ("<lines>\n");
			
			os.put_string (@"\t<top_limit>$top_limit</top_limit>\n");
			os.put_string (@"\t<top_position>$top_position</top_position>\n");
			os.put_string (@"\t<x-height>$xheight_position</x-height>\n");
			os.put_string (@"\t<base_line>$base_line</base_line>\n");
			os.put_string (@"\t<bottom_position>$bottom_position</bottom_position>\n");
			os.put_string (@"\t<bottom_limit>$bottom_limit</bottom_limit>\n");
			
			os.put_string ("</lines>\n\n");

			foreach (SpinButton s in GridTool.sizes) {
				os.put_string (@"<grid width=\"$(s.get_display_value ())\"/>\n");
			}
			
			if (GridTool.sizes.length () > 0) {
				os.put_string ("\n");
			}
			
			os.put_string (@"<background scale=\"$(MainWindow.get_toolbox ().background_scale.get_display_value ())\" />\n");
			os.put_string ("\n");
			
			if (background_images.length () > 0) {
				os.put_string (@"<images>\n");
				
				foreach (string f in background_images) {
					os.put_string (@"\t<img src=\"$f\"/>\n");
				}
			
				os.put_string (@"</images>\n");
				os.put_string ("\n");
			}
			
			glyph_cache.for_each ((gc) => {
				try {
					bool selected;
					foreach (Glyph g in gc.get_version_list ().glyphs) {
						selected = (g == gc.get_current ());
						write_glyph (g, selected, os);
					}
				} catch (GLib.Error ef) {
					stderr.printf (@"Failed to save $path \n");
					stderr.printf (@"$(ef.message) \n");
				}
			});
		
			// FIXME: implement kerning in webkit 
			kerning.for_each ((key, kern) => {
				try {
					string l = to_hex (kern.left.get_char (0));
					string r = to_hex (kern.right.get_char (0));
					
					os.put_string (@"<hkern left=\"$l\" right=\"$r\" kerning=\"$(kern.val)\"/>\n");
				} catch (GLib.Error ef) {
					stderr.printf (@"Failed to save $path \n");
					stderr.printf (@"$(ef.message) \n");
				}
			});
						
			os.put_string ("</font>");
			
		} catch (GLib.Error e) {
			stderr.printf (@"Failed to save $path \n");
			stderr.printf (@"$(e.message) \n");
			return false;
		}
		
		return true;
	}

	private void write_glyph (Glyph g, bool selected, DataOutputStream os) throws GLib.Error {
		os.put_string (@"<glyph unicode=\"$(to_hex (g.unichar_code))\" selected=\"$selected\" left=\"$(g.left_limit)\" right=\"$(g.right_limit)\">\n");

		foreach (var p in g.path_list) {
			if (p.points.length () == 0) {
				continue;
			}
			
			os.put_string ("\t<object>");

			foreach (var ep in p.points) {
				os.put_string (@"<point x=\"$(ep.x)\" y=\"$(ep.y)\" ");
				
				if (ep.right_handle.type == PointType.CURVE) {
					os.put_string (@"right_angle=\"$(ep.right_handle.angle)\" ");
					os.put_string (@"right_length=\"$(ep.right_handle.length)\" ");
				}
				
				if (ep.left_handle.type == PointType.CURVE) {
					os.put_string (@"left_angle=\"$(ep.left_handle.angle)\" ");
					os.put_string (@"left_length=\"$(ep.left_handle.length)\" ");						
				}
				
				if (ep.right_handle.type == PointType.CURVE || ep.left_handle.type == PointType.CURVE) {
					os.put_string (@"tie_handles=\"$(ep.tie_handles)\" ");
				}
				
				os.put_string ("/>");
				
			}
			
			os.put_string ("</object>\n");
		}
		
		GlyphBackgroundImage? bg = g.get_background_image ();
		
		if (bg != null) {
			GlyphBackgroundImage background_image = (!) bg;

			double off_x = background_image.img_offset_x;
			double off_y = background_image.img_offset_y;
			
			double scale_x = background_image.img_scale_x;
			double scale_y = background_image.img_scale_y;
			
			double rotation = background_image.img_rotation;
			
			os.put_string (@"\t<background src =\"$(background_image.get_path ())\" offset_x=\"$off_x\" offset_y=\"$off_y\" scale_x=\"$scale_x\" scale_y=\"$scale_y\" rotation=\"$rotation\"/>\n");
		}
		
		os.put_string ("</glyph>\n\n"); 

	}

	public void set_font_file (string path) {
		font_file = path;
		modified = false;
	}

	public uint length () {
		return glyph_names.length ();
	}

	public bool is_empty () {
		return (glyph_names.length () == 0);
	}

	public bool load (string path) {
		bool loaded = false;
		set_font_file (path);
		
		if (path.has_suffix (".ffi")) {
			loaded = parse_file (path);
		}
		
		if (path.has_suffix (".ttf")) {
			loaded = parse_otf_file (path);
		}
		
		return loaded;
	}

	private void add_thumbnail () {
		File f = Supplement.get_thumbnail_directory ().get_child (@"$((!) get_file_name ()).png");
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

	/** Callbackt function for finishing parsing of font file. */ 
	public void loading_finished_callback () {
		add_thumbnail ();
		Preferences.add_recent_files (get_path ());
		loading = false;
		print ("Done Loading.\n");
	}

	/** Callback function for loading glyph in a separate thread. */
	public void add_glyph_callback (Glyph g) {
		GlyphCollection? gcl;
		GlyphCollection gc;
		
		gcl = get_cached_glyph_collection (g.get_name ());
		
		if (gcl != null) {
			warning (@"glyph \"$(g.get_name ())\" does already exist");
		}
		
		if (g.is_unassigned ()) {
			gc = new GlyphCollection (g);
			
			if (g.name == "") {
				warning ("refusing to insert glyph without name");
				g.name = @"($(++next_unindexed))";
				return;
			}
			
			// del: print (@"added name: $(g.name)\n");
			
			add_glyph_collection ((!) gc);
		} else if (gcl == null) {
			gc = new GlyphCollection (g);
			add_glyph_collection ((!) gc);
		} else {
			stderr.printf (@"Glyph collection does already have an entry for $(g.get_name ()) char $((uint64) g.unichar_code).\n");
			gc = new GlyphCollection (g);
			g.name = @"($(++next_unindexed))";
			add_glyph_collection ((!) gc);
		}
				
		// take xheight from appropriate lower case letter
		// xheight_position = estimate_xheight ();
	}

	public bool parse_otf_file (string path) {
		otf = new OpenFontFormatReader ();
		loading = true;
		
		while (glyph_names.length () > 0) {
			glyph_names.remove_link (glyph_names.first ());
		}
		
		glyph_cache.remove_all ();
		unassigned_glyphs.remove_all ();
		
		font_file = path;
		
		otf.parse_index (path);
		
		foreach (string n in otf.get_all_names ()) {
			glyph_names.append (n);
		}
				
		/*
		ThreadFunc<void*> run = () => {
			string file = (!) font_file;

			try {
				parse_otf_async ((!) font_file);
			} catch (GLib.Error e) {
				stderr.printf (e.message);
			}

			return null;
		};
		
		try {
			Thread.create<void*> (run, false);
			yield;
		} catch (ThreadError e) {
			stderr.printf ("Thread error: %s\n", e.message);
		}
		*/
		return true;
	}
	
	void parse_otf_async (string fn) {
		// otf.parse (fn);
	}
	
	/** Measure height of x or other lower case letter. */
	private double estimate_xheight () {
		Glyph? g;
		double ym = 0;
		for (unichar c = 'x'; c >= 'a' ; c--) {
			g = get_glyph_from_unichar (c);
			
			// we want x-height skip letters with ascender
			if (c == 'l' || c == 'k' || c == 'i' 
				|| c == 'j' || c == 'h' || c == 'd') {
				continue;
			}
			
			if (g != null) {
				foreach (Path path in ((!) g).path_list) {
					path.update_region_boundries ();
					if (path.ymax > ym) {
						ym = path.ymax;
					}
				}
			} 
		}
		
		return -ym;
	}
	
	public bool parse_file (string path) {
		Parser.init ();
		
		Xml.Doc* doc = Parser.parse_file (path);
		Xml.Node* root = doc->get_root_element ();

		if (root == null) {
			delete doc;
			return false;
		}

		// set this path as file for this font
		font_file = path;
		
		// empty cache and fill it with new glyphs from disk
		glyph_cache.remove_all ();
		unassigned_glyphs.remove_all ();
		
		MainWindow.get_toolbox ().remove_all_grid_buttons ();
		while (background_images.length () > 0) {
			background_images.remove_link (background_images.first ());
		}

		Xml.Node* node = root;
		for (Xml.Node* iter = node->children; iter != null; iter = iter->next) {
		
			if (iter->name == "glyph") {
				parse_glyph (iter);
			}

			if (iter->name == "lines") {
				parse_font_boundries (iter);
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

			if (iter->name == "name") {
				name = iter->children->content;
			}

			if (iter->name == "hkern") {
				parse_kerning (iter);
			}

			if (iter->name == "ttf-export") {
				ttf_export = bool.parse (iter->children->content);
			}			

			if (iter->name == "svg-export") {
				svg_export = bool.parse (iter->children->content);
			}			
			
		}
    
		delete doc;
		Parser.cleanup ();

		loading_finished_callback ();
		return true;
	}
	
	private void parse_kerning (Xml.Node* node) {
		string attr_name;
		string attr_content;
		string left = "";
		string right = "";
		string kern = "";
		Kerning k;
		StringBuilder b;
		
		
		for (Xml.Attr* prop = node->properties; prop != null; prop = prop->next) {
			attr_name = prop->name;
			attr_content = prop->children->content;
			
			if (attr_name == "left") {
				b = new StringBuilder ();
				b.append_unichar (to_unichar (attr_content));
				left = @"$(b.str)";
			}

			if (attr_name == "right") {
				b = new StringBuilder ();
				b.append_unichar (to_unichar (attr_content));
				right = @"$(b.str)";
			}
			
			if (attr_name == "kerning") {
				kern = attr_content;
			}
		}
		
		k = new Kerning.from_attribute (left, right, kern);
		
		this.kerning.insert (@"$left$right", k);
	}
	
	private void parse_background (Xml.Node* node) {
		string attr_name;
		string attr_content;
				
		for (Xml.Attr* prop = node->properties; prop != null; prop = prop->next) {
			attr_name = prop->name;
			attr_content = prop->children->content;
			
			if (attr_name == "scale") {
				MainWindow.get_toolbox ().background_scale.set_value (attr_content);
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
						background_images.append (attr_content);
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
				MainWindow.get_toolbox ().parse_grid (attr_content);
			}
		}		
	}
	
	private void parse_font_boundries (Xml.Node* node) {
		for (Xml.Node* iter = node->children; iter != null; iter = iter->next) {
			if (iter->name == "top_limit") top_limit = parse_double_from_node (iter);
			if (iter->name == "top_position") top_position = parse_double_from_node (iter);
			if (iter->name == "x-heigh") xheight_position = parse_double_from_node (iter);
			if (iter->name == "base_line") base_line = parse_double_from_node (iter);
			if (iter->name == "bottom_position") bottom_position = parse_double_from_node (iter);
			if (iter->name == "bottom_limit") bottom_limit = parse_double_from_node (iter);
		}			
	}
	
	private double parse_double_from_node (Xml.Node* iter) {
		double d;
		bool r = double.try_parse (iter->children->content, out d);
		
		if (unlikely (!r)) {
			string? s = iter->content;
			if (s == null) warning (@"Content is null for node $(iter->name)\n");
			else warning (@"Failed to parse double for \"$(iter->content)\"\n");
		}
		
		return (r) ? d : 0;
	}
	
	/** Parse one glyph. */
	public void parse_glyph (Xml.Node* node) {
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
				uni = to_unichar (attr_content);
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
		
		// todo: use disk thread and idle add this:
		
		gc = get_glyph_collection (g.get_name ());
		
		if (g.get_name () == "") {
			warning ("No name set for glyph.");
		}
				
		if (gc == null) {
			gc = new GlyphCollection (g);
			add_glyph_collection ((!) gc);
		} else {
			((!)gc).insert_glyph (g, selected);
		}
		
	}
	
	/** Parse visual objects and paths */
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
		GlyphBackgroundImage img = new GlyphBackgroundImage ();
		
		string attr_name;
		string attr_content;
		
		for (Xml.Attr* prop = node->properties; prop != null; prop = prop->next) {
			attr_name = prop->name;
			attr_content = prop->children->content;
							
			if (attr_name == "src") {
				img = new GlyphBackgroundImage (attr_content);
				g.set_background_image (img);
			}
		}
	
		for (Xml.Attr* prop = node->properties; prop != null; prop = prop->next) {
			attr_name = prop->name;
			attr_content = prop->children->content;
							
			if (attr_name == "offset_x") {
				img.img_offset_x = double.parse (attr_content);
			}

			if (attr_name == "offset_y") {
				img.img_offset_y = double.parse (attr_content);
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
				
	}
	
	private void parse_point (Path p, Xml.Node* iter) {
		double x = 0;
		double y = 0;
		
		PointType type = PointType.LINE;
		
		double angle_right = 0;
		double angle_left = 0;
		
		double length_right = 0;
		double length_left = 0;
		
		PointType type_right = PointType.LINE;
		PointType type_left = PointType.LINE;
		
		bool tie_handles = false;
		
		EditPoint ep;
		
		for (Xml.Attr* prop = iter->properties; prop != null; prop = prop->next) {
			string attr_name = prop->name;
			string attr_content = prop->children->content;
						
			if (attr_name == "x") x = double.parse (attr_content);
			if (attr_name == "y") y = double.parse (attr_content);
			
			if (attr_name == "right_angle") {
				type = PointType.CURVE; // FIXA: delete, maybe
			}	
			
			if (attr_name == "right_angle") {
				type_right = PointType.CURVE;
			}	

			if (attr_name == "left_angle") {
				type_left = PointType.CURVE;
			}
						
			if (attr_name == "right_angle") angle_right = double.parse (attr_content);
			if (attr_name == "right_length") length_right = double.parse (attr_content);
			if (attr_name == "left_angle") angle_left = double.parse (attr_content);
			if (attr_name == "left_length") length_left = double.parse (attr_content);
			
			if (attr_name == "tie_handles") tie_handles = bool.parse (attr_content);
		}
		
		ep = new EditPoint (x, y);
		
		ep.type = type;
		
		ep.right_handle.angle = angle_right;
		ep.right_handle.length = length_right;
		ep.right_handle.type = type_right;
		
		ep.left_handle.angle = angle_left;
		ep.left_handle.length = length_left;
		ep.left_handle.type = type_left;
		
		ep.tie_handles = tie_handles;
		
		p.add_point (ep);
	}
	
	public bool restore_backup () {
		string? b = present_backup_file ();
		
		if (b == null) return false;
		
		return parse_file ((!)b);
	}
	
	private string? present_backup_file () {
		try {
			File dir = Supplement.get_settings_directory ();
			var files = dir.enumerate_children (FILE_ATTRIBUTE_STANDARD_NAME, 0);

			// What if we have more than one backup file left?
			FileInfo? file_info;
			while ((file_info = files.next_file ()) != null) {
				FileInfo fi = (!) file_info;
				if (fi.get_name ().index_of ("current_font_") != -1) {
					File f = dir.get_child (fi.get_name ());
					backup_file = f.get_path ();
					return backup_file;
				}
			}
		} catch (GLib.Error e) {
			stderr.printf (@"Failed to load backup\n");
			stderr.printf (@"$(e.message) \n");
		}
		
		return null;
	}
	
	/** Delete temporary rescue files. */
	public void delete_backup () {
		if (backup_file == null) return;

		try {
			File f = File.new_for_path ((!) backup_file);
			f.delete ();		
		} catch (GLib.Error e) {
			stderr.printf (@"Failed to delete backup\n");
			stderr.printf (@"$(e.message) \n");
		}

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

	public static unichar to_unichar (string unicode) {
		int index = 2;
		int i = 0;
		unichar c;
		unichar rc = 0;
		bool r;

		if (unlikely (unicode.index_of ("U+") != 0)) {
			warning ("All unicode values must begin with U+");
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

}

}
