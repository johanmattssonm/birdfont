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
	static const int ALTERNATE_ENTRY = 4;
	
	GlyphCollection? glyph_collection = null;
	GlyphCollection? replacement_glyph = null;
	string alternate_name = "";
	TextListener listener;
	
	Gee.ArrayList<AlternateItem> undo_items;
	// FIXME: implement redo
	
	public OtfFeatureTable (GlyphCollection? gc) {
		glyph_collection = gc;
		undo_items = new Gee.ArrayList<AlternateItem> ();
	}

	public override Gee.ArrayList<Row> get_rows () {
		return rows;
	}

	public override void selected_row (Row row, int column, bool delete_button) {
		int row_index = row.get_index ();
		Object o;
		String s;
		AlternateItem a;
		
		if (row_index == SOURCE_GLYPH) {
			GlyphSelection gs = new GlyphSelection ();
			
			gs.selected_glyph.connect ((gc) => {
				glyph_collection = gc;
				replacement_glyph = null;
				Tool.yield ();		
				MainWindow.get_tab_bar ().select_tab_name (get_name ());
			});
			
			GlyphCanvas.set_display (gs);
		} else if (row_index == REPLACEMENT_GLYPH) {
			GlyphSelection gs = new GlyphSelection ();
			
			gs.selected_glyph.connect ((gc) => {
				replacement_glyph = gc;
				Tool.yield ();		
				MainWindow.get_tab_bar ().select_tab_name (get_name ());
			});
			
			GlyphCanvas.set_display (gs);
		} else if (row_index == OTF_FEATURE) {
			return_if_fail (row.has_row_data ());
			o = (!) row.get_row_data ();
			return_if_fail (o is String);
			s = (String) o;
			add_new_alternate (s.data);
		} else if (row_index == ALTERNATE_ENTRY) {
			if (delete_button) {
				return_if_fail (row.has_row_data ());
				o = (!) row.get_row_data ();
				return_if_fail (o is AlternateItem);
				a = (AlternateItem) o;
				
				a.delete_item_from_list ();				
				Font f = BirdFont.get_current_font ();
				f.alternates.remove_empty_sets ();
				
				undo_items.add (a);
				
				update_rows ();
				GlyphCanvas.redraw ();
			}
		}
	}

	public override void update_rows () {
		Row row;
		Font font;
		
		font = BirdFont.get_current_font ();
		rows.clear ();

		row = new Row.headline (t_("Glyph Substitutions"));
		rows.add (row);
		
		string glyph = "";
		
		if (glyph_collection == null) {
			glyph = t_("New glyph");
		} else {
			glyph = ((!) glyph_collection).get_name ();
		}
		
		row = new Row.columns_1 (t_("Glyph") + ": " + glyph, SOURCE_GLYPH, false);
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
		
		Gee.ArrayList<string> tags = font.alternates.get_all_tags ();
		foreach (string tag in tags) {
			row = new Row.headline (OtfLabel.get_string (tag));
			rows.add (row);
			add_alternate_items (tag);
		}
			
		GlyphCanvas.redraw ();
	}

	void add_alternate_items (string tag) {
		Font font = BirdFont.get_current_font ();
		foreach (Alternate alt in font.alternates.get_alt (tag)) {
			add_alternate_rows (alt);
		}		
	}

	void add_alternate_rows (Alternate alt) {
		Row row;
		
		foreach (string a in alt.alternates) {
			row = new Row.columns_2 (alt.glyph_name, a, ALTERNATE_ENTRY, true);
			row.set_row_data (new AlternateItem (alt, a));
			rows.add (row);
		}		
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
		GlyphCollection gc;
		
		if (glyph_collection == null) {
			MainWindow.show_message (t_("Select a glyph to create an alternate for."));
			return;
		}
		
		gc = (!) glyph_collection;
		
		listener = new TextListener (t_("Glyph name"), "", t_("Add"));
		
		listener.signal_text_input.connect ((text) => {
			alternate_name = text;
		});
		
		listener.signal_submit.connect (() => {
			GlyphCollection alt;
			Font font;
			OverView overview = MainWindow.get_overview ();
			
			font = BirdFont.get_current_font ();

			if (font.glyph_name.has_key (alternate_name)) {
				MainWindow.show_message (t_("All glyphs must have unique names."));
			} else {
				alt = new GlyphCollection.with_glyph ('\0', alternate_name);
				alt.set_unassigned (true);
				font.add_new_alternate (gc, alt, tag);
				update_rows ();
				GlyphCanvas.redraw ();
				MainWindow.get_overview ().update_item_list ();
				overview.open_glyph_signal (alt);
			}
		});
		
		if (replacement_glyph != null) {
			GlyphCollection replacement = (!) replacement_glyph;
			Font f = BirdFont.get_current_font ();
			f.add_alternate (gc.get_name (), replacement.get_name (), tag);
			update_rows ();
			GlyphCanvas.redraw ();
		} else {
			TabContent.show_text_input (listener);
		}		
	}
	
	public override void undo () {
		AlternateItem item;
		Font font;
		
		font = BirdFont.get_current_font ();
		
		if (undo_items.size > 0) {
			item = undo_items.get (undo_items.size - 1);
			undo_items.remove_at (undo_items.size - 1);
			
			font.add_alternate (item.alternate_list.glyph_name,
				item.alternate,
				item.alternate_list.tag);
				
			update_rows ();
			GlyphCanvas.redraw ();
		}
	}
}

}
