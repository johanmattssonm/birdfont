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
	
class GlyphBackgroundImage {	
	public double img_offset_x = 0;
	public double img_offset_y = 0;
	public double img_scale_x = 1;
	public double img_scale_y = 1;
	public double img_rotation = 0;
	
	public int active_handle = -1;
	public int selected_handle = -1;
	
	public bool scaled = false;
	
	private ImageSurface? background_image = null;
	private ImageSurface? original_image = null;
	
	private string path;

	private double contrast = 1.0;
	private bool desaturate = false;
	private double threshold = 1.0;
	
	private bool update_sheduled = false;	
	private bool background_image_is_processing = false;

	public signal void updated ();
	
	public GlyphBackgroundImage (string fn = "") {
		path = fn;
	}
	
	public ImageSurface get_img () {
		if (path.index_of (".png") == -1) {
			create_png ();
		}
		
		if (background_image == null) {
			background_image = new ImageSurface.from_png (path);
			original_image = new ImageSurface.from_png (path);
		}
		
		return (!) background_image;
	}
	
	private void create_png () {
		ImageSurface img;
		Context ct;
		string fn = @"$path.png";
		
		Font font = Supplement.get_current_font ();
		File folder = font.get_backgrounds_folder ();
		File original = File.new_for_path (fn);
		File png_image = folder.get_child (@"full_$((!)original.get_basename ())");

		Pixbuf pixbuf;
		
		if (png_image.query_exists ()) {
			path = (!) png_image.get_path ();
			return;
		}
		
		pixbuf = new Pixbuf.from_file (path);
		pixbuf.save ((!) png_image.get_path (), "png");
		path = (!) png_image.get_path ();
	}
	
	public File get_thumbnail_file () {
		Font font = Supplement.get_current_font ();
		File folder = font.get_backgrounds_folder ();
		File full = File.new_for_path (path);
		File thumbnail = folder.get_child (@"thumbnail_$((!)full.get_basename ())");
		
		if (!thumbnail.query_exists ()) {
			create_thumbnail (get_img (), thumbnail);
		}
		
		return thumbnail;
	}

	private void create_thumbnail (ImageSurface source, File thumbnail) {
		Context c;
		Surface s;
		double zoom;
		ImageSurface img = source;
		
		zoom = Math.fmin (80.0 / img.get_width(), 80.0 / img.get_height());

		s = new Surface.similar (img, img.get_content (), 80, 80);
		c = new Context (s);

		c.set_source_rgba (1, 1, 1, 1);
		c.rectangle (0, 0, 80, 80);
		c.fill ();
							
		c.scale (zoom, zoom);
		c.set_source_surface (img, 0, 0);
		c.paint ();
		
		c.get_target ().write_to_png ((!) thumbnail.get_path ());
	}
	
	public double get_current_width () {
		return get_img ().get_width () * img_scale_x;
	}

	public double get_current_height () {
		return get_img ().get_height () * img_scale_y;
	}
	
	public void set_img_rotation (double angle) {
		img_rotation = angle;
	}
	
	public double get_img_rotation () {
		return img_rotation;
	}
		
	public void set_img_rotation_from_coordinate (double x, double y) {
		double bcx, bcy;
		double a, b, c, length;

		img_center (out bcx, out bcy);

		a = bcx - x;
		b = bcy - y;
		c = a * a + b * b;
		
		if (c == 0) {
			return;
		}
		
		length = sqrt (fabs (c));	
		
		if (c < 0) {
			length = -length;
		}
	
		img_rotation =  (y < bcy) ? acos (a / length) + PI : -acos (a / length) + PI;
	}
	
	public void set_img_scale (double xs, double ys) {
		img_scale_x = xs;
		img_scale_y = ys;
	}

	public void set_img_offset (double x, double y) {
		img_offset_x = x;
		img_offset_y = y;
	}

	public string get_path () {
		return path;
	}

	public void scale_image_proportional_to_boundries (Glyph g) {
		double w, h;
		
		w = g.get_width ();
		h = g.get_height ();
						
		g.reset_zoom ();

		img_scale_y = h / get_img ().get_height ();
		
		img_offset_x = g.get_line ("left").pos;		
		img_offset_y = g.vertical_help_lines.first ().data.pos;

	}

	public void reset_scale (Glyph g) {
		double w, h;

		w = g.get_width ();
		h = g.get_height ();

		img_scale_x = 1;			
		img_scale_y = 1;
		
		img_offset_x = g.get_line ("left").pos;
		img_offset_y = g.get_line ("top").pos;		
	}

