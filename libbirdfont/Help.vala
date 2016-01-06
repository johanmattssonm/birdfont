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

namespace BirdFont {

public class Help {

	bool visible;
	TextArea help_text;
	Text close;
	const int box_margin = 7;
	
	public Help () {
		string v = Preferences.get ("help_visible");
		visible = v == "true";
		help_text = create_help_text (t_("BirdFont is a font editor."));
		
		Color color = Theme.get_color ("Menu Foreground");
		close = new Text ("close", 30, 0, color);
		close.load_font ("icons.bf");
	}

	public static TextArea create_help_text (string lines) {
		Color color = Theme.get_color ("Menu Foreground");
		TextArea text = new TextArea (17, color);
		text.min_width = 200;
		text.min_height = 100;
		text.width = 200;
		text.height = 100;
		text.allocation = new WidgetAllocation.for_area (0, 0, (int)text.min_width, (int)text.min_height);
		text.set_text (lines);
		text.layout ();
		text.set_editable (false);
		text.draw_border = false;
		return text;
	}

	public void set_help_text (TextArea text) {
		if (text != help_text && is_visible ()) {
			help_text = text;
			GlyphCanvas.redraw ();
		}
	}

	public void set_visible (bool v) {
		visible = v;
		Preferences.set ("help_visible", @"$v");
	}
	
	public bool is_visible () {
		return visible;
	}

	public void draw (Context cr, WidgetAllocation allocation) {
		int margin_x = 10;
		int margin_y = 15;

		help_text.allocation = allocation;
		help_text.widget_x = allocation.width - help_text.width - margin_x;
		help_text.widget_y = allocation.height - help_text.height - margin_y;
		
		draw_box (cr, allocation);
		
		help_text.draw (cr);

		double close_x = allocation.width;
		close_x -= close.get_sidebearing_extent ();
		close_x -= margin_x;
		close_x -= box_margin;
		
		double close_y = allocation.height;
		close_y -= help_text.height;
		close_y -= margin_y;
		close_y -= 2 * box_margin;
		
		close.widget_x = close_x;
		close.widget_y = close_y;
		close.draw (cr);
	}

	public bool button_press (uint button, double x, double y) {
		if (close.widget_x < x < close.widget_x + close.get_sidebearing_extent ()
			&& close.widget_y < y < close.widget_y + close.font_size) {
			
			set_visible (false);
			GlyphCanvas.redraw ();
			return true;
		}
		
		return false;
	}

	public void draw_box (Context cr, WidgetAllocation allocation) {
		cr.save();

		Theme.color (cr, "Menu Background");
		double x, y, w, h;
		x = help_text.widget_x - 2 * box_margin;
		y = help_text.widget_y - 2 * box_margin; 
		w = help_text.width + 2 * box_margin;
		h = help_text.height + 2 * box_margin;
		Widget.draw_rounded_rectangle (cr, x, y, w, h, 7);
		cr.fill ();

		cr.restore();
	}

}

}
