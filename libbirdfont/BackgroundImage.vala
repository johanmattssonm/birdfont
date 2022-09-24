/*
	Copyright (C) 2012 2013 2014 2015 Johan Mattsson

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
	
public class BackgroundImage : GLib.Object {
	
	public string name = "";
	public Gee.ArrayList<BackgroundSelection> selections;

	/** Image position in canvas coordinates. */
	public double img_x = 0;
	public double img_y = 0;

	public double img_scale_x {
		get {
			return img_scale_x_size;
		}
		
		set {
			if (value > 0.0001) {
				img_scale_x_size = value;
			}
		}
	}
	
	public double img_scale_y {
		get {
			return img_scale_y_size;
		}
		
		set {
			if (value > 0.0001) {
				img_scale_y_size = value;
			}
		}
	}
	
	private double img_scale_x_size = 1;	
	private double img_scale_y_size = 1;
	
	public double img_rotation = 0;
	private double preview_img_rotation = 0;
	
	private int size = -1;

	public int active_handle = -1;
	public int selected_handle = -1;
	
	private ImageSurface? background_image = null;
	private ImageSurface? original_image = null;
	
	private string path;

	public bool high_contrast = false;
	private Gee.ArrayList<TracedPoint> points = new Gee.ArrayList<TracedPoint> ();
	private Gee.ArrayList<TracedPoint> start_points = new Gee.ArrayList<TracedPoint> ();
	
	public signal void updated ();

	private ScaledBackgrounds? scaled = null;
	private ImageSurface? contrast_image = null;

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

	public int margin_left {
		get {
			return size_margin - get_img ().get_width ();
		}
	}

	public int margin_top {
		get {
			return size_margin - get_img ().get_height ();
		}
	}
	
	public double img_middle_x {
		get { return img_x + (size_margin * img_scale_x) / 2; }
		set { img_x = value - (size_margin * img_scale_x) / 2; }
	}
	
	public double img_middle_y {
		get { return img_y - (size_margin * img_scale_y) / 2; }
		set { img_y = value + (size_margin * img_scale_y) / 2; }
	}
				
	public BackgroundImage (string file_name) {
		path = file_name;
		selections = new Gee.ArrayList<BackgroundSelection> ();
	}

	public BackgroundImage copy () {
		BackgroundImage bg = new BackgroundImage (path);
			
		bg.img_x = img_x;
		bg.img_y = img_y;

		bg.img_scale_x = img_scale_x;
		bg.img_scale_y = img_scale_y;
		bg.img_rotation = img_rotation;

		bg.high_contrast = high_contrast;
		
		foreach (BackgroundSelection b in selections) {
			bg.selections.add (b);
		}

		return bg;		
	}

	public ScaledBackgrounds get_scaled_backgrounds () {
		if (scaled == null) {
			ImageSurface rotated = rotate ((ImageSurface) get_padded_image ());
			scaled = new ScaledBackgrounds (rotated);
		}
		
		return (!) scaled;
 	}

	public void add_selection (BackgroundSelection bs) {
		selections.add (bs);
	}

	public void set_high_contrast (bool t) {
		high_contrast = t;
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

	public ImageSurface get_original () {
		if (!path.has_suffix (".png")) {
			create_png ();
		}
		
		if (background_image == null) {
			background_image = new ImageSurface.from_png (path);
			original_image = new ImageSurface.from_png (path);			
		}
		
		return (!) original_image;
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
			DirUtils.create ((!) dir.get_path (), 0755);
		}
		
		dir = font.get_backgrounds_folder ();
		if (!dir.query_exists ()) {
			DirUtils.create ((!) dir.get_path (), 0755);
		}

		dir = get_child (font.get_backgrounds_folder (), "parts");
		if (!dir.query_exists ()) {
			DirUtils.create ((!) dir.get_path (), 0755);
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
		File png_image = get_child (folder, @"full_$((!)original.get_basename ())");
		bool converted;
		
		if (png_image.query_exists ()) {
			path = (!) png_image.get_path ();
			return;
		}
		
		if (is_null (path)) {
			warning ("Background image path is null.");
			return;
		}
		
		try  {
			folder.make_directory ();
		} catch (GLib.Error e) {
			warning (e.message);
		}
		
		converted = MainWindow.native_window.convert_to_png (path.dup (), ((!) png_image.get_path ()).dup ());
		
		if (!converted) {
			warning ("Failed to convert image: $(path)");
			return;
		}
		
		path = (!) png_image.get_path ();
	}

	private ScaledBackgrounds get_image () {
		return get_scaled_backgrounds ();
	}
	
	public void start_rotation_preview () {
		preview_img_rotation = img_rotation;
	}

	public void preview_img_rotation_from_coordinate (double x, double y, double view_zoom) {
		double rotation;
		ScaledBackgrounds backgrounds;
		ScaledBackground backgound;
		
		if (get_img_rotation_from_coordinate (x, y, out rotation)) {	
			backgrounds = get_scaled_backgrounds ();
			backgound = backgrounds.get_image (view_zoom * img_scale_x); // FIXME: y
			
			img_rotation = rotation;
			
			if (!high_contrast) {
				backgound.rotate (rotation - preview_img_rotation);
			} else {
				contrast_image = null;
			}
		}
	}

	public void set_img_rotation_from_coordinate (double x, double y) {
		double rotation;
		if (get_img_rotation_from_coordinate (x, y, out rotation)) {
			img_rotation = rotation;
			Task task = new Task (cache_scaled_image); // cache all sizes
			MainWindow.run_blocking_task (task);
		}
	}
	
	void cache_scaled_image () {
		scaled = null;
		contrast_image = null;
		get_image ();
	}
	
	public bool get_img_rotation_from_coordinate (double x, double y, out double rotation) {
		double bcx, bcy;
		double a, b, c, length;

		rotation = 0;
		
		bcx = img_middle_x;
		bcy = img_middle_y;

		a = bcx - x;
		b = bcy - y;
		c = a * a + b * b;
		
		if (c == 0) {
			return false;
		}
		
		length = sqrt (fabs (c));	
		
		if (c < 0) {
			length = -length;
		}
	
		rotation = (y > bcy) ? acos (a / length) + PI : -acos (a / length) + PI;
		return true;
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

	public void draw (Context cr, WidgetAllocation allocation,
			double view_offset_x, double view_offset_y, double view_zoom) {
				
		double scale_x, scale_y;
		double image_scale_x, image_scale_y;

		ScaledBackgrounds backgrounds = get_scaled_backgrounds ();
		
		if (unlikely (get_img ().status () != Cairo.Status.SUCCESS)) {
			warning (@"Background image is invalid. (\"$path\")\n");
			MainWindow.get_current_glyph ().set_background_visible (false);
			return;
		}

		image_scale_x = img_scale_x;
		image_scale_y = img_scale_y;

		ImageSurface scaled_image;
		Context scaled_context;

		if (!high_contrast) {
			ScaledBackground scaled;
			ScaledBackgroundPart part;

			scaled = backgrounds.get_image (view_zoom * img_scale_x); // FIXME: y
			
			double part_offset_x = img_offset_x - view_offset_x;
			part_offset_x /= img_scale_x / scaled.get_scale ();
			part_offset_x = -part_offset_x;

			double part_offset_y = img_offset_y - view_offset_y;
			part_offset_y /= img_scale_y / scaled.get_scale ();
			part_offset_y = -part_offset_y;

			double part_allocation_width;
			double part_allocation_height;

			part_allocation_height = allocation.height;
			part_allocation_height /= view_zoom;
			part_allocation_height /= image_scale_x;

			part_allocation_width = allocation.width;
			part_allocation_width /= view_zoom;
			part_allocation_width /= image_scale_y;
			
			part = scaled.get_part (part_offset_x, part_offset_y, 
				(int) (part_allocation_width), (int) (part_allocation_height)); 

			scale_x = view_zoom * image_scale_x;
			scale_y = view_zoom * image_scale_y;
			
			scale_x /= part.get_scale ();
			scale_y /= part.get_scale ();
						
			scaled_image = new ImageSurface (Format.ARGB32, allocation.width, allocation.height);
			
			scaled_context = new Context (scaled_image);

			scaled_context.scale (scale_x, scale_y);
			
			double scaled_x = part.offset_x;
			double scaled_y = part.offset_y;
			
			scaled_x += view_zoom * (img_offset_x / scale_x - view_offset_x / scale_x);
			scaled_y += view_zoom * (img_offset_y / scale_y - view_offset_y / scale_y);
			
			scaled_context.set_source_surface (part.get_image (), scaled_x, scaled_y);
			scaled_context.paint ();
		} else {
			ImageSurface contrast = get_contrast_image ();
			
			image_scale_x = img_scale_x * ((double) size_margin / contrast.get_width ());
			image_scale_y = img_scale_y * ((double) size_margin / contrast.get_height ());			
			
			scaled_image = new ImageSurface (Format.ARGB32, allocation.width, allocation.height);
			Context contrast_context = new Context (scaled_image);
			contrast_context.save ();

			contrast_context.set_source_rgba (1, 1, 1, 1);
			contrast_context.rectangle (0, 0, allocation.width, allocation.height);
			contrast_context.fill ();

			// scale both canvas and image at the same time
			scale_x = view_zoom * image_scale_x;
			scale_y = view_zoom * image_scale_y;
			
			contrast_context.scale (scale_x, scale_y);
			contrast_context.translate (-view_offset_x / image_scale_x, -view_offset_y / image_scale_y);
			
			contrast_context.set_source_surface (contrast, img_offset_x / image_scale_x, img_offset_y / image_scale_y);

			contrast_context.paint ();
			contrast_context.restore ();
		}
		
		// add it
		cr.save ();		
		cr.set_source_surface (scaled_image, 0, 0);
		cr.paint ();
		cr.restore ();
	}
	
	public Surface get_padded_image () {
		double x, y;
		double iw, ih;
		int h, w;
		double oy, ox;
		
		Surface o;
		Surface sg;
		Context cg;

		double wc, hc;
		
		o = get_original ();
		
		// add margin
		sg = new Surface.similar (o, o.get_content (), size_margin, size_margin);
		cg = new Context (sg);
		
		wc = get_margin_width ();
		hc = get_margin_height ();
		
		Theme.color (cg, "Background 1");
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

		return sg;
	}
	
	private ImageSurface rotate (ImageSurface padded_image) {
		return rotate_image (padded_image, img_rotation);
	}
	
	public static ImageSurface rotate_image (ImageSurface padded_image, double angle) {
		ImageSurface s;
		Context c;
		
		int w = padded_image.get_width ();
		int h = padded_image.get_height ();
		
		s = new ImageSurface (Format.ARGB32, w, h);
		c = new Context (s);
	
		c.save ();

		c.translate (w * 0.5, h * 0.5);
		c.rotate (angle);
		c.translate (-w * 0.5, -h * 0.5);
		
		c.set_source_surface (padded_image, 0, 0);
		c.paint ();	
		c.restore ();
		
		return s;
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

	bool is_over_rotate (double nx, double ny) {
		double x, y, d;

		x = Glyph.reverse_path_coordinate_x (img_middle_x);
		y = Glyph.reverse_path_coordinate_y (img_middle_y);

		x += cos (img_rotation) * 75;
		y += sin (img_rotation) * 75;

		d = Path.distance (x, nx, y, ny);
		
		return d < 15;
	}

	bool is_over_resize (double nx, double ny) {
		double x, y, size;
		bool inx, iny;
	
		size = 12;

		x = img_middle_x - (img_scale_x * get_img ().get_width () / 2);
		y = img_middle_y - (img_scale_y * get_img ().get_height () / 2);
		
		x = Glyph.reverse_path_coordinate_x (x);
		y = Glyph.reverse_path_coordinate_y (y);
		
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
		
		Theme.color (cr, "Menu Background");

		x = img_middle_x - (img_scale_x * get_img ().get_width () / 2);
		y = img_middle_y - (img_scale_y * get_img ().get_height () / 2);

		x = Glyph.reverse_path_coordinate_x (x);
		y = Glyph.reverse_path_coordinate_y (y);
			
		draw_handle_triangle (x, y, cr, g, 6);
		
		cr.restore ();
	}
		
	public void draw_rotate_handle (Context cr, Glyph g) {
		double x, y, hx, hy, x2, y2;
		
		double ivz = 1.0 / (g.view_zoom);
		
		cr.save ();
		
		cr.scale (g.view_zoom, g.view_zoom);
		
		if (selected_handle == 2) {
			Theme.color (cr, "Highlighted 1");
		} else if (active_handle == 2) {
			Theme.color (cr, "Default Background");
		} else {
			Theme.color (cr, "Menu Background");
		}

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
		cr.move_to (x + 2.5 * ivz, y + 2.5 * ivz);
		cr.line_to (x2 + 2.5 * ivz, y2 + 2.5 * ivz);
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
		
		if (selected_handle == 1) Theme.color (cr, "Highlighted 1");
		else if (active_handle == 1) Theme.color (cr, "Default Background");
		else Theme.color (cr, "Menu Background");

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

	public void update_background () {
		background_image = null;
		contrast_image = null;
		
		GlyphCanvas.redraw ();
		updated ();
	}

	ImageSurface get_contrast_image () {
		if (contrast_image == null) {
			contrast_image  = get_contrast_image_surface ();
		}
		
		return (!) contrast_image;
	}

	ImageSurface get_contrast_image_surface () {
		ImageSurface s;
		Context c;

		ImageSurface sg;		
		int scaled_width;
		
		unowned uchar[] pix_buff;
		int i, len;
		double thres;
		int stride;
		
		ImageSurface img;
		ImageSurface ns;

		double trace_resolution = DrawingTools.auto_trace_resolution.get_value ();
		double threshold = DrawingTools.background_threshold.get_value ();
		
		thres = (threshold - 0.5) * 255;
		
		scaled_width = (int) (600 * trace_resolution);

		s = new ImageSurface (Format.RGB24, scaled_width, scaled_width);
		sg = (ImageSurface) get_padded_image ();	
		sg = rotate (sg);
		c = new Context (s);
	
		c.save ();
		Theme.color (c, "Background 1");
		c.rectangle (0, 0, scaled_width, scaled_width);
		c.fill ();

		c.translate (scaled_width * 0.5, scaled_width * 0.5);
		c.rotate (img_rotation);
		c.translate (-scaled_width * 0.5, -scaled_width * 0.5);

		c.scale ((double) scaled_width / sg.get_width (), (double) scaled_width / sg.get_height ());

		c.set_source_surface (sg, 0, 0);
		c.paint ();	
		c.restore ();

		img = (ImageSurface) s;
		pix_buff = img.get_data ();

		len = s.get_height () * s.get_stride ();

		uint8* outline_img = new uint8[len];

		for (i = 0; i < len - 4; i += 4) {
			uint8 o = (uint8) ((pix_buff[i] + pix_buff[i + 1] + pix_buff[i + 2]) / 3.0);
			uint8 bw = (o < thres) ? 0 : 255;
			outline_img[i] = bw;
			outline_img[i + 1] = bw;
			outline_img[i + 2] = bw;
			outline_img[i + 3] = bw;
		}

		// fill blur with black
		stride = s.get_stride ();
		for (int m = 0; m < 2; m++) {
			i = stride + 4;
			while (i < len - 4 - stride) {
				if ((outline_img[i] == 255 && outline_img[i + 4] == 0
						&& outline_img[i + stride] == 0 && outline_img[i + stride + 4] == 255)
						|| (outline_img[i] == 0 && outline_img[i + 4] == 255
						&& outline_img[i + stride] == 255 && outline_img[i + stride + 4] == 0)) {
					outline_img[i] = 0;
					outline_img[i + 4] = 0;
					outline_img[i + stride] = 0;
					outline_img[i + stride + 4] = 0;
				}
				
				if (outline_img[i] == 255 && outline_img[i + 4] == 0 && outline_img[i + 8] == 255
						|| outline_img[i] == 0 && outline_img[i + 4] == 255 && outline_img[i + 8] == 0) {
					outline_img[i] = 0;
					outline_img[i + 4] = 0;
					outline_img[i + stride] = 0;
					outline_img[i + stride + 4] = 0;
				}
				i += 4;
			}
		}

		ns = new ImageSurface.for_data ((uchar[])outline_img, s.get_format (), s.get_width (), s.get_height (), s.get_stride ());		
		background_image = null;
		original_image = null;
		
		return (ImageSurface) ns;
	}
	
	public PathList autotrace () {
		ImageSurface img;
		int len, w, h, i, s;
		Path p;
		PathList pl;
		uint8* outline_img;
		
		ImageSurface scaled_image;
		double scale;
		
		p = new Path ();
		pl = new PathList ();

		get_img ();

		if (background_image == null) {
			return pl;
		}

		img = get_contrast_image ();

		w = img.get_width();
		h = img.get_height();

		if (unlikely (img.status () != Cairo.Status.SUCCESS)) {
			warning ("Error");
			return pl;
		}
		
		if (img.get_format () != Format.RGB24) {
			warning ("Wrong format");
			return pl;
		}
		
		scaled_image = img;

		img = (ImageSurface) scaled_image;
		w = img.get_width ();
		h = img.get_height ();
		s = img.get_stride ();
		len = s * h;

		outline_img = (uint8*) img.get_data ();

		start_points = new Gee.ArrayList<TracedPoint> ();
		points = new Gee.ArrayList<TracedPoint> ();

		int direction_vertical = 4;
		int direction_horizontal = s; // FIXME: SET AT FIND START
		int last_move = 0;		
		int pp = 0;
		
		scale = 1;
		i = 0;
		while ((i = find_start_point (outline_img, len, s, i)) != -1) {
			pp = 0;
			
			while (4 + s <= i < len - 4 - s) {	
				pp++;
				if (is_traced (i)) {
					Path np = generate_path (outline_img, s, w, h, len);
					
					if (np.points.size >= 3) {
						if (Path.is_counter (pl, np)) {
							np.force_direction (Direction.COUNTER_CLOCKWISE);
						} else {
							np.force_direction (Direction.CLOCKWISE);
						}

						pl.add (np);
					}
					
					break;
				}

				if (outline_img[i] == 255 && outline_img[i + 4] == 255
						&& outline_img[i + s] == 255 && outline_img[i + s + 4] == 255) {
					warning ("Lost path");
					Path np = generate_path (outline_img, s, w, h, len);
					pl.add (np);
					break;
				}

				if (outline_img[i] == 0 && outline_img[i + 4] == 0
						&& outline_img[i + s] == 0 && outline_img[i + s + 4] == 0) {
					warning ("Lost path");
					Path np = generate_path (outline_img, s, w, h, len);
					pl.add (np);
					break;
				}
							
				if (outline_img[i] == 0 && outline_img[i + 4] == 255
						&& outline_img[i + s] == 255 && outline_img[i + s + 4] == 255) {
					points.add (new TracedPoint (i));
					
					if (last_move == direction_horizontal) {
						direction_vertical = -s;
						i += direction_vertical;	
						last_move = direction_vertical;
					} else {
						direction_horizontal = -4;
						i += direction_horizontal;
						last_move = direction_horizontal;
					}				
					
				} else if (outline_img[i] == 0 && outline_img[i + 4] == 255
						&& outline_img[i + s] == 255 && outline_img[i + s + 4] == 255) {
					points.add (new TracedPoint (i));
				
					if (last_move == direction_horizontal) {
						direction_vertical = -s;
						i += direction_vertical;	
						last_move = direction_vertical;
					} else {
						direction_horizontal = -4;
						i += direction_horizontal;	
						last_move = direction_horizontal;
					}

				} else if (outline_img[i] == 255 && outline_img[i + 4] == 0
						&& outline_img[i + s] == 255 && outline_img[i + s + 4] == 255) {
					points.add (new TracedPoint (i));
				
					if (last_move == direction_horizontal) {
						direction_vertical = -s;
						i += direction_vertical;	
						last_move = direction_vertical;
					} else {
						direction_horizontal = 4;
						i += direction_horizontal;	
						last_move = direction_horizontal;
					}

				} else if (outline_img[i] == 0 && outline_img[i + 4] == 0
						&& outline_img[i + s] == 255 && outline_img[i + s + 4] == 0) {
					points.add (new TracedPoint (i));
				
					if (last_move == direction_horizontal) {
						direction_vertical = s;
						i += direction_vertical;	
						last_move = direction_vertical;
					} else {
						direction_horizontal = -4;
						i += direction_horizontal;	
						last_move = direction_horizontal;
					}

				} else if (outline_img[i] == 255 && outline_img[i + 4] == 255
						&& outline_img[i + s] == 255 && outline_img[i + s + 4] == 0) {
					points.add (new TracedPoint (i));
				
					if (last_move == direction_horizontal) {
						direction_vertical = s;
						i += direction_vertical;	
						last_move = direction_vertical;
					} else {
						direction_horizontal = 4;
						i += direction_horizontal;	
						last_move = direction_horizontal;
					}

				} else if (outline_img[i] == 255 && outline_img[i + 4] == 255
						&& outline_img[i + s] == 0 && outline_img[i + s + 4] == 255) {
					points.add (new TracedPoint (i));
					
					if (last_move == direction_horizontal) {
						direction_vertical = s;
						i += direction_vertical;	
						last_move = direction_vertical;
					} else {
						direction_horizontal = -4;
						i += direction_horizontal;	
						last_move = direction_horizontal;
					}
					
				} else if (outline_img[i] == 255 && outline_img[i + 4] == 0
						&& outline_img[i + s] == 0 && outline_img[i + s + 4] == 0) {
					points.add (new TracedPoint (i));
					
					if (last_move == direction_horizontal) {
						direction_vertical = -s;
						i += direction_vertical;	
						last_move = direction_vertical;
					} else {
						direction_horizontal = -4;
						i += direction_horizontal;	
						last_move = direction_horizontal;
					}
				} else if (outline_img[i] == 0 && outline_img[i + 4] == 255
						&& outline_img[i + s] == 0 && outline_img[i + s + 4] == 0) {
					points.add (new TracedPoint (i));
				
					if (last_move == direction_horizontal) {
						direction_vertical = -s;
						i += direction_vertical;	
						last_move = direction_vertical;
					} else {
						direction_horizontal = 4;
						i += direction_horizontal;	
						last_move = direction_horizontal;
					}
				} else if (outline_img[i] == 0 && outline_img[i + 4] == 0
						&& outline_img[i + s] == 0 && outline_img[i + s + 4] == 255) {
					points.add (new TracedPoint (i));
				
					if (last_move == direction_horizontal) {
						direction_vertical = s;
						i += direction_vertical;	
						last_move = direction_vertical;
					} else {
						direction_horizontal = 4;
						i += direction_horizontal;	
						last_move = direction_horizontal;
					}
				} else if (outline_img[i] == 255 && outline_img[i + 4] == 255
						&& outline_img[i + s] == 0 && outline_img[i + s + 4] == 255) {
					points.add (new TracedPoint (i));
				
					if (last_move == direction_horizontal) {
						direction_vertical = s;
						i += direction_vertical;	
						last_move = direction_vertical;
					} else {
						direction_horizontal = -4;
						i += direction_horizontal;	
						last_move = direction_horizontal;
					}
				} else if (outline_img[i] == 255 && outline_img[i + 4] == 255
						&& outline_img[i + s] == 0 && outline_img[i + s + 4] == 0) {
					points.add (new TracedPoint (i));
				
					i += direction_horizontal;
					last_move = direction_horizontal;
					
				} else if (outline_img[i] == 0 && outline_img[i + 4] == 0
						&& outline_img[i + s] == 255 && outline_img[i + s + 4] == 255) {
					points.add (new TracedPoint (i));
				
					i += direction_horizontal;
					last_move = direction_horizontal;
				} else if (outline_img[i] == 255 && outline_img[i + 4] == 0
						&& outline_img[i + s] == 255 && outline_img[i + s + 4] == 0) {
					points.add (new TracedPoint (i));
				
					i += direction_vertical;
					last_move = direction_vertical;
				} else if (outline_img[i] == 0 && outline_img[i + 4] == 255
						&& outline_img[i + s] == 0 && outline_img[i + s + 4] == 255) {
					points.add (new TracedPoint (i));
				
					i += direction_vertical;
					last_move = direction_vertical;
				} else if ((outline_img[i] == 255 && outline_img[i + 4] == 0
							&& outline_img[i + s] == 0 && outline_img[i + s + 4] == 255)
						|| (outline_img[i] == 0 && outline_img[i + 4] == 255
							&& outline_img[i + s] == 255 && outline_img[i + s + 4] == 0)) {
					points.add (new TracedPoint (i));
					
					warning ("Bad edge");
					i += last_move;
						
				} else {
					points.add (new TracedPoint (i));
					warning (@"No direction\n $(outline_img[i]) $(outline_img[i + 4])\n $(outline_img[i + s]) $(outline_img[i + s + 4])");
					i += 4;
				}
			}
		}

		start_points.clear ();
		points.clear ();
		
		return pl;
	}

	int find_start_point (uint8* outline_img, int len, int s, int start_index) {
		// find start point
		int i = start_index;
		
		if (i < s + 4) {
			i = s + 4;
		}
		
		while (i < len - 4 - s) {
			if (outline_img[i] == 0 && outline_img[i + 4] == 255
					&& outline_img[i + s] == 255 && outline_img[i + s + 4] == 255
					&& !has_start_point (i)) {
				return i;
			} else if (outline_img[i] == 255 && outline_img[i + 4] == 0
					&& outline_img[i + s] == 255 && outline_img[i + s + 4] == 255
					&& !has_start_point (i)) {
				return i;
			} else if (outline_img[i] == 255 && outline_img[i + 4] == 255
					&& outline_img[i + s] == 0 && outline_img[i + s + 4] == 255
					&& !has_start_point (i)) {
				return i;
			} else if (outline_img[i] == 255 && outline_img[i + 4] == 255
					&& outline_img[i + s] == 255 && outline_img[i + s + 4] == 0
					&& !has_start_point (i)) {
				return i;
			} else if (outline_img[i] == 255 && outline_img[i + 4] == 0 
					&& outline_img[i + s] == 0 && outline_img[i + s + 4] == 0
					&& !has_start_point (i)) {
				return i;
			} else if (outline_img[i] == 0 && outline_img[i + 4] == 255
					&& outline_img[i + s] == 0 && outline_img[i + s + 4] == 0
					&& !has_start_point (i)) {
				return i;
			} else if (outline_img[i] == 0 && outline_img[i + 4] == 0
					&& outline_img[i + s] == 255 && outline_img[i + s + 4] == 0
					&& !has_start_point (i)) {
				return i;
			} else if (outline_img[i] == 0 && outline_img[i + 4] == 0
					&& outline_img[i + s] == 0 && outline_img[i + s + 4] == 255
					&& !has_start_point (i)) {
				return i;
			}
			
			i +=4;
		}
		
		return -1;
	}
	
	void find_corner (Path path, int point_index, int end, double points_per_unit, ref double x, ref double y) {
		TracedPoint tp0;
		double sx = 0;
		double sy = 0;
		double d = 0;
		double mind = double.MAX;
		int index = 0;
		int pi;
		EditPoint ep0, ep1;
		double dx, dy;
		
		pi = point_index - 1;
		if (pi < 0) {
			pi += path.points.size;
		}
		ep0 = path.points.get (pi);
		
		pi = point_index + 1;
		pi %= path.points.size;
		ep1 = path.points.get (pi);
		
		Path.find_intersection_handle (ep0.get_left_handle (), ep1.get_right_handle (), out sx, out sy);

		dx = x - ep0.x;
		dy = y - ep0.y;

		sx += 3 * dx;
		sy += 3 * dy;

		dx = x - ep1.x;
		dy = y - ep1.y;

		sx += 3 * dx;
		sy += 3 * dy;
		
		end += (int) (points_per_unit / 2.0);
		for (int i = 0; i < 2 * points_per_unit; i++) {
			index = end - i;
						
			if (index < 0) {
				index += points.size;
			} else {
				index %= points.size;
			}
			
			tp0 = points.get (index);
			
			d = Path.distance (tp0.x, sx, tp0.y, sy);
			if (d < mind) {
				mind = d;
				x = tp0.x;
				y = tp0.y;
			}
		}		
	}
	
	Path generate_path (uint8* outline_img, int stride, int w, int h, int length) {
		double x, y, np;
		int i, index;
		double sumx, sumy, points_per_unit;
		Path path = new Path ();
		Gee.ArrayList<int?> sp = new Gee.ArrayList<int?> ();
		double corner;
		Gee.ArrayList<TracedPoint> traced = new Gee.ArrayList<TracedPoint> ();
		Gee.ArrayList<EditPoint> corners = new Gee.ArrayList<EditPoint> ();
		EditPoint ep;
		EditPointHandle r, l;
		double la, a;
		PointSelection ps;
		double image_scale_x;
		double image_scale_y;
		TracedPoint average_point;
		int pi;
		ImageSurface img;
		double simplification = DrawingTools.auto_trace_simplify.get_value ();

		img = get_contrast_image ();

		image_scale_x = ((double) size_margin / img.get_width ());
		image_scale_y = ((double) size_margin / img.get_height ());
				
		foreach (TracedPoint p in points) {
			start_points.add (p);
		}

		sumx = 0;
		sumy = 0;
		np = 0;

		points_per_unit = 9;
		corner = PI / 3.5;
		
		i = 0;
		foreach (TracedPoint p in points) {
			index = p.index;
			x = -w * img_scale_x / 2 + (((index + 4) % stride) / 4) * img_scale_x;
			y = h * img_scale_y / 2 +  -((index - x * 4) / stride) * img_scale_y;

			x *= image_scale_x;
			y *= image_scale_y;
			
			x += img_middle_x;
			y += img_middle_y;
			
			p.x = x;
			p.y = y;

			np++;
						
			sumx += x;
			sumy += y;
			
			if (np >= points_per_unit) {
				average_point = new TracedPoint (-1);
				average_point.x = sumx / np;
				average_point.y = sumy / np;
				traced.add (average_point);
				
				sp.add (i);
				
				np = 0;
				sumx = 0;
				sumy = 0;
			}
			
			i++;
		}
		
		if (np != 0) {
			average_point = new TracedPoint (-1);
			average_point.x = sumx / np;
			average_point.y = sumy / np;
			traced.add (average_point);
			sp.add (i);
		}
		
		foreach (TracedPoint avgp in traced) {
			ep = new EditPoint (avgp.x, avgp.y);
			
			path.points.add (ep);
			
			if (DrawingTools.point_type == PointType.CUBIC) {
				ep.type = PointType.CUBIC;
				ep.get_right_handle ().type = PointType.LINE_CUBIC;
				ep.get_left_handle ().type = PointType.LINE_CUBIC;
			} else {
				ep.type = PointType.DOUBLE_CURVE;
				ep.get_right_handle ().type = PointType.LINE_DOUBLE_CURVE;
				ep.get_left_handle ().type = PointType.LINE_DOUBLE_CURVE;
			}
		}

		path.close ();
		path.create_list ();
		path.recalculate_linear_handles ();
		
		// Find corners
		pi = 0;
		for (i = 1; i < sp.size; i += 2) {
			return_val_if_fail (0 <= i < path.points.size, path);
			ep = path.points.get (i);

			pi = i + 2;
			pi %= path.points.size;
			return_val_if_fail (0 <= pi < path.points.size, path);
			l = path.points.get (pi).get_left_handle ();

			pi = i - 2;
			if (pi < 0) {
				pi += path.points.size;
			}
			return_val_if_fail (0 <= pi < path.points.size, path);
			r = path.points.get (pi).get_right_handle ();

			la = l.angle - PI;

			while (la < 0) {
				la += 2 * PI;
			}
			
			if (r.angle > (2.0 / 3.0) * PI && la < PI / 2) {
				la += 2 * PI;
			} else if (la > (2.0 / 3.0) * PI && r.angle < PI / 2) {
				la -= 2 * PI;
			}
			
			a = r.angle - la;

			if (fabs (a) > corner) { // corner			
				ep.set_tie_handle (false);
				find_corner (path, i, (!) sp.get (i), points_per_unit, ref ep.x, ref ep.y);
				corners.add (ep);
			} else {
				ep.set_tie_handle (true);
			}
		}
		
		path.recalculate_linear_handles ();
		path.remove_points_on_points ();
		path.create_list ();
		foreach (EditPoint e in path.points) {
			if (e.tie_handles) {
				e.process_tied_handle ();
			}
		}

		if (simplification > 0.01) {
			for (i = 0; i < path.points.size; i++) {
				ep = path.points.get (i);
				ps = new PointSelection (ep, path);
				if (corners.index_of (ep) == -1) {
					PenTool.remove_point_simplify (ps, simplification);
				} 
			}
		}
		
		for (i = 0; i < path.points.size; i++) {
			ep = path.points.get (i);
			ps = new PointSelection (ep, path);
			if (corners.index_of (ep) == -1) {
				ep.set_selected (true);
			}
		}
		
		path = PenTool.simplify (path, true, simplification);
		points.clear ();
		path.update_region_boundaries ();
		
		return path;
	}
	
	bool has_start_point (int i) {
		foreach (TracedPoint p in start_points) {
			if (p.index == i) {
				return true;
			}
		}
		return false;
	}
	
	bool is_traced (int i) {
		foreach (TracedPoint p in points) {
			if (p.index == i) {
				return true;
			}
		}
		return false;
	}
	
	public void center_in_glyph (Glyph? glyph = null) {
		Glyph g;
		Font f = BirdFont.get_current_font ();
		
		if (glyph != null) {
			g = (!) glyph;
		} else {
			g = MainWindow.get_current_glyph ();
		}
		
		img_middle_x = g.left_limit + (g.right_limit - g.left_limit) / 2;
		img_middle_y = f.bottom_position + (f.top_position - f.bottom_position) / 2;
	}
	
	class TracedPoint {
		public int index;
		
		public double x = 0;
		public double y = 0;
		
		public TracedPoint (int index) {
			this.index = index;
		}
	}
}
	
}
