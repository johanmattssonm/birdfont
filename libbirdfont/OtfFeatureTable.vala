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

namespace BirdFont {

/** A table for managing feature tags in Open Type tables. */
public class OtfFeatureTable : Table {
	Gee.ArrayList<Row> rows = new Gee.ArrayList<Row> ();
	
	static const int NONE = 0;
	static const int OTF_FEATURE = 1;
	
	GlyphCollection glyph_collection;
	string alternate_name = "";
	TextListener listener;
	
	public OtfFeatureTable (GlyphCollection gc) {
		glyph_collection = gc;
	}

	public override Gee.ArrayList<Row> get_rows () {
		return rows;
	}

	public override void selected_row (Row row, int column, bool delete_button) {
		if (row.get_index () == OTF_FEATURE) {
			String s = (String) row.get_row_data ();
			add_new_alternate (s.data);
		}
	}

	public override void update_rows () {
		Row row;

		rows.clear ();

		row = new Row.headline (t_("OTF Features"));
		rows.add (row);
		
		row = new Row.columns_1 (t_("Glyph") + ": " + glyph_collection.get_name (), NONE, false);
		rows.add (row);
					
		// FIXME: reuse parts of this for fractions etc.
	
		row = new Row.headline (t_("Tag"));
		rows.add (row);
		
		row = new Row.columns_1 (t_("Stylistic Alternate") + " (salt)", OTF_FEATURE, false);
		row.set_row_data (new String ("salt"));
		rows.add (row);

		row = new Row.columns_1 (t_("Small Caps") + " (smcp)", OTF_FEATURE, false);
		row.set_row_data (new String ("smcp"));
		rows.add (row);

		row = new Row.columns_1 (t_("Capitals to Small Caps") + " (c2sc)", OTF_FEATURE, false);
		row.set_row_data (new String ("c2sc"));
		rows.add (row);

		row = new Row.columns_1 (t_("Swashes") + " (swsh)", OTF_FEATURE, false);
		row.set_row_data (new String ("swsh"));
		rows.add (row);
				
		GlyphCanvas.redraw ();
	}

	public override string get_label () {
		return t_("OTF Feature Tags");
	}

	public override string get_name () {
		return "OTF Feature Tags";
	}

	public override void draw (WidgetAllocation allocation, Context cr) {
		base.draw (allocation, cr);
	}	

	public void add_new_alternate (string tag) {
		GlyphCollection gc = glyph_collection;
		
		listener = new TextListener (t_("Glyph name"), "", t_("Add"));
		
		listener.signal_text_input.connect ((text) => {
			alternate_name = text;
		});
		
		listener.signal_submit.connect (() => {
			GlyphCollection alt;
			Font font;
			OverView overview = MainWindow.get_overview ();
			
			font = BirdFont.get_current_font ();
			
			if (alternate_name == "" || gc.is_unassigned ()) {
				MainWindow.tabs.close_display (this);
				return;
			}
			
			if (font.glyph_name.has_key (alternate_name)) {
				MainWindow.show_message (t_("All glyphs must have unique names."));
			} else {
				alt = new GlyphCollection.with_glyph ('\0', alternate_name);
				alt.set_unassigned (true);
				font.add_new_alternate (gc, alt, tag);
				MainWindow.tabs.close_display (this);
				MainWindow.get_overview ().update_item_list ();
				overview.open_glyph_signal (alt);
			}
		});
		
		TabContent.show_text_input (listener);
	}
}

}
