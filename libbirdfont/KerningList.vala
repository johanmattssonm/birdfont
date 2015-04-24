/*
    Copyright (C) 2013 2015 Johan Mattsson

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

public class KerningList : Table {
	
	Gee.ArrayList<UndoItem> undo_items;
	
	public KerningList () {
		undo_items = new Gee.ArrayList<UndoItem> ();
	}

	public override Gee.ArrayList<Row> get_rows () {
		Gee.ArrayList<Row> rows = new Gee.ArrayList<Row> ();
		KerningClasses classes = BirdFont.get_current_font ().get_kerning_classes ();
		int i;
		
		i = 0;

		classes.get_classes ((left, right, kerning) => {
			Row r = new Row.columns_3 (left, right, @"$kerning", i);
			rows.add (r);
			i++;
		});

		classes.get_single_position_pairs ((left, right, kerning) => {
			Row r = new Row.columns_3 (left, right, @"$kerning", i);
			rows.add (r);
			i++;
		});
		
		rows.sort ((a, b) => {
			Row sa, sb;
			sa = (Row) a;
			sb = (Row) b;
			return strcmp (sa.column_text.get (0).text, sb.column_text.get (0).text);
		});

		rows.insert (0, new Row.headline (t_("Kerning Pairs")));
		
		if (rows.size == 1) {
			rows.insert (1, new Row.columns_1 (t_("No kerning pairs created."), 0, false));
		}
		
		return rows;
	}

	public override void selected_row (Row row, int column, bool delete_button) {
		return_if_fail (row.column_text.size > 2);
		
		if (delete_button) {
			delete_kerning (row.column_text.get (0).text, row.column_text.get (1).text);
		}
	}

	 void delete_kerning (string left, string right) {
		double kerning = 0;
		GlyphRange glyph_range_first, glyph_range_next;
		Font font = BirdFont.get_current_font ();
		KerningClasses classes = font.get_kerning_classes ();
		string l, r;
		int class_index = -1;
		
		l = GlyphRange.unserialize (left);
		r = GlyphRange.unserialize (right);
					
		glyph_range_first = new GlyphRange ();
		glyph_range_next = new GlyphRange ();
		
		try {
			glyph_range_first.parse_ranges (left);
			glyph_range_next.parse_ranges (right);
		} catch (GLib.MarkupError e) {
			warning (e.message);
			return;
		}

		if (left != "" && right != "") {
			if (glyph_range_first.is_class () || glyph_range_next.is_class ()) {
				
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
	}

	public override string get_label () {
		return t_("Kerning Pairs");
	}

	public override string get_name () {
		return "Kerning Pairs";
	}
	
	public override void undo () {
		UndoItem ui;
		KerningClasses classes = BirdFont.get_current_font ().get_kerning_classes ();
		GlyphRange glyph_range_first, glyph_range_next;
		
		try {
			if (undo_items.size == 0) {
				return;
			}
			
			ui = undo_items.get (undo_items.size - 1);

			glyph_range_first = new GlyphRange ();
			glyph_range_next = new GlyphRange ();
			
			glyph_range_first.parse_ranges (ui.first);
			glyph_range_next.parse_ranges (ui.next);
						
			if (glyph_range_first.is_class () || glyph_range_next.is_class ()) {
				classes.set_kerning (glyph_range_first, glyph_range_next, ui.kerning, ui.class_priority);
			} else {
				classes.set_kerning_for_single_glyphs (ui.first, ui.next, ui.kerning);
			}
			
			undo_items.remove_at (undo_items.size - 1);
		} catch (MarkupError e) {
			warning (e.message);
		}
		
		update_rows ();
	}
	
	public override void update_rows () {
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
