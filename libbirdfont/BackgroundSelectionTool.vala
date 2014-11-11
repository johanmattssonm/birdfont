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
using Math;

namespace BirdFont {

public class BackgroundSelectionTool : CutBackgroundTool {
	
	public BackgroundSelectionTool () {
		base ("select_background", t_("Select Background"));
		editor_events = true;
		persistent = true;
		self_destination = false;
		
		new_image.connect (add_new_image);

		select_action.connect ((t) => {
			GlyphCanvas.redraw ();
		});

		draw_action.connect ((self, cr, glyph) => {
			double x, y, w, h;
			BackgroundImage bg;
			Text label = new Text ();
			GlyphCollection g;
			double tx, ty, font_height;
			
			if (glyph.get_background_image () == null) {
				warning ("No image");
				return;
			}
			
			// draw a border around each selection
			bg = (!) glyph.get_background_image ();
			foreach (BackgroundSelection bs in bg.selections) {
				x = Glyph.reverse_path_coordinate_x (bs.x);
				y = Glyph.reverse_path_coordinate_y (bs.y);
				w = Glyph.reverse_path_coordinate_x (bs.x + bs.w) - x;
				h = Glyph.reverse_path_coordinate_y (bs.y + bs.h) - y;
				
				cr.save ();
				cr.set_line_width (2.0);
				
				if (bs.assigned_glyph != null) {
					cr.set_source_rgba (237 / 255.0, 67 / 255.0, 0, 1);
				} else {
					cr.set_source_rgba (132 / 255.0, 132 / 255.0, 132 / 255.0, 1);
				}
				
				cr.rectangle (x, y, w, h);
				cr.stroke ();
				
				cr.arc (x + w, y + h, 9.0, 0, 2 * PI);
				cr.fill ();
				
				if (bs.assigned_glyph != null) {
					g = (!) bs.assigned_glyph;
					
					if (label.has_character (g.get_name ())) {
						font_height = 18;
						cr.set_source_rgba (1, 1, 1, 1);
						label.set_text (g.get_name ());
						tx = x  + w - label.get_width (font_height) / 2.0;
						ty = y + h;
						ty += label.get_height (font_height) / 2.0;
						ty -= label.get_decender (font_height);
						label.draw (cr, tx, ty, font_height);
					}
				}
				
				cr.restore ();
			}
		});
	}
	
	public void add_new_image (BackgroundImage image,
		double x, double y, double w, double h) {
			
		BackgroundImage bg;
		BackgroundSelection selection;

		if (MainWindow.get_current_glyph ().get_background_image () == null) {
			warning ("No image");
			return;
		}
				
		bg = (!) MainWindow.get_current_glyph ().get_background_image ();
		selection = new BackgroundSelection (image, bg, x, y, w, h);
		
		bg.add_selection (selection);
		Toolbox.background_tools.add_part (selection);
	}
}

}
