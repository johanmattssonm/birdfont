/*
	Copyright (C) 2016 Johan Mattsson

	This library is free software; you can redistribute it and/or modify 
	it under the terms of the GNU Lesser General Public License as 
	published by the Free Software Foundation; either version 3 of the 
	License, or (at your option) any later version.

	This library is distributed in the hope that it will be useful, but 
	WITHOUT ANY WARRANTY; without even the implied warranty of 
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU 
	Lesser General Public License for more details.
*/

namespace BirdFont {

public class TransformTask : Task {
	static Transform transform;
	
	public TransformTask (Transform transform) {
		base (process_transform);
		TransformTask.transform = transform;
	}
	
	public static void process_transform () {
		OverView o;
		Glyph g;
		OverView.OverViewUndoItem ui;
		
		o = OverviewTools.get_overview ();
		ui = new OverView.OverViewUndoItem ();
		
		Font f = BirdFont.get_current_font ();
		ui.alternate_sets = f.alternates.copy ();
					
		foreach (GlyphCollection gc in o.selected_items) {
			if (gc.length () > 0) {
				g = gc.get_current ();
				ui.glyphs.add (gc.copy_deep ());
				g.add_help_lines ();
				
				if (transform == Transform.SLANT) {
					if (OverviewTools.skew.get_value () != 0) {
						DrawingTools.resize_tool.skew_glyph (g, -OverviewTools.skew.get_value (), 0, false);
					}
				}
				
				if (transform == Transform.SIZE) {
					if (OverviewTools.resize.get_value () != 100) {
						double scale = OverviewTools.resize.get_value () / 100;
						DrawingTools.resize_tool.resize_glyph (g, scale, scale, false);
					}
				}
				
				if (transform == Transform.SVG_TO_TTF) {
					DrawingTools.move_tool.convert_glyph_to_monochrome (gc.get_current ());
				}
			}
		}
		
		foreach (OverViewItem item in o.visible_items) {
			item.clear_cache ();
			item.draw_glyph_from_font ();	
		}
		
		o.undo_items.add (ui);
		
		MainWindow.get_overview ().update_item_list ();
		GlyphCanvas.redraw ();
	}
}

}	
