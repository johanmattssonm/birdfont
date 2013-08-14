/*
    Copyright (C) 2012 Johan Mattsson

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

/** Kerning context. */
public class KerningDisplay : FontDisplay {

	List <GlyphSequence> row;
	int active_handle = -1;
	int selected_handle = -1;
	
	double begin_handle_x = 0;
	double begin_handle_y = 0;
	
	double last_handle_x = 0;

	public KerningDisplay () {
		GlyphSequence w = new GlyphSequence ();
		row = new List <GlyphSequence> ();
		row.append (w);
	}

	public override string get_name () {
		return "Kerning";
	}
	
	public override void draw (WidgetAllocation allocation, Context cr) {
		Glyph glyph;
		double x, y, w, kern, alpha;
		double x2;
		int i, wi;
		Glyph? prev;
		Font font = BirdFont.get_current_font ();
		GlyphSequence word_with_ligatures;
		
		i = 0;
		
		// bg color
		cr.save ();
		cr.set_source_rgba (1, 1, 1, 1);
		cr.rectangle (0, 0, allocation.width, allocation.height);
		cr.fill ();
		cr.restore ();
	
		alpha = 1;
		y = 100;
		x = 20;
		w = 0;
		prev = null;
		
		foreach (GlyphSequence word in row) {
			wi = 0;
			word_with_ligatures = word.process_ligatures ();
			foreach (Glyph? g in word_with_ligatures.glyph) {
				if (g == null) {
					continue;
				}
				
				if (prev == null) {
					kern = 0;
				} else {
					kern = font.get_kerning_by_name (((!)prev).get_name (), ((!)g).get_name ());
				}
								
				// draw glyph				
				if (g == null) {
					w = 50;
					alpha = 1;
				} else {
					alpha = 0;
					glyph = (!) g;
					Svg.draw_svg_path (cr, glyph.get_svg_data (), x + kern, y);
					w = glyph.get_width ();
				}

				// handle
				if (active_handle == i) {
					//x2 = x + kern;
					x2 = x + kern / 2.0;
					
					cr.save ();
					cr.set_source_rgba (153/255.0, 153/255.0, 173/255.0, 1);
					cr.move_to (x2 - 5, y + 20);
					cr.line_to (x2 + 0, y + 20 - 5);
					cr.line_to (x2 + 5, y + 20);
					cr.fill ();
					
					cr.set_font_size (10);
					cr.show_text (((!)g).get_name ());
					cr.restore ();
				}	
				
				x += w + kern;
	
				// caption
				if (g == null || ((!)g).is_empty ()) {
					cr.save ();
					cr.set_source_rgba (153/255.0, 153/255.0, 153/255.0, alpha);
					cr.move_to (x - w / 2.0 - 5, y + 20);
					cr.set_font_size (10);
					cr.show_text ("?"); // ?
					cr.restore ();
				}
							
				prev = g;
				
				wi++;
				i++;
			}
			
			if (y > allocation.height && i > 10) {
				row.remove (word);
			}
						
			y += MainWindow.get_current_glyph ().get_height () + 20;
			x = 20;			
		}
	}
	
	private void set_kerning (int handle, double val) {
		string a, b;
		Font font;
		int wi = 0;
		double kern;
		GlyphSequence word_with_ligatures;
		
		font = BirdFont.get_current_font ();

		font.touch ();

		a = "";
		b = "";

		foreach (GlyphSequence word in row) {
			word_with_ligatures = word.process_ligatures ();
			foreach (Glyph? g in word_with_ligatures.glyph) {
				
				if (g == null) {
					continue;
				}
				
				b = ((!) g).get_name ();
				
				if (handle == wi) {
					kern = font.get_kerning_by_name (a, b) + val;
					font.set_kerning_by_name (a, b, kern);
				}
				
				wi++;
				
				a = b;
			}
		}
		
		
	}

