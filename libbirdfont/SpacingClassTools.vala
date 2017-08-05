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

namespace BirdFont {

public class SpacingClassTools : ToolCollection  {
	public static Gee.ArrayList<Expander> expanders;

	public SpacingClassTools () {
		expanders = new Gee.ArrayList<Expander> ();

		Expander font_name = new Expander ();
		font_name.add_tool (new FontName ());
		
		Expander spacing_class_tools = new Expander ();
		Tool insert = new Tool ("insert_glyph_from_overview_in_spacing_class", t_("Insert glyph from overview"));
		
		insert.set_icon ("insert_glyph_from_overview");
		
		insert.select_action.connect ((self) => {
			GlyphSelection glyph_selection = new GlyphSelection ();
			
			glyph_selection.selected_glyph.connect ((glyph_collection) => {
				SpacingClassTab.set_class (glyph_collection.get_name ());
				MainWindow.get_tab_bar ().select_tab_name ("SpacingClasses");
			});
			
			GlyphCanvas.set_display (glyph_selection);
			self.set_selected (false);
			
			TabContent.hide_text_input ();
		});
		spacing_class_tools.add_tool (insert);
		
		expanders.add (font_name);
		
		expanders.add (spacing_class_tools);
	}
	
	public override Gee.ArrayList<Expander> get_expanders () {
		return expanders;
	}
	
	public override Gee.ArrayList<string> get_displays () {
		Gee.ArrayList<string> d = new Gee.ArrayList<string> ();
		d.add ("SpacingClasses");
		return d;
	}
		
}

}
