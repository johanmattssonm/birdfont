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

[CCode (cname = "draw_overview_glyph")]
public extern bool draw_overview_glyph (Context context, string font_file, double width, double height, unichar character);

namespace BirdFont {
	
public class OverviewItem : GLib.Object {
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
	
	private Surface? cache = null;
	
	public static Surface? label_background = null;
	public static Surface? selected_label_background = null;
	public static Surface? label_background_no_menu = null;
	public static Surface? selected_label_background_no_menu = null;
		
	public OverviewItem () {	
	}

	public void set_character (unichar character) {
		this.character = character;
	}
	
	public void set_glyphs (GlyphCollection? gc) {
		glyphs = gc;
		
		if (glyphs != null) {	
			version_menu = new VersionList ((!) glyphs);
			version_menu.add_glyph_item.connect ((glyph) => {
				((!) glyphs).insert_glyph (glyph, true);
			});
			
			version_menu.signal_delete_item.connect ((glyph_index) => {
				Overview v = MainWindow.get_overview ();
				version_menu = new VersionList ((!) glyphs);
				v.update_item_list ();
				GlyphCanvas.redraw ();
			});
		}	

		info = new CharacterInfo (character, glyphs);
		
		if (glyphs == null) {
			label = new Text ();
		} else {
			if (character != '\0') {
				label = new Text ((!) character.to_string (), 17);
			} else {
				label = new Text ((!) info.get_name (), 17);
			}
			
			truncate_label ();
		}
		
		draw_background ();		
	}

	public void clear_cache () {
		cache = null;
		
		if (glyphs != null) {
			Glyph g = ((!) glyphs).get_current ();
			g.overview_thumbnail = null;
		}
	}

	public void draw_glyph_from_font () {
		if (glyphs == null) {
			return;
		}
		
		Glyph g;
		double gx, gy;
		double x1, x2, y1, y2;
		double scale_box;
		double w, h;
		double glyph_width, glyph_height;
		Surface s;
		Context c;
		Color color = Color.black ();
		
		g = ((!) glyphs).get_current ();
		
		if (likely (g.overview_thumbnail != null)) {
			cache = g.overview_thumbnail;
			return;
		}
		
		w = width;
		h = height;

		scale_box = (height / DEFAULT_HEIGHT) * 0.65;

		s = Screen.create_background_surface ((int) width, (int) height - 20);
		c = new Context (s);
		
		c.save ();
		g.boundaries (out x1, out y1, out x2, out y2);
	
		glyph_width = x2 - x1;
		glyph_height = y2 - y1;
		
		c.save ();
		c.scale (scale_box * Screen.get_scale (), scale_box * Screen.get_scale ());

		g.add_help_lines ();
		
		gx = ((w / scale_box) - glyph_width) / 2 - g.get_left_side_bearing ();
		gy = h / scale_box + g.get_baseline () - 20 / scale_box - 20;

		c.translate (gx - Glyph.xc () - g.get_lsb (), gy - Glyph.yc ());

		g.draw_paths (c, color);
		c.restore ();
		
		cache = s;
		g.overview_thumbnail = s;
		
		GlyphCanvas.redraw ();
	}

