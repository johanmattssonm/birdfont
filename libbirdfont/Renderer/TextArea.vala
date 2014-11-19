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
	
	public bool draw_carret {
		get { return carret_is_visible; }
		set { 
			carret_is_visible = value; 
			if (!value) {
				update_selection = false;
				selection_end = carret;
			}
		}
	}
	public bool carret_is_visible = false;
	public bool draw_border = true;

	public double width;
	public double height;

	int carret = 0;
	int selection_end = -1;
	bool update_selection = false;
	
	string text = "";
	int text_length = 0;
		
	int iter_pos;
	
	public signal void text_changed (string text);
	Gee.ArrayList<Paragraph> paragraphs = new Gee.ArrayList<Paragraph>  ();
	
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
	
	void generate_paragraphs () {
		Paragraph paragraph;
		string[] p = text.split ("\n");
		double y = 200;
		
		foreach (string t in p) {
			paragraph = new Paragraph (t);
			paragraphs.add (paragraph);
			paragraph.y = y;
			
			y += 200;
		}
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
	
	public string get_selected_text () {
		int start, stop;
		
		if (!has_selection ()) {
			return "".dup ();
		}
		
		start = (carret < selection_end) ? carret : selection_end;
		stop = (carret > selection_end) ? carret : selection_end;
		
		return text.substring (start, stop - start);
	}
	
	public void select_all () {
		carret = 0;
		selection_end = text_length;
	}
	
	public void delete_selected_text () {
		int start = (carret < selection_end) ? carret : selection_end;
		int stop = (carret > selection_end) ? carret : selection_end;
		set_text (text.substring (0, start) + text.substring (stop));
		selection_end = -1;
		carret = start;
	}
	
	public void remove_last_character () {
		int last_index = 0;
		int index = 0;
		unichar c;
		
		while (text.get_next_char (ref index, out c) && index < carret) {
			last_index = index;
		}
		
		set_text (text.substring (0, last_index) + text.substring (carret));
		selection_end = -1;
		carret = last_index;
	}
	
	public void remove_next_character () {
		int index = carret;
		unichar c;		
		text.get_next_char (ref index, out c);
		set_text (text.substring (0, carret) + text.substring (index));
	}
	
	public void move_carret_next () {
		int index = 0;
		int index_space;
		unichar c;
		char* s = (char*) text + carret;
		string n = (string) s;

		if (!has_selection () && KeyBindings.has_shift ()) {
			selection_end = carret;
		} else if (!KeyBindings.has_shift ()) {
			selection_end = -1;
		}
		
		n.get_next_char (ref index, out c);
		
		if (KeyBindings.has_ctrl ()) {
			index_space = n.index_of (" ", index);
			if (index_space != -1) {
				index = index_space;
			}
		}
		
		carret += index;
	}

	public void move_carret_previous () {
		int last_index = 0;
		int index = 0;
		unichar c;
		int index_space;
		
		while (text.get_next_char (ref index, out c) && index < carret) {
			last_index = index;
		}
		
		if (!has_selection () && KeyBindings.has_shift ()) {
			selection_end = carret;
		} else if (!KeyBindings.has_shift ()) {
			selection_end = -1;
		}

		if (KeyBindings.has_ctrl ()) {
			index_space = text.last_index_of (" ", last_index);
			if (index_space != -1) {
				last_index = index_space;
			}
		}
				
		carret = last_index;
	}
	
	public bool has_selection () {
		return selection_end >= 0 && selection_end != carret;
	}
		
	public void insert_text (string t) {
		string s;
		
		if (single_line) {
			s = t.replace ("\n", "").replace ("\r", "");
		} else {
			s = t;
		}

		if (has_selection ()) {
			delete_selected_text ();
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
	
	/** @return offset to click in text. */
	public int layout (double click_x = -1, double click_y = -1) {
		Text word;
		double p;
		double tx, ty;
		string w;
		double xmax = 0;
		double width = this.width - 2 * padding;
		double height = this.height - 2 * padding;
		bool carret_visibility;
		int carret_position = text_length;

		word = new Text ();
		word.set_font_size (font_size);
		
		tx = 0;
		ty = font_size;
		iter_pos = 0;
		while (iter_pos < text_length) {
			w = get_next_word (out carret_visibility, ref iter_pos);
			
			if (w == "") {
				break;
			}

			word.set_text (w);
			
			p = word.get_sidebearing_extent ();
			
			if (!single_line) {
				if (tx + p > width || w == "\n") {
					tx = 0;
					ty += font_size;
					
					if (ty + widget_y > 2 * allocation.height) {
						height = widget_y + 2 * allocation.height;
						break;
					}
				}
			}
			
			if (widget_y + ty - font_size <= click_y <= widget_y + ty + padding
				&& widget_x + tx <= click_x) {
				carret_position = find_carret_pos_in_word (word, iter_pos, tx, click_x);
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

		if (click_x > 0 && click_x < widget_x + padding) {
			carret_position = 0;
		}
				
		return carret_position;
	}
	
	private int find_carret_pos_in_word (Text word, int iter_pos, double tx, double click_x) {
		double wx = widget_x + tx + padding;
		double ratio = word.get_scale ();
		int i = 0;
		double d = 0;
		double min_d = Math.fabs (click_x - wx);
		int carret_position;
		string w = word.text;
		
		carret_position = iter_pos - w.length;
		word.iterate ((glyph, kerning, last) => {
			glyph.add_help_lines ();
			
			i += ((!) glyph.get_unichar ().to_string ()).length;
			wx += (glyph.get_width () + kerning) * ratio;
			d = Math.fabs (wx - click_x);
			if (d < min_d) {
				min_d = d;
				carret_position = iter_pos - w.length + i;
			}
		});
			
		d = Math.fabs (click_x - wx);
		if (d < min_d) {
			min_d = d;
			carret_position = iter_pos + i;
		}
		
		return carret_position;
	}
	
	public void button_press (uint button, double x, double y) {
		if (is_over (x, y)) {
			carret = layout (x, y);
			selection_end = carret;
			update_selection = true;
		}
	}

	public void button_release (uint button, double x, double y) {
		update_selection = false;
	}
	
	public bool motion (double x, double y) {
		if (update_selection) {
			selection_end = layout (x, y);
		}
		
		return update_selection;
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
		int selection_start, selection_stop;
		unichar c;
		
		layout ();

		if (draw_border) {
			// background
			cr.save ();
			cr.set_line_width (1);
			cr.set_source_rgba (101 / 255.0, 108 / 255.0, 116 / 255.0, 1);
			draw_rounded_rectangle (cr, x, y, this.width, this.height, padding);
			cr.fill ();
			cr.restore ();
			
			// border
			cr.save ();
			cr.set_line_width (1);
			draw_rounded_rectangle (cr, x, y, this.width, this.height, padding);
			cr.stroke ();
			cr.restore ();
		}
		
		cr.save ();

		word = new Text ();
		
		width = this.width - padding;
		x += padding;
		word.set_font_size (font_size);
		scale = word.get_scale ();
		y += font_size;
		
		if (draw_carret && carret == 0) {
			draw_carret_at (cr, x + padding, y + padding - 1);
		}
		
		// draw selection background
		if (selection_end >= 0 && selection_end != carret) {
			tx = 0;
			ty = 0;

			selection_start = carret < selection_end ? carret : selection_end;
			selection_stop = carret > selection_end ? carret : selection_end;
			
			cr.save ();
			cr.set_source_rgba (234 / 255.0, 77 / 255.0, 26 / 255.0, 1);
			iter_pos = 0;
			
			tx = 0;
			ty = 0;
			iter_pos = 0;
			while (iter_pos < text_length) {
				w = get_next_word (out carret_at_end_of_word, ref iter_pos);
				
				if (w == "") {
					break;
				}
				
				word.set_text (w);
				p = word.get_sidebearing_extent ();
				
				if (tx + p > width || w == "\n") {
					tx = 0;
					ty += font_size;
				}
				
				if (y + ty > allocation.height) {
					break;
				}
				
				if (w != "\n") {
					iter_pos -= w.length;
					word.iterate ((glyph, kerning, last) => {
						double selection_y;
						double cw;
						
						glyph.add_help_lines ();
						
						iter_pos += ((!) glyph.get_unichar ().to_string ()).length;
						cw = (glyph.get_width () + kerning) * word.get_scale ();
						tx += cw;
						
						if (selection_start < iter_pos <= selection_stop) { 
							selection_y = y + ty + scale * - word.font.bottom_limit - font_size;
							cr.rectangle (x + tx - 1 - cw, selection_y, cw + 1, font_size);
							cr.fill ();
						}
					});
				}
			}
			
			cr.restore ();
		}
		

		// draw characters
		tx = 0;
		ty = 0;
		iter_pos = 0;
		while (iter_pos < text_length) {
			w = get_next_word (out carret_at_end_of_word, ref iter_pos);
			
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

			if (y + ty > allocation.height) {
				break;
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
	
	unichar get_next_char (ref int iter_pos) {
		unichar n;

		if (iter_pos >= text_length) {
			return '\0';
		}
		
		n = text.get_char (iter_pos);
		iter_pos += ((!) n.to_string ()).length;		
		
		return n;
	}
	
	string get_next_word (out bool carret_at_end_of_word, ref int iter_pos) {
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
	
	class Paragraph : GLib.Object {
		public double x = -1;
		public double y = -1;
		public string text;
		public Gee.ArrayList<Text> words = new Gee.ArrayList<Text> ();
		
		public Paragraph (string text) {
			this.text = text;
		}
		
	}
}

}
