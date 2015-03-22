/*
    Copyright (C) 2015 Johan Mattsson

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

public class KerningStringsTab : FontDisplay {
	
	double scroll = 0;
	double content_height = 1;
	WidgetAllocation allocation;
	
	TextArea kerning_text;
	Button load_text;
	
	Gee.ArrayList<Widget> widgets;
	
	public KerningStringsTab () {
		double margin = 12 * MainWindow.units;
		double label_size = 20 * MainWindow.units;
		double label_margin = 4 * MainWindow.units;
		Headline headline;
		Font font = BirdFont.get_current_font ();
		
		allocation = new WidgetAllocation ();
		widgets = new Gee.ArrayList<Widget> ();

		headline = new Headline (t_("Kerning Strings"));
		headline.margin_bottom = 20 * MainWindow.units;
		widgets.add (headline);

		kerning_text = new TextArea (label_size);
		kerning_text.margin_bottom = margin;
		kerning_text.set_text (""); // FIXME:
		widgets.add (kerning_text);
	}
	
	public override void draw (WidgetAllocation allocation, Context cr) {
		this.allocation = allocation;
		
		layout ();
		
		// background
		cr.save ();
		cr.rectangle (0, 0, allocation.width, allocation.height);
		cr.set_line_width (0);
		
		Theme.color (cr, "Background 4");

		cr.fill ();
		cr.stroke ();
		cr.restore ();

		foreach (Widget w in widgets) {
			if (w.is_on_screen ()) {			
				if (w is Text) {
					cr.save ();
					Theme.color (cr, "Foreground 1");
					w.draw (cr);
					cr.restore ();
				} else {
					w.draw (cr);
				}
			}
		}
	}	

	void layout () {
		double y = -scroll;
		
		foreach (Widget w in widgets) {
			w.widget_x = 17 * MainWindow.units;
			w.widget_y = y;
			w.allocation = allocation;
			
			if (w is TextArea) {
				((TextArea) w).layout ();
			}
			
			y += w.get_height () + w.margin_bottom;
		}
		
		content_height = y + scroll;
		update_scrollbar ();
	}

	public void scroll_event (double p) {
		scroll += p;
		layout ();
		GlyphCanvas.redraw ();
	}

	public override void key_press (uint keyval) {
		kerning_text.key_press (keyval);
	}
	
	public override void button_press (uint button, double x, double y) {
		TextArea t;
		TextArea old;
		
		foreach (Widget w in widgets) {
			if (w.is_over (x, y)) {
				if (w is TextArea) {
					t = (TextArea) w;
					if (kerning_text != t) {
						old = (!) kerning_text;
						old.draw_carret = false;
					}
					
					t.draw_carret = true;
					t.button_press (button, x, y);
					kerning_text = t;
				}
			}
		}

		GlyphCanvas.redraw ();
	}
	
	public override void button_release (int button, double x, double y) {
		TextArea t;
		
		kerning_text.button_release (button, x, y);
					
		GlyphCanvas.redraw ();
	}

	public override void motion_notify (double x, double y) {
		kerning_text.motion (x, y);
	}

	public override string get_label () {
		return t_("Name and Description");
	}

	public override string get_name () {
		return "Description";
	}

	public override bool has_scrollbar () {
		return true;
	}
	
	public override void scroll_wheel_down (double x, double y) {
		scroll += 25 * MainWindow.units;

		if (scroll + allocation.height >=  content_height) {
			scroll = content_height - allocation.height;
		}
		
		update_scrollbar ();
		GlyphCanvas.redraw ();
	}
	
	public override void scroll_wheel_up (double x, double y) {
		scroll -= 25 * MainWindow.units;
		
		if (scroll < 0) {
			scroll = 0;
		}
		
		update_scrollbar ();
		GlyphCanvas.redraw ();
	}

	public override void selected_canvas () {
		update_scrollbar ();
		GlyphCanvas.redraw ();
	}
	
	public override void update_scrollbar () {
		double h = content_height - allocation.height;
		MainWindow.set_scrollbar_size (allocation.height / content_height);
		MainWindow.set_scrollbar_position (scroll /  h);
	}

	public override void scroll_to (double percent) {
		double h = content_height - allocation.height;
		scroll = percent * h;
		GlyphCanvas.redraw ();
	}
}

}
