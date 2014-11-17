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

public class TextArea : Widget {
	
	public double min_width = 500;
	public double min_height = 100;
	public double font_size;
	public double padding = 3.3;
	public bool single_line = false;
	
	public bool draw_carret = false;
	public bool draw_border = true;

	public double width;
	public double height;

	int carret = 0;
	string text = "";
	int text_length = 0;
		
	int iter_pos;
	
	public signal void text_changed (string text);
	
	public TextArea (double font_size = 14) {
		this.font_size = font_size;
		width = min_width;
		height = min_height;
	}

	public override double get_height () {
		return height;
	}

	public override double get_width () {
		return width;
	}

	public void set_font_size (double z) {
		font_size = z;
	}
	
	public void set_text (string t) {
		int tl;
		
		if (single_line) {
			text = t.replace ("\n", "").replace ("\r", "");
		} else {
			text = t;
		}
		
		tl = t.length;
		carret = tl;
		text_length += tl;
		
		text_changed (text);
	}
	
	public void remove_last_character () {
		int last_index = 0;
		int index = 0;
		unichar c;
		
		while (text.get_next_char (ref index, out c) && index < carret) {
			last_index = index;
		}
		
		set_text (text.substring (0, last_index) + text.substring (carret));
	}
	
	public void move_carret_next () {
		int index = 0;
		unichar c;
		char* s = (char*) text + carret;
		string n = (string) s;
		
		n.get_next_char (ref index, out c);
		carret += index;
	}

	public void move_carret_previous () {
		int last_index = 0;
		int index = 0;
		unichar c;
		
		while (text.get_next_char (ref index, out c) && index < carret) {
			last_index = index;
		}
		
		carret = last_index;
	}
		
	public void insert_text (string t) {
		string s;
		
		if (single_line) {
			s = t.replace ("\n", "").replace ("\r", "");
		} else {
			s = t;
		}

		string nt = text.substring (0, carret);
		int tl = s.length;
		nt += s;
		nt += text.substring (carret);
		carret += tl;
		text = nt;
		text_length += tl;
		
		text_changed (text);
	}
	
	public void layout () {
		Text word;
		double p;
		double tx, ty;
		string w;
		double xmax = 0;
		double width = this.width - 2 * padding;
		double height = this.height - 2 * padding;
		bool carret_visibility;
		
		iter_pos = 0;
		word = new Text ();
		word.set_font_size (font_size);
		
		tx = 0;
		ty = font_size;
		while (iter_pos < text_length) {
			w = get_next_word (out carret_visibility);
			
			if (w == "") {
				break;
			}

			word.set_text (w);
			
			p = word.get_sidebearing_extent ();
			
			if (!single_line) {
				if (tx + p > width || w == "\n") {
					tx = 0;
					ty += font_size;
				}
			}
			
			if (w != "\n") {
				tx += p;
			}
			
			if (tx > xmax) {
				xmax = tx;
			}
		}
		
		this.width = min_width;
		
		if (xmax > width) {
			this.width = xmax + 2 * padding;
		}
		
		this.height = fmax (min_height, ty + 2 * padding);
	}
	
	public override void draw (Context cr) {
		Text word;
		double p;
		double tx, ty;
		string w;
		bool carret_at_end_of_word;
		double scale;
		double width;
		double x = widget_x;
		double y = widget_y;
		
		layout ();

		if (draw_border) {
			// background
			cr.save ();
			cr.set_line_width (1);
			cr.set_source_rgba (101 / 255.0, 108 / 255.0, 116 / 255.0, 1);
			create_border (cr, x, y);
			cr.fill ();
			cr.restore ();
			
			// border
			cr.save ();
			cr.set_line_width (1);
			create_border (cr, x, y);
			cr.stroke ();
			cr.restore ();
		}
		
		cr.save ();
		
		iter_pos = 0;
		word = new Text ();
		
		width = this.width - padding;
		x += padding;
		word.set_font_size (font_size);
		scale = word.get_scale ();
		y += font_size;
		
		if (draw_carret && iter_pos == 0 && text_length == 0) {
			draw_carret_at (cr, x + padding, y + padding);
		}
		
		tx = 0;
		ty = 0;
		while (iter_pos < text_length) {
			w = get_next_word (out carret_at_end_of_word);
			
			if (w == "") {
				break;
			}
			
			word.set_text (w);
			p = word.get_sidebearing_extent ();
			
			if (tx + p > width || w == "\n") {
				tx = 0;
				ty += font_size;
			}
			
			if (w != "\n") {
				word.draw_at_baseline (cr, x + tx, y + ty);
				tx += p;
			}
			
			if (carret_at_end_of_word && draw_carret) {
				draw_carret_at (cr, x + tx, y + ty + scale * - word.font.bottom_limit);
			}
		}
		cr.restore ();
	}
	
	void draw_carret_at (Context cr, double x, double y) {
		cr.save ();
		cr.set_source_rgba (0, 0, 0, 0.5);
		cr.set_line_width (1);
		cr.move_to (x, y);
		cr.line_to (x, y - font_size);
		cr.stroke ();
		cr.restore ();		
	}
	
	string get_next_word (out bool carret_at_end_of_word) {
		int i;
		int ni;
		int pi;
		string n;
		int nl;
		
		carret_at_end_of_word = false;
		
		if (iter_pos >= text_length) {
			carret_at_end_of_word = true;
			return "".dup ();
		}
		
		if (text.get_char (iter_pos) == '\n') {
			iter_pos += "\n".length;
			carret_at_end_of_word = (iter_pos == carret);
			return "\n".dup ();
		}
		
		i = text.index_of (" ", iter_pos);
		pi = i + " ".length;
		
		ni = text.index_of ("\t", iter_pos);
		if (ni != -1 && ni < pi || i == -1) {
			i = ni;
			pi = i  + "\t".length;
		}
		
		ni = text.index_of ("\n", iter_pos);
		if (ni != -1 && ni < pi || i == -1) {
			i = ni;
			pi = i;
		}
		
		if (iter_pos + iter_pos - pi > text_length || i == -1) {
			n = text.substring (iter_pos);
		} else {
			n = text.substring (iter_pos, pi - iter_pos);
		}
		
		nl = n.length;
		if (iter_pos < carret < iter_pos + nl) {
			n = text.substring (iter_pos, carret - iter_pos);
			nl = n.length;
			carret_at_end_of_word = true;
		}
		
		iter_pos += nl;
		
		if (iter_pos == carret) {
			carret_at_end_of_word = true;
		}
		
		return n;
	}

	void create_border (Context cr, double x, double y) {
		double radius = padding;		
		double w = width;
		double h = height;
		
		cr.move_to (x, y + radius);
		cr.arc (x + radius, y + radius, radius, 2 * (PI / 2), 3 * (PI / 2));
		cr.line_to (x + w - radius, y);
		cr.arc (x + w - radius, y + radius, radius, 3 * (PI / 2), 4 * (PI / 2));
		cr.line_to (x + w, y + h);		
		cr.arc (x + w - radius, y + h, radius, 4 * (PI / 2), 5 * (PI / 2));
		cr.line_to (x + radius, y + h + radius);
		cr.arc (x + radius, y + h, radius, 5 * (PI / 2), 6 * (PI / 2));
		cr.line_to (x, y + radius);
		cr.close_path ();		
	}
}

}
