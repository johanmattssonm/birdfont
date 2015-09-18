/*
    Copyright (C) 2015 Johan Mattsson

    This library is free software; you can redistribute it and/or modify 
    it under the terms of the GNU Lesser General Public License as 
    published by the Free Software Foundation; either version 3 of the 
    License, or (at your option) any later version.

    This library is distributed in the hope that it will be useful, but 
    WITHOUT ANY WARRANTY; without even the implied warranty of 
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU 
    Lesser General Public License for more details.
*/

using Gee;

[SimpleType]
[CCode (has_type_id = false)]
extern struct FcConfig {
}

[CCode (cname = "FcInitLoadConfigAndFonts")]
extern FcConfig* FcInitLoadConfigAndFonts ();

[CCode (cname = "find_font")]
extern string? find_font (FcConfig* font_config, string characters);

[CCode (cname = "find_font_file")]
extern string? find_font_file (FcConfig* font_config, string font_name);

namespace BirdFont {

// TODO: use font config
public class FallbackFont : GLib.Object {
	Gee.ArrayList<File> font_directories;
	
	FcConfig* font_config = null;
	FontFace* default_font = null;
	static bool font_config_stated = false;
	
	string default_font_file_name = "Roboto-Regular.ttf";
	string default_font_family_name = "Roboto";

	Gee.HashMap<unichar, CachePair> glyphs;
	Gee.ArrayList<CachePair> cached;

	public int max_cached_fonts = 300;
	
	public FallbackFont () {
		string home = Environment.get_home_dir ();
		
		font_directories = new Gee.ArrayList<File> ();

		if (!font_config_stated) {
			font_config_stated = true;
			
			IdleSource idle = new IdleSource ();
			idle.set_callback (() => {
				Task t = new Task ();
				t.task.connect (init_font_config);
				MainWindow.native_window.run_non_blocking_background_thread (t);
				return false;
			});
			idle.attach (null);
		}
		
		add_font_folder ("/usr/share/fonts/");
		add_font_folder ("/usr/local/share/fonts/");
		add_font_folder (home + "/.local/share/fonts");
		add_font_folder (home + "/.fonts");
		add_font_folder ("C:\\Windows\\Fonts");
		add_font_folder (home + "/Library/Fonts");
		add_font_folder ("/Library/Fonts");
		add_font_folder ("/Network/Library/Fonts");
		add_font_folder ("/System/Library/Fonts");
		add_font_folder ("/System Folder/Fonts");
		
		glyphs = new Gee.HashMap<unichar, CachePair> ();
		cached = new Gee.ArrayList<CachePair> ();
		
		open_default_font ();
	}
	
	~FallbackFont () {
		if (default_font != null) {
			close_font (default_font);
		}
	}

	public void init_font_config () {
		FcConfig* fc = FcInitLoadConfigAndFonts ();
		IdleSource idle = new IdleSource ();
		
		idle.set_callback (() => {
			font_config = fc;
			return false;
		});
		idle.attach (null);
	}

	public Font get_single_glyph_font (unichar c) {
		Font f;
		unichar last; 
		CachePair p;
		
		if (likely (glyphs.has_key (c))) {
			p = glyphs.get (c);
			
			if (p.referenced < int.MAX) {
				p.referenced++;
			}
			
			return p.font;
		}

		// remove glyphs from cache if it is full
		if (cached.size > max_cached_fonts - 100) {
			
			cached.sort ((a, b) => {
				CachePair pa = (CachePair) a;
				CachePair pb = (CachePair) b;
				return pb.referenced - pa.referenced;
			});
			
			int j = 0;
			for (int i = cached.size - 1; i > 0; i--) {
				if (j > 100) {
					break;
				}
				
				j++;
				
				last = cached.get (i).character;
				glyphs.unset (last);
				cached.remove_at (i);
			}
		}
				
		f = get_single_fallback_glyph_font (c);
		p = new CachePair (f, c);
		
		glyphs.set (c, p);
		cached.add (p);
		
		return (Font) f;
	}

	Font get_single_fallback_glyph_font (unichar c) {
		string? font_file;
		BirdFontFile bf_parser;
		Font bf_font;
		StringBuilder? glyph_data;
		FontFace* font;

		bf_font = new Font ();
		font_file = null;
		glyph_data = null;

		// don't use fallback font in private use area
		if (0xe000 <= c <= 0xf8ff) {
			return bf_font;
		}
		
		// control characters
		if (c <= 0x001f || (0x007f <= c <= 0x008d)) {
			return bf_font;
		}
		
		// check if glyph is available in roboto
		if (default_font != null) {
			glyph_data = get_glyph_in_font ((!) default_font, c);
		}
				
		// use fontconfig to find a fallback font
		if (glyph_data == null) {
			font_file = find_font (font_config, (!) c.to_string ());
			if (font_file != null) {
				font = open_font ((!) font_file);
				glyph_data = get_glyph_in_font (font, c);
				close_font (font);
			}
		}
		
		if (glyph_data != null) {
			bf_parser = new BirdFontFile (bf_font);
			bf_parser.load_data (((!) glyph_data).str);
		}

		return bf_font;		
	}

	public StringBuilder? get_glyph_in_font (FontFace* font, unichar c) {
		StringBuilder? glyph_data = null;
		GlyphCollection gc;

		gc = new GlyphCollection (c, (!)c.to_string ());		
		glyph_data = load_glyph (font, (uint) c);

		return glyph_data;
	}
	
	void add_font_folder (string f) {
		File folder = File.new_for_path (f);
		FileInfo? file_info;
		string fn;
		string file_attributes;
		try {
			if (folder.query_exists ()) {
				font_directories.add (folder);
				
				file_attributes = FileAttribute.STANDARD_NAME;
				file_attributes += ",";
				file_attributes += FileAttribute.STANDARD_TYPE;
				var enumerator = folder.enumerate_children (file_attributes, 0);
				
				while ((file_info = enumerator.next_file ()) != null) {
					fn = ((!) file_info).get_name ();

					if (((!)file_info).get_file_type () == FileType.DIRECTORY) {
						add_font_folder ((!) get_child (folder, fn).get_path ());
					}
				}
			}
		} catch (GLib.Error e) {
			warning (e.message);
		}
	}

	File search_font_file (string font_file) {
		File d, f;
		
		for (int i = font_directories.size - 1; i >= 0; i--) {
			d = font_directories.get (i);
			f = get_child (d, font_file);
			
			if (f.query_exists ()) {
				return f;
			}
		}
		
		warning (@"The font $font_file not found");
		return File.new_for_path (font_file);
	}

	void open_default_font () {
		File font_file;
		string? fn = null;
		
		font_file = SearchPaths.search_file (null, default_font_file_name);
		
		if (font_file.query_exists ()) {
			fn = (!) font_file.get_path ();
		} else {
			font_file = search_font_file (default_font_file_name);
	
			if (font_file.query_exists ()) {
				fn = (!) font_file.get_path ();
			} else {
				fn = find_font_file (font_config, default_font_family_name);
			}
		}
			
		if (fn != null) {
			default_font = open_font ((!) fn);
		}
	}
	
	class CachePair : GLib.Object {
		public Font font;
		public unichar character;
		public int referenced = 1;
		
		public CachePair (Font f, unichar c) {
			font = f;
			character = c;
		}
	}
}

}
