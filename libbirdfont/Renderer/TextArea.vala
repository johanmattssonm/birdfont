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
	public double margin = 10;
	
	public bool draw_carret = true;
	public bool draw_border = true;

	private double width;
	private double height;

	int carret = 0;
	string text = "";
	int text_length = 0;
		
	int iter_pos;
	
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
		int tl = t.length;
		text = t;
		carret = tl;
		text_length += tl;
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
	
	public void insert_text (string t) {
		string nt = text.substring (0, carret);
		int tl = t.length;
		nt += t;
		nt += text.substring (carret);
		carret += tl;
		text = nt;
		text_length += tl;
	}
	
	void layout () {
		Text word;
		double p;
		double tx, ty;
		string w;
		double xmax = 0;
		double width = this.width - 2 * margin;
		double height = this.height - 2 * margin;
		
		iter_pos = 0;
		word = new Text ();
		word.set_font_size (font_size);
		
		tx = 0;
		ty = 0;
		while (iter_pos < text_length) {
			w = get_next_word (out draw_carret);
			
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
				tx += p;
			}
			
			if (tx > xmax) {
				xmax = tx;
			}
		}
		
		this.width = min_width;
		
		if (xmax > width) {
			this.width = xmax + 2 * margin;
		}
		
		this.height = fmax (min_height, ty + 2 * margin);
	}
	
	public override void draw (Context cr) {
		Text word;
		double p;
		double tx, ty;
		string w;
		bool draw_carret;
		double carret_y;
		double scale;
		double width;
		double x = widget_x;
		double y = widget_y;
		
		layout ();

		if (draw_border) {
			// background
			cr.save ();
			cr.set_line_width (1);
			cr.set_source_rgba (1, 1, 1, 1);
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
		cr.set_source_rgba (38 / 255.0, 39 / 255.0, 43 / 255.0, 1);
		
		iter_pos = 0;
		word = new Text ();
		
		width = this.width - margin;
		x += margin;
		word.set_font_size (font_size);
		scale = word.get_scale ();
		//y += font_size - scale * (word.font.bottom_limit - word.font.base_line);
		y += font_size;
		
		tx = 0;
		ty = 0;
		while (iter_pos < text_length) {
			w = get_next_word (out draw_carret);
			
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
			
			if (draw_carret && this.draw_carret) {
				cr.save ();
				cr.set_line_width (1);
				carret_y = y + ty;
				carret_y += scale * -word.font.bottom_limit;
				cr.move_to (x + tx, carret_y);
				cr.line_to (x + tx, carret_y - font_size);
				cr.stroke ();
				cr.restore ();
			}
		}
		cr.restore ();
	}
	
	string get_next_word (out bool draw_carret) {
		int i;
		int ni;
		int pi;
		string n;
		int nl;
		
		draw_carret = false;
		
		if (iter_pos >= text_length) {
			draw_carret = true;
			return "".dup ();
		}
		
		if (text.get_char (iter_pos) == '\n') {
			iter_pos += "\n".length;
			draw_carret = (iter_pos == carret);
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
			draw_carret = true;
		}
		
		iter_pos += nl;
		
		if (iter_pos == carret) {
			draw_carret = true;
		}
		
		return n;
	}

	void create_border (Context cr, double x, double y) {
		double radius = margin;		
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
