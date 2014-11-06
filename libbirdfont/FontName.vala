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

	public FontName (string? name = null, string tip = "", unichar key = '\0', uint modifier_flag = 0) {
		base (null , tip, key, modifier_flag);

		if (name != null) {
			base.name = (!) name;
		}
	}
	
	public override void draw (Context cr) {
		Text font_name;
		double text_height;
		
		cr.save ();
		// tab label
		font_name = new Text ();
		font_name.set_text (BirdFont.get_current_font ().get_full_name ());
		text_height = 12;
		cr.set_source_rgba (234 / 255.0, 77 / 255.0, 26 / 255.0, 1);
		font_name.draw (cr, x, y + 3, text_height);
		cr.restore ();
	}
}

}
