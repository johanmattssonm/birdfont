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

public class DescriptionDisplay : FontDisplay {
	
	double scroll = 0;
	double content_height = 1;
	WidgetAllocation allocation;
	
	TextArea version;
	TextArea description;
	TextArea copyright;
	
	Gee.ArrayList<Widget> widgets;
	
	public DescriptionDisplay () {
		double margin = 20 * MainWindow.units;
		double label_size = 22 * MainWindow.units;
		double label_margin = 4 * MainWindow.units;
		
		allocation = new WidgetAllocation ();
		
		widgets = new Gee.ArrayList<Widget> ();
		
		copyright = new TextArea (label_size);
		description = new TextArea (label_size);
		version = new TextArea (label_size);

		widgets.add (new Text (t_("Version"),label_size, label_margin));
		version.margin_bottom = margin;
		widgets.add (version);

		widgets.add (new Text (t_("Description"), label_size, label_margin));
		description.margin_bottom = margin;
		widgets.add (description);
		
		widgets.add (new Text (t_("Copyright"), label_size, label_margin));
		copyright.margin_bottom = margin;
		widgets.add (copyright);
	}

	public override void draw (WidgetAllocation allocation, Context cr) {
		this.allocation = allocation;
		
		layout ();
		
		// background
		cr.save ();
		cr.rectangle (0, 0, allocation.width, allocation.height);
		cr.set_line_width (0);
		cr.set_source_rgba (51 / 255.0, 54 / 255.0, 59 / 255.0, 1);
		cr.fill ();
		cr.stroke ();
		cr.restore ();

		foreach (Widget w in widgets) {
			if (w is Text) {
				cr.save ();
				cr.set_source_rgba (101 / 255.0, 108 / 255.0, 116 / 255.0, 1);
				w.draw (cr);
				cr.restore ();
			} else {
				w.draw (cr);
			}
		}
	}	

	void layout () {
		double y = 10 * MainWindow.units;
		double margin;
		
		foreach (Widget w in widgets) {
			w.widget_x = 17 * MainWindow.units;
			w.widget_y = y;
			y += w.get_height () + w.margin_bottom;
		}
	}

	public override void key_press (uint keyval) {
		unichar c = (unichar) keyval;
		string s;
		
		if (!KeyBindings.has_alt () && !KeyBindings.has_ctrl ()) {
			switch (c) {
				case Key.BACK_SPACE:
					copyright.remove_last_character ();
					break;
				case Key.ENTER:
					copyright.insert_text ("\n");
					break;				
				default:
					if (!is_modifier_key (keyval)) {
						s = (!) c.to_string ();
						if (s.validate ()) {
							copyright.insert_text (s);
							print (@"keyval: $keyval\n");
						}
					}
					break;
			}
		}
		
		GlyphCanvas.redraw ();
	}

	public override void button_press (uint button, double x, double y) {
		GlyphCanvas.redraw ();
	}
	
	public override void button_release (int button, double x, double y) {
		GlyphCanvas.redraw ();
	}

	public override void motion_notify (double x, double y) {
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
	
	public void update_scrollbar () {
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
