/*
    Copyright (C) 2015 Johan Mattsson

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

public class GuideTab : Table {
	
	Gee.ArrayList<Row> rows = new Gee.ArrayList<Row> ();
	
	public GuideTab () {
	}

	public override Gee.ArrayList<Row> get_rows () {
		return rows;
	}

	public override void selected_row (Row row, int column, bool delete_button) {
		Font font = BirdFont.get_current_font ();
		int index = row.get_index ();
		
		if (delete_button) {
			return_if_fail (0 <= index < font.custom_guides.size);
			BirdFont.get_current_font ().custom_guides.remove_at (index);
			update_rows ();
		}
	}
	
	public override void update_rows () {
		int i = 0;
		
		rows.clear ();
		
		foreach (Line guide in BirdFont.get_current_font ().custom_guides) {
			rows.add (new Row.columns_1 (guide.label, i));
			i++;
		}
		
		GlyphCanvas.redraw ();
	}

	public override string get_label () {
		return t_("Guides");
	}

	public override string get_name () {
		return "Guides";
	}
}

}
