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

public class ZoomBar : Tool {

	double zoom_level = 1 / 3.0;
	bool update_zoom = false;
	
	public signal void new_zoom (double zoom_level);
	
	public ZoomBar () {
		base ();
		
		panel_press_action.connect ((selected, button, tx, ty) => {
			if (y <= ty <= y + h) {
				set_zoom_from_mouse (tx);
				update_zoom = true;
			}
		});

		panel_move_action.connect ((selected, button, tx, ty) => {
			if (update_zoom) {
				set_zoom_from_mouse (tx);
			}
			
			return true;
		});
		
		panel_release_action.connect ((selected, button, tx, ty) => {
			update_zoom = false;
		});
	}
	
	/** Zoom level from 0 to 1. */
	public void set_zoom (double z) {
		zoom_level = z;
		
		if (!MenuTab.background_thread) {
			Toolbox.redraw_tool_box ();
		}
	}
	
	void set_zoom_from_mouse (double tx) {
		double margin = w * 0.1;
		double bar_width = w - margin - x;
		
		tx -= x;
		zoom_level = tx / bar_width;
		
		if (zoom_level > 1) {
			zoom_level = 1;
		}

		if (zoom_level < 0) {
			zoom_level = 0;
		}
		
		set_zoom (zoom_level);
		
		if (!MenuTab.suppress_event) {
			new_zoom (zoom_level);
		}
		
		GlyphCanvas.current_display.dirty_scrollbar = true;
	}
	
	public override void draw (Context cr) {
		double margin = w * 0.1;
		double bar_width = w - margin - x;
		
		// filled
		cr.save ();
		cr.set_source_rgba (26 / 255.0, 30 / 255.0, 32 / 255.0, 1);
		draw_bar (cr);
		cr.fill ();
		cr.restore ();
		
		// remove non filled parts
		cr.save ();
		cr.set_source_rgba (51 / 255.0, 54 / 255.0, 59 / 255.0, 1);
		cr.rectangle (x + bar_width * zoom_level, y, w, h);
		cr.fill ();
		cr.restore ();
		
		// border
		cr.save ();
		cr.set_source_rgba (26 / 255.0, 30 / 255.0, 32 / 255.0, 1);
		cr.set_line_width (0.8);
		draw_bar (cr);
		cr.stroke ();
		cr.restore ();
	}
	
	void draw_bar (Context cr) {
		double height = h;
		double radius = height / 2;
		double margin = w * 0.1;
	
		cr.move_to (x + radius, y + height);
		cr.arc (x + radius, y + radius, radius, PI / 2, 3 * (PI / 2));
		cr.line_to (w - margin - radius, y);
		cr.arc (w - margin - radius, y + radius, radius, 3 * (PI / 2), 5 * (PI / 2));
		cr.line_to (x + radius, y + height);
		cr.close_path ();			
	}
}

}