	public void draw (Context cr, Allocation allocation, double view_offset_x, double view_offset_y, double view_zoom) {
		double x, y;
		int h, w;
		
		Surface s;
		Context c;

		if (unlikely (get_img ().status () != Cairo.Status.SUCCESS)) {
			stderr.printf (@"Background image is invalid. (\"$path\")\n");
			MainWindow.get_current_glyph ().set_background_visible (false);
			return;
		}
	
		x = -view_offset_x + allocation.width / 2.0; // center for glyph
		y = -view_offset_y + allocation.height / 2.0;
		
		x += img_offset_x;
		y += img_offset_y;
				
		cr.save ();
		
		h = (int) get_img ().get_height ();
		w = (int) get_img ().get_width ();
		
		if (w < allocation.width) {
			w = allocation.width;
		}
		
		if (h < allocation.height) {
			h = allocation.height;
		}
			
		s = new Surface.similar (get_img (), get_img ().get_content (), w, h);
		c = new Context (s);

		c.save ();
		c.set_source_rgba (1, 1, 1, 1);
		c.rectangle (0, 0, w, h);
		c.fill ();
		c.restore ();
		
		c.rotate (img_rotation);
		c.scale (view_zoom * img_scale_x, view_zoom * img_scale_y);
		c.set_source_surface (get_img (), 0, 0);
		c.paint ();
		
		cr.save ();
		cr.set_source_rgba (1, 1, 1, 1);
		cr.rectangle (0, 0, w, h);
		cr.fill ();
		cr.restore ();
		
		cr.set_source_surface (s, x * view_zoom, y * view_zoom);
		cr.paint ();
		
		cr.restore ();
	}
	
	public void handler_release (double nx, double ny) {		
		selected_handle = 0;
		handler_move (nx, ny);
	}
			
	public void handler_press (double nx, double ny) {		
		if (is_over_rotate (nx, ny)) {
			selected_handle = 2;
		} else if (is_over_resize (nx, ny)) {
			selected_handle = 1;
		} else {
			selected_handle = 0;
		}	
	}

	void img_center (out double x, out double y) {
		double a, b;
		Glyph g = MainWindow.get_current_glyph ();
		
		x = img_offset_x - g.view_offset_x + g.allocation.width  / 2.0;
		y = img_offset_y - g.view_offset_y + g.allocation.height / 2.0;
		
		y *= g.view_zoom;
		x *= g.view_zoom;
		
		a = get_img ().get_width () / 2.0 * img_scale_x;
		b = get_img ().get_height () / 2.0 * img_scale_y;

		a *= g.view_zoom;
		b *= g.view_zoom;
		
		x += a;
		y += b;
	}

	bool is_over_rotate (double nx, double ny) {
		double x, y, d;

		img_center (out x, out y);

		x += cos (img_rotation) * 75;
		y += sin (img_rotation) * 75;

		d = sqrt (pow (x - nx, 2) + pow (y - ny, 2));
		
		return d < 10;
	}

	bool is_over_resize (double nx, double ny) {
		Glyph g = MainWindow.get_current_glyph ();
		double x, y, cx, cy, size, w, h;
		bool inx, iny;

		size = 12 * g.view_zoom;
		
		x = img_offset_x - g.view_offset_x;
		y = img_offset_y - g.view_offset_y + get_img ().get_height () * img_scale_y;

		cx = g.allocation.width / 2.0;
		cy = g.allocation.height / 2.0;
		
		w = 0;
		h = get_img ().get_height () * img_scale_y;
		
		x = img_offset_x + w - g.view_offset_x + g.allocation.width  / 2.0;
		y = img_offset_y + h - g.view_offset_y + g.allocation.height / 2.0;
		
		y *= g.view_zoom;
		x *= g.view_zoom;
				
		inx = x - size <= nx <= x + size;
		iny = y - size <= ny <= y + size;
		
		return inx && iny;
	}

	public void handler_move (double nx, double ny) {
		int prev_handle = active_handle;

		if (is_over_rotate (nx, ny)) {
			active_handle = 2;		
		} else if (is_over_resize (nx, ny)) {
			active_handle = 1;
		} else {
			active_handle = 0;
		}
		
		if (prev_handle != active_handle) {
			MainWindow.get_glyph_canvas ().redraw ();
		}
	}
	
	public void draw_handle (Context cr, Glyph g) {
		draw_resize_handle (cr, g);
		draw_rotate_handle (cr, g);
	}
	
