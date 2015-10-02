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
	static const int SOURCE_GLYPH = 2; // the glyph to replace
	static const int REPLACEMENT_GLYPH = 3;
	
	GlyphCollection glyph_collection;
	GlyphCollection? replacement_glyph = null;
	string alternate_name = "";
	TextListener listener;
	
	public OtfFeatureTable (GlyphCollection gc) {
		glyph_collection = gc;
	}

	public override Gee.ArrayList<Row> get_rows () {
		return rows;
	}

	public override void selected_row (Row row, int column, bool delete_button) {
		int row_index = row.get_index ();
		
		if (row_index == SOURCE_GLYPH) {
			GlyphSelection gs = new GlyphSelection ();
			
			gs.selected_glyph.connect ((gc) => {
				glyph_collection = gc;		
				MainWindow.get_tab_bar ().select_tab_name (get_name ());
			});
			
			GlyphCanvas.set_display (gs);
		} else if (row_index == REPLACEMENT_GLYPH) {
			GlyphSelection gs = new GlyphSelection ();
			
			gs.selected_glyph.connect ((gc) => {
				replacement_glyph = gc;		
				MainWindow.get_tab_bar ().select_tab_name (get_name ());
			});
			
			GlyphCanvas.set_display (gs);
		} else if (row_index == OTF_FEATURE) {
			String s = (String) row.get_row_data ();
			add_new_alternate (s.data);
		}
	}

	public override void update_rows () {
		Row row;

		rows.clear ();

		row = new Row.headline (t_("Glyph Substitutions"));
		rows.add (row);
		
		row = new Row.columns_1 (t_("Glyph") + ": " + glyph_collection.get_name (), SOURCE_GLYPH, false);
		rows.add (row);
		
		string replacement = t_("New glyph");
		
		if (replacement_glyph != null) {
			GlyphCollection gc = (!) replacement_glyph;
			replacement = gc.get_name ();
		}
		
		row = new Row.columns_1 (t_("Replacement") + ": " + replacement, REPLACEMENT_GLYPH, false);
		rows.add (row);

		// FIXME: reuse parts of this for fractions etc.
	
		row = new Row.headline (t_("Tag"));
		rows.add (row);
		
		row = new Row.columns_1 (OtfLabel.get_string ("salt"), OTF_FEATURE, false);
		row.set_row_data (new String ("salt"));
		rows.add (row);

		row = new Row.columns_1 (OtfLabel.get_string ("smcp"), OTF_FEATURE, false);
		row.set_row_data (new String ("smcp"));
		rows.add (row);

		row = new Row.columns_1 (OtfLabel.get_string ("c2sc"), OTF_FEATURE, false);
		row.set_row_data (new String ("c2sc"));
		rows.add (row);

		row = new Row.columns_1 (OtfLabel.get_string ("swsh"), OTF_FEATURE, false);
		row.set_row_data (new String ("swsh"));
		rows.add (row);
				
		GlyphCanvas.redraw ();
	}

	public override string get_label () {
		return t_("Glyph Substitutions");
	}

	public override string get_name () {
		return "Glyph Substitutions";
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
		
		if (replacement_glyph != null) {
			GlyphCollection replacement = (!) replacement_glyph;
			Font f = BirdFont.get_current_font ();
			f.add_alternate (gc.get_name (), replacement.get_name (), tag);
			MainWindow.tabs.close_display (this);
		} else {
			TabContent.show_text_input (listener);
		}
		
	}
}

}