	public override void selected_canvas () {
		Glyph g;
		GlyphSequence w;
		unowned List<GlyphSequence>? r;
		StringBuilder s = new StringBuilder ();
		bool append_char = false;
		Font font = BirdFont.get_current_font ();
		
		KeyBindings.singleton.set_require_modifier (true);
		
		g = MainWindow.get_current_glyph ();
		s.append_unichar (g.get_unichar ());

		r = row;
		return_if_fail (r != null);

		if (row.length () == 0) {
			append_char = true;
		}
		
		if (append_char) {
			w = new GlyphSequence ();
			row.append (w);
			w.glyph.prepend (font.get_glyph (s.str));
		}		
	}
	
	public override void key_press (uint keyval) {
		unichar c = (unichar) keyval;
		Glyph? g;
		Font f = BirdFont.get_current_font ();
		string name;
		
		if (KeyBindings.modifier == NONE || KeyBindings.modifier == SHIFT) {
					
			if (keyval == Key.BACK_SPACE && row.length () > 0) {	
				row.first ().data.glyph.remove_link (row.first ().data.glyph.last ());
			}
			
			if (row.length () == 0 || c == Key.ENTER) {
				row.prepend (new GlyphSequence ());
			}
			
			if (!is_modifier_key (c) && c.validate ()) {
				name = f.get_name_for_character (c);
				g = f.get_glyph_by_name (name);
				row.first ().data.glyph.append (g);
			}
		}
		
		MainWindow.get_glyph_canvas ().redraw ();
	}
	
	public override void motion_notify (double ex, double ey) {
		double k, y;
		
		if (selected_handle == -1) {
			set_active_handle (ex, ey);
		} else {
			y = 1;
			
			if (Math.fabs (ey - begin_handle_y) > 20) {
				y = ((Math.fabs (ey - begin_handle_y) / 100) + 1);
			}
			
			k = (ex - last_handle_x) / y; // y-axis is variable precision
			set_kerning (selected_handle, k);
			MainWindow.get_glyph_canvas ().redraw ();
		}
		
		last_handle_x = ex;
	}
	
	public void set_active_handle (double ex, double ey) {
		double y = 100;
		double x = 20;
		double w = 0;
		double d, kern;
		double min = double.MAX;
		int i = 0;
		int row_index = 0;
		int col_index = 0;
		Glyph glyph = new Glyph.no_lines ("");
		Font font = BirdFont.get_current_font ();
		
		Glyph? prev = null;
		string gl_name = "";
		GlyphSequence word_with_ligatures;
		
		foreach (GlyphSequence word in row) {
			foreach (Glyph? g in word.glyph) {
				if (g == null) print ("null");
				else print (((!)g).get_name ());
				print ("\n");
			}
		}
		print ("\n");
		
		foreach (GlyphSequence word in row) {
			col_index = 0;
			
			word_with_ligatures = word.process_ligatures ();
			foreach (Glyph? g in word_with_ligatures.glyph) {
				if (g == null) {
					w = 50;	
				} else {
					glyph = (!) g;
					w = glyph.get_width ();
				}
				
				gl_name = glyph.get_name ();
				
				if (prev == null) {
					kern = 0;
				} else {
					kern = font.get_kerning_by_name (((!)prev).get_name (), gl_name);
				}
								
				d = Math.pow (x + kern - ex, 2) + Math.pow (y - ey, 2);
				
				if (d < min) {
					min = d;
					
					if (active_handle != i - row_index) {
						active_handle = i - row_index;
						MainWindow.get_glyph_canvas ().redraw ();
					}
					
					if (col_index == word.glyph.length () || col_index == 0) {
						active_handle = -1;
					} else {
						active_handle += row_index;
					}
				}
				
				prev = g;
				x += w + kern;
				i++;
				col_index++;
			}
			
			row_index++;
			y += MainWindow.get_current_glyph ().get_height () + 20;
			x = 20;
		}
	}
	
	public override void button_release (int button, double ex, double ey) {
		set_active_handle (ex, ey);
		selected_handle = -1;
	}
	
	public override void button_press (uint button, double ex, double ey) {
		set_active_handle (ex, ey);
		selected_handle = active_handle;
		begin_handle_x = ex;
		begin_handle_y = ey;
		last_handle_x = ex;
	}

}

}
