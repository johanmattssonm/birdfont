/*
    Copyright (C) 2013 Johan Mattsson

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

public class KerningList : FontDisplay {
	
	int scroll = 0;
	int visible_rows = 0;
	WidgetAllocation allocation;
	Gee.ArrayList<UndoItem> undo_items;
	Gee.ArrayList<string> single_pairs;
	
	public KerningList () {
		allocation = new WidgetAllocation ();
		undo_items = new Gee.ArrayList<UndoItem> ();
		single_pairs = new Gee.ArrayList<string> ();
	}

	private void update_single_pair_list () {
		KerningClasses classes = KerningClasses.get_instance ();
		
		single_pairs.clear ();
		
		classes.get_single_position_pairs ((left, right, kerning) => {
			single_pairs.add (@"$left - $right");
		});
		
		single_pairs.sort ();
	}

	public override void draw (WidgetAllocation allocation, Context cr) {
		KerningClasses classes = KerningClasses.get_instance ();
		int y = 20;
		int s = 0;
		bool color = (scroll % 2) == 0;
		string l, r;
		string[] p;
		double k;
		
		this.allocation = allocation;
		
		visible_rows = (int) (allocation.height / 18.0);
		
		cr.save ();
		cr.set_source_rgba (1, 1, 1, 1);
		cr.rectangle (0, 0, allocation.width, allocation.height);
		cr.fill ();
		cr.restore ();
		
		cr.save ();
		cr.set_source_rgba (0.3, 0.3, 0.3, 1);
		cr.set_font_size (12);

		classes.get_classes ((left, right, kerning) => {
			if (s++ >= scroll) {
				draw_row (allocation, cr, left, right, @"$kerning", y, color);
				y += 18;
				color = !color;
			}
		});
	
		foreach (string pair in single_pairs) {
			if (s++ >= scroll) {
				p = pair.split (" - ");
				return_if_fail (p.length == 2);
								
				l = p[0];
				r = p[1];
				k = classes.get_kerning (l, r);
				
				draw_row (allocation, cr, l, r, @"$k", y, color);
				y += 18;
				color = !color;
			}
		}
		
		cr.restore ();
	}	

	private static void draw_row (WidgetAllocation allocation, Context cr,
		string left, string right, string kerning, int y, bool color) {

		if (color) {
			cr.save ();
			cr.set_source_rgba (224/255.0, 224/255.0, 224/255.0, 1);
			cr.rectangle (0, y - 14, allocation.width, 18);
			cr.fill ();
			cr.restore ();
		}
		
		// remove kerning icon
		cr.save ();
		cr.set_line_width (1);
		cr.move_to (10, y - 8);
		cr.line_to (15, y - 3);
		cr.move_to (10, y - 3);
		cr.line_to (15, y - 8);		
		cr.stroke ();
		cr.restore ();
		
		cr.move_to (60, y);
		cr.show_text (left);
		cr.move_to (230, y);
		cr.show_text (right);
		cr.move_to (430, y);
		cr.show_text (kerning);
	}

	public override void button_release (int button, double ex, double ey) {
		KerningClasses classes = KerningClasses.get_instance ();
		int s = 0;
		int y = 0;
		string l, r;
		string[] p;
		double k;
		
		l = "";
		r = "";
		
		if (ex < 20) {
			classes.get_classes ((left, right, kerning) => {
				if (s++ >= scroll) {
					y += 18;
					
					if (y - 10 <= ey <= y + 5) {
						l = left;
						r = right;
					}				
				}
			});

			foreach (string pair in single_pairs) {
				if (s++ >= scroll) {
					y += 18;
					p = pair.split (" - ");
					return_if_fail (p.length == 2);
					
					if (y - 10 <= ey <= y + 5) {			
						l = p[0];
						r = p[1];
					}
				}
			}	
			delete_kerning (l, r);
			
			update_single_pair_list ();
			update_scrollbar ();
			redraw_area (0, 0, allocation.width, allocation.height);
		}
	}

	 void delete_kerning (string left, string right) {
		double kerning = 0;
		GlyphRange glyph_range_first, glyph_range_next;
		KerningClasses classes = KerningClasses.get_instance ();
		Font font = BirdFont.get_current_font ();
		string l, r;
		int class_index = -1;
		
		l = GlyphRange.unserialize (left);
		r = GlyphRange.unserialize (right);
		
		try {
			if (left != "" && right != "") {
				
				if (l.char_count () > 1 || r.char_count () > 1) {
					glyph_range_first = new GlyphRange ();
					glyph_range_next = new GlyphRange ();
					
					glyph_range_first.parse_ranges (left);
					glyph_range_next.parse_ranges (right);
					
					kerning = classes.get_kerning_for_range (glyph_range_first, glyph_range_next);
					class_index = classes.get_kerning_item_index (glyph_range_first, glyph_range_next);
					
					classes.delete_kerning_for_class (left, right);
				} else {
					kerning = classes.get_kerning (left, right);
					classes.delete_kerning_for_pair (left, right);
				}
				
				undo_items.add (new UndoItem (left, right, kerning, class_index));
				font.touch ();
			}
		} catch (MarkupError e) {
			warning (e.message);
		}
	}

	public override string get_label () {
		return t_("Kerning Pairs");
	}

	public override string get_name () {
		return "Kerning Pairs";
	}

	public override bool has_scrollbar () {
		return true;
	}
	
	public override void scroll_wheel_down (double x, double y) {
		uint pairs = KerningClasses.get_instance ().get_number_of_pairs ();
		scroll += 3;

		if (scroll > pairs - visible_rows) {
			scroll = (int) (pairs - visible_rows);
		}
		
		if (visible_rows > pairs) {
			scroll = 0;
		} 
		
		update_scrollbar ();
		redraw_area (0, 0, allocation.width, allocation.height);
	}
	
	public override void scroll_wheel_up (double x, double y) {
		scroll -= 3;
		
		if (scroll < 0) {
			scroll = 0;
		}
		
		update_scrollbar ();
		redraw_area (0, 0, allocation.width, allocation.height);
	}

	public override void selected_canvas () {
		update_single_pair_list ();
		update_scrollbar ();
		redraw_area (0, 0, allocation.width, allocation.height);
	}
	
	public void update_scrollbar () {
		uint rows = KerningClasses.get_instance ().get_number_of_pairs ();

		if (rows == 0 || visible_rows == 0) {
			MainWindow.set_scrollbar_size (0);
			MainWindow.set_scrollbar_position (0);
		} else {
			MainWindow.set_scrollbar_size ((double) visible_rows / rows);
			MainWindow.set_scrollbar_position ((double) scroll /  rows);
		}
	}

	public override void scroll_to (double percent) {
		uint pairs = KerningClasses.get_instance ().get_number_of_pairs ();
		scroll = (int) (percent * pairs);
		
		if (scroll > pairs - visible_rows) {
			scroll = (int) (pairs - visible_rows);
		}
		
		redraw_area (0, 0, allocation.width, allocation.height);
	}
	
	public override void undo () {
		UndoItem ui;
		KerningClasses classes = KerningClasses.get_instance ();
		GlyphRange glyph_range_first, glyph_range_next;
		
		try {
			if (undo_items.size == 0) {
				return;
			}
			
			ui = undo_items.get (undo_items.size - 1);
			
			if (ui.first.char_count () > 1 || ui.next.char_count () > 1) {
				glyph_range_first = new GlyphRange ();
				glyph_range_next = new GlyphRange ();
				
				glyph_range_first.parse_ranges (ui.first);
				glyph_range_next.parse_ranges (ui.next);
				
				classes.set_kerning (glyph_range_first, glyph_range_next, ui.kerning, ui.class_priority);
			} else {
				classes.set_kerning_for_single_glyphs (ui.first, ui.next, ui.kerning);
			}
			
			undo_items.remove_at (undo_items.size - 1);
		} catch (MarkupError e) {
			warning (e.message);
		}
		
		update_single_pair_list ();
		update_scrollbar ();
		redraw_area (0, 0, allocation.width, allocation.height);
	}
	
	private class UndoItem : GLib.Object {
		public string first;
		public string next;
		public double kerning;
		public int class_priority;
		
		public UndoItem (string first, string next, double kerning, int class_priority = -1) {
			this.first = first;
			this.next = next;
			this.kerning = kerning;
			this.class_priority = class_priority;
		}
	}
}

}