	public void draw_background () {
		double scale_box;
		double w, h;
		Surface s;
		Context c;
		
		w = width;
		h = height;
		
		scale_box = width / DEFAULT_WIDTH;
		s = Screen.create_background_surface ((int) width, (int) height - 20);
		c = new Context (s);
		
		if (glyphs != null) { // FIXME: lock
			draw_glyph_from_font ();
		} else {
			c.scale (Screen.get_scale (), Screen.get_scale ());
			
			c.save ();
			
			bool glyph_found;
			string? font_file;
			
			Theme.color (c, "Overview Glyph");
			
			font_file = FontCache.fallback_font.get_default_font_file ();	
			glyph_found = draw_overview_glyph (c, (!) font_file, width, height, character);
			
			if (!glyph_found) {
				font_file = find_font (FallbackFont.font_config, (!) character.to_string ());
				
				if (font_file != null) {
					string path = (!) font_file;
					
					if (!path.has_suffix("LastResort.ttf")) {
						draw_overview_glyph (c, path, width, height, character);
					}
				}
			}
			
			c.restore ();
			
			cache = s;
			GlyphCanvas.redraw ();
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
	
	public bool click_menu (uint button, double px, double py) {
		bool a;
		GlyphCollection g;

		if (has_icons () && glyphs != null) {
			g = (!) glyphs;
			version_menu.set_position (x + width - 21, y + height - 18);
			a = version_menu.menu_item_action (px, py); // select one item on the menu
			
			if (a) {
				MainWindow.get_overview ().reset_cache ();
				MainWindow.get_overview ().update_item_list ();

				GlyphCanvas.redraw ();
				return true;
			}
			
			version_menu.menu_icon_action (px, py); // click in the open menu
		}
		
		return false;
	}
	
	public bool click_info (uint button, double px, double py) {
		info.set_position (x + width - 17, y + height - 22.5);
		
		if (has_icons () && info.is_over_icon (px, py)) {
			MainWindow.get_overview ().set_character_info (info);
			return true;
		}
		
		return false;
	}
	
	public bool click (uint button, double px, double py) {
		bool s = (x <= px <= x + width) && (y <= py <= y + height);		
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
		
		draw_thumbnail (cr, x, y + height);
		
		draw_caption (cr);
		draw_menu (cr);
	}

	private void draw_thumbnail (Context cr, double x, double y) {		
		if (cache != null) {
			cr.save ();
			cr.set_antialias (Cairo.Antialias.NONE);
			cr.scale (1 / Screen.get_scale (), 1 / Screen.get_scale ());	
			cr.set_source_surface ((!) cache, (int) (x * Screen.get_scale ()), (int) ((y - height)) * Screen.get_scale ());
			cr.paint ();
			cr.restore ();
		}
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
		
		cr.restore ();
	}
	
	public void create_label_background_cache (Context cr) {
		Context cc;
		Cairo.Pattern p;
		Surface cache;
			
		// unselected item
		cache = Screen.create_background_surface ((int) width + 1, 20);
		cc = new Context (cache);
		cc.scale(Screen.get_scale(), Screen.get_scale());

		cc.rectangle (0, 0, width, 20 - 1);
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
		cache = Screen.create_background_surface ((int) width + 1, 20);
		cc = new Context (cache);
		cc.scale(Screen.get_scale(), Screen.get_scale());

		cc.rectangle (0, 0, width, 20 - 1);

		Theme.color (cc, "Selected Overview Item");
			
		cc.fill ();
		
		if (has_icons ()) {
			draw_menu_icon (cc, true);
			draw_character_info_icon (cc);
		}

		selected_label_background = (!) cache;	
	
		// deselected item without menu icon
		cache = Screen.create_background_surface ((int) width, 20);
		cc = new Context (cache);
		cc.scale(Screen.get_scale(), Screen.get_scale());
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
		cache = Screen.create_background_surface ((int) width + 1, 20);
		cc = new Context (cache);
		cc.scale(Screen.get_scale(), Screen.get_scale());
		cc.rectangle (0, 0, width, 20 - 1);
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
			
			Screen.paint_background_surface (cr, cache, (int) x, (int) (y + height - 19));
		}
	}
	
	private void draw_character_info_icon (Context cr) {
		info.draw_icon (cr, selected, width - 17, -1.5);
	}
	
	public void hide_menu () {
		if (!is_null (version_menu)) {
			version_menu.menu_visible = false;
		}
	}
	
	private void draw_menu_icon (Context cc, bool selected) {
		Text icon;

		icon = new Text ("dropdown_menu", 17);
		icon.load_font ("icons.birdfont");

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
