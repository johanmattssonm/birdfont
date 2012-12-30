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
using Math;

namespace Supplement {

class CutBackgroundTool : Tool {

	double x1 = 0;
	double y1 = 0;
	double x2 = 0;
	double y2 = 0;
	
	bool is_visible = false;
	bool is_set = false;
	bool is_done = false;
		
	public signal void new_image (GlyphBackgroundImage file);
	
	public CutBackgroundTool (string name) {
		base (name, _("Crop background image"));

		select_action.connect((self) => {
		});

		deselect_action.connect ((self) => {
		});
		
		press_action.connect((self, b, x, y) => {				
			if (!is_over_rectangle (x, y) || !is_visible) {
				x1 = x;
				y1 = y;
	
				x2 = x;
				y2 = y;
				
				is_visible = true;
				is_set = false;
				is_done = false;
			}
			
			if (is_set && is_visible && is_over_rectangle (x, y)) {
				do_cut ();
				is_set = false;
				is_visible = false;
				is_done = true;
				
				x1 = 0;
				y1 = 0;
				x2 = 0;
				y2 = 0;
			}
		});

		release_action.connect((self, b, x, y) => {
			if (!is_set && !is_done) {
				x2 = x;
				y2 = y;
				is_set = true;
			}
			
			is_done = false;
		});

		move_action.connect((self, x, y) => {
			if (is_visible && !is_set) {
				x2 = x;
				y2 = y;
				
				MainWindow.get_glyph_canvas ().redraw ();
			}
		});
		
		draw_action.connect ((self, cr, glyph) => {
			if (is_visible) {
				cr.save ();
				cr.set_line_width (2.0);
				cr.set_source_rgba (0, 0, 1, 0.3);
				cr.rectangle (fmin (x1, x2), fmin (y1, y2), fabs (x1 - x2), fabs (y1 - y2));
				cr.stroke ();
				cr.restore ();
			}
		});

		new_image.connect ((file) => {
			Glyph glyph = MainWindow.get_current_glyph ();
			TabBar tb = MainWindow.get_tab_bar ();
			
			glyph.store_undo_state ();
			
			glyph.set_background_image (file);
			tb.select_tab_name (glyph.get_name ());
			
			glyph.set_background_visible (true);
		});

	}

	bool is_over_rectangle (double x, double y) {
		return fmin (x1, x2) + 1 < x < fmax (x1, x2) - 1 && fmin (y1, y2) + 1 < y < fmax (y1, y2) - 1;
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
		double wc, hc;
		
		Glyph g = MainWindow.get_current_glyph ();
		GlyphBackgroundImage? b = g.get_background_image ();
		GlyphBackgroundImage bg = (!) b;
		
		ImageSurface img;
		
		Surface sr;
		Context cr;
		
		double tx, ty, vx, vy;	
		if (b == null) {
			return;
		}

		// Add margin
		Surface sg = new Surface.similar (bg.get_img (), bg.get_img ().get_content (), bg.size_margin, bg.size_margin);
		Context cg = new Context (sg);
		
		wc = bg.get_margin_width ();
		hc = bg.get_margin_height ();
		
		cg.set_source_rgba (1, 1, 1, 1);
		cg.rectangle (0, 0, bg.size_margin, bg.size_margin);
		cg.fill ();
		
		cg.set_source_surface (bg.get_img (), wc, hc);
		cg.paint ();

		// find start
		tx = bg.img_offset_x - g.view_offset_x;
		ty = bg.img_offset_y - g.view_offset_y;
				
		ty *= g.view_zoom;
		tx *= g.view_zoom;

		vx = Glyph.path_coordinate_x (tx) - Glyph.path_coordinate_x (fmin (x1, x2));			
		vy = Glyph.path_coordinate_y (ty) - Glyph.path_coordinate_y (fmin (y1, y2));
		
		x = (int) (vx / bg.img_scale_x);
		y = (int) (-vy / bg.img_scale_y);

		// do the cut
		img = bg.get_img ();

		w = (int) (get_width () / g.view_zoom);
		h = (int) (get_height () / g.view_zoom);

		sr = new Surface.similar (sg, img.get_content (), w, h);
		cr = new Context (sr);

		cr.set_source_rgba (1, 1, 1, 1);
		cr.rectangle (0, 0, w, h);
		cr.fill ();
			
		cr.scale (bg.img_scale_x, bg.img_scale_y);
		
		cr.set_source_surface (sg, x, y);
		cr.paint ();
		
		save_img (sr, g);
		
		cr.restore ();
	}

	void save_img (Surface sr, Glyph g) {
		GlyphBackgroundImage newbg;
		Font f = Supplement.get_current_font ();
		File img_dir;
		File img_file;
		File img_file_next;
		string fn;
		double wc, hc;
		
		img_dir =  f.get_backgrounds_folder ().get_child ("parts");

		if (!img_dir.query_exists ()) {
			DirUtils.create ((!) img_dir.get_path (), 0xFFFFFF);
		}
	
		img_file = img_dir.get_child (@"NEW_BACKGROUND.png");
		fn = (!) img_file.get_path ();
		
		sr.write_to_png (fn);
		
		newbg = new GlyphBackgroundImage (fn);
		
		fn = newbg.get_sha1 () + ".png";

		img_file_next = img_dir.get_child (fn);
		
		try {
			if (img_file_next.query_exists ()) {
				img_file_next.delete ();
			}

			img_file.set_display_name (fn);
		} catch (GLib.Error e) {
			warning (e.message);
			return;
		}
		
		newbg = new GlyphBackgroundImage ((!) f.get_backgrounds_folder ().get_child ("parts").get_child (fn).get_path ());
			
		// set position for the new background
		wc = newbg.get_margin_width ();
		hc = newbg.get_margin_height ();
		
		newbg.img_x = Glyph.path_coordinate_x (fmin (x1, x2)) - wc - 0.5;
		newbg.img_y = Glyph.path_coordinate_y (fmin (y1, y2)) + hc + 0.5;

		new_image (newbg);
	}
}

}
