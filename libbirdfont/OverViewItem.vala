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
	
public class OverViewItem : GLib.Object {
	public unichar character = 'A'; // FIXME: 
	public GlyphCollection? glyphs;
	public double x;
	public double y;
	public bool selected = false;
	public CharacterInfo info;
	public bool display_info = false;
	
	public static double DEFAULT_WIDTH = 100;
	public static double DEFAULT_HEIGHT = 130;
	public static double DEFAULT_MARGIN = 20;
	
	public static double width = 100;
	public static double height = 130;
	public static double margin = 20;
	
	public OverViewItem (GlyphCollection? glyphs, unichar character, double x, double y) {	
		this.x = x;
		this.y = y;
		this.character = character;
		this.glyphs = glyphs;
		this.info = new CharacterInfo (character);
	}
	
	public static double full_width () {
		return width + margin;
	}

	public static double full_height () {
		return height + margin;
	}
	
	public bool click (uint button, double px, double py) {
		bool a;
		GlyphCollection g;
		selected = (x <= px <= x + width) && (y <= py <= y + height);
		
		if (glyphs != null) {
			g = (!) glyphs;
			a = g.get_version_list ().menu_item_action (px, py); // select one item on the menu
			if (a) {
				return selected;
			}
			
			g.get_version_list ().menu_icon_action (px, py); // click in the open menu
		}
		
		return selected;
	}

	public void double_click (uint button, double px, double py) {
		selected = (x <= px <= x + width) && (y <= py <= y + height);
		
		if (selected) {
			edit_glyph ();
		}
		
		display_info = info.is_over_icon (px, py);
	}
	
	public void edit_glyph () {
		OverView overview = MainWindow.get_overview ();
		
		if (glyphs == null) {
			overview.open_new_glyph_signal (character);
		} else {
			overview.open_glyph_signal ((!) glyphs);
		}		
	}
	
	public void draw (Context cr) {
		cr.save ();
		cr.set_source_rgba (1, 1, 1, 1);
		cr.rectangle (x, y, width, height);
		cr.fill ();
		cr.restore ();
		
		cr.save ();
		cr.set_source_rgba (0, 0, 0, 1);
		cr.rectangle (x, y, width, height);
		cr.set_line_width (0.5);
		cr.stroke ();
		cr.restore ();
				
		draw_thumbnail (cr, glyphs, x, y + height); 	
		draw_caption (cr);
		
		if (display_info) {
			draw_character_info (cr);
		}		
	}

	private bool draw_thumbnail (Context cr, GlyphCollection? gl, double x, double y) {
		Glyph g;
		double gx, gy;
		double x1, x2, y1, y2;
		double scale = width / DEFAULT_WIDTH;
		double w, h;

		w = width;
		h = height;
		
		if (gl == null) {
			return false;
		}
		
		g = ((!) gl).get_current ();
		g.boundries (out x1, out y1, out x2, out y2);

		gx = (width - (x2 - x1)) / 2*scale;
		
		if (gx < 0) {
			gx = 0;
		}
		
		gy = (h / scale) - 25 / scale;
		
		Surface s = new Surface.similar (cr.get_target (), Content.COLOR_ALPHA, (int) w, (int) h - 20);
		Context c = new Context (s);
		
		c.scale (scale, scale);				
		Svg.draw_svg_path (c, g.get_svg_data (), gx, gy);
		
		cr.save ();
		cr.set_source_surface (s, x, y - h);
		cr.paint ();
		cr.restore ();

		return true;
	}

	public void draw_caption (Context cr) {
		cr.save ();
		
		if (selected) {
			cr.set_source_rgba (50/255.0, 50/255.0, 50/255.0, 1);
		} else {
			cr.set_source_rgba (100/255.0, 100/255.0, 100/255.0, 1);			
		}
		
		cr.rectangle (x + 1, y + height - 20, width - 2, 20 - 1);
		cr.fill ();
		draw_menu (cr);
		draw_character_info_icon (cr);
		cr.restore ();
	}

	private void draw_character_info_icon (Context cr) {
		double px = x + width - 17;
		double py = y + height - 16;
		info.set_position (px, py);
		info.draw_icon (cr);
	}
	
	private void draw_menu (Context cr) {
		GlyphCollection g;
		DropMenu menu;
		
		if (glyphs == null) {
			return;
		}
		
		g = (!) glyphs;
		
		menu = g.get_version_list ();
		menu.set_position (x + width - 32, y + height - 16);
		menu.draw_icon (cr);
		menu.draw_menu (cr);
	}

	/** Display one entry from the Unicode Character Database. */
	void draw_character_info (Context cr) {
		double x, y, w, h;
		int i;
		string unicode_value, unicode_description;
		string[] column;
		string entry;
		int len = 0;
		int length = 0;
		bool see_also = false;
		Allocation allocation = MainWindow.get_overview ().allocation;
		
		entry = info.get_entry ();
		
		foreach (string line in entry.split ("\n")) {
			len = line.char_count ();
			if (len > length) {
				length = len;
			}
		}
		
		x = allocation.width * 0.1;
		y = allocation.height * 0.1;
		w = allocation.width * 0.9 - x; 
		h = allocation.height * 0.9 - y;
		
		if (w < 8 * length) {
			w = 8 * length;
			x = (allocation.width - w) / 2.0;
		}
		
		// background	
		cr.save ();
		cr.set_source_rgba (1, 1, 1, 0.8);
		cr.rectangle (x, y, w, h);
		cr.fill ();
		cr.restore ();

		cr.save ();
		cr.set_source_rgba (0, 0, 0, 0.8);
		cr.set_line_width (2);
		cr.rectangle (x, y, w, h);
		cr.stroke ();
		cr.restore ();

		// database entry
		i = 0;
		foreach (string line in entry.split ("\n")) {
			if (i == 0) {
				column = line.split ("\t");
				return_if_fail (column.length == 2);
				unicode_value = "U+" + column[0];
				unicode_description = column[1];

				draw_info_line (unicode_description, cr, x, y, i);
				i++;

				draw_info_line (unicode_value, cr, x, y, i);
				i++;			
			} else {
				
				if (line.has_prefix ("\t*")) {
					draw_info_line (line.replace ("\t*", "•"), cr, x, y, i);
					i++;					
				} else if (line.has_prefix ("\tx (")) {
					if (!see_also) {
						i++;
						draw_info_line (_("See also:"), cr, x, y, i);
						i++;
						see_also = true;
					}
					
					draw_info_line (line.replace ("\tx (", "•").replace (")", ""), cr, x, y, i);
					i++;
				} else {

					i++;
				}
			}
		}
	}

	void draw_info_line (string line, Context cr, double x, double y, int row) {
		cr.save ();
		cr.set_font_size (12);
		cr.set_source_rgba (0, 0, 0, 1);
		cr.move_to (x + 10, y + 28 + row * 18 * 1.2);
		cr.show_text (line);
		cr.restore ();		
	}
}

}
