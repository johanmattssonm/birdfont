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

	void add_contextual_ligature (string backtrack, string input, string lookahead) {
		Font font = BirdFont.get_current_font ();
		Ligatures ligatures = font.get_ligatures ();
		ligatures.add_contextual_ligature (backtrack, input, lookahead);
	}
	
	void add_ligature (string subst, string liga) {
		Font font = BirdFont.get_current_font ();
		Ligatures ligatures = font.get_ligatures ();
		ligatures.add_ligature (subst, liga);
	}

	public override void selected_row (Row row, int column, bool delete_button) {
		Font font = BirdFont.get_current_font ();
		Ligatures ligatures = font.get_ligatures ();
		int i;
		ContextualLigature cl;
		
		if (row.get_index () == NEW_LIGATURE && column == 0) {
			add_ligature (t_("character sequence"), t_("ligature"));
			MainWindow.native_window.hide_text_input ();
		} else if (row.get_index () == NEW_LIGATURE && column == 1) {
			if (BirdFont.has_argument ("--test")) {
				add_contextual_ligature (t_("beginning"), t_("middle"), t_("end"));
				MainWindow.native_window.hide_text_input ();
			}
		} else if (row.has_row_data ()) {
			i = row.get_index ();
			cl = (ContextualLigature) ((!) row.get_row_data ());
			
			if (delete_button) {
				cl.remove_ligature_at (i);
			} else if (column == 0) {
				cl.set_ligature (i);
			} else if (column == 2) {
				cl.set_substitution (i);
			}
		} else if (row.get_index () < ligatures.count ()) {
			if (ligatures.count () != 0) {
				if (delete_button) {
					return_if_fail (0 <= row.get_index () < ligatures.count ());
					ligatures.remove_at (row.get_index ());
					MainWindow.native_window.hide_text_input ();
				} else if (column == 0) {
					return_if_fail (0 <= row.get_index () < ligatures.count ());
					ligatures.set_ligature (row.get_index ());
				} else if (column == 2) {
					return_if_fail (0 <= row.get_index () < ligatures.count ());
					ligatures.set_substitution (row.get_index ());
				}
			}
		} else {
			i = row.get_index () - ligatures.count ();
			if (i < ligatures.count_contextual_ligatures ()) {
				return_if_fail (0 <= i < ligatures.count_contextual_ligatures ());
				if (delete_button) {
					ligatures.remove_contextual_ligatures_at (i);
					MainWindow.native_window.hide_text_input ();
				} else if (column == 0) {
					ligatures.set_beginning (i);
				} else if (column == 1) {
					ligatures.set_middle (i);
				} else if (column == 2) {
					ligatures.set_end (i);
				} else if (column == 3) {
					ligatures.add_substitution_at (i);
				}
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
		Row row;
		
		rows.clear ();
		if (BirdFont.has_argument ("--test")) {
			row = new Row.columns_2 (t_("New Ligature"), t_("New Contextual Substitution"), NEW_LIGATURE, false);
			rows.add (row);
		} else {
			row = new Row.columns_1 (t_("New Ligature"), NEW_LIGATURE, false);
			rows.add (row);
		}
		
		i = 0;
		ligatures.get_ligatures ((subst, liga) => {
			row = new Row.columns_3 (liga, "",  subst, i);
			rows.add (row);
			i++;
		});

		ligatures.get_contextual_ligatures ((liga) => {
			int j;
			
			row = new Row.columns_4 (liga.backtrack, liga.input, liga.lookahead,
				t_("Add Ligature"), i);
			rows.add (row);
			
			j = 0;
			foreach (Ligature l in liga.ligatures) {
				row = new Row.columns_3 (l.ligature, "",  l.substitution, j);
				row.set_row_data (liga);
				rows.add (row);
				j++;
			}
			
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
