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

public class LanguageSelectionTab : Table {
	
	public LanguageSelectionTab () {
	}
	
	public override Gee.ArrayList<Row> get_rows () {
		Gee.ArrayList<Row> rows = new Gee.ArrayList<Row> ();
		int i = 0;

		rows.add (new Row.headline (t_("Character Sets")));

		foreach (string language in DefaultLanguages.names) {
			Row r = new Row.columns_1 (language, i, false);
			rows.add (r);
			i++;
		}
		
		return rows;
	}

	public override void update_rows () {
		redraw_area (0, 0, allocation.width, allocation.height);
	}

	public override void selected_row (Row row, int column, bool delete_button) {
		select_language (row.get_index ());
	}

	void select_language (int row) {
		string iso_code;
		OverView overview;
		GlyphRange gr;
		TabBar tb = MainWindow.get_tab_bar ();
		
		return_if_fail (0 <= row < DefaultLanguages.codes.size);
		
		iso_code = DefaultLanguages.codes.get (row);
		Preferences.set ("language", iso_code);
		tb.close_display (this);

		overview = MainWindow.get_overview ();
		gr = new GlyphRange ();
		DefaultCharacterSet.use_default_range (gr);
		overview.set_current_glyph_range (gr);
		OverviewTools.update_overview_characterset ();
		FontDisplay.dirty_scrollbar = true;
	}
	
	public override string get_label () {
		return t_("Character Set");
	}
	
	public override string get_name () {
		return "Character Set";
	}
}

}
