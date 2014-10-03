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

public class SpacingClassTab : Table {
	
	public Gee.ArrayList<SpacingClass> classes = new Gee.ArrayList<SpacingClass> ();
	public static int NEW_CLASS = -1;
	Gee.ArrayList<string> connections = new Gee.ArrayList<string> ();
	Gee.ArrayList<Row> rows = new Gee.ArrayList<Row> ();
	
	public SpacingClassTab () {
	}

	public override Gee.ArrayList<Row> get_rows () {
		return rows;
	}

	public static void remove_all_spacing_classes () {
		if (!is_null (MainWindow.spacing_class_tab)) {
			MainWindow.spacing_class_tab.classes.clear ();
		}
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
			return strcmp ((string) a, (string) b);
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

	public override void selected_row (Row row, int column, bool delete_button) {
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
	
	void update_all_rows (SpacingClass s) {
		update_rows ();
	}
	
	public override void update_rows () {
		int i = 0;
		
		rows.clear ();
		rows.add (new Row (t_("New spacing class"), NEW_CLASS, false));
		
		foreach (SpacingClass c in classes) {
			rows.add (new Row.columns_3 (@"$(c.first)", "=",  @"$(c.next)", i));
			i++;
		}
		
		GlyphCanvas.redraw ();
	}

	public override string get_label () {
		return t_("Spacing Classes");
	}

	public override string get_name () {
		return "SpacingClasses";
	}
}

}
