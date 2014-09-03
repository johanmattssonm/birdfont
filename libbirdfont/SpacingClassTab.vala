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

public class SpacingClassTab : FontDisplay {

	int scroll = 0;
	int visible_rows = 0;
	WidgetAllocation allocation = new WidgetAllocation ();
	Gee.ArrayList<Row> rows = new Gee.ArrayList<Row> ();
	
	public Gee.ArrayList<SpacingClass> classes = new Gee.ArrayList<SpacingClass> ();
	
	public static int NEW_CLASS = -1;
	
	Gee.ArrayList<string> connections = new Gee.ArrayList<string> ();
	
	public SpacingClassTab () {
	}

	public Gee.ArrayList<string> get_all_connections (string glyph) {
		Gee.ArrayList<string> c = new Gee.ArrayList<string> ();
		
		connections.clear ();
		add_connections (glyph);
		
		foreach (string t in connections) {
			c.add (t);
		}
		
		connections.clear ();
		
		return c;
	}
	
	public void add_connections (string glyph) {
		connections.add (glyph);
		
		foreach (SpacingClass s in classes) {
			if (s.first == glyph) {
				if (connections.index_of (s.next) == -1) {
					add_connections (s.next);
				}
			}

			if (s.next == glyph) {
				if (connections.index_of (s.first) == -1) {
					add_connections (s.first);
				}
			}
		}
		
		connections.sort ((a, b) => {
			return strcmp (a, b);
		});
	}

	public void add_class (string first, string next) {
		SpacingClass s = new SpacingClass (first, next);
		s.updated.connect (update_all_rows);
		s.updated.connect (update_kerning);
		classes.add (s);
		update_kerning (s);
	}

	public void update_kerning (SpacingClass s) {
		Font font = BirdFont.get_current_font ();
		GlyphCollection? g;
		GlyphCollection gc;
		
		if (s.next != "?") {
			KerningClasses.get_instance ().update_space_class (s.next);
			g = font.get_glyph_collection (s.next);
			if (g != null) {
				gc = (!) g;
				gc.get_current ().update_spacing_class ();
			}
		}
		
		if (s.first != "?") {
			KerningClasses.get_instance ().update_space_class (s.first);
			g = font.get_glyph_collection (s.first);
			if (g != null) {
				gc = (!) g;
				gc.get_current ().update_spacing_class ();
			}
		}
		
		KerningTools.update_spacing_classes ();
	}

	public void selected_row (Row row, int column, bool delete_button) {
		Font font = BirdFont.get_current_font ();
		
		if (row.get_index () == -1) {
			add_class ("?", "?");
			MainWindow.native_window.hide_text_input ();
			update_rows ();
			update_scrollbar ();
			font.touch ();
		} else if (classes.size != 0) {
			if (delete_button) {
				return_if_fail (0 <= row.get_index () < classes.size);
				classes.remove_at (row.get_index ());
				MainWindow.native_window.hide_text_input ();
				update_rows ();
				update_scrollbar ();
				font.touch ();
			} else if (column == 0) {
				if (!(0 <= row.get_index () < classes.size)) {
					warning (@"Index: $(row.get_index ()) classes.size: $(classes.size)");
					return;
				}
				classes.get (row.get_index ()).set_first ();
				font.touch ();
			} else if (column == 2) {
				return_if_fail (0 <= row.get_index () < classes.size);
				classes.get (row.get_index ()).set_next ();
				font.touch ();
			}
		}
	}

	public override void selected_canvas () {
		update_rows ();
		update_scrollbar ();
	}
	
	void update_all_rows (SpacingClass s) {
		update_rows ();
	}
	
	void update_rows () {
		int i = 0;
		
		rows.clear ();
		rows.add (new Row (t_("New spacing class"), NEW_CLASS, false));
		
		foreach (SpacingClass c in classes) {
			rows.add (new Row.columns_3 (@"$(c.first)", "=",  @"$(c.next)", i));
			i++;
		}
		
		GlyphCanvas.redraw ();
	}
	