	public void draw_rotate_handle (Context cr, Glyph g) {
		double x, y, a, b, hx, hy, x1, y1, x2, y2;
		
		double ivz = 1.0 / (g.view_zoom);
		
		cr.save ();

		if (selected_handle == 2) cr.set_source_rgba (1, 0, 0.3, 1);
		else if (active_handle == 2) cr.set_source_rgba (0, 0, 0.3, 1);
		else cr.set_source_rgba (0.7, 0.7, 0.8, 1);
		
		cr.set_line_width (ivz);

		a = get_img ().get_width () / 2.0 * img_scale_x;
		b = get_img ().get_height () / 2.0 * img_scale_y;

		cr.scale (g.view_zoom, g.view_zoom);
		
		x = img_offset_x + a - g.view_offset_x + g.allocation.width  / 2.0;
		y = img_offset_y + b - g.view_offset_y + g.allocation.height / 2.0;
		
		hx = cos (img_rotation) * 75;
		hy = sin (img_rotation) * 75;
		
		x1 = x + 2.5 * ivz;
		y1 = y + 2.5 * ivz;
		
		x2 = x + 2.5 * ivz + hx * ivz;
		y2 = y + 2.5 * ivz + hy * ivz;
		
		cr.move_to (x1, y1);
		cr.line_to (x2, y2);
		cr.stroke ();
		
		cr.rectangle (x, y, 5 * ivz, 5 * ivz);
		cr.rectangle (x2 - 5 * ivz, y2 - 5 * ivz, 10 * ivz, 10 * ivz); // Fixa: do arc instead

		cr.fill ();

		cr.restore ();
	}
	
	public void draw_resize_handle (Context cr, Glyph g) {
		double x, y;
		
		double w = 0;
		double h = get_img ().get_height () * img_scale_y;

		cr.save ();
		
		cr.scale (g.view_zoom, g.view_zoom);
		
		x = img_offset_x + w - g.view_offset_x + g.allocation.width  / 2.0;
		y = img_offset_y + h - g.view_offset_y + g.allocation.height / 2.0;
		
		draw_handle_triangle (x - 1, y - 1, cr, g, 6);
		
		cr.restore ();
	}

	void draw_handle_triangle (double x, double y, Context cr, Glyph g, int direction, double s = 1) 
		requires (0 < direction < 8)
	{
		double ivz = 1.0 / (g.view_zoom);
		double size;
		
		cr.save ();
		cr.set_line_width (ivz);
		
		if (selected_handle == 1) cr.set_source_rgba (1, 0, 0.3, 1);
		else if (active_handle == 1) cr.set_source_rgba (0, 0, 0.3, 1);
		else cr.set_source_rgba (0.7, 0.7, 0.8, 1);	

		size = (8 * ivz) * s;
		
		cr.scale (1, 1);
		cr.new_path ();
		
		// up + left
		if (direction == 1) {
			cr.move_to (x - size, y - size);
			cr.line_to (x + size, y - size);
			cr.line_to (x - size, y + size);	
		}
		
		if (direction == 6) {
			cr.move_to (x + size, y + size);	
			cr.line_to (x - size, y + size);
			cr.line_to (x - size, y - size);	
		}
		
		cr.close_path();
		cr.fill ();

		cr.restore ();
		
	}

	private static uchar ftu (double c) {
		if (c < 0) return 0;
		if (c > 255) return 255;
		return (uchar) c;
	}

	private static ImageSurface? process_background_colors (ImageSurface img, double contrast, bool desaturate, double threshold) {
		int i;
		unowned uchar[]? pix_buff_t;
		unowned uchar[] pix_buff;
		int len;
		uchar[] contrast_img;
		ImageSurface contrast_surface;
		double c, thres;
		uchar nc;

		int w = img.get_width();
		int h = img.get_height();

		if (unlikely (img.status () != Cairo.Status.SUCCESS)) {
			warning ("Err");
			return null;
		}
		
		len = 4 * w * h;
		
		pix_buff_t = img.get_data ();
		return_if_fail (pix_buff_t != null);
		pix_buff = pix_buff_t;
		
		contrast_img = new uchar[len];

		pix_buff_t = contrast_img;
		return_if_fail (pix_buff_t != null);
		
		contrast += 70;
		contrast /= 71;
		
		if (desaturate) {
			i = 0;
			
			while (i < len) {
				c = (pix_buff[i] + pix_buff[i+1] + pix_buff[i+2]) / 3.0;
				nc = ftu (Math.pow (c, contrast));

				contrast_img[i]   = nc;
				contrast_img[i+1] = nc; 
				contrast_img[i+2] = nc;
				contrast_img[i+3] = 255;
				
				i += 4;
			}
		} else {
			i = 0;
			while (i < len) {
				contrast_img[i] = ftu (Math.pow (pix_buff[i], contrast) - Math.pow (100, contrast) + 100);
				contrast_img[i+1] = ftu (Math.pow (pix_buff[i+1], contrast) - Math.pow (100, contrast) + 100);
				contrast_img[i+2] = ftu (Math.pow (pix_buff[i+2], contrast) - Math.pow (100, contrast) + 100);
				contrast_img[i+3] = 255;
				
				i += 4;
			}
		}

		if (true) {
			thres = (threshold - 0.5) * 255;
			
			i = 0;
			while (i < len) {
				c = (pix_buff[i] + pix_buff[i+1] + pix_buff[i+2]) / 3.0;
				nc = (c > thres) ? 255 : 0;

				contrast_img[i]   = nc;
				contrast_img[i+1] = nc; 
				contrast_img[i+2] = nc;
				contrast_img[i+3] = 255;
				
				i += 4;
			}
		}

		contrast_surface = new ImageSurface.for_data (contrast_img, img.get_format(), w, h, img.get_stride());

		if (unlikely (contrast_surface.status () != Cairo.Status.SUCCESS)) {
			warning ("Err");
			return null;
		}
		
		contrast_surface.mark_dirty	();
			
		return contrast_surface;	
	}

