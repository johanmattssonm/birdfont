/*
    Copyright (C) 2012 2014 Johan Mattsson

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

public class BackgroundTool : Tool {

	double begin_x = 0;
	double begin_y = 0;

	public double img_offset_x = 0;
	public double img_offset_y = 0;

	public double img_width = 0;
	public double img_height = 0;
	
	public double img_scale_x = 0;

	public static double top_limit;
	public static double bottom_limit;
		
	bool move_bg;
	
	static BackgroundImage imported_background;
	
	public BackgroundTool (string name) {
		base (name, t_("Move, resize and rotate background image"));
		
		top_limit = 0;
		bottom_limit = 0;

		imported_background = new BackgroundImage ("");

		select_action.connect((self) => {
		});

		deselect_action.connect ((self) => {
		});
		
		press_action.connect((self, b, x, y) => {
			Glyph g = MainWindow.get_current_glyph ();
			BackgroundImage? bg = g.get_background_image ();
			BackgroundImage background;
			
			if (bg == null) {
				return;
			}

			background = (!) bg;
			
			g.store_undo_state ();
			
			background.handler_press (x, y);
			
			begin_x = x;
			begin_y = y;
			
			img_offset_x = background.img_offset_x;
			img_offset_y = background.img_offset_y;
			
			img_scale_x = background.img_scale_x;
			
			img_width = background.get_img ().get_width () * background.img_scale_x;
			img_height = background.get_img ().get_height () * background.img_scale_y;
			
			move_bg = true;
		});

		release_action.connect((self, b, x, y) => {
			Glyph g = MainWindow.get_current_glyph ();
			BackgroundImage? bg = g.get_background_image ();
			
			if (bg == null) {
				return;
			}
			
			img_offset_x = ((!)bg).img_offset_x;
			img_offset_y = ((!)bg).img_offset_y;
			
			((!)bg).handler_release (x, y);
			
			move_bg = false;
		});

		move_action.connect((self, x, y) => {			
			move (x, y);
		});
		
		draw_action.connect ((self, cairo_context, glyph) => {
			Glyph g = MainWindow.get_current_glyph ();
			BackgroundImage? background_image = g.get_background_image ();
			if (background_image == null) return;
			
			((!) background_image).draw_handle (cairo_context, glyph);
		});
	}
		
	void move (double x, double y) {
		Glyph g = MainWindow.get_current_glyph ();
		BackgroundImage? background_image = g.get_background_image ();
		BackgroundImage bg = (!) background_image;
		
		double xscale, yscale, dx, dy;

		if (background_image == null) {
			return;
		}
		 		
		bg.handler_move (x, y);
		
		dx = x - begin_x;
		dy = y - begin_y;
		
		dx *= 1 / g.view_zoom;
		dy *= 1 / g.view_zoom;
	
		dx *= PenTool.precision;
		dy *= PenTool.precision;
		
		if (bg.selected_handle == 2) {
			bg.set_img_rotation_from_coordinate (x, y);
		}
		
		if (bg.selected_handle == 1) {
			xscale = img_scale_x * ((img_width - dx) / img_width);	
			yscale = xscale;

			bg.set_img_scale (xscale, yscale);
			bg.set_img_offset (this.img_offset_x + dx, this.img_offset_y);
		} 
		
		if (move_bg && bg.selected_handle <= 0) {
			bg.set_img_offset (this.img_offset_x + dx, this.img_offset_y + dy);
		}

		GlyphCanvas.redraw ();
	}

	public static void load_background_image () {
		// generate png file if needed and load the image with cairo
		imported_background.load ();
		
		IdleSource idle = new IdleSource ();
		idle.set_callback (() => {
			TabBar tb = MainWindow.get_tab_bar ();
			Glyph g = MainWindow.get_current_glyph ();
			
			g.set_background_image (imported_background);
			imported_background.center_in_glyph ();			
			
			tb.select_tab_name (g.get_name ());

			Toolbox.select_tool_by_name ("zoom_background_image");
			Toolbox.select_tool_by_name ("cut_background");
			
			GlyphCanvas.redraw ();
			return false;
		});
		idle.attach (null);
	}

	internal static void import_background_image () {
		BackgroundImage bg;
		string? fn;
		string path;
		
		fn = MainWindow.file_chooser_open (_("Select background image"));
		
		if (fn != null) {
			path = (!) fn;
			bg = new BackgroundImage (path);
			imported_background = bg;
			MainWindow.native_window.load_background_image ();
		}
	}
}

}