	public override void draw (WidgetAllocation allocation, Context cr) {
		double y = 20 * MainWindow.units;
		int s = 0;
		bool color = (scroll + 1 % 2) == 0;
		
		if (allocation.width != this.allocation.width
				|| allocation.height != this.allocation.height) {
			this.allocation = allocation;
			update_rows ();
			update_scrollbar ();
		}
		
		visible_rows = (int) (allocation.height / 18.0);
		
		cr.save ();
		cr.set_source_rgba (1, 1, 1, 1);
		cr.rectangle (0, 0, allocation.width, allocation.height);
		cr.fill ();
		cr.restore ();
		
		cr.save ();
		cr.set_source_rgba (0.3, 0.3, 0.3, 1);
		cr.set_font_size (12);

		foreach (Row r in rows) {
			if (s++ >= scroll) {
				draw_row (allocation, cr, r, y, color, true);
				y += 18 * MainWindow.units;
				color = !color;
			}
		}
		
		cr.restore ();
	}	

	private static void draw_row (WidgetAllocation allocation, Context cr,
			Row row, double y, bool color, bool dark) {
		
		double margin;
	
		if (color) {
			cr.save ();
			cr.set_source_rgba (224/255.0, 224/255.0, 224/255.0, 1);
			cr.rectangle (0, y - 14 * MainWindow.units, allocation.width, 18 * MainWindow.units);
			cr.fill ();
			cr.restore ();
		}

		if (row.has_delete_button ()) {
			cr.save ();
			cr.set_line_width (1);
			cr.move_to (10 * MainWindow.units, y - 8 * MainWindow.units);
			cr.line_to (15 * MainWindow.units, y - 3 * MainWindow.units);
			cr.move_to (10 * MainWindow.units, y - 3 * MainWindow.units);
			cr.line_to (15 * MainWindow.units, y - 8 * MainWindow.units);		
			cr.stroke ();
			cr.restore ();
		}
		
		for (int i = 0; i < row.columns; i++) {
			cr.save ();
			margin = (row.has_delete_button ()) ? 120 * MainWindow.units : 3* MainWindow.units;
			cr.move_to (margin + i * 120 * MainWindow.units, y);
			cr.set_font_size (12 * MainWindow.units);
			cr.show_text (row.get_column (i));
			cr.restore ();
		}
	}

	public override void button_release (int button, double ex, double ey) {
		int s = 0;
		double y = 0;
		int colum = -1;
		Row? selected = null;
		bool over_delete = false;

		foreach (Row r in rows) {
			if (s++ >= scroll) {
				y += 18 * MainWindow.units;
				
				if (y - 10 * MainWindow.units <= ey * MainWindow.units <= y + 5 * MainWindow.units) {
					
					if (r.has_delete_button ()) {
						colum = (int) ((ex - 120) / 120 * MainWindow.units);
					} else {
						colum = (int) ((ex) / 120 * MainWindow.units);
					}
					
					over_delete = (ex < 18 && r.has_delete_button ());
					selected = r;
					break;
				}
			}
		}
		
		if (selected != null) {
			selected_row ((!) selected, colum, over_delete);	
		}
		
		update_scrollbar ();
		redraw_area (0, 0, allocation.width, allocation.height);
	}

	public override string get_label () {
		return t_("Spacing Classes");
	}

	public override string get_name () {
		return "SpacingClasses";
	}

	public override bool has_scrollbar () {
		return true;
	}
	
	public override void scroll_wheel_down (double x, double y) {
		int nrows = rows.size;
		scroll += 3;

		if (scroll > nrows - visible_rows) {
			scroll = (int) (nrows - visible_rows);
		}
		
		if (visible_rows > nrows) {
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
	
	public void update_scrollbar () {
		uint rows = rows.size;

		if (rows == 0 || visible_rows == 0) {
			MainWindow.set_scrollbar_size (0);
			MainWindow.set_scrollbar_position (0);
		} else {
			MainWindow.set_scrollbar_size ((double) visible_rows / rows);
			MainWindow.set_scrollbar_position ((double) scroll /  rows);
		}
	}

	public override void scroll_to (double percent) {
		uint rows = rows.size;
		scroll = (int) (percent * rows);
		
		if (scroll > rows - visible_rows) {
			scroll = (int) (rows - visible_rows);
		}
		
		redraw_area (0, 0, allocation.width, allocation.height);
	}
}

}
