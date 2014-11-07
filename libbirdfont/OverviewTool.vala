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

public class OverviewTool : Tool {

	private static ImageSurface? counter_background = null;
	public string label { get; set; }
	public string number { get; set; }
	public bool has_counter { get; set; }

	public OverviewTool (string label) {
		base ();

		this.label = label;
		this.number = "-";
		
		has_counter = true;
		counter_background = Icons.get_icon ("overview_counter.png");
		
		panel_press_action.connect ((selected, button, tx, ty) => {
		});

		panel_move_action.connect ((selected, button, tx, ty) => {
			return false;
		});

		panel_release_action.connect ((selected, button, tx, ty) => {
			set_selected (y <= ty <= y + h);
		});
	}
	
	public override void draw (Context cr) {
		Text font_name, glyph_count;
		double text_height;
		double scale, bgx, bgy;
		double center_x, center_y;
		
		// background
		if (is_selected ()) {
			cr.save ();
			cr.set_source_rgba (38 / 255.0, 39 / 255.0, 43 / 255.0, 1);
			cr.rectangle (0, y - 2, w, h + 7);
			cr.fill ();
			cr.restore ();		
		}
		
		// tab label
		cr.save ();
		font_name = new Text ();
		font_name.set_text (label);
		text_height = 18;

		if (is_selected ()) {
			cr.set_source_rgba (1, 1, 1, 1);
		} else {
			cr.set_source_rgba (101 / 255.0, 108 / 255.0, 116 / 255.0, 1);
		}
		
		font_name.draw (cr, x + 14, y - 4.5, text_height);
		cr.restore ();

		// glyph count
		if (has_counter && counter_background != null) {
			cr.save ();
			scale = 30.0 / 111.0; // scale to 320 dpi
			cr.scale (scale, scale);
			
			bgx = Toolbox.allocation_width / scale - ((!) counter_background).get_width () - 15 / scale;
			bgy = y / scale + 2 / scale;
			
			cr.set_source_surface ((!) counter_background, bgx, bgy);
			cr.paint ();
			
			glyph_count = new Text ();
			glyph_count.set_text (@"$(this.number)");
			text_height = 12 / scale;
			
			center_x = bgx + ((!) counter_background).get_width () / 2.0  - glyph_count.get_extent (text_height) / 2.0;
			center_y = bgy + ((!) counter_background).get_height () / 2.0 - text_height / 2.0 - 3 / scale;;
			
			if (is_selected ()) {
				cr.set_source_rgba (1, 1, 1, 1);
			} else {
				cr.set_source_rgba (51 / 255.0, 54 / 255.0, 59 / 255.0, 1);
			}
			
			glyph_count.draw (cr, center_x, center_y, text_height);
									
			cr.restore ();
		}
		
	}
}

}
