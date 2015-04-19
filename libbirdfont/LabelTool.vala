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

public class LabelTool : Tool {

	public string label { get; set; }
	public string number { get; set; }
	public bool has_counter { get; set; }
	public bool has_delete_button { get; set; }
	public signal void delete_action (LabelTool self);

	double counter_box_width = 24;
	double counter_box_height = 11;

	public LabelTool (string label) {
		base ();

		this.label = label;
		this.number = "-";
		
		has_delete_button = false;
		has_counter = false;

		panel_press_action.connect ((selected, button, tx, ty) => {
			if (has_delete_button && y <= ty <= y + h && tx >= w - 30) {
				delete_action (this);
			}
		});

		panel_move_action.connect ((selected, button, tx, ty) => {
			return false;
		});
	}
	
	public override void draw (Context cr) {
		Text label_text, glyph_count;
		double text_height;
		double bgx, bgy;
		double center_x, center_y;
		
		// background
		if (is_selected ()) {
			cr.save ();
			Theme.color (cr, "Menu Background");
			cr.rectangle (0, y - 2, w, h + 7);
			cr.fill ();
			cr.restore ();		
		}
		
		// tab label
		cr.save ();
		label_text = new Text ();
		label_text.set_text (label);
		text_height = 18;

		if (is_selected ()) {
			Theme.text_color (label_text, "Text Tool Box");
		} else {
			Theme.text_color (label_text, "Text Tool Box");
		}
		
		label_text.set_font_size (text_height);
		label_text.draw_at_baseline (cr, x + 14, y + h - 1.5);
		cr.restore ();

		// glyph count
		if (has_counter) {
			cr.save ();
			bgx = Toolbox.allocation_width - counter_box_width - 9;
			bgy = y + 2;
			
			if (is_selected ()) {
				Theme.color (cr, "Glyph Count Background 1");
			} else {
				Theme.color (cr, "Glyph Count Background 2");
			}
			
			draw_rounded_rectangle (cr, bgx, bgy, counter_box_width, counter_box_height, 3);
			cr.fill ();
			cr.restore ();
			
			glyph_count = new Text ();
			glyph_count.set_text (@"$(this.number)");
			text_height = 12;
			
			glyph_count.set_font_size (text_height);
			center_x = bgx + (counter_box_width / 2.0  - glyph_count.get_extent () / 2.0);
			center_y = bgy + (counter_box_height / 2.0 + 5);

			if (is_selected ()) {
				Theme.text_color (glyph_count, "Text Foreground");
			} else {
				Theme.text_color (glyph_count, "Text Foreground");
			}
			
			glyph_count.set_font_size (text_height);
			glyph_count.draw_at_baseline (cr, center_x, center_y);
		}
		
		if (has_delete_button) {
			cr.save ();
			Theme.color (cr, "Foreground Inverted");
			cr.set_line_width (1);
			cr.move_to (w - 20, y + h / 2 - 2.5 + 2);
			cr.line_to (w - 25, y + h / 2 + 2.5 + 2);
			cr.move_to (w - 20, y + h / 2 + 2.5 + 2);
			cr.line_to (w - 25, y + h / 2 - 2.5 + 2);	
			cr.stroke ();
			cr.restore ();
		}
	}
}

}
