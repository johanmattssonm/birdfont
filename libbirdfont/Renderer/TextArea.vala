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
	int last_paragraph = 0;
	
	public signal void text_changed (string text);
	Gee.ArrayList<Paragraph> paragraphs = new Gee.ArrayList<Paragraph>  ();
	private static const int DONE = -2; 
	
	int64 cache_id = -1;
	
	public TextArea (double font_size = 20) {
		this.font_size = font_size;
		width = min_width;
		height = min_height;
	}

	public override double get_height () {
		return height + 2 * padding;
	}

	public override double get_width () {
		return width + 2 * padding;
	}

	public void set_font_size (double z) {
		font_size = z;
	}
	
	void generate_paragraphs () {
		Paragraph paragraph;

		int next_paragraph = -1;
		
		if (last_paragraph == DONE) {
			return;
		}
	
		next_paragraph = text.index_of ("\n", last_paragraph);
		
		if (next_paragraph == -1) {
			paragraph = new Paragraph (text.substring (last_paragraph), font_size);
			paragraphs.add (paragraph);
			last_paragraph = DONE;
		} else {
			next_paragraph +=  "\n".length;
			paragraph = new Paragraph (text.substring (last_paragraph, next_paragraph - last_paragraph), font_size);
			paragraphs.add (paragraph);
			last_paragraph = next_paragraph;
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
		
		paragraphs.clear ();
		generate_paragraphs ();
		
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
		
		paragraphs.clear (); // DELETE
		generate_paragraphs (); // FIXME:
		
		text_changed (text);
	}
	
	/** @return offset to click in text. */
	public int layout (double click_x = -1, double click_y = -1) {
		double p;
		double tx, ty;
		string w;
		double xmax = 0;
		double width = this.width - 2 * padding;
		int carret_position = text_length;
		
		tx = 0;
		ty = font_size;
		iter_pos = 0;
										
		foreach (Paragraph paragraph in paragraphs) {
			if (paragraph.need_layout) {
				paragraph.start_y = ty;
				paragraph.start_x = tx;
				
				foreach (Text next_word in paragraph.words) {
					w = next_word.text;
					p = next_word.get_sidebearing_extent ();
					
					if (w == "") {
						break;
					}

					if (!single_line) {
						if (tx + p > width || w == "\n") {
							tx = 0;
							ty += next_word.font_size;
						}
					}
					
					if (widget_y + ty - font_size <= click_y <= widget_y + ty + padding
						&& widget_x + tx <= click_x) {
						carret_position = find_carret_pos_in_word (next_word, iter_pos, tx, click_x);
					}
												
					if (w != "\n") {
						tx += p;
					}
					
					if (tx > xmax) {
						xmax = tx;
					}
				}
				
				paragraph.width = xmax;
				paragraph.end_x = tx;
				paragraph.end_y = ty;
				paragraph.need_layout = false;
			}
									
			tx = paragraph.end_x;
			ty = paragraph.end_y;
		}
		
		this.width = min_width;
		
		if (xmax > width) {
			this.width = xmax + 2 * padding;
		}
		
		this.height = fmax (min_height, ty + 2 * padding);

		if (click_x > 0 && click_x < widget_x + padding) {
			carret_position = 0;
		}

		if (last_paragraph != DONE) {
			this.height = (text_length / (double) last_paragraph) * ty + 2 * padding; // estimate height
		}
		
		if (ty + widget_y < allocation.height && last_paragraph != DONE) {
			generate_paragraphs ();
			return layout (click_x, click_y);
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
			cr.set_source_rgba (0, 0, 0, 1);
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
		// FIXME: put back
		/*
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
		*/

		tx = 0;
		ty = 0;	
		
		int first_visible = 0;
		int last_visible;
		int paragraphs_size = paragraphs.size;
		while (first_visible < paragraphs_size) {
			if (paragraphs.get (first_visible).text_is_on_screen (allocation, widget_y)) {
				break;
			}
			first_visible++;
		}
		
		last_visible = first_visible;
		while (last_visible < paragraphs_size) {
			if (!paragraphs.get (last_visible).text_is_on_screen (allocation, widget_y)) {
				last_visible++;
				break;
			}
			last_visible++;
		}	
		
		if (paragraphs_size == 0) {
			return;
		}
		
		Context cc; // cached context
		double cc_x, cc_y;
		Paragraph paragraph;
		paragraph = paragraphs.get (0);
		
		tx = paragraph.start_x;
		ty = paragraph.start_y;

		if (cache_id == -1 && paragraphs.size > 0 && paragraphs.get (0).words.size > 0) {
			Text t = paragraphs.get (0).words.get (0);
			t.set_source_rgba (0, 0, 0, 1);
			cache_id = t.get_cache_id ();
		}
				
		for (int i = first_visible; i < last_visible; i++) { 
			paragraph = paragraphs.get (i);
			
			tx = paragraph.start_x;
			ty = paragraph.start_y;

			if (paragraph.cached_surface == null) {		
				paragraph.cached_surface = new Surface.similar (cr.get_target (), Cairo.Content.COLOR_ALPHA, paragraph.get_width (), paragraph.get_height () + (int) font_size + 1);
				cc = new Context ((!) paragraph.cached_surface);
		
				cc_x = paragraph.start_x;
				cc_y = 0;
				
				foreach (Text next_word in paragraph.words) {
					w = next_word.text;
					
					next_word.set_source_rgba (0, 0, 0, 1);
					
					p = next_word.get_sidebearing_extent ();
					
					if (cc_x + p > width || w == "\n") {
						cc_x = 0;
						cc_y += next_word.font_size;
					}
					
					if (w != "\n") {
						next_word.draw_at_top (cc, cc_x, cc_y, cache_id);
						cc_x += p;
					}
				}
			}
			
			if (likely (paragraph.cached_surface != null)) {
				cr.set_source_surface ((!) paragraph.cached_surface, x + tx, widget_y + paragraph.start_y - font_size + padding);
				cr.paint ();
			} else {
				warning ("No paragraph image.");
			}
		}
		
/*
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
		*/
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
		public double end_x = -10000;
		public double end_y = -10000;
		
		public double start_x = -10000;
		public double start_y = -10000;
		
		public double width = -10000;
		
		public string text;
		public Gee.ArrayList<Text> words = new Gee.ArrayList<Text> ();
		
		int text_length;
		
		public bool need_layout = true;
		
		public Surface? cached_surface = null;
		
		public Paragraph (string text, double font_size) {
			this.text = text;
			text_length = text.length;
			generate_words (font_size);
		}

		public int get_height () {
			return (int) (end_y - start_y) + 1;
		}
		
		public int get_width () {
			return (int) width + 1;
		}
		
		public bool text_is_on_screen (WidgetAllocation alloc, double widget_y) {
			bool v = (0 <= start_y + widget_y <= alloc.height)
				|| (0 <= end_y + widget_y <= alloc.height)
				|| (start_y + widget_y <= 0 && alloc.height <= end_y + widget_y);
			return v;
		}

		void generate_words (double font_size) {
			string w;
			int p = 0;
			bool carret_at_word_end = false;
			Text word;
			int carret = 0;
			int iter_pos = 0;

			while (p < text_length) {
				w = get_next_word (out carret_at_word_end, ref iter_pos, carret);
				
				if (w == "") {
					break;
				}
				
				word = new Text (w, font_size);
				words.add (word);
			}
		}

		string get_next_word (out bool carret_at_end_of_word, ref int iter_pos, int carret) {
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
	}
}

}