	async ImageSurface? do_process_background_colors () {
		SourceFunc callback = do_process_background_colors.callback;
		ImageSurface? output = null;
		double contrast = get_contrast ();
		bool desaturate = get_desaturate_background ();
		double threshold = this.threshold;

		if (original_image == null) {
			return null;
		}
		
		// Fixa: Add multi threading
		//ThreadFunc<void*> run = () => {
			output = process_background_colors ((!)original_image, contrast, desaturate, threshold);
			Idle.add ((owned) callback);
			//return null;
		//};
		
		try {
			//Thread.create<void*> (run, false);
			yield;
		} catch (ThreadError e) {
			stderr.printf ("Thread error: %s\n", e.message);
		}

		return output;
	}

	public void update_background (double contrast, bool desaturate) {
		background_image_is_processing = true;
		
		do_process_background_colors.begin ((obj, res) => {
			ImageSurface? img;

			img = do_process_background_colors.end (res);
			
			if (img != null) {
				background_image = (!) img;
				updated ();
			} else {
				stderr.printf ("Error: No background image");	
			}
			
			// update image if new value was set while background task was running 
			if (get_contrast () != contrast || get_desaturate_background () != desaturate) {

				do_process_background_colors.begin ((obj, res) => {
					img = do_process_background_colors.end (res);
					if (likely (img != null)) {
						background_image = (!) img;
						updated ();
					} else {
						stderr.printf ("Error: No background image");	
					}
				});
			}

			background_image_is_processing = false;
			updated ();
			
		});
	}

	public double get_contrast () {
		double bc;
		lock (contrast) {
			bc = contrast;
		}
		return bc;
	}
		
	public bool get_desaturate_background () {
		bool bw;
		lock (desaturate) {
			bw = desaturate;
		}
		return bw;
	}
	
	public void set_desaturate_background (bool bw) {
		lock (desaturate) {
			desaturate = bw;
		}
	
		if (background_image_is_processing) {
			return;
		}
		
		background_image_is_processing = true;
		
		update_background (get_contrast (), bw);
	}
	
	public void set_threshold (double t) {
		threshold = t;
	}
	
	public Path auto_trace () {
		ImageSurface img;
		int len, w, h, i;
		unowned uchar[] pix_buff;
		Path p = new Path ();
		double x, y;

		if (background_image == null) {
			return p;
		}

		img = (!) background_image;

		w = img.get_width();
		h = img.get_height();

		if (unlikely (img.status () != Cairo.Status.SUCCESS)) {
			warning ("Err");
			return p;
		}
		
		len = 4 * w * h;

		pix_buff = img.get_data ();

		i = 0;
		while (i < len - 4) {
			if (is_edge (pix_buff[i], pix_buff[i + 4])) {
				y = i / w;
				x = i - y;
				
				p.add (x, y);
				
				if (p.points.length () > 10) {
					return p;
				}
			}
			
			i += 4;
		}
		
		return p;
	}
	
	private bool is_edge (uchar a, uchar b) {
		return (a == 255 && b == 0);
	}
	
	public void set_contrast (double contrast) {
		lock (this.contrast) {
			this.contrast = contrast;
		}
		
		if (background_image_is_processing) {
			return;
		}
		
		background_image_is_processing = true;
		
		update_background (contrast, get_desaturate_background ());
	}
}
	
}
