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
	public string data = "";

	double counter_box_width = 24 * Toolbox.get_scale ();
	double counter_box_height = 11 * Toolbox.get_scale ();
	
	Text label_text;

	public LabelTool (string label) {
		double text_height;
		
		base ();

		this.label = label;
		this.number = "-";
		
		label_text = new Text ();
		label_text.set_text (label);
		text_height = 17 * Toolbox.get_scale ();
		label_text.set_font_size (text_height);

		has_delete_button = false;
		has_counter = false;

		panel_press_action.connect ((selected, button, tx, ty) => {
			if (has_delete_button && y <= ty <= y + h && tx >= w - 30 * Toolbox.get_scale ()) {
				delete_action (this);
			}
		});
	}
	
	public override void draw_tool (Context cr, double px, double py) {
		Text glyph_count;
		double bgx, bgy;
		double center_x, center_y;
		double x = this.x - px;
		double y = this.y - py;
		double text_height;
		double text_width;
		
		// background
		if (is_selected ()) {
			cr.save ();
			Theme.color (cr, "Menu Background");
			cr.rectangle (0, y - 2 * Toolbox.get_scale (), w, h ); // labels overlap with 2 pixels
			cr.fill ();
			cr.restore ();		
		}
		
		// tab label
		cr.save ();

		if (is_selected ()) {
			Theme.text_color (label_text, "Text Tool Box");
		} else {
			Theme.text_color (label_text, "Text Tool Box");
		}
		
		text_width = Toolbox.allocation_width;
		
		if (has_counter) {
			text_width -= counter_box_width - 15;
		}
		
		if (has_delete_button) {
			text_width -= 30;
		}
		
		label_text.truncate (text_width);
		
		label_text.draw_at_top (cr, x, y);
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
			Theme.color (cr, "Text Foreground");
			cr.set_line_width (1);
			cr.move_to (w - 20, y + h / 2 - 2.5 - 2);
			cr.line_to (w - 25, y + h / 2 + 2.5 - 2);
			cr.move_to (w - 20, y + h / 2 + 2.5 - 2);
			cr.line_to (w - 25, y + h / 2 - 2.5 - 2);
			cr.stroke ();
			cr.restore ();
		}
	}
}

}
