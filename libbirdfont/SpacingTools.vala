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

using Cairo;
using Math;

namespace BirdFont {

public class SpacingTools : ToolCollection  {
	public static Gee.ArrayList<Expander> expanders;

	public static ZoomBar zoom_bar;
	
	public SpacingTools () {
		expanders = new Gee.ArrayList<Expander> ();

		Expander font_name = new Expander ();
		font_name.add_tool (new FontName ());

		Expander zoom_expander = new Expander (t_("Font Size"));

		zoom_bar = new ZoomBar ();
		zoom_bar.new_zoom.connect ((z) => {
			Font f;
			
			KerningTools.font_size = 3 * z;
			
			if (KerningTools.font_size < 0.1) {
				KerningTools.font_size = 0.1;
			}

			f = BirdFont.get_current_font ();
			f.settings.set_setting ("spacing_zoom", @"$z");
			
			GlyphCanvas.redraw ();
		});
		zoom_expander.add_tool (zoom_bar);
		
		Expander spacing_tools_expander = new Expander ();
		
		Tool insert_last = new Tool ("insert_glyph_from_overview", t_("Insert glyph from overview"));
		insert_last.select_action.connect ((self) => {
			SpacingTab d = MainWindow.get_spacing_tab ();
			GlyphSelection gs = new GlyphSelection ();
			
			gs.selected_glyph.connect ((gc) => {
				d.inser_glyph (gc.get_current ());
				MainWindow.get_tab_bar ().select_tab_name ("Spacing");
			});
			
			GlyphCanvas.set_display (gs);
			self.set_selected (false);
		});
		spacing_tools_expander.add_tool (insert_last);

		Tool insert_unicode = new Tool ("insert_unichar", t_("Insert character by unicode value"));
		insert_unicode.select_action.connect ((self) => {
			SpacingTab d = MainWindow.get_spacing_tab ();
			d.insert_unichar ();
			self.set_selected (false);
		});
		spacing_tools_expander.add_tool (insert_unicode);

		spacing_tools_expander.add_tool (KerningTools.previous_kerning_string);
		spacing_tools_expander.add_tool (KerningTools.next_kerning_string);
		
		expanders.add (font_name);
		expanders.add (zoom_expander);
		expanders.add (spacing_tools_expander);
	}

	public override Gee.ArrayList<string> get_displays () {
		Gee.ArrayList<string> d = new Gee.ArrayList<string> ();
		d.add ("Spacing");
		return d;
	}
	
	public override Gee.ArrayList<Expander> get_expanders () {
		return expanders;
	}
}

}
