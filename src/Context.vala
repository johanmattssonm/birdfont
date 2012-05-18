/*
    Copyright (C) 2012 Johan Mattsson

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

using Gtk;
using Gdk;
using Cairo;

namespace Supplement {

/** Kerning context. */
class ContextDisplay : FontDisplay {

	List <Word> row;
	int active_handle = -1;
	int selected_handle = -1;
	
	double begin_handle_x = 0;
	double begin_handle_y = 0;
	
	double current_kerning = 0;
	
	public ContextDisplay () {
		Word w = new Word ();
		row = new List <Word> ();
		row.append (w);
	}

	public override string get_name () {
		return "Context";
	}
	
	public override void draw (Allocation allocation, Context cr) {
		Glyph? g;
		Glyph glyph;
		double x, y, w, kern, alpha;
		double x2;
		int i, wi;
		string prev;
		
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
		prev = "";
		
		foreach (Word word in row) {
			wi = 0;
			
			foreach (string s in word.glyph) {				
				g = (!) Supplement.get_current_font ().get_glyph (s);	
				kern = get_kerning (prev, s);
				
				if (s == "") {
					continue;
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
				if (active_handle == i && active_handle < word.glyph.length ()) {
					x2 = x + kern;
					
					cr.save ();
					cr.set_source_rgba (153/255.0, 153/255.0, 173/255.0, 1);
					cr.move_to (x2 - 5, y + 20);
					cr.line_to (x2 + 0, y + 20 - 5);
					cr.line_to (x2 + 5, y + 20);
					cr.fill ();
					
					cr.set_font_size (10);
					cr.show_text (s);
					cr.restore ();
				}	
				
				x += w + kern;
	
				// caption
				if (g == null || ((!)g).is_empty ()) {
					cr.save ();
					cr.set_source_rgba (153/255.0, 153/255.0, 153/255.0, alpha);
					cr.move_to (x - w / 2.0 - 5, y + 20);
					cr.set_font_size (10);
					cr.show_text (s);
					cr.restore ();
				}
							
				prev = s;
				
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
		
		font = Supplement.get_current_font ();

		font.touch ();

		handle++; // use handle before next glyph

		a = "";
		b = "";

		foreach (Word word in row) {
			foreach (string s in word.glyph) {
				b = s;
				
				if (handle == wi) {
					kern = current_kerning + val;
					font.set_kerning (a, b, kern);
				}
				
				wi++;
				
				a = b;
			}
		}
		
		
	}
	
	private double get_kerning (string a, string b) {
		Font font = Supplement.get_current_font ();
		return font.get_kerning (a, b);
	}
	
	public override void selected_canvas () {
		Glyph g;
		Word w;
		unowned List<Word>? r;
		unowned List<string>? rw;
		StringBuilder s = new StringBuilder ();
		bool append_char = false;
		
		KeyBindings.singleton.set_require_modifier (true);
		
		g = MainWindow.get_current_glyph ();
		s.append_unichar (g.get_unichar ());

		r = row;
		return_if_fail (r != null);

		if (row.length () == 0) {
			append_char = true;
		}
		
		if (row.length () > 0) {
			rw = row.first ().data.glyph;
			return_if_fail (rw != null);
			append_char = (row.first ().data.glyph.data.index_of (s.str) == -1);
		}
		
		if (append_char) {
			w = new Word ();
			row.append (w);
			w.glyph.prepend (s.str);
		}					
	}
	
	public override void key_press (EventKey e) {
		unichar c = (unichar) e.keyval;
		StringBuilder s = new StringBuilder ();
		
		if (e.type == EventType.KEY_PRESS && (KeyBindings.singleton.modifier == NONE || KeyBindings.singleton.modifier == SHIFT)) {
					
			if (e.keyval == Key.BACK_SPACE && row.length () > 0) {	
				row.first ().data.glyph.remove_link (row.first ().data.glyph.last ());
			}
			
			if (row.length () == 0 || c == Key.ENTER) {
				row.prepend (new Word ());
			}
			
			if (!is_modifier_key (c) && c.validate ()) {
				s.append_unichar (c);
				row.first ().data.glyph.append (s.str);
			}
		}
		
		MainWindow.get_glyph_canvas ().redraw ();
	}
	
	public override void motion_notify (EventMotion e) {
		double k, y;
		
		if (selected_handle == -1) {
			set_active_handle (e.x, e.y);
		} else {
			y = 1;
			
			if (Math.fabs (e.y - begin_handle_y) > 20) {
				y = ((Math.fabs (e.y - begin_handle_y) / 100) + 1);
			}
			
			k = (e.x - begin_handle_x) / y; // y-axis is variable presition // Fixa: spell
			set_kerning (selected_handle, k);
			MainWindow.get_glyph_canvas ().redraw ();
		}
	}
	
	public void set_active_handle (double ex, double ey) {
		double y = 100;
		double x = 20;
		double w = 0;
		double d, kern;
		double min = double.MAX;
		int i = 0;
		Glyph? g;
		Glyph glyph;
		
		string prev = "";
		
		foreach (Word word in row) {
			foreach (string s in word.glyph) {
				// draw glyph
				g = (!) Supplement.get_current_font ().get_glyph (s);	
				kern = get_kerning (prev, s);
				
				if (g == null) {
					w = 50;	
				} else {
					glyph = (!) g;
					w = glyph.get_width ();
				}
				
				d = Math.pow (x + kern - ex, 2) + Math.pow (y - ey, 2);
				
				if (d < min) {
					min = d;
					
					if (active_handle != i) {
						active_handle = i;
						current_kerning = get_kerning (prev, s);
						MainWindow.get_glyph_canvas ().redraw ();
					}
				}
				
				prev = s;
				x += w + kern;
				i++;
			}
			
			y += MainWindow.get_current_glyph ().get_height () + 20;
			x = 20;	
		}
	}
	
	public override void button_release (EventButton e) {
		set_active_handle (e.x, e.y);
		selected_handle = -1;
	}
	
	public override void button_press (EventButton e) {
		set_active_handle (e.x, e.y);
		selected_handle = active_handle;
		begin_handle_x = e.x;
		begin_handle_y = e.y;
	}

}

class Word {
	public List <string> glyph;
	
	public Word () {
		glyph = new List <string> ();
		glyph.append ("");
	}

}

}
