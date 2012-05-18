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
using Cairo;

namespace Supplement {

class BackgroundSelection : FontDisplay {

	int active_box = -1;
	ImageSurface add_icon; 
	Glyph glyph;
	CutBackgroundCanvas cut_background_canvas;
	List <string> background_images = new List <string> ();
	Allocation allocation;
	
	public BackgroundSelection (Glyph glyph) {
		ImageSurface? i;
		i = Icons.get_icon ("add_background_image.png");
		return_if_fail (i != null);
		add_icon = (!) i;
		this.glyph = glyph;
		
		CutBackgroundTool cb = (CutBackgroundTool) MainWindow.get_toolbox ().get_tool ("cut_background");
		
		cb.set_destination_file_name (glyph.get_name ());
		
		cb.new_image.connect ((file) => {
			Tool zoom_background;
			TabBar tb = MainWindow.get_tab_bar ();
			
			glyph.set_background_image (new GlyphBackgroundImage (file));

			tb.close_display (cut_background_canvas);
			tb.select_tab_name (glyph.get_name ());
			
			glyph.set_background_visible (true);
			
			zoom_background = MainWindow.get_tool ("zoom_background_image");
			zoom_background.select_action (zoom_background);

		});
	}

	public override string get_name () {
		return "Backgrounds";
	}

	public override void draw (Allocation allocation, Context cr) {		
		double x, y, zoom;
		int box_index = 0;
		Font font;

		this.allocation = allocation;

		// bg color
		cr.save ();
		cr.set_source_rgba (255/255.0, 255/255.0, 255/255.0, 1);
		cr.rectangle (0, 0, allocation.width, allocation.height);
		cr.fill ();
		cr.restore ();
		
		draw_box (box_index, 20, 20, cr);
		cr.set_source_surface (add_icon, 52, 52);
		cr.paint ();
			
		cr.save ();
		x = 140;
		y = 20;
		zoom = 0.04;
		
		font = Supplement.get_current_font ();
		foreach (string file in background_images) {
			box_index++;

			if (x > allocation.width - 120) {
				x = 20;
				y += 120;
			}

			draw_box (box_index, x, y, cr);
			draw_thumbnail (file, x, y, cr, box_index);
			
			x += 120;	
		}
		cr.restore ();
			
	}
		
	private bool draw_thumbnail (string file, double x, double y, Context cr, int box_index) {
		ImageSurface img;
		GlyphBackgroundImage bg = new GlyphBackgroundImage (file);
		File thumbnail = bg.get_thumbnail_file ();
		File full = File.new_for_path (file);

		img = new ImageSurface.from_png ((!) thumbnail.get_path ());
		
		if (img.status () != Cairo.Status.SUCCESS) {
			return false;
		}

		cr.set_source_surface (img, x + 10, y + 10);
		cr.paint ();
		
		return true;	
	}
	
	private void draw_box (int index, double x, double y, Context cr) {
		cr.save ();
		cr.set_line_join (LineJoin.ROUND);
		cr.set_line_width (7);
		
		if (index == active_box) {
			cr.set_source_rgba (203/255.0, 220/255.0, 249/255.0, 1);
		} else {
			cr.set_source_rgba (183/255.0, 200/255.0, 223/255.0, 1);
		}
		
		cr.rectangle (x, y, 100, 100);
		cr.fill_preserve ();
		cr.stroke ();
		
		cr.restore ();		
	}
	
	public override void button_release (EventButton e) {
		motion (e.x, e.y);
		
		if (active_box == 0) {
			add_image ();
		} else {
			select_image ();
		}
	}

	private void add_image () {
		FileChooserDialog file_chooser;
		string file;
		ImageSurface image;
		
		try {
			file_chooser = new FileChooserDialog ("Add background image", MainWindow.get_current_window (), FileChooserAction.OPEN, Stock.CANCEL, ResponseType.CANCEL, Stock.OPEN, ResponseType.ACCEPT);
			file_chooser.set_current_folder_file (Supplement.get_current_font ().get_folder ());
			
			if (file_chooser.run () == ResponseType.ACCEPT) {
				// Fixa: Set file name relative to font folder
				file = file_chooser.get_filename ();

				image = new ImageSurface.from_png (file);
				
				if (image.status () == Cairo.Status.SUCCESS) {
					Supplement.get_current_font ().add_background_image (file);
					MainWindow.get_glyph_canvas ().redraw ();				
				}
			}

			file_chooser.destroy ();
		} catch (GLib.Error e) {
			warning (e.message);
		}
		
		collect_background_images ();
	}

