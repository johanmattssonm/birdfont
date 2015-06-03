/*
    Copyright (C) 2012 2014 2015 Johan Mattsson

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
	
public class OverViewItem : GLib.Object {
	public unichar character = '\0';
	public GlyphCollection? glyphs;
	public double x;
	public double y;
	public bool selected = false;
	public CharacterInfo info;
		
	public static double DEFAULT_WIDTH = 100;
	public static double DEFAULT_HEIGHT = 130;
	public static double DEFAULT_MARGIN = 20;
	
	public static double width = 100;
	public static double height = 130;
	public static double margin = 20;

	public static double glyph_scale = 1.0;
	
	public VersionList version_menu;
	Text label;
	
	static Surface? label_background = null;
	static Surface? selected_label_background = null;
	static Surface? label_background_no_menu = null;
	static Surface? selected_label_background_no_menu = null;
	
	public OverViewItem (GlyphCollection? glyphs, unichar character, double x, double y) {	
		this.x = x;
		this.y = y;
		this.character = character;
		this.glyphs = glyphs;
		this.info = new CharacterInfo (character, glyphs);		

		label = new Text ((!) character.to_string (), 17);		
		truncate_label ();
			
		if (glyphs != null) {
			version_menu = new VersionList ((!) glyphs);
			version_menu.add_glyph_item.connect ((glyph) => {
				((!) glyphs).insert_glyph (glyph, true);
			});
			
			version_menu.signal_delete_item.connect ((glyph_index) => {
				OverView v = MainWindow.get_overview ();
				version_menu = new VersionList ((!) glyphs);
				v.update_item_list ();
				GlyphCanvas.redraw ();
			});
		} else {
			version_menu = new VersionList (new GlyphCollection (character, (!) character.to_string ()));
		}
	}

	public static void reset_label () {
		label_background = null;
		selected_label_background = null;
	}
	
	void truncate_label () {
		double w = has_icons () ? width - 43 : width;
		label.truncate (w);
	}

	public string get_name () {
		StringBuilder s;
		
		if (glyphs != null) {
			return ((!) glyphs).get_name ();
		}
		
		s = new StringBuilder ();
		s.append_unichar (character);
		
		return s.str;
	}
	
	public void set_selected (bool s) {
		selected = s;
	}
	
	public static double full_width () {
		return width + margin;
	}

	public static double full_height () {
		return height + margin;
	}
	
	public bool click (uint button, double px, double py) {
		bool a;
		GlyphCollection g;
		bool s = (x <= px <= x + width) && (y <= py <= y + height);

		if (has_icons () && glyphs != null) {
			g = (!) glyphs;
			version_menu.set_position (x + width - 21, y + height - 18);
			a = version_menu.menu_item_action (px, py); // select one item on the menu
			if (a) {
				return s;
			}
			
			version_menu.menu_icon_action (px, py); // click in the open menu
		}
		
		info.set_position (x + width - 17, y + height - 22.5);
		if (has_icons () && info.is_over_icon (px, py)) {
			MainWindow.get_overview ().set_character_info (info);
		}
				
		return s;
	}

	public bool double_click (uint button, double px, double py) {
		selected = (x <= px <= x + width) && (y <= py <= y + height);
		return selected;
	}

	public bool is_on_screen (WidgetAllocation allocation) {
		return y + height > 0 && y < allocation.height;
	}

	public void draw (WidgetAllocation allocation, Context cr) {
		if (!is_on_screen (allocation)) {
			return;
		}
		
		cr.save ();
		Theme.color (cr, "Background 1");
		cr.rectangle (x, y, width, height);
		cr.fill ();
		cr.restore ();

		cr.save ();
		Theme.color (cr, "Overview Item Border");
		cr.rectangle (x, y, width, height);
		cr.set_line_width (1);
		cr.stroke ();
		cr.restore ();
		
		draw_thumbnail (cr, glyphs, x, y + height); 	
		draw_caption (cr);
	}

	public void adjust_scale () {
		double x1, x2, y1, y2, glyph_width, glyph_height, scale, gx;
		Glyph g;
		Font font;
		
		if (glyphs != null) {
			font = BirdFont.get_current_font ();
			g = ((!) glyphs).get_current ();
			g.boundaries (out x1, out y1, out x2, out y2);
		
			glyph_width = x2 - x1;
			glyph_height = y2 - y1;

			if (glyph_scale == 1) {
				// caption height is 20
				glyph_scale = (height - 20) / (font.top_limit - font.bottom_limit);	
			}
			
			scale = glyph_scale;			
			gx = ((width / scale) - glyph_width) / 2;
		
			if (gx < 0) {
				glyph_scale = 1 + 2 * gx / width;
			}
		}
	}

	private void draw_thumbnail (Context cr, GlyphCollection? gl, double x, double y) {
		Glyph g;
		Font font;
		double gx, gy;
		double x1, x2, y1, y2;
		double scale_box;
		double w, h;
		double glyph_width, glyph_height;
		Surface s;
		Context c;
		Color color = Color.black ();

		w = width;
		h = height;
		
		scale_box = width / DEFAULT_WIDTH;

		s = new Surface.similar (cr.get_target (), Content.COLOR_ALPHA, (int) w, (int) h - 20);
		c = new Context (s);
			
		if (gl != null) {
			font = BirdFont.get_current_font ();
			g = ((!) gl).get_current ();

			c.save ();
			g.boundaries (out x1, out y1, out x2, out y2);
		
			glyph_width = x2 - x1;
			glyph_height = y2 - y1;
			
			gx = ((w / glyph_scale) - glyph_width) / 2;
			gy = (h / glyph_scale) - 25 / glyph_scale;

			c.save ();
			c.scale (glyph_scale, glyph_scale);	

			g.add_help_lines ();
			
			c.translate (gx - g.get_lsb () - Glyph.xc (), g.get_baseline () + gy - Glyph.yc ());
			
			g.draw_paths (c, color);
			c.restore ();
		} else {
			c.save ();
			Text fallback = new Text ();
			Theme.text_color (fallback, "Overview Glyph");
			fallback.set_text ((!) character.to_string ());
			double font_size = height * 0.8;
			fallback.set_font_size (font_size);

			gx = (width - fallback.get_extent ()) / 2.0;
			gy = height - 30;
			fallback.set_font_size (font_size);
			fallback.draw_at_baseline (c, gx, gy);
			c.restore ();
		}
		
		cr.save ();
		cr.set_source_surface (s, x, y - h);
		cr.paint ();
		cr.restore ();
	}

	public bool has_icons () {
		return width > 50;
	}

	public void draw_caption (Context cr) {
		draw_label_background (cr);
		
		cr.save ();
		
		if (glyphs != null) {
			if (selected) {
				Theme.text_color (label, "Overview Selected Foreground");
			} else {
				Theme.text_color (label, "Overview Foreground");
			}
		
			label.draw_at_baseline (cr, x + 0.08 * width, y + height - 6);
		}
		
		draw_menu (cr);
		cr.restore ();
	}
	
	public void create_label_background_cache (Context cr) {
		Context cc;
		Cairo.Pattern p;
		Surface cache;
			
		// unselected item
		cache = new Surface.similar (cr.get_target (), Cairo.Content.COLOR_ALPHA, (int) width, 20);
		cc = new Context (cache);
		cc.rectangle (0, 0, width - 1, 20 - 1);
		p = new Cairo.Pattern.linear (0.0, 0, 0.0, 20);
		Theme.gradient (p, "Overview Item 1", "Overview Item 2");
		cc.set_source (p);
			
		cc.fill ();
		
		if (has_icons ()) {
			draw_menu_icon (cc, false);
			draw_character_info_icon (cc);
		}

		label_background = (!) cache;	

		// selected item
		cache = new Surface.similar (cr.get_target (), Cairo.Content.COLOR_ALPHA, (int) width, 20);
		cc = new Context (cache);

		cc.rectangle (0, 0, width - 1, 20 - 1);

		Theme.color (cc, "Selected Overview Item");
			
		cc.fill ();
		
		if (has_icons ()) {
			draw_menu_icon (cc, true);
			draw_character_info_icon (cc);
		}

		selected_label_background = (!) cache;	
	
		// unselected item without menu icon
		cache = new Surface.similar (cr.get_target (), Cairo.Content.COLOR_ALPHA, (int) width, 20);
		cc = new Context (cache);

		cc.rectangle (0, 0, width - 1, 20 - 1);
		p = new Cairo.Pattern.linear (0.0, 0, 0.0, 20);
		Theme.gradient (p, "Overview Item 1", "Overview Item 2");
		cc.set_source (p);
		cc.fill ();

		if (has_icons ()) {
			draw_character_info_icon (cc);
		}
		
		label_background_no_menu = (!) cache;

		// selected item
		cache = new Surface.similar (cr.get_target (), Cairo.Content.COLOR_ALPHA, (int) width, 20);
		cc = new Context (cache);
		cc.rectangle (0, 0, width - 1, 20 - 1);
		Theme.color (cc, "Selected Overview Item");
		cc.fill ();

		if (has_icons ()) {
			draw_character_info_icon (cc);
		}
				
		selected_label_background_no_menu = (!) cache;		
	}
	
	bool has_menu () {
		return glyphs != null;
	}
	
	public void draw_label_background (Context cr) {
		Surface cache;
		bool icon;
		
		if (unlikely (label_background == null)) {
			create_label_background_cache (cr);
		}
		
		if (label_background != null 
			&& selected_label_background != null
			&& label_background_no_menu != null
			&& selected_label_background_no_menu != null) {
			
			icon = has_menu ();
			if (selected && icon) {
				cache = (!) selected_label_background;
			} else if (!selected && icon) {
				cache = (!) label_background;
			} else if (selected && !icon) {
				cache = (!) selected_label_background_no_menu;
			} else {
				cache = (!) label_background_no_menu;
			}
			
			cr.save ();
			cr.set_antialias (Cairo.Antialias.NONE);
			cr.set_source_surface (cache, (int) (x + 1), (int) (y + height - 19));
			cr.paint ();
			cr.restore ();
		}
	}
	
	private void draw_character_info_icon (Context cr) {
		info.draw_icon (cr, selected, width - 17, -2.5);
	}
	
	public void hide_menu () {
		version_menu.menu_visible = false;
	}
	
	private void draw_menu_icon (Context cc, bool selected) {
		Text icon;

		icon = new Text ("dropdown_menu", 17);
		icon.load_font ("icons.bf");

		if (selected) {
			Theme.text_color (icon, "Overview Selected Foreground");
		} else {
			Theme.text_color (icon, "Overview Foreground");
		}
		
		icon.draw_at_top (cc, width - 32, 0);
	}
	
	private void draw_menu (Context cr) {
		if (likely (glyphs == null || !version_menu.menu_visible)) {
			return;
		}
		
		version_menu.draw_menu (cr);
	}
}

}
