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

namespace BirdFont {

public class GlyphSelection : OverView {

	public signal void selected_glyph (GlyphCollection gc);

	public GlyphSelection () {
		base (null, false);
		
		if (BirdFont.get_current_font ().length () > 0) {
			display_all_available_glyphs ();
		} else {
			GlyphRange gr = new GlyphRange ();
			DefaultCharacterSet.use_default_range (gr);
			set_glyph_range (gr);
		}

		OverviewTools.update_overview_characterset (this);
		FontDisplay.dirty_scrollbar = true;	
		
		open_glyph_signal.connect ((gc) => {
			selected_glyph (gc);
			Toolbox.redraw_tool_box ();
		});
	}
}

}