	private void select_image () {
		Font font;
		string file;
		GlyphBackgroundImage bg;
		TabBar tb;
		Tool zoom_background;

		font = Supplement.get_current_font ();
				
		if (!(0 <= active_box - 1 < background_images.length ())) {
			return;
		}
		
		file = background_images.nth (active_box - 1).data; // Fixa: check bounds
		bg = new GlyphBackgroundImage (file);
		tb = MainWindow.get_tab_bar ();
		cut_background_canvas = new CutBackgroundCanvas (glyph);
		
		bg.reset_scale (glyph);
		
		cut_background_canvas.set_background_image (bg);
		
		tb.select_tab_name (glyph.get_name ());
		tb.close_display (this);
		
		tb.add_tab (cut_background_canvas, 110, false);

		cut_background_canvas.set_show_help_lines (false);
		cut_background_canvas.set_background_visible (true);

		zoom_background = MainWindow.get_tool ("zoom_background_image");
		zoom_background.select_action (zoom_background);

		MainWindow.get_toolbox ().select_tool_by_name ("cut_background");

	}

	private void add_unique_background (string file) {
		foreach (var f in background_images) {
			if (f == file) {
				return;
			}
		}
		
		background_images.prepend (file);
	}

	public override void selected_canvas () {
		Font font = Supplement.get_current_font ();
		File folder = font.get_backgrounds_folder ();
		
		if (!folder.query_exists ()) {
			DirUtils.create ((!) folder.get_path (), 0xFFFFFF);
		}
		
		collect_background_images ();
	}

	bool is_image (string file_name) {
		return file_name.index_of (".png") != -1 
			|| file_name.index_of (".jpg") != -1
			|| file_name.index_of (".jpeg") != -1;
	}

	void collect_background_images () {
		Font font = Supplement.get_current_font ();
		File directory = font.get_folder ();
		FileEnumerator enumerator;
		FileInfo? file_info;
		FileInfo fi;
		File img_file;

		while (background_images.length () > 0) {
			background_images.delete_link (background_images.first ());
		}
		
		foreach (string file in font.background_images) {
			add_unique_background (file);
		}
				
		try {
			enumerator = directory.enumerate_children (FILE_ATTRIBUTE_STANDARD_NAME, 0);
			
			while ((file_info = enumerator.next_file ()) != null) {
				fi = (!) file_info;
				
				if (is_image (fi.get_name ())) {
					img_file = directory.get_child (fi.get_name ());					
					add_unique_background ((!)img_file.get_path ());
				}
				
			}
		} catch (GLib.Error e) {
			warning (e.message);
		}
	}
	
	public override void key_press (EventKey e) {
	}

	public override void key_release (EventKey e) {
	}
	
	public override void motion_notify (EventMotion e) {
		motion (e.x, e.y);
	}
	
	public void motion (double x, double y) {
		int active;
		
		active = (int) (x / 120); // column
		active += (int) (y / 120) * (int) (allocation.width / 120.0); // row
		
		if (active != active_box) {
			MainWindow.get_glyph_canvas ().redraw ();
			active_box = active;
		}
	}

	public override void button_press (EventButton e) {
		motion (e.x, e.y);
	}

	public override void store_current_view () {
	}
	
	public override void restore_last_view () {
	}

	public override void next_view () {
	}
	
	public override void scroll_wheel_up (Gdk.EventScroll e) {
	}

	public override void scroll_wheel_down (Gdk.EventScroll e) {
	}

}

class CutBackgroundCanvas : Glyph {
	Glyph glyph;

	public CutBackgroundCanvas (Glyph g) {
		base ("Background");
		glyph = g;
		redraw_help_lines ();
	}
}

}
