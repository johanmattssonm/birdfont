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

public class LigatureList : Table {
	Gee.ArrayList<Row> rows = new Gee.ArrayList<Row> ();

	public const int NEW_LIGATURE = -1;
	
	public LigatureList () {
	}

	public override Gee.ArrayList<Row> get_rows () {
		return rows;
	}

	void add_ligature (string subst, string liga) {
		Font font = BirdFont.get_current_font ();
		Ligatures ligatures = font.get_ligatures ();
		ligatures.add_ligature (subst, liga);
	}

	public override void selected_row (Row row, int column, bool delete_button) {
		Font font = BirdFont.get_current_font ();
		Ligatures ligatures = font.get_ligatures ();
		
		if (row.get_index () == NEW_LIGATURE) {
			add_ligature (t_("substitute"), t_("ligature"));
			MainWindow.native_window.hide_text_input ();
		} else if (ligatures.count () != 0) {
			if (delete_button) {
				return_if_fail (0 <= row.get_index () < ligatures.count ());
				ligatures.remove_at (row.get_index ());
				MainWindow.native_window.hide_text_input ();
			} else if (column == 0) {
				if (!(0 <= row.get_index () < ligatures.count ())) {
					warning (@"Index: $(row.get_index ()) ligatures.count (): $(ligatures.count ())");
					return;
				}
				ligatures.set_ligature (row.get_index ());
			} else if (column == 2) {
				return_if_fail (0 <= row.get_index () < ligatures.count ());
				ligatures.set_substitution (row.get_index ());
			}
		}

		update_rows ();
		update_scrollbar ();
		font.touch ();
	}

	public override void update_rows () {
		int i;
		Font font = BirdFont.get_current_font ();
		Ligatures ligatures = font.get_ligatures ();
		
		rows.clear ();
		rows.add (new Row (t_("New Ligature"), NEW_LIGATURE, false));
		
		i = 0;
		ligatures.get_ligatures ((subst, liga) => {
			rows.add (new Row.columns_3 (@"$subst", "->",  @"$liga", i));
			i++;
		});
		
		GlyphCanvas.redraw ();
	}

	public override string get_label () {
		return t_("Ligatures");
	}

	public override string get_name () {
		return "Ligatures";
	}
}

}
