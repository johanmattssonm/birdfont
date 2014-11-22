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
				selection_end = carret.copy ();
			}
		}
	}
	public bool carret_is_visible = false;
	public bool draw_border = true;

	public double width;
	public double height;

	Carret carret = new Carret ();
	Carret selection_end = new Carret ();
	bool update_selection = false;
	public bool show_selection = false;
	
	public signal void scroll (double pixels);
	public signal void text_changed (string text);
	
	Gee.ArrayList<Paragraph> paragraphs = new Gee.ArrayList<Paragraph>  ();
	private static const int DONE = -2; 
	
	int64 cache_id = -1;
	
	int last_paragraph = 0;
	string text;
	int text_length;
	
	Gee.ArrayList<TextUndoItem> undo_items = new Gee.ArrayList<TextUndoItem> ();
	Gee.ArrayList<TextUndoItem> redo_items = new Gee.ArrayList<TextUndoItem> ();
	
	bool store_undo_state_at_next_event = false;
	
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
			paragraph = new Paragraph (text.substring (last_paragraph), font_size, paragraphs.size);
			paragraphs.add (paragraph);
			last_paragraph = DONE;
		} else {
			next_paragraph +=  "\n".length;
			paragraph = new Paragraph (text.substring (last_paragraph, next_paragraph - last_paragraph), font_size, paragraphs.size);
			paragraphs.add (paragraph);
			last_paragraph = next_paragraph;
		}
	}
	
	public void key_press (uint keyval) {
		unichar c;
		TextUndoItem ui;
		
		c = (unichar) keyval;
			
		switch (c) {
			case ' ':
				store_undo_edit_state ();
				add_character (keyval);
				break;
			case 'a':
				if (KeyBindings.has_ctrl ()) {
					select_all ();
				} else {
					add_character (keyval);
				}
				break;
			case 'c':
				if (KeyBindings.has_ctrl ()) {
					ClipTool.copy_text (this);
				} else {
					add_character (keyval);
				}
				break;
			case 'v':
				if (KeyBindings.has_ctrl ()) {
					store_undo_edit_state ();
					ClipTool.paste_text (this);
					store_undo_state_at_next_event = true;
				} else {
					add_character (keyval);
				}
				break;
			case 'y':
				if (KeyBindings.has_ctrl ()) {
					redo ();
				} else {
					add_character (keyval);
				}
				break;
			case 'z':
				if (KeyBindings.has_ctrl ()) {
					undo ();
				} else {
					add_character (keyval);
				}
				break;
			case Key.RIGHT:
				move_carret_next ();
				break;
			case Key.LEFT:
				move_carret_previous ();
				break;
			case Key.DOWN:
				move_carret_next_row ();
				break;
			case Key.UP:
				move_carret_previous_row ();
				break;
			case Key.BACK_SPACE:
				if (has_selection ()) {
					ui = delete_selected_text ();
					undo_items.add (ui);
					redo_items.clear ();
					store_undo_state_at_next_event = true;
				} else {
					ui = remove_last_character ();
					undo_items.add (ui);
					redo_items.clear ();
					store_undo_state_at_next_event = true;
				}
				break;
			case Key.ENTER:
				store_undo_edit_state ();
				insert_text ("\n");
				break;
			case Key.DEL:
				if (has_selection ()) {
					ui = delete_selected_text ();
					undo_items.add (ui);
					redo_items.clear ();
					store_undo_state_at_next_event = true;
				} else {
					ui = remove_next_character ();
					undo_items.add (ui);
					redo_items.clear ();
					store_undo_state_at_next_event = true;
				}
				break;		
			default:
				add_character (keyval);
				break;
		}
		
		GlyphCanvas.redraw ();
	}

	private void add_character (uint keyval) {
		unichar c = (unichar) keyval;
		string s;
		TextArea focus;
		TextUndoItem ui;
		
		if (!is_modifier_key (keyval)) {
			s = (!) c.to_string ();		
			
			if (s.validate ()) {				
				if (store_undo_state_at_next_event) {
					store_undo_edit_state ();
					store_undo_state_at_next_event = false;
				}
				
				insert_text (s);
			}
		}
	}

	Paragraph get_current_paragraph () {
		Paragraph p;
		return_val_if_fail (0 <= carret.paragraph < paragraphs.size, new Paragraph ("", 0, 0));
		p = paragraphs.get (carret.paragraph);
		return p;
	}

	public void set_text (string t) {
		int tl;
		
		if (single_line) {
			text = t.replace ("\n", "").replace ("\r", "");
		} else {
			text = t;
		}
		
		tl = t.length;		
		text_length += tl;
		
		paragraphs.clear ();
		generate_paragraphs ();
		
		return_if_fail (paragraphs.size != 0);
		
		carret.paragraph = paragraphs.size - 1;
		carret.character_index = paragraphs.get (paragraphs.size - 1).text.length;
		selection_end = carret.copy ();
		show_selection = false;
		
		text_changed (get_text ());
	}
	
	public string get_selected_text () {
		if (!has_selection ()) {
			return "".dup ();
		}
		
		//FIXME:
		return "".dup ();
	}
	
	public void select_all () {
		while (last_paragraph != DONE) {
			generate_paragraphs ();
		}
			
		if (paragraphs.size > 0) {
			carret.paragraph = 0;
			carret.character_index = 0;
			selection_end.paragraph = paragraphs.size - 1;
			selection_end.character_index = paragraphs.get (paragraphs.size - 1).text_length;
			show_selection = true;
		}
	}
	
	public TextUndoItem delete_selected_text () {
		Carret selection_start, selection_stop;
		int i;
		Paragraph pg, pge;
		string e, s, n;
		bool same;
		TextUndoItem ui;
		
		ui = new TextUndoItem (carret);
		
		e = "";
		s = "";
		n = "";
		
		if (!has_selection ()) {
			warning ("No selected text.");
			return ui;
		}
		
		if (carret.paragraph == selection_end.paragraph) {
			selection_start = carret.character_index < selection_end.character_index ? carret : selection_end;
			selection_stop = carret.character_index > selection_end.character_index ? carret : selection_end;
		} else {
			selection_start = carret.paragraph < selection_end.paragraph ? carret : selection_end;
			selection_stop = carret.paragraph > selection_end.paragraph ? carret : selection_end;	
		}
		
		same = selection_start.paragraph == selection_stop.paragraph;
		
		if (!same) {
			pg = paragraphs.get (selection_start.paragraph);
			s = pg.text.substring (0, selection_start.character_index);

			pge = paragraphs.get (selection_stop.paragraph);
			e = pge.text.substring (selection_stop.character_index);
							
			if (!s.has_suffix ("\n")) {
				ui.deleted.add (pge.copy ());
				ui.edited.add (pg.copy ());
				
				pg.set_text (s + e);
				pge.set_text ("");
			} else {
				ui.edited.add (pg.copy ());
				ui.edited.add (pge.copy ());
				
				pg.set_text (s);
				pge.set_text (e);
			}
		} else {
			pg = paragraphs.get (selection_start.paragraph);
			n = pg.text.substring (0, selection_start.character_index);
			n += pg.text.substring (selection_stop.character_index);
			
			if (n == "") {
				ui.deleted.add (pg.copy ());
				paragraphs.remove_at (selection_start.paragraph);
			} else {
				ui.edited.add (pg.copy ());
			}
			
			pg.set_text (n);
		}
		
		if (e == "" && !same) {
			paragraphs.remove_at (selection_stop.paragraph);
		}
		
		for (i = selection_stop.paragraph - 1; i > selection_start.paragraph; i--) {
			return_if_fail (0 <= i < paragraphs.size);
			ui.deleted.add (paragraphs.get (i));
			paragraphs.remove_at (i);
		}
		
		if (s == "" && !same) {
			paragraphs.remove_at (selection_start.paragraph);
		}
		
		carret = selection_start;
		selection_end = carret.copy ();
				
		show_selection = false;
		layout ();
		
		return ui;
	}
	
	public TextUndoItem remove_last_character () {
		TextUndoItem ui;
		move_carret_previous ();
		ui = remove_next_character ();
		return ui;
	}
	
	public TextUndoItem remove_next_character () {
		Paragraph paragraph;
		Paragraph next_paragraph;
		int index;
		unichar c;
		string np;
		TextUndoItem ui;
		
		ui = new TextUndoItem (carret);
		
		return_val_if_fail (0 <= carret.paragraph < paragraphs.size, ui);
		paragraph = paragraphs.get (carret.paragraph);
		
		index = carret.character_index;
	
		paragraph.text.get_next_char (ref index, out c);
		
		if (index >= paragraph.text_length) {
			np = paragraph.text.substring (0, carret.character_index);
			
			if (carret.paragraph + 1 < paragraphs.size) {
				next_paragraph = paragraphs.get (carret.paragraph + 1);
				paragraphs.remove_at (carret.paragraph + 1);
				
				np = np + next_paragraph.text;
				
				ui.deleted.add (next_paragraph);
			}
			
			paragraph.set_text (np);
			ui.edited.add (paragraph);
		} else {
			np = paragraph.text.substring (0, carret.character_index) + paragraph.text.substring (index);
			paragraph.set_text (np);

			if (np == "") {
				return_if_fail (carret.paragraph > 0);
				carret.paragraph--;
				paragraph = paragraphs.get (carret.paragraph);
				carret.character_index = paragraph.text_length;
				
				ui.deleted.add (paragraphs.get (carret.paragraph + 1));
				
				paragraphs.remove_at (carret.paragraph + 1);
			} else {
				ui.edited.add (paragraph);
			}
		}
		
		layout ();
		
		return ui;
	}
	
	public void move_carret_next () {
		Paragraph paragraph;
		int index;
		unichar c;
		
		return_if_fail (0 <= carret.paragraph < paragraphs.size);
		paragraph = paragraphs.get (carret.paragraph);
		
		index = carret.character_index;
		paragraph.text.get_next_char (ref index, out c);
		
		if (index >= paragraph.text_length && carret.paragraph + 1 < paragraphs.size) {
			carret.paragraph++;
			carret.character_index = 0;
		} else {
			carret.character_index = index;
		}
	}

	public void move_carret_previous () {
		Paragraph paragraph;
		int index, last_index;
		unichar c;
		
		return_if_fail (0 <= carret.paragraph < paragraphs.size);
		paragraph = paragraphs.get (carret.paragraph);
		
		index = 0;
		last_index = -1;
		
		while (text.get_next_char (ref index, out c) && index < carret.character_index) {
			last_index = index;
		}
		
		if (last_index <= 0 && carret.paragraph > 0) {
			carret.paragraph--;
			
			return_if_fail (0 <= carret.paragraph < paragraphs.size);
			paragraph = paragraphs.get (carret.paragraph);
			carret.character_index = paragraph.text_length;
			
			if (paragraph.text.has_suffix ("\n")) {
				carret.character_index -= "\n".length;
			}
		} else {
			carret.character_index = (last_index) > 0 ? last_index : 0;
		}
		
		return_if_fail (0 <= carret.paragraph < paragraphs.size);
	}
	
	public void move_carret_next_row () {
		double nr = font_size;
		
		if (carret.desired_y + 2 * font_size >= allocation.height) {
			scroll (2 * font_size);
			nr = -font_size;
		}
		
		if (carret.desired_y + nr < widget_y + height - padding) {
			carret = get_carret_at (carret.desired_x, carret.desired_y + nr);
		}
	}

	public void move_carret_previous_row () {
		double nr = -font_size;
		
		if (carret.desired_y - 2 * font_size < 0) {
			scroll (-2 * font_size);
			nr = font_size;
		}
		
		if (carret.desired_y + nr > widget_y + padding) {
			carret = get_carret_at (carret.desired_x, carret.desired_y + nr);
		}
	}
	
	public bool has_selection () {
		return show_selection && selection_is_visible ();
	}
	
	private bool selection_is_visible () {
		return carret.paragraph != selection_end.paragraph || carret.character_index != selection_end.character_index;
	}
	
	public void insert_text (string t) {
		string s;
		Paragraph paragraph;
		TextUndoItem ui;
				
		if (single_line) {
			s = t.replace ("\n", "").replace ("\r", "");
		} else {
			s = t;
			
			if (t.last_index_of ("\n") > 0) {
				string[] parts = t.split ("\n");
				int i;
				for (i = 0; i < parts.length -1; i++) {
					insert_text (parts[i]);
					insert_text ("\n");
				}

				insert_text (parts[parts.length - 1]);
				
				if (s.has_suffix ("\n")) {
					insert_text ("\n");
				}
				
				return;
			}
		}

		if (has_selection () && show_selection) {
			ui = delete_selected_text ();
			undo_items.add (ui);
			redo_items.clear ();
		}
		
		return_if_fail (0 <= carret.paragraph < paragraphs.size);
		paragraph = paragraphs.get (carret.paragraph);
		
		string nt = paragraph.text.substring (0, carret.character_index);
		int tl = s.length;
		nt += s;
		nt += paragraph.text.substring (carret.character_index);
		carret.character_index += tl;
	
		paragraph.set_text (nt);
		
		layout ();
		
		show_selection = false;
		
		text_changed (get_text ());
		
		// FIXME: new paragraphs
	}
	
	public string get_text () {
		StringBuilder sb = new StringBuilder ();
		foreach (Paragraph p in paragraphs) {
			sb.append (p.text);
		}
		return sb.str;
	}
	
	Carret get_carret_at (double click_x, double click_y) {
		int i = 0;
		double tx, ty;
		double p;
		string w;
		int ch_index;
		double min_d = double.MAX;
		Carret c = new Carret ();
		double dt;

		c.paragraph = -1;
		c.desired_x = click_x;
		c.desired_y = click_y;
		
		foreach (Paragraph paragraph in paragraphs) {
			if (paragraph.text_is_on_screen (allocation, widget_y)) {
				ch_index = 0;
				
				tx = paragraph.start_x;
				ty = paragraph.start_y + widget_y;
				
				foreach (Text next_word in paragraph.words) {
					w = next_word.text;
					
					next_word.set_source_rgba (0, 0, 0, 1);
					
					p = next_word.get_sidebearing_extent ();

					if ((ty - next_word.font_size + next_word.get_baseline_to_bottom () <= click_y <= ty + next_word.get_baseline_to_bottom ())
						&& (next_word.widget_x + widget_x + padding <= click_x <= next_word.widget_x + widget_x + padding + next_word.get_sidebearing_extent ())) {
						
						next_word.iterate ((glyph, kerning, last) => {
							double cw;
							int ci;
							double d;

							d = Math.fabs (click_x - (tx + widget_x + padding));
							if (d < min_d) {
								min_d = d;
								c.character_index = ch_index;
								c.paragraph = i;
							}
							
							cw = (glyph.get_width ()) * next_word.get_scale () + kerning;
							ci = ((!) glyph.get_unichar ().to_string ()).length;
							
							tx += cw;
							ch_index += ci;
						});

						
						dt = Math.fabs (click_x - (tx + widget_x + padding));
						if (dt < min_d) {
							min_d = dt;
							c.character_index = ch_index;
							c.paragraph = i;
						}
					} else {
					
						if (ty - next_word.font_size + next_word.get_baseline_to_bottom () <= click_y <= ty + next_word.get_baseline_to_bottom ()) {
							dt = Math.fabs (click_x - (tx + widget_x + padding));
							if (dt < min_d) {
								min_d = dt;
								c.character_index = ch_index;
								c.paragraph = i;
							}
						}
						
						if (tx + p > width || w == "\n") {
							tx = 0;
							ty += next_word.font_size;
						}
											
						if (w != "\n") {
							tx += p;
						}
						
						ch_index += w.length;
					}
				}				
			}
			i++;
		}
		
		if (unlikely (c.paragraph < 0)) {
			c.paragraph = 0;
			c.character_index = 0;
		}
		
		store_undo_state_at_next_event = true;
		
		return c;
	}
	
	/** @return offset to click in text. */
	public void layout () {
		double p;
		double tx, ty;
		string w;
		double xmax = 0;
		double width = this.width - 2 * padding;
		int i = 0;
		double dd;
		
		tx = 0;
		ty = font_size;

		for (i = paragraphs.size - 1; i >= 0; i--) {
			if (paragraphs.get (i).is_empty ()) {
				paragraphs.remove_at (i);
			}
		}

		i = 0;
		foreach (Paragraph paragraph in paragraphs) {
			
			if (unlikely (paragraph.is_empty ())) {
				warning ("Empty paragraph.");
			}
			
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
					
					if (tx > xmax) {
						xmax = tx;
					}

					next_word.widget_x = tx;
					next_word.widget_y = ty;

					if (w != "\n") {
						tx += p;
					}
				}
				
				if (tx > xmax) {
					xmax = tx;
				}
					
				paragraph.width = xmax;
				paragraph.end_x = tx;
				paragraph.end_y = ty;
				paragraph.need_layout = false;
			}
									
			tx = paragraph.end_x;
			ty = paragraph.end_y;
			i++;
		}
		
		this.width = min_width;
		
		if (xmax > width) {
			this.width = xmax + 2 * padding;
		}
		
		this.height = fmax (min_height, ty + 2 * padding);

		if (last_paragraph != DONE) {
			this.height = (text_length / (double) last_paragraph) * ty + 2 * padding; // estimate height
		}
		
		if (ty + widget_y < allocation.height && last_paragraph != DONE) {
			generate_paragraphs ();
			layout ();
			return;
		}

		ty = font_size;
		tx = 0;
		
		foreach (Paragraph paragraph in paragraphs) {
			dd = ty - paragraph.start_y;
			
			if (dd != 0) {
				paragraph.start_y += dd;
				paragraph.end_y += dd;
				foreach (Text word in paragraph.words) {
					word.widget_y += dd;
				}
			}
						
			ty = paragraph.end_y;
		}
	}
	
	public void button_press (uint button, double x, double y) {
		if (is_over (x, y)) {
			carret = get_carret_at (x, y);
			selection_end = carret.copy ();
			update_selection = true;
		}
	}

	public void button_release (uint button, double x, double y) {
		update_selection = false;
		show_selection = selection_is_visible ();
	}
	
	public bool motion (double x, double y) {
		if (update_selection) {
			selection_end = get_carret_at (x, y);
			show_selection = selection_is_visible ();
		}
		
		return update_selection;
	}
	
	public override void draw (Context cr) {
		Text word;
		double p;
		double tx, ty;
		string w;
		double scale;
		double width;
		double x = widget_x;
		double y = widget_y;
		Carret selection_start, selection_stop;
		double carret_x;
		double carret_y;
		
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
		
		// draw selection background
		if (has_selection ()) {
			tx = 0;
			ty = 0;
			
			if (carret.paragraph == selection_end.paragraph) {
				selection_start = carret.character_index < selection_end.character_index ? carret : selection_end;
				selection_stop = carret.character_index > selection_end.character_index ? carret : selection_end;
			} else {
				selection_start = carret.paragraph < selection_end.paragraph ? carret : selection_end;
				selection_stop = carret.paragraph > selection_end.paragraph ? carret : selection_end;	
			}
			
			cr.save ();
			cr.set_source_rgba (234 / 255.0, 77 / 255.0, 26 / 255.0, 1);

			for (int i = selection_start.paragraph; i <= selection_end.paragraph; i++) {
				return_if_fail (0 <= i < paragraphs.size);
				Paragraph pg = paragraphs.get (i);

				if (pg.text_is_on_screen (allocation, widget_y)) {
					int char_index = 0;
					
					foreach (Text next_word in pg.words) {
						double cw = next_word.get_sidebearing_extent ();
						bool paint_background = false;
						bool partial_start = false;
						bool partial_stop = false;
						int wl;
						
						w = next_word.text;
						wl = w.length;
						scale = next_word.get_scale ();
												
						if (selection_start.paragraph == selection_end.paragraph) {
							partial_start = true;
							partial_stop = true;
						} else if (selection_start.paragraph < i < selection_end.paragraph) {
							paint_background = true;
						} else if (selection_start.paragraph == i) {
							paint_background = true;
							partial_start = true;
						} else if (selection_end.paragraph == i) {
							paint_background = char_index + wl < selection_end.character_index;
							partial_stop = !paint_background;
						}
						
						if (paint_background && !(partial_start || partial_stop)) {	
							double selection_y = widget_y + next_word.widget_y + scale * -next_word.font.bottom_limit - font_size;
							cr.rectangle (widget_x + padding + next_word.widget_x - 1, selection_y, cw + 1, font_size);
							cr.fill ();
						}
						
						if (partial_start || partial_stop) {
							int index = char_index;
							double bx = widget_x + padding + next_word.widget_x + (partial_start ? 0 : 1);
							
							next_word.iterate ((glyph, kerning, last) => {
								double cwi;
								int ci;
								bool draw = (index >= selection_start.character_index && partial_start && !partial_stop)
									|| (index < selection_stop.character_index && !partial_start && partial_stop)
									|| (selection_start.character_index <= index < selection_stop.character_index && partial_start && partial_stop);
								
								cwi = (glyph.get_width ()) * next_word.get_scale () + kerning;

								if (draw) {
									double selection_y = widget_y + next_word.widget_y + scale * -next_word.font.bottom_limit - font_size;
									cr.rectangle (bx - 1, selection_y, cwi + 1, font_size);
									cr.fill ();
								}
								
								bx += cwi;
								ci = ((!) glyph.get_unichar ().to_string ()).length;
								index += ci;
							});
						}	
					
						char_index += w.length;	
					}
				}
			}
			
			cr.restore ();
		}

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
				paragraph.cached_surface = new Surface.similar (cr.get_target (), Cairo.Content.COLOR_ALPHA, (int) width + 1, paragraph.get_height () + (int) font_size + 1);
				cc = new Context ((!) paragraph.cached_surface);

				foreach (Text next_word in paragraph.words) {
					next_word.set_source_rgba (0, 0, 0, 1);

					if (next_word.text != "\n") {
						next_word.draw_at_top (cc, next_word.widget_x, next_word.widget_y - ty, cache_id);
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
		
		
		
		if (carret_is_visible) {
			get_carret_position (carret, out carret_x, out carret_y);
			
			if (carret_y < 0) {
				draw_carret_at (cr, widget_x + padding, widget_y + font_size + padding);
			} else {
				draw_carret_at (cr, carret_x, carret_y);
			}
		}
		
		if (has_selection ()) {
			get_carret_position (selection_end, out carret_x, out carret_y);
			
			if (carret_y < 0) {
				draw_carret_at (cr, widget_x + padding, widget_y + font_size + padding);
			} else {
				draw_carret_at (cr, carret_x, carret_y);
			}
		}
	}
	
	void get_carret_position (Carret carret, out double carret_x, out double carret_y) {
		Paragraph paragraph;
		
		carret_x = -1;
		carret_y = -1;
		
		return_if_fail (0 <= carret.paragraph < paragraphs.size);
		paragraph = paragraphs.get (carret.paragraph);

		double tx = paragraph.start_x;
		double ty = paragraph.start_y + widget_y;
		int ch_index = 0;
		int wl;
		double pos_x, pos_y;
		
		pos_x = -1;
		pos_y = -1;
		
		foreach (Text next_word in paragraph.words) {
			string w = next_word.text;
			double p = next_word.get_sidebearing_extent ();
			wl = w.length;

			if (carret.character_index >= ch_index + wl) {
				pos_x = tx + next_word.get_sidebearing_extent () + padding + widget_x;
				pos_y = ty + next_word.get_baseline_to_bottom ();		
			} else if (ch_index <= carret.character_index <= ch_index + wl) {
				
				if (carret.character_index <= ch_index) {
					pos_x = padding + widget_x;
					pos_y = ty + next_word.get_baseline_to_bottom ();		
				}

				next_word.iterate ((glyph, kerning, last) => {
					double cw;
					int ci;
					
					cw = (glyph.get_width ()) * next_word.get_scale () + kerning;
					ci = ((!) glyph.get_unichar ().to_string ()).length;
					
					if (ch_index == carret.character_index) {
						pos_x = tx + padding + widget_x;
						pos_y = ty + next_word.get_baseline_to_bottom ();						
					}
					
					if (ch_index < carret.character_index <= ch_index + ci) {
						pos_x = tx + padding + widget_x + cw;
						pos_y = ty + next_word.get_baseline_to_bottom ();
					}
					
					tx += cw;
					ch_index += ci;
				});
			}
			
			if (tx + p > width || w == "\n") {
				tx = 0;
				ty += next_word.font_size;
			}
			
			if (w != "\n") {
				tx += p;
			}
			
			ch_index += wl;
		}
		
		carret_x = pos_x;
		carret_y = pos_y;
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

	public void store_undo_edit_state () {
		TextUndoItem ui = new TextUndoItem (carret);
		ui.edited.add (get_current_paragraph ().copy ());
		undo_items.add (ui);
		redo_items.clear ();
	}
	
	public void redo () {
		TextUndoItem i;
		TextUndoItem undo_item;
		
		if (redo_items.size > 0) {
			i = redo_items.get (redo_items.size - 1); 
			
			undo_item = new TextUndoItem (i.carret);
			
			i.deleted.sort ((a, b) => {
				Paragraph pa = (Paragraph) a;
				Paragraph pb = (Paragraph) b;
				return a.index - b.index;
			});
			
			foreach (Paragraph p in i.deleted) {
				if (unlikely (!(0 <= p.index < paragraphs.size))) {
					warning ("Paragraph not found.");
				} else {
					undo_item.deleted.add (p.copy ());
					paragraphs.remove_at (p.index);
				}
			}

			foreach (Paragraph p in i.edited) {
				if (unlikely (!(0 <= p.index < paragraphs.size))) {
					warning (@"Index: $(p.index ) out of bounds, size: $(paragraphs.size)");
					return;
				}
				
				undo_item.edited.add (paragraphs.get (p.index).copy ());
				paragraphs.set (p.index, p.copy ());
			}			

			foreach (Paragraph p in i.added) {
				if (p.index == paragraphs.size) {
					paragraphs.add (p.copy ());
				} else {
					if (unlikely (!(0 <= p.index < paragraphs.size))) {
						warning (@"Index: $(p.index) out of bounds, size: $(paragraphs.size)");
					} else {
						undo_item.added.add (paragraphs.get (p.index).copy ());
						paragraphs.insert (p.index, p.copy ());
					}
				}
			}
			
			redo_items.remove_at (redo_items.size - 1);
			undo_items.add (undo_item);
			
			carret = i.carret.copy ();
			layout ();
		}
	}
	
	public void undo () {
		TextUndoItem i;
		TextUndoItem redo_item;
		
		if (undo_items.size > 0) {
			i = undo_items.get (undo_items.size - 1); 
			redo_item = new TextUndoItem (i.carret);
			
			i.deleted.sort ((a, b) => {
				Paragraph pa = (Paragraph) a;
				Paragraph pb = (Paragraph) b;
				return a.index - b.index;
			});
			
			foreach (Paragraph p in i.deleted) {
				if (p.index == paragraphs.size) {
					paragraphs.add (p.copy ());
				} else {
					if (unlikely (!(0 <= p.index < paragraphs.size))) {
						warning (@"Index: $(p.index) out of bounds, size: $(paragraphs.size)");
					} else {
						redo_item.deleted.add (p.copy ());
						paragraphs.insert (p.index, p.copy ());
					}
				}
			}

			foreach (Paragraph p in i.edited) {
				if (unlikely (!(0 <= p.index < paragraphs.size))) {
					warning (@"Index: $(p.index ) out of bounds, size: $(paragraphs.size)");
					return;
				}
				
				redo_item.edited.add (paragraphs.get (p.index).copy ());
				paragraphs.set (p.index, p.copy ());
			}			

			foreach (Paragraph p in i.added) {
				if (unlikely (!(0 <= p.index < paragraphs.size))) {
					warning ("Paragraph not found.");
				} else {
					redo_item.added.add (paragraphs.get (p.index).copy ());
					paragraphs.remove_at (p.index);
				}
			}
			
			undo_items.remove_at (undo_items.size - 1);
			redo_items.add (redo_item);
			
			carret = i.carret.copy ();
			layout ();
		}
	}
	
	public class TextUndoItem : GLib.Object {
		public Carret carret;
		public Gee.ArrayList<Paragraph> added = new Gee.ArrayList<Paragraph> ();
		public Gee.ArrayList<Paragraph> edited = new Gee.ArrayList<Paragraph> ();
		public Gee.ArrayList<Paragraph> deleted = new Gee.ArrayList<Paragraph> ();
		
		public TextUndoItem (Carret c) {
			carret = c.copy ();
		}
	}
		
	public class Paragraph : GLib.Object {
		public double end_x = -10000;
		public double end_y = -10000;
		
		public double start_x = -10000;
		public double start_y = -10000;
		
		public double width = -10000;
		
		public string text;
		
		public Gee.ArrayList<Text> words {
			get {
				if (words_in_paragraph.size == 0) {
					generate_words ();
				}
				
				return words_in_paragraph;
			}
		}
		
		private Gee.ArrayList<Text> words_in_paragraph = new Gee.ArrayList<Text> ();
		
		public int text_length;
		
		public bool need_layout = true;
		
		public Surface? cached_surface = null;
		
		double font_size;
		
		public int index;
		
		public Paragraph (string text, double font_size, int index) {
			this.index = index;
			this.font_size = font_size;
			set_text (text);
		}

		public Paragraph copy () {
			Paragraph p = new Paragraph (text.dup (), font_size, index);
			p.need_layout = true;
			return p;
		}

		public bool is_empty () {
			return text == "";
		}

		public void set_text (string t) {
			this.text = t;
			text_length = t.length;
			need_layout = true;
			words.clear ();
			cached_surface = null;
			generate_words ();
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

		private void generate_words () {
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
				words_in_paragraph.add (word);
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
	
	public class Carret : GLib.Object {
		
		public int paragraph = 0;
		public int character_index = 0;
		
		public double desired_x = 0;
		public double desired_y = 0;
		
		public Carret () {
		}
		
		public void print () {
			stdout.printf (@"paragraph: $paragraph, character_index: $character_index\n");
		}
		
		public Carret copy () {
			Carret c = new Carret ();
			
			c.paragraph = paragraph;
			c.character_index = character_index;
			
			c.desired_x = desired_x;
			c.desired_y = desired_y;
			
			return c;
		}
	}
}

}
