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

public class FontName : Tool {

	public FontName (string? name = null, string tip = "") {
		base (null , tip);

		if (name != null) {
			base.name = (!) name;
		}
		
		select_action.connect ((tool) => {
			MenuTab.select_overview ();
		});
	}
	
	public override void draw (Context cr) {
		Text font_name;
		double text_height;
		double extent;
		double width = Toolbox.allocation_width * Toolbox.get_scale ();
		double max_width;
		
		cr.save ();
		// tab label
		font_name = new Text ();
		font_name.set_text (BirdFont.get_current_font ().get_full_name ());
		text_height = 22 * Toolbox.get_scale ();
		
		max_width = (width - 2 * x * Toolbox.get_scale ());
		font_name.set_font_size (text_height);
		extent = font_name.get_extent () * Toolbox.get_scale ();
		if (extent > max_width) {
			text_height *= max_width / extent;
		}
		
		Theme.text_color (font_name, "Font Name");
		font_name.set_font_size (text_height);
		font_name.draw_at_baseline (cr, x, y + 13 * Toolbox.get_scale ());
		cr.restore ();
	}
}

}
