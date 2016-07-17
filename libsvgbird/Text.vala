/*
	Copyright (C) 2016 Johan Mattsson

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
using Math;

[SimpleType]
[CCode (has_type_id = false)]
public extern struct FcConfig {
}

[SimpleType]
[CCode (has_type_id = false)]
extern struct svg_bird_font_item {
}

extern void svg_bird_draw_text (Context cr, svg_bird_font_item* font, string text);
extern void svg_bird_get_extent (svg_bird_font_item* font, string text, out double w, out double h);

extern void svg_bird_font_item_delete (svg_bird_font_item* item);
extern svg_bird_font_item* svg_bird_font_item_create (string font_file, int font_size);

extern bool svg_bird_has_font_config ();
extern void svg_bird_set_font_config (FcConfig* f);

[CCode (cname = "FcInitLoadConfigAndFonts")]
public extern FcConfig* FcInitLoadConfigAndFonts ();
	
[CCode (cname = "FcConfigAppFontAddDir")]
public extern string* FcConfigAppFontAddDir (FcConfig* config, string path);

[CCode (cname = "FcConfigSetSysRoot")]
public extern void FcConfigSetSysRoot (FcConfig* config, string path);

[CCode (cname = "FcConfigParseAndLoad")]
public extern bool FcConfigParseAndLoad (FcConfig* config, string path, bool complain);

[CCode (cname = "FcConfigSetCurrent")]
public extern void FcConfigSetCurrent (FcConfig* config);

[CCode (cname = "FcConfigCreate")]
public extern FcConfig* FcConfigCreate ();

[CCode (cname = "FcConfigFilename")]
public extern string FcConfigFilename (string path);


namespace SvgBird {

public class Text : Object {
	string font_family = "";
	int font_size = 12;
	string content;
	
	public double x = 0;
	public double y = 0;

	svg_bird_font_item* font = null;

	public Text () {
		if (!svg_bird_has_font_config ()) {
			init_font_config ();
		}
		
		set_font ("Roboto");
	}

	~Text () {
		svg_bird_font_item_delete (font);
	}

	public void get_text_extents (out double w, out double h) {
		svg_bird_get_extent (font, content, out w, out h);
	}

	public override bool update_boundaries (Context context) {
		double w;
		double h;
		get_text_extents (out w, out h);
		left = x;
		top = y;
		bottom = y + h;
		right = x + w;
		return true;
	}
	
	public void set_font_size (int s) {
		font_size = s;
		set_font (font_family);
	}
	
	public void set_font (string font_family) {
		if (font != null) {
			svg_bird_font_item_delete (font);
		}
		
		font = svg_bird_font_item_create (font_family, font_size);
	}

	public void init_font_config () {
		FcConfig* config;
		
#if MAC
		config = FcConfigCreate();
		
		string bundle = (!) BirdFont.get_settings_directory ().get_path ();
		FcConfigSetSysRoot(config, bundle);
	
		string path = FcConfigFilename((!) SearchPaths.search_file(null, "fontconfig.settings").get_path ());
		bool loaded = FcConfigParseAndLoad(config, path, true);
		
		if (!loaded) {
			warning ("Fontconfig initialization failed.");
		}
		
		FcConfigSetCurrent (config);
#else
		config = FcInitLoadConfigAndFonts ();
#endif
		svg_bird_set_font_config (config);
	}
	
	public void set_text (string t) {
		content = t.replace ("\n", " ");
		content = content.replace ("\t", " ");
		
		while (content.index_of ("  ") > -1) {
			content = content.replace ("  ", " ");
		}
		
		content = content.strip ();
	}

	public Text.create_copy (Text c) {
		Object.copy_attributes (c, this);
		font_family = c.font_family;
		x = c.x;
		y = c.y;
		font_size = c.font_size;
	}
	
	public override void draw_outline (Context cr) {
		cr.save ();
		cr.translate (x, y);

		double w, h;
		svg_bird_get_extent (font, content, out w, out h);
		
		if (font != null) {
			svg_bird_draw_text (cr, font, content);
		} 
		
		cr.restore ();
	}

	public override bool is_empty () {
		return false;
	}
	
	public override Object copy () {
		return new Text.create_copy (this);
	}

	public override string to_string () {
		return "Text";
	}
}

}
