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

	static OverviewTool all_glyphs;
	static OverviewTool default_glyphs;
	static OverviewTool unicode;

	public static Gee.ArrayList<Expander> expanders;

	public OverviewTools () {
		Expander font_name = new Expander ();
		Expander character_sets = new Expander (t_("Character Sets"));
		
		expanders = new Gee.ArrayList<Expander> ();
		
		font_name.add_tool (new FontName ());
		font_name.draw_separator = false;
				
		all_glyphs = new OverviewTool (t_("All Glyphs"));
		all_glyphs.select_action.connect ((self) => {
			OverView overview = MainWindow.get_overview ();
			overview.display_all_available_glyphs ();
		});
		character_sets.add_tool (all_glyphs);

		default_glyphs = new OverviewTool (t_("Default"));
		default_glyphs.select_action.connect ((self) => {
			OverView overview = MainWindow.get_overview ();
			GlyphRange gr = new GlyphRange ();
			DefaultCharacterSet.use_default_range (gr);
			overview.set_glyph_range (gr);
		});
		character_sets.add_tool (default_glyphs);

		unicode = new OverviewTool (t_("Unicode"));
		unicode.select_action.connect ((self) => {
			OverView overview = MainWindow.get_overview ();
			GlyphRange gr = new GlyphRange ();
			DefaultCharacterSet.use_full_unicode_range (gr);
			overview.set_glyph_range (gr);
		});
		character_sets.add_tool (unicode);

		character_sets.set_persistent (true);
		character_sets.set_unique (true);

		expanders.add (font_name);
		expanders.add (character_sets);
		
		update_overview_characterset ();
	}
	
	public static void update_overview_characterset () {
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
		
		overview = MainWindow.get_overview ();
		
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
	
}

}
