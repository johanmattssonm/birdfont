/*
    Copyright (C) 2014 Johan Mattsson

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

public class OverviewTools : ToolCollection  {

	static LabelTool all_glyphs;
	static LabelTool default_glyphs;
	static LabelTool unicode;

	static Gee.ArrayList<LabelTool> custom_character_sets;

	public static Gee.ArrayList<Expander> expanders;
	public ZoomBar zoom_bar;

	public OverviewTools () {
		Expander font_name = new Expander ();
		Expander character_sets = new Expander (t_("Character Sets"));
		Expander zoom_expander = new Expander (t_("Zoom"));
		
		expanders = new Gee.ArrayList<Expander> ();
		custom_character_sets = new Gee.ArrayList<LabelTool> ();
		
		font_name.add_tool (new FontName ());

		zoom_bar = new ZoomBar ();
		zoom_bar.new_zoom.connect ((z) => {
			get_overview ().set_zoom (z);
		});
		zoom_expander.add_tool (zoom_bar);
						
		all_glyphs = new LabelTool (t_("All Glyphs"));
		all_glyphs.has_counter = true;
		all_glyphs.select_action.connect ((self) => {
			OverView overview = get_overview ();
			overview.display_all_available_glyphs ();
			update_overview_characterset ();
			FontDisplay.dirty_scrollbar = true;
		});
		character_sets.add_tool (all_glyphs);

		default_glyphs = new LabelTool (t_("Default"));
		default_glyphs.has_counter = true;
		default_glyphs.select_action.connect ((self) => {
			OverView overview = get_overview ();
			GlyphRange gr = new GlyphRange ();
			DefaultCharacterSet.use_default_range (gr);
			overview.set_glyph_range (gr);
			update_overview_characterset ();
			FontDisplay.dirty_scrollbar = true;
		});
		character_sets.add_tool (default_glyphs);

		unicode = new LabelTool (t_("Unicode"));
		unicode.has_counter = true;
		unicode.select_action.connect ((self) => {
			OverView overview = get_overview ();
			GlyphRange gr = new GlyphRange ();
			DefaultCharacterSet.use_full_unicode_range (gr);
			overview.set_glyph_range (gr);
			update_overview_characterset ();
			FontDisplay.dirty_scrollbar = true;
		});
		character_sets.add_tool (unicode);
		
		character_sets.set_persistent (true);
		character_sets.set_unique (false);

		expanders.add (font_name);
		expanders.add (zoom_expander);
		expanders.add (character_sets);
	}
	
	public OverView get_overview () {
		FontDisplay fd = MainWindow.get_current_display ();
		
		if (fd is OverView || fd is GlyphSelection) {
			return (OverView) fd;
		}
		
		warning ("Current tab is not overview.");
		
		return new OverView ();
	}
	
	public static void show_all_available_characters () {
		all_glyphs.select_action (all_glyphs);
	}
	
	public static void update_overview_characterset (OverView? tab = null) {
		GlyphRange gr;
		uint size;
		OverView overview;

		// All characters
		size = BirdFont.get_current_font ().length ();
		all_glyphs.number = get_display_value (size);
		
		// Default
		gr = new GlyphRange ();
		DefaultCharacterSet.use_default_range (gr);
		size = gr.get_length ();
		default_glyphs.number = get_display_value (size);
		
		// Unicode
		gr = new GlyphRange ();
		DefaultCharacterSet.use_full_unicode_range (gr);
		size = gr.get_length ();
		unicode.number = get_display_value (size);
		
		overview = (tab == null) ? MainWindow.get_overview () : (!) tab;
		
		// set selected item
		all_glyphs.set_selected (false);
		default_glyphs.set_selected (false);
		unicode.set_selected (false);
		
		if (overview.all_available) {
			all_glyphs.set_selected (true);
		} else if (overview.glyph_range.name == "Default") {
			default_glyphs.set_selected (true);
		} else if (overview.glyph_range.name == "Unicode") {
			unicode.set_selected (true);
		}
		
		Toolbox.redraw_tool_box ();
	}

	static string get_display_value (uint size) {
		double k;
		string display_size;
		
		if (size >= 1000) {
			k = size / 1000.0;
			size = (uint) Math.rint (k);
			display_size = @"$(size)k";
		} else {
			display_size = @"$(size)";
		}
		
		return display_size;
	}
	
	public override Gee.ArrayList<Expander> get_expanders () {
		return expanders;
	}

	public override Gee.ArrayList<string> get_displays () {
		Gee.ArrayList<string> d = new Gee.ArrayList<string> ();
		d.add ("Overview");
		return d;
	}
}

}
