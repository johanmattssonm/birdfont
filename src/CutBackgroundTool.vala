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

using Cairo;
using Gtk;
using Gdk;
using Math;

namespace Supplement {

class CutBackgroundTool : Tool {

	double x1 = 0;
	double y1 = 0;
	double x2 = 0;
	double y2 = 0;
	bool cut_background_is_visible = false;
	bool cut_background_is_moving = false;
	
	public signal void new_image (string file);
	
	string? destination_file_name = null;
	
	public CutBackgroundTool (string name) {
		base (name, "cut background image", 'u', CTRL);		

		select_action.connect((self) => {
		});

		deselect_action.connect ((self) => {
		});
		
		press_action.connect((self, b, x, y) => {
			bool selection = MainWindow.get_current_display () is CutBackgroundCanvas;

			if (!selection) {
				return;
			}
						
			if (!is_over_rectangle (x, y)) {
				x1 = x;
				y1 = y;
				
				cut_background_is_moving = true;
				cut_background_is_visible = true;
			} else {
		
				do_cut ();
				
				cut_background_is_visible = false;
				cut_background_is_moving = false;
			}
			
		});

		release_action.connect((self, b, x, y) => {
			x2 = x;
			y2 = y;
			
			cut_background_is_moving = false;
		});

		move_action.connect((self, x, y) => {
			if (cut_background_is_moving) {
				x2 = x;
				y2 = y;
			}
			
			MainWindow.get_glyph_canvas ().redraw ();
		});
		
		draw_action.connect ((self, cr, glyph) => {
			if (cut_background_is_visible) {
				cr.save ();
				cr.set_line_width (2.0);
				cr.set_source_rgba (0, 0, 1, 0.3);
				cr.rectangle (fmin (x1, x2), fmin (y1, y2), fabs (x1 - x2), fabs (y1 - y2));
				cr.fill_preserve ();
				cr.restore ();
			}
		});

	}

	public void set_destination_file_name (string fn) {
		destination_file_name = fn;
	}

	bool is_over_rectangle (double x, double y) {
		return fmin (x1, x2) < x < fmax (x1, x2) && fmin (y1, y2) < y < fmax (y1, y2);
	}

	double get_width () {
		return fabs (x1 - x2);
	}

	double get_height () {
		return fabs (y1 - y2);
	}

	void do_cut () {
		double x, y;
		int h, w;
		
		Glyph g = MainWindow.get_current_glyph ();
		GlyphBackgroundImage? b = g.get_background_image ();
		GlyphBackgroundImage bg = (!) b;
		
		ImageSurface img;
		
		Surface sr;
		Context cr;
		
		if (b == null) {
			return;
		}

		img = bg.get_img ();

		w = (int) (get_width () / g.view_zoom);
		h = (int) (get_height () / g.view_zoom);

		sr = new Surface.similar (img, img.get_content (), w, h);
		cr = new Context (sr);
		
		// fine for 1:1 but not for scaled image
		x = bg.img_offset_x;
		y = bg.img_offset_y;
		
		x -= fmin (x1, x2);
		y -= fmin (y1, y2);

		x *= Glyph.ivz ();
		y *= Glyph.ivz ();

		x += Glyph.xc ();
		y += Glyph.yc ();

		x -= g.view_offset_x;
		y -= g.view_offset_y;

		x -= bg.img_offset_x * (Glyph.ivz () - 1);
		y -= bg.img_offset_y * (Glyph.ivz () - 1);

		cr.save ();
		cr.set_source_rgba (1, 1, 1, 1);
		cr.rectangle (0, 0, w, h);
		cr.fill ();
		cr.restore ();
		
		cr.set_source_surface (img, x, y);
		cr.paint ();
		
		save_img (sr, g);
		
		cr.restore ();		
	}
	
	void save_img (Surface sr, Glyph g) {
		GlyphBackgroundImage newbg;
		Font f = Supplement.get_current_font ();
		File img_dir;
		File img_file;
		string fn;
		string name;
		
		if (destination_file_name != null) {
			name = (!) destination_file_name;
		} else {
			name = g.get_name ();
		}
		
		img_dir =  f.get_backgrounds_folder ().get_child ("parts");

		if (!img_dir.query_exists ()) {
			DirUtils.create ((!) img_dir.get_path (), 0xFFFFFF);
		}
	
		img_file = img_dir.get_child (@"$(name).png");
		fn = (!) img_file.get_path ();
		
		sr.write_to_png (fn);
		
		newbg = new GlyphBackgroundImage (fn);
		g.set_background_image (newbg);
		newbg.reset_scale (g);
		
		new_image (fn);
	}
}

}
