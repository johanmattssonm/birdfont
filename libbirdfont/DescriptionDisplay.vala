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
	
	TextArea? keyboard_focus = null;
	
	TextArea postscript_name;
	TextArea name;
	TextArea style;
	TextArea weight;
	TextArea full_name;
	TextArea unique_id;
	TextArea version;
	TextArea description;
	TextArea copyright;
	
	Gee.ArrayList<Widget> widgets;
	
	public DescriptionDisplay () {
		double margin = 12 * MainWindow.units;
		double label_size = 20 * MainWindow.units;
		double label_margin = 4 * MainWindow.units;
		Headline headline;
		Font font = BirdFont.get_current_font ();
		
		allocation = new WidgetAllocation ();
		
		widgets = new Gee.ArrayList<Widget> ();
		
		postscript_name = new LineTextArea (label_size);
		name = new LineTextArea (label_size);
		style = new LineTextArea (label_size);
		weight = new LineTextArea (label_size);
		full_name = new LineTextArea (label_size);
		unique_id = new LineTextArea (label_size);
		version = new LineTextArea (label_size);
		description = new TextArea (label_size);
		copyright = new TextArea (label_size);

		headline = new Headline (t_("Name and Description"));
		headline.margin_bottom = 20 * MainWindow.units;
		widgets.add (headline);

		widgets.add (new Text (t_("PostScript Name"), label_size, label_margin));
		postscript_name.margin_bottom = margin;
		postscript_name.set_text (font.postscript_name);
		postscript_name.text_changed.connect ((t) => {
			font.postscript_name = t;
		});
		widgets.add (postscript_name);
		
		widgets.add (new Text (t_("Name"), label_size, label_margin));
		name.margin_bottom = margin;
		name.set_text (font.name);
		name.text_changed.connect ((t) => {
			font.name = t;
		});
		widgets.add (name);
				
		widgets.add (new Text (t_("Style"), label_size, label_margin));
		style.margin_bottom = margin;
		style.set_text (font.subfamily);
		style.text_changed.connect ((t) => {
			font.subfamily = t;
		});
		widgets.add (style);
		
		widgets.add (new Text (t_("Weight"), label_size, label_margin));
		weight.margin_bottom = margin;
		weight.set_text (font.get_weight ());
		weight.text_changed.connect ((t) => {
			font.set_weight (t);
		});
		widgets.add (weight);
		
		widgets.add (new Text (t_("Full Name (Name and Style)"), label_size, label_margin));
		full_name.margin_bottom = margin;
		full_name.set_text (font.full_name);
		full_name.text_changed.connect ((t) => {
			font.full_name = t;
		});
		widgets.add (full_name);
		
		widgets.add (new Text (t_("Unique Identifier"), label_size, label_margin));
		unique_id.margin_bottom = margin;
		unique_id.set_text (font.unique_identifier);
		unique_id.text_changed.connect ((t) => {
			font.unique_identifier = t;
		});
		widgets.add (unique_id);
		
		widgets.add (new Text (t_("Version"), label_size, label_margin));
		version.margin_bottom = margin;
		version.set_text (font.version);
		version.text_changed.connect ((t) => {
			font.version = t;
		});
		widgets.add (version);

		widgets.add (new Text (t_("Description"), label_size, label_margin));
		description.margin_bottom = margin;
		description.set_text (font.description);
		description.text_changed.connect ((t) => {
			font.description = t;
		});
		widgets.add (description);
		
		widgets.add (new Text (t_("Copyright"), label_size, label_margin));
		copyright.margin_bottom = margin;
		copyright.set_text (font.copyright);
		copyright.text_changed.connect ((t) => {
			font.copyright = t;
		});
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
				cr.set_source_rgba (0, 0, 0, 1);
				w.draw (cr);
				cr.restore ();
			} else {
				w.draw (cr);
			}
		}
	}	

	void layout () {
		double y = -scroll;
		double margin;
		
		foreach (Widget w in widgets) {
			w.widget_x = 17 * MainWindow.units;
			w.widget_y = y;
			w.allocation = allocation;
			y += w.get_height () + w.margin_bottom;
		}
		
		content_height = y + scroll;
		update_scrollbar ();
	}

	public override void key_press (uint keyval) {
		unichar c = (unichar) keyval;
		string s;
		TextArea focus;
		
		if (keyboard_focus == null) {
			return;
		}
		
		focus = (!) keyboard_focus;
		if (!KeyBindings.has_alt () && !KeyBindings.has_ctrl ()) {
			switch (c) {
				case Key.RIGHT:
					focus.move_carret_next ();
					break;
				case Key.LEFT:
					focus.move_carret_previous ();
					break;
				case Key.BACK_SPACE:
					focus.remove_last_character ();
					break;
				case Key.ENTER:
					focus.insert_text ("\n");
					break;				
				default:
					if (!is_modifier_key (keyval)) {
						s = (!) c.to_string ();
						if (s.validate () && keyboard_focus != null) {
							focus.insert_text (s);
						}
					}
					break;
			}
		}
		
		GlyphCanvas.redraw ();
	}

	public override void button_press (uint button, double x, double y) {
		TextArea t;
		
		if (keyboard_focus != null) {
			t = (!) keyboard_focus;
			t.draw_carret = false;
			keyboard_focus = null;
		}
		
		foreach (Widget w in widgets) {
			if (w.widget_x <= x <= w.widget_x + w.get_width ()
				&&  w.widget_y <= y <= w.widget_y + w.get_height ()) {
				
				if (w is TextArea) {
					t = (TextArea) w;
					t.draw_carret = true;
					keyboard_focus = t;
				}
			}
		}

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
