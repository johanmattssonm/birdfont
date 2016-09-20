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

	public string label { 
		get {
			return label_text.text;
		}
		
		set {
			clear_cache ();
			label_text.set_text (value);
		}
	}
	
	public string number {
		get {
			return counter_number;
		}
	
		set {
			clear_cache ();
			counter_number = value;
		} 
	}
	
	string counter_number = "";
	
	public bool has_counter { get; set; }
	public bool has_delete_button { get; set; }
	public signal void delete_action (LabelTool self);
	public string data = "";

	double counter_box_width = 24 * Toolbox.get_scale ();
	double counter_box_height = 11 * Toolbox.get_scale ();
	
	Text label_text;

	Surface? selected_cache = null;
	Surface? deselected_cache = null;

	public LabelTool (string label) {
		double text_height;
		
		base ();
		
		label_text = new Text ();
		label_text.set_text (label);
		
		this.label = label;
		this.number = "-";

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

	public override void clear_cache () {
		base.clear_cache ();
		selected_cache = null;
		deselected_cache = null;
	}
	
	public override void draw_tool (Context cr, double px, double py) {
		double x = this.x - px;
		double y = this.y - py;
		
		if (is_selected ()) {
		
			if (selected_cache == null) {
				selected_cache = Screen.create_background_surface ((int) (w * Screen.get_scale ()), (int) ((h + 2) * Screen.get_scale ()));
				Context c = new Context ((!) selected_cache);
				c.scale (Screen.get_scale (), Screen.get_scale ());
				draw_tool_surface (c, x, 2, true);
			}
			
			cr.save ();
			cr.scale (1 / Screen.get_scale (), 1 / Screen.get_scale ());
			cr.set_antialias (Cairo.Antialias.NONE);
			cr.set_source_surface ((!) selected_cache, 0, (int) ((y - 2) * Screen.get_scale ()));
			cr.paint ();
			cr.restore ();
		} else {
		
			if (deselected_cache == null) {
				deselected_cache = Screen.create_background_surface ((int) (w * Screen.get_scale ()), (int) ((h + 2) * Screen.get_scale ()));
				Context c = new Context ((!) deselected_cache);
				c.scale (Screen.get_scale (), Screen.get_scale ());
				draw_tool_surface (c, x, 2, false);
			}
			
			cr.save ();
			cr.scale (1 / Screen.get_scale (), 1 / Screen.get_scale ());
			cr.set_antialias (Cairo.Antialias.NONE);
			cr.set_source_surface ((!) deselected_cache, 0, (int) ((y - 2) * Screen.get_scale ()));
			cr.paint ();
			cr.restore ();
		}
	}
	
	public void draw_tool_surface (Context cr, double px, double py, bool selected) {
		Text glyph_count;
		double bgx, bgy;
		double center_x, center_y;
		double text_height;
		double text_width;
		double x = px;
		double y = py;
		
		// background
		if (selected) {
			cr.save ();
			Theme.color (cr, "Menu Background");
			cr.rectangle (0, y - 2 * Toolbox.get_scale (), w, h); // labels overlap with 2 pixels
			cr.fill ();
			cr.restore ();		
		}
		
		// tab label
		cr.save ();

		Theme.text_color (label_text, "Text Tool Box");
		
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
