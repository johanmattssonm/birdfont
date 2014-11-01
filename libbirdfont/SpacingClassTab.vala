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
	
	public static int NEW_CLASS = -1;
	Gee.ArrayList<Row> rows = new Gee.ArrayList<Row> ();
	
	public SpacingClassTab () {
	}

	public override Gee.ArrayList<Row> get_rows () {
		return rows;
	}

	public override void selected_row (Row row, int column, bool delete_button) {
		Font font = BirdFont.get_current_font ();
		SpacingData spacing = font.get_spacing ();
		
		if (row.get_index () == -1) {
			spacing.add_class ("?", "?");
			MainWindow.native_window.hide_text_input ();
			update_rows ();
			update_scrollbar ();
			font.touch ();
		} else if (spacing.classes.size != 0) {
			if (delete_button) {
				return_if_fail (0 <= row.get_index () < spacing.classes.size);
				spacing.classes.remove_at (row.get_index ());
				MainWindow.native_window.hide_text_input ();
				update_rows ();
				update_scrollbar ();
				font.touch ();
			} else if (column == 0) {
				if (!(0 <= row.get_index () < spacing.classes.size)) {
					warning (@"Index: $(row.get_index ()) classes.size: $(spacing.classes.size)");
					return;
				}
				spacing.classes.get (row.get_index ()).set_first ();
				font.touch ();
			} else if (column == 2) {
				return_if_fail (0 <= row.get_index () < spacing.classes.size);
				spacing.classes.get (row.get_index ()).set_next ();
				font.touch ();
			}
		}
	}
	
	public override void update_rows () {
		int i = 0;
		SpacingData spacing = BirdFont.get_current_font ().get_spacing ();
		
		rows.clear ();
		rows.add (new Row (t_("New spacing class"), NEW_CLASS, false));
		
		foreach (SpacingClass c in spacing.classes) {
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
