/*
    Copyright (C) 2012 Johan Mattsson

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

using Gtk;
using Gdk;

namespace Supplement {

class BackgroundTool : Tool {

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
	bool resize_bg; // DEL
	
	public BackgroundTool (string name) {
		base (name, "Move, resize and rotate background image");
		
		top_limit = 0;
		bottom_limit = 0;

		select_action.connect((self) => {
		});

		deselect_action.connect ((self) => {
		});
		
		press_action.connect((self, b, x, y) => {
			Glyph g = MainWindow.get_current_glyph ();
			GlyphBackgroundImage? bg = g.get_background_image ();
			GlyphBackgroundImage background;
			
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
			GlyphBackgroundImage? bg = g.get_background_image ();
			
			if (bg == null) {
				return;
			}
			
			img_offset_x = ((!)bg).img_offset_x;
			img_offset_y = ((!)bg).img_offset_y;
			
			((!)bg).handler_release (x, y);
			
			move_bg = false;
			resize_bg = false;
		});

		move_action.connect((self, x, y) => {			
			move (x, y);
		});
		
		draw_action.connect ((self, cairo_context, glyph) => {
			Glyph g = MainWindow.get_current_glyph ();
			GlyphBackgroundImage? background_image = g.get_background_image ();
			if (background_image == null) return;
			
			((!) background_image).draw_handle (cairo_context, glyph);
		});
	}
		
	void move (double x, double y) {
		Glyph g = MainWindow.get_current_glyph ();
		GlyphBackgroundImage? background_image = g.get_background_image ();
		GlyphBackgroundImage bg = (!) background_image;
		
		double xscale, yscale, dx, dy;

		if (background_image == null) return;
		 		
		bg.handler_move (x, y);
	
		if (!(move_bg || resize_bg)) return;
		
		dx = x - begin_x;
		dy = y - begin_y;
		
		dx *= 1/g.view_zoom;
		dy *= 1/g.view_zoom;
	
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

		MainWindow.get_glyph_canvas ().redraw ();
	}
	
	public override bool test () {
		return false;
	}

}

}

