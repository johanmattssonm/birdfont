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

namespace Supplement {

class ResizeTool : Tool {

	ImageSurface move_icon;
	ImageSurface move_icon_active;

	ImageSurface rotate_icon;
	ImageSurface rotate_icon_active;
		
	int active_handle = -1;
	
	Path selected_path = new Path ();
	
	bool resize = false;
	double resize_begin_x = 0;
	double resize_begin_y = 0;
	Path? original_path = null;
	
	public ResizeTool (string n) {
		base (n, "resize paths");

		select_action.connect((self) => {
			active_handle = -1;
			redraw_handle ();
		});
			
		deselect_action.connect((self) => {
			active_handle = -1;
			redraw_handle ();
		});
		
		press_action.connect((self, b, x, y) => {
			if (get_handle_at (x, y) > -1) {
				resize_begin_x = x;
				resize_begin_y = y;
				resize = true;
				original_path = null;
			}
		});

		release_action.connect((self, b, x, y) => {
			resize = false;
			original_path = null;
		});
		
		move_action.connect ((self, x, y)	 => {
			high_light (x, y);
			
			if (resize) {
				resize_process (x, y);
			}
		});
		
		draw_action.connect ((self, cairo_context, glyph) => {
				draw_handle (cairo_context, glyph);
			});
			
		move_icon = (!) Icons.get_icon ("move_handle.png");
		move_icon_active = (!) Icons.get_icon ("move_handle_active.png");

		rotate_icon = (!) Icons.get_icon ("rotate_icon.png");
		rotate_icon_active = (!) Icons.get_icon ("rotate_icon_active.png");		
		
	}

	private void resize_process (double x, double y) {
		double a, b, c, nc, tx, ty;
		
		Path p;
		
		// TODO: this function resizes only one path not a group of paths
		Path po = selected_path;
		
		if (po.empty ()) return;
				
		if (original_path == null) original_path = po.copy ();
		
		p = ((!)original_path).copy ();
		
		a = p.xmax - p.xmin;
		b = p.ymax - p.ymin;
		
		tx = x - resize_begin_x;
		ty = y - resize_begin_y;
		
		c  =  Math.sqrt (Math.pow (a, 2) + Math.pow (b, 2));
		nc =  Math.sqrt (Math.pow (a + tx, 2) + Math.pow (b + ty, 2));

		p.resize (nc / c);
		po.replace_path (p);

		MainWindow.get_current_glyph ().queue_redraw_path (po);
		MainWindow.get_current_glyph ().queue_redraw_path (p);
	}

	private void high_light (double x, double y) {
		int i = get_handle_at (x, y);

		if (active_handle != i) {
			redraw_handle ();
			active_handle = i;
		}
	}

	private int get_handle_at (double x, double y) {
		Glyph g = MainWindow.get_current_glyph ();
		int hx, hy;
		double ivz = 1/g.view_zoom;
				
		int i = 0;
		foreach (var p in g.path_list) {
			hx = (int) (p.xmax * ivz + g.view_offset_x + (g.allocation.width / 2) * ivz);
			hy = (int) (p.ymax * ivz + g.view_offset_y + (g.allocation.height / 2) * ivz);
		
			if (p.points.length () > 0 && hx <= x <= hx + move_icon.get_width () && hy <= y <= hy + move_icon.get_height ()) {
				selected_path = p;
				return i;
			}
			
			i++;
		}
		
		selected_path = new Path ();
		return -1;
	}

	private void draw_handle (Context cr, Glyph g) {
		double x, y;
		int i = 0;	
		double ivz = 1/g.view_zoom;

		if (resize) return;
						
		foreach (var p in g.path_list) {
			x = p.xmax * ivz + g.view_offset_x + (g.allocation.width / 2) * ivz;
			y = p.ymax * ivz + g.view_offset_y + (g.allocation.height / 2) * ivz;
			
			if (p.points.length () > 0) {
				ImageSurface s = (i == active_handle) ? move_icon_active : move_icon;
				cr.set_source_surface (s, x, y);
				cr.paint ();

				ImageSurface r = (i == active_handle) ? rotate_icon_active : rotate_icon;
				cr.set_source_surface (r, x, y - 20);
				cr.paint ();
			}
			
			i++;
		}
	}

	private void redraw_handle () {
		Glyph g = MainWindow.get_current_glyph ();
		int x, y;
		double ivz = 1/g.view_zoom;
		
		foreach (var p in g.path_list) {
			x = (int) (p.xmax * ivz + g.view_offset_x + (g.allocation.width / 2) * ivz);
			y = (int) (p.ymax * ivz + g.view_offset_y + (g.allocation.height / 2) * ivz);

			g.queue_draw_area (x, y, (int) move_icon.get_width (), (int) move_icon.get_height ());
			g.queue_draw_area (0, 0, g.allocation.width, g.allocation.height);
		}
	}

	public override bool test () {
		// draw and resize glyphs 
		
		draw_test_glyph (0, 100); // 1:1

		draw_test_glyph (0, 89); 
		resize_test_glyph (0.99); // 99%
				
		for (int i = 2; i < 10; i++) {
			draw_test_glyph (10 * (i - 1), 100);
			resize_test_glyph (1.0 / i);
		}

		int m = 100;
		for (int i = 2; i < 6; i++) {
			m += ((i - 1) * 30) + 5;
			draw_test_glyph (0, m);
			resize_test_glyph (i);
		}

		this.yield ();
		
		return true;
	}

	private void resize_test_glyph (double ratio_percent) {
		test_select_action ();
		
		this.yield ();
		
		Glyph g = MainWindow.get_current_glyph ();
		Path? pn = g.get_last_path ();
		return_if_fail (pn != null);

		Path p = (!) pn;		
		p.resize (ratio_percent);

	}
	
	private void draw_test_glyph (int x_offset, int y_offset) {
		// open a new glyph
		Tool pen_tool = MainWindow.get_toolbox ().get_tool ("pen_tool");

		this.yield ();
		MainWindow.get_tab_bar ().select_overview ();

		this.yield ();
		MainWindow.get_overview ().open_current_glyph ();
		
		pen_tool.test_select_action ();
		
		// paint
		pen_tool.test_click_action (1, 10 + x_offset, 10 + y_offset); 
		pen_tool.test_click_action (1, 20 + x_offset, 10 + y_offset);
		pen_tool.test_click_action (1, 20 + x_offset, 20 + y_offset);
		pen_tool.test_click_action (1, 10 + x_offset, 20 + y_offset);
		
		// close
		pen_tool.test_click_action (3, 0, 0);
	}
	
}

}
