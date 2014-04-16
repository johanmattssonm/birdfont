/*
    Copyright (C) 2012, 2013, 2014 Johan Mattsson

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
	
public class GlyphBackgroundImage {
		
	public double img_x = 0;
	public double img_y = 0;
	
	public double img_scale_x = 1;
	public double img_scale_y = 1;
	public double img_rotation = 0;
	private int size = -1;

	public int active_handle = -1;
	public int selected_handle = -1;
	
	private ImageSurface? background_image = null;
	private ImageSurface? original_image = null;
	
	private string path;

	private double contrast = 1.0;
	private bool desaturate = false;
	private double threshold = 1.0;
	
	private bool background_image_is_processing = false;

	public signal void updated ();

	public double img_offset_x {
		get { return img_x + Glyph.xc (); }
		set { img_x = value - Glyph.xc (); }
	}

	public double img_offset_y {
		get { return Glyph.yc () - img_y; }
		set { img_y = Glyph.yc () - value; }
	}
	
	public int size_margin {
		get {
			if (unlikely (size == -1)) {
				size = (int) (Math.sqrt (Math.pow (get_img ().get_height (), 2) 
					+ Math.pow (get_img ().get_width (), 2)) + 0.5);
			}
			
			return size;
		}
	}
		
	public GlyphBackgroundImage (string file_name) {
		path = file_name;
	}

	public GlyphBackgroundImage copy () {
		GlyphBackgroundImage bg = new GlyphBackgroundImage (path);
			
		bg.img_x = img_x;
		bg.img_y = img_y;

		bg.img_scale_x = img_scale_x;
		bg.img_scale_y = img_scale_y;
		bg.img_rotation = img_rotation;

		bg.contrast = contrast;
		bg.desaturate = desaturate;
		bg.threshold = threshold;

		return bg;
		
	}

	public double get_margin_width () {
		return ((size_margin - get_img ().get_width ()) / 2.0);
	}

	public double get_margin_height () {
		return ((size_margin - get_img ().get_height ()) / 2.0);
	}

	public void set_img_offset (double x, double y) {
		img_offset_x = x;
		img_offset_y = y;
	}

	public void set_position (double coordinate_x, double coordinate_y) {
		img_x = coordinate_x;
		img_y = coordinate_y;
	}
			
	public ImageSurface get_img () {
		if (!path.has_suffix (".png")) {
			create_png ();
		}
		
		if (background_image == null) {
			background_image = new ImageSurface.from_png (path);
			original_image = new ImageSurface.from_png (path);
		}
		
		return (!) background_image;
	}

	public bool is_valid () {
		FileInfo file_info;
		File file = File.new_for_path (path);
	
		if (!file.query_exists ()) {
			return false;
		}
		
		try {
			file_info = file.query_info ("*", FileQueryInfoFlags.NONE);
			
			if (file_info.get_size () == 0) {
				return false;
			}
		} catch (GLib.Error e) {
			warning (e.message);
			return false;
		}
				
		return true;
	}

	public string get_png_base64 () {
		try {
			File file = File.new_for_path (path);
			FileInfo file_info = file.query_info ("*", FileQueryInfoFlags.NONE);
			uint8[] buffer = new uint8[file_info.get_size ()];
			FileInputStream file_stream;
			DataInputStream png_stream;
			
			if (!file.query_exists ()) {
				warning (@"Can't to save image $path, file does not exist.");
				return "";
			}
			
			if (is_null (buffer)) {
				warning (@"Can not allocate a buffer of $(file_info.get_size ()) bytes to store $path.");
				return "";
			}
			
			file_stream = file.read ();
			
			png_stream = new DataInputStream (file_stream);
			png_stream.read (buffer);
			
			return Base64.encode (buffer);
		} catch (GLib.Error e) {
			warning (e.message);
		}
		
		return "";

	}

	public void create_background_folders (Font font) {
		File dir;
		
		dir = BirdFont.get_settings_directory ();
		if (!dir.query_exists ()) {
			DirUtils.create ((!) dir.get_path (), 0xFFFFFF);
		}
		
		dir = font.get_backgrounds_folder ();
		if (!dir.query_exists ()) {
			DirUtils.create ((!) dir.get_path (), 0xFFFFFF);
		}

		dir = font.get_backgrounds_folder ().get_child ("parts");
		if (!dir.query_exists ()) {
			DirUtils.create ((!) dir.get_path (), 0xFFFFFF);
		}
	}

	public void copy_if_new (File destination) {
		if (!destination.query_exists ()) {
			copy_file (destination);
		}
	}

	public void copy_file (File destination) {
		File source;
		FileInfo info;
		
		try {
			if (destination.query_exists ()) {
				info = destination.query_info ("standard::*", FileQueryInfoFlags.NONE);
				if (info.get_file_type () == FileType.DIRECTORY) {
					warning (@"$((!) destination.get_path ()) is a directory.");
					return;
				}
			}
			
			if (!((!)destination.get_parent ()).query_exists ()) {
				warning (@"Directory for file $((!) destination.get_path ()) is not created.");
				return;
			}
			
			if (destination.query_exists ()) {
				warning (@"Image $((!) destination.get_path ()) is already created.");
				return;
			}
			
			source = File.new_for_path (path);
			source.copy (destination, FileCopyFlags.NONE);
		} catch (GLib.Error e) {
			warning (e.message);
		}
	}

	public string get_sha1 () {
		try {
			File file = File.new_for_path (path);
			FileInfo file_info;
			uint8[] buffer;
			FileInputStream file_stream;
			DataInputStream png_stream;
			
			if (!file.query_exists ()) {
				warning (@"Can't save $path file does not exist.");
				return "";
			}
			
			file_info = file.query_info ("*", FileQueryInfoFlags.NONE);
			
			if (file_info.get_size () == 0) {
				warning (@"length of image $path is zero");
				return "";
			}
			
			buffer = new uint8[file_info.get_size ()];
			file_stream = file.read ();
			png_stream = new DataInputStream (file_stream);

			png_stream.read (buffer);
			
			return Checksum.compute_for_data (ChecksumType.SHA1, buffer);
		} catch (GLib.Error e) {
			warning (e.message);
		}
		
		return "";
	}
	
	private void create_png () {
		string file_name = @"$path.png";
		Font font = BirdFont.get_current_font ();
		File folder = font.get_backgrounds_folder ();
		File original = File.new_for_path (file_name);
		File png_image = folder.get_child (@"full_$((!)original.get_basename ())");
		bool converted;
		
		if (png_image.query_exists ()) {
			path = (!) png_image.get_path ();
			return;
		}
		
		if (is_null (path)) {
			warning ("Background image path is null.");
			return;
		}
		
		converted = MainWindow.native_window.convert_to_png (path, (!) png_image.get_path ());
		
		if (!converted) {
			warning ("Failed to convert image: $(path)");
		}
		
		path = (!) png_image.get_path ();
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

	public void reset_scale (Glyph g) {
		double w, h;

		w = g.get_width ();
		h = g.get_height ();

		img_scale_x = 1;			
		img_scale_y = 1;
		
		img_offset_x = g.get_line ("left").pos;
		img_offset_y = g.get_line ("top").pos;		
	}

	public void draw (Context cr, WidgetAllocation allocation, double view_offset_x, double view_offset_y, double view_zoom) {
		double x, y;
		double iw, ih;
		int h, w;
		double scale_x, scale_y;
		double oy, ox;
				
		Surface s;
		Context c;

		Surface sg;
		Context cg;

		Surface st;
		Context ct;

		double wc, hc;

		if (unlikely (get_img ().status () != Cairo.Status.SUCCESS)) {
			warning (@"Background image is invalid. (\"$path\")\n");
			MainWindow.get_current_glyph ().set_background_visible (false);
			return;
		}
		
		// add margin
		sg = new Surface.similar (get_img (), get_img ().get_content (), size_margin, size_margin);
		cg = new Context (sg);
		
		wc = get_margin_width ();
		hc = get_margin_height ();
		
		cg.set_source_rgba (1, 1, 1, 1);
		cg.rectangle (0, 0, size_margin, size_margin);
		cg.fill ();
		
		cg.set_source_surface (get_img (), wc, hc);
		cg.paint ();

		x = Glyph.reverse_path_coordinate_x (img_offset_x);
		y = Glyph.reverse_path_coordinate_y (img_offset_y);
		
		ih = (int) get_img ().get_height ();
		iw = (int) get_img ().get_width ();
		
		w = (int) iw;
		h = (int) ih;

		oy = size_margin;
		ox = size_margin;

		// rotate image
		s = new Surface.similar (sg, sg.get_content (), (int) (ox), (int) (oy));
		c = new Context (s);
	
		c.save ();

		c.set_source_rgba (1, 1, 1, 1);
		c.rectangle (0, 0, size_margin, size_margin);
		c.fill ();
			
   		c.translate (size_margin * 0.5, size_margin * 0.5);
		c.rotate (img_rotation);
		c.translate (-size_margin * 0.5, -size_margin * 0.5);

		c.set_source_surface (cg.get_target (), 0, 0);
		c.paint ();	
		c.restore ();

		// mask
		st = new Surface.similar (s, s.get_content (), allocation.width, allocation.height);
		ct = new Context (st);
		ct.save ();

		ct.set_source_rgba (1, 1, 1, 1);
		ct.rectangle (0, 0, allocation.width, allocation.height);
		ct.fill ();

		// scale both canvas and image at the same time
		scale_x = view_zoom * img_scale_x;
		scale_y = view_zoom * img_scale_y;
		
		ct.scale (scale_x, scale_y);
		ct.translate (-view_offset_x / img_scale_x, -view_offset_y / img_scale_y);
		
		ct.set_source_surface (s, img_offset_x / img_scale_x, img_offset_y / img_scale_y);

		ct.paint ();
		ct.restore ();
		
		// add it
		cr.save ();
		cr.set_source_surface (st, 0, 0);
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
		Glyph g = MainWindow.get_current_glyph ();
		
		x = img_offset_x - g.view_offset_x + (size_margin / 2) * img_scale_x;
		y = img_offset_y - g.view_offset_y + (size_margin / 2) * img_scale_y;

		y *= g.view_zoom;
		x *= g.view_zoom;
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
		double x, y, size;
		bool inx, iny;

		size = 12 * g.view_zoom;

		x = img_offset_x - g.view_offset_x;
		y = img_offset_y - g.view_offset_y + (size_margin) * img_scale_y;
				
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
			GlyphCanvas.redraw ();
		}
	}
	
	public void draw_handle (Context cr, Glyph g) {
		draw_resize_handle (cr, g);
		draw_rotate_handle (cr, g);
	}

	public void draw_resize_handle (Context cr, Glyph g) {
		double x, y;
		cr.save ();
		
		cr.set_source_rgba (1, 0, 0.3, 1);

		x = img_offset_x - g.view_offset_x;
		y = img_offset_y - g.view_offset_y + (size_margin) * img_scale_y;
				
		y *= g.view_zoom;
		x *= g.view_zoom;
				
		draw_handle_triangle (x, y, cr, g, 6);
		
		cr.restore ();
	}
		
	public void draw_rotate_handle (Context cr, Glyph g) {
		double x, y, hx, hy, x2, y2;
		
		double ivz = 1.0 / (g.view_zoom);
		
		cr.save ();
		
		cr.scale (g.view_zoom, g.view_zoom);
		
		if (selected_handle == 2) cr.set_source_rgba (1, 0, 0.3, 1);
		else if (active_handle == 2) cr.set_source_rgba (0, 0, 0.3, 1);
		else cr.set_source_rgba (0.7, 0.7, 0.8, 1);

		x = img_offset_x - g.view_offset_x + (size_margin / 2) * img_scale_x;
		y = img_offset_y - g.view_offset_y + (size_margin / 2) * img_scale_y;
				
		cr.rectangle (x, y, 5 * ivz, 5 * ivz);
		cr.fill ();

		hx = cos (img_rotation) * 75 * ivz;
		hy = sin (img_rotation) * 75 * ivz;
		
		x2 = x + hx;
		y2 = y + hy;

		cr.rectangle (x2, y2, 5 * ivz, 5 * ivz);
		cr.fill ();

		cr.set_line_width (ivz);
		cr.move_to (x + 2.5* ivz, y + 2.5* ivz);
		cr.line_to (x2 + 2.5* ivz, y2 + 2.5* ivz);
		cr.stroke ();
										
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

		size = (8) * s;
		
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
		return_val_if_fail (pix_buff_t != null, null);
		pix_buff = pix_buff_t;
		
		contrast_img = new uchar[len];

		pix_buff_t = contrast_img;
		return_val_if_fail (pix_buff_t != null, null);
		
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
		
		// TODO: Add multi threading
		output = process_background_colors ((!)original_image, contrast, desaturate, threshold);
		Idle.add ((owned) callback);

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
			warning ("Error");
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
				
				if (p.points.size > 10) {
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
