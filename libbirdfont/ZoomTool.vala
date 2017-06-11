/*
	Copyright (C) 2012 Johan Mattsson

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

public class ZoomTool : Tool {

	int zoom_area_begin_x = -1;
	int zoom_area_begin_y = -1;
	
	int view_index = 0;
	Gee.ArrayList<Tab> views;
	
	public ZoomTool (string n) {
		base (n, "Zoom");

		views = new Gee.ArrayList<Tab> ();

		select_action.connect((self) => {
		});

		select_action.connect((self) => {
		});
			
		press_action.connect((self, b, x, y) => {
			if (b == 1 && !KeyBindings.has_ctrl () && !KeyBindings.has_shift ()) {
				zoom_area_begin_x = x;
				zoom_area_begin_y = y;
				Glyph g = MainWindow.get_current_glyph ();
				g.zoom_area_is_visible = true;
			}
		});

		move_action.connect((self, x, y) => {
			Glyph g = MainWindow.get_current_glyph ();
			
			if (g.zoom_area_is_visible) {
				g.show_zoom_area (zoom_area_begin_x, zoom_area_begin_y, x, y);
			}
		});
		
		release_action.connect((self, b, x, y) => {
			Glyph g;
						
			if (b == 1 && !KeyBindings.has_ctrl () && !KeyBindings.has_shift ()) {
				store_current_view ();
				
				g =	MainWindow.get_current_glyph ();
				
				if (zoom_area_begin_x == x && zoom_area_begin_y == y) { // zero width center this point but don't zoom in
					g.set_center (x, y);
				} else { 
					g.set_zoom_from_area ();
				}
				
				g.zoom_area_is_visible = false;
				zoom_area_begin_x = -1;
				zoom_area_begin_y = -1;
			}
		});
		
		draw_action.connect ((tool, cairo_context, glyph) => {
			 draw_zoom_area (cairo_context);
		});
	}

	public void draw_zoom_area (Context cr) {
		Glyph g = MainWindow.get_current_glyph ();
		
		if (g.zoom_area_is_visible) {
			cr.save ();
			cr.set_line_width (2.0);
			Theme.color (cr, "Selection Border");
			
			cr.rectangle (Math.fmin (g.zoom_x1, g.zoom_x2), 
				Math.fmin (g.zoom_y1, g.zoom_y2), 
				Math.fabs (g.zoom_x1 - g.zoom_x2),
				Math.fabs (g.zoom_y1 - g.zoom_y2));
				
			cr.stroke ();
			cr.restore ();
		}
	}
	
	public static void zoom_full_background_image () {
		BackgroundImage bg;
		Glyph g = MainWindow.get_current_glyph ();
		int x, y;
		
		g.reset_zoom ();
		
		if (g.get_background_image () == null) {
			return;
		}
		
		bg = (!) g.get_background_image ();
		
		x = (int) (bg.img_offset_x);
		y = (int) (bg.img_offset_y);
		
		g.set_zoom_area (x, y, (int) (x + bg.size_margin * bg.img_scale_x), (int) (y + bg.size_margin * bg.img_scale_y));
		g.set_zoom_from_area ();
	}

	public void zoom_full_glyph () {
		store_current_view ();		
		MainWindow.get_current_display ().zoom_min ();
	}
	
	/** Add an item to zoom view list. */
	public void store_current_view () {	
		if (views.size - 1 > view_index) {
			int i = view_index + 1;
			while (i != views.size - 1) {
				views.remove_at (i);
			}
		}
		
		views.add (MainWindow.get_current_tab ());
		view_index = (int) views.size - 1;
		MainWindow.get_current_display ().store_current_view ();
	}

	/** Redo last zoom.*/
	public void next_view () {
		if (view_index + 1 >= (int) views.size) {
			return;
		}
		
		view_index++;
	
		MainWindow.get_current_display ().next_view ();
		GlyphCanvas.redraw ();
	}
	
	/** Undo last zoom. */
	public void previous_view () {
		if (view_index == 0) {
			return;
		}
		
		view_index--;
	
		MainWindow.get_current_display ().restore_last_view ();
		GlyphCanvas.redraw ();
	}
}
	
}
