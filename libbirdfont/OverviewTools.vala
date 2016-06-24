/*
	Copyright (C) 2014 2015 Johan Mattsson

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

namespace BirdFont {

public enum Transform {
	SLANT,
	SIZE,
	SVG_TO_TTF
}

public class OverviewTools : ToolCollection  {

	static LabelTool all_glyphs;
	static LabelTool default_glyphs;
	static LabelTool unicode;

	static Gee.ArrayList<LabelTool> custom_character_sets;

	public static Gee.ArrayList<Expander> expanders;
	public ZoomBar zoom_bar;
	
	public static Expander zoom_expander;

	public static SpinButton skew;
	public static SpinButton resize;
	
	public static double current_master_size;
	
	public OverviewTools () {
		Expander font_name = new Expander ();
		Expander character_sets = new Expander (t_("Character Sets"));
		Expander zoom_expander = new Expander (t_("Zoom"));
		Expander transform_slant_expander = new Expander (t_("Transform"));
		Expander transform_size_expander = new Expander ();
		Expander glyph_expander = new Expander (t_("Glyph"));
		Expander multi_master = new Expander (t_("Multi-Master"));
		
		expanders = new Gee.ArrayList<Expander> ();
		custom_character_sets = new Gee.ArrayList<LabelTool> ();
		
		font_name.add_tool (new FontName ());

		zoom_bar = new ZoomBar ();
		zoom_bar.new_zoom.connect ((z) => {
			get_overview ().set_zoom (z);
		});
		zoom_expander.add_tool (zoom_bar);
						
		all_glyphs = new LabelTool (t_("All Glyphs"));
		all_glyphs.has_counter = true;
		all_glyphs.select_action.connect ((self) => {
			OverView overview = get_overview ();
			overview.display_all_available_glyphs ();
			update_overview_characterset (overview);
			FontDisplay.dirty_scrollbar = true;
		});
		character_sets.add_tool (all_glyphs);

		default_glyphs = new LabelTool (t_("Default"));
		default_glyphs.has_counter = true;
		default_glyphs.select_action.connect ((self) => {
			OverView overview = get_overview ();
			GlyphRange gr = new GlyphRange ();
			DefaultCharacterSet.use_default_range (gr);
			overview.set_current_glyph_range (gr);
			update_overview_characterset (overview);
			FontDisplay.dirty_scrollbar = true;
		});
		character_sets.add_tool (default_glyphs);

		unicode = new LabelTool (t_("Unicode"));
		unicode.has_counter = true;
		unicode.select_action.connect ((self) => {
			OverView overview = get_overview ();
			GlyphRange gr = new GlyphRange ();
			DefaultCharacterSet.use_full_unicode_range (gr);
			overview.set_current_glyph_range (gr);
			update_overview_characterset (overview);
			FontDisplay.dirty_scrollbar = true;
		});
		character_sets.add_tool (unicode);
		
		character_sets.set_persistent (true);
		character_sets.set_unique (false);

		skew = new SpinButton ("skew_overview", t_("Skew"));
		skew.set_big_number (true);
		skew.set_int_value ("0.000");

		FontSettings settings = BirdFont.get_current_font ().settings;			
		string? skew_value = settings.get_setting ("skew_overview");

		if (skew_value != null) {
			skew.set_int_value ((!) skew_value);
		}

		skew.set_int_step (1);
		skew.set_min (-100);
		skew.set_max (100);
		skew.show_icon (true);
		skew.set_persistent (false);
		transform_slant_expander.add_tool (skew);
			
		Tool transform_slant = new Tool ("transform_slant", t_("Transform"));
		transform_slant.set_icon ("transform");
		transform_slant.select_action.connect ((self) => {
			FontSettings fs = BirdFont.get_current_font ().settings;			
			fs.set_setting ("skew_overview", @"$(skew.get_value ())");
			transform_slant.selected = false;
			
			process_transform (Transform.SLANT);
			
			BirdFont.get_current_font ().touch ();
		});
		transform_slant.selected = false;
		transform_slant.set_persistent (false);
		transform_slant_expander.add_tool (transform_slant);

		resize = new SpinButton ("resize_overview", t_("Resize"));
		resize.set_big_number (true);
		resize.set_int_value ("100.0");
					
		string? resize_value = settings.get_setting ("resize_overview");

		if (resize_value != null) {
			resize.set_int_value ((!) resize_value);
			
			if (resize.get_value () <= 0) {
				resize.set_int_value ("100.0");
			}
		}

		resize.set_int_step (1);
		resize.set_min (0);
		resize.set_max (300);
		resize.show_icon (true);
		resize.set_persistent (false);
		transform_size_expander.add_tool (resize);

		Tool transform_size = new Tool ("transform_size", t_("Transform"));
		transform_size.set_icon ("transform");
		transform_size.select_action.connect ((self) => {
			FontSettings fs = BirdFont.get_current_font ().settings;			
			fs.set_setting ("resize_overview", @"$(resize.get_value ())");
			transform_size.selected = false;
			
			process_transform (Transform.SIZE);
			
			BirdFont.get_current_font ().touch ();
		});
		transform_size.selected = false;
		transform_size.set_persistent (false);
		transform_size_expander.add_tool (transform_size);

		Tool alternate = new Tool ("alternate", t_("Create alternate"));
		alternate.select_action.connect (add_new_alternate);
		glyph_expander.add_tool (alternate);
		
		Tool curve_orientation = new Tool ("curve_orientation", t_("Set curve orientation"));
		curve_orientation.select_action.connect ((self) => {
			Task t = new Task (fix_curve_orientation);
			
			MainWindow.run_blocking_task (t);
			
			IdleSource idle = new IdleSource ();
			idle.set_callback (() => {
				self.set_selected (false);
				BirdFont.get_current_font ().touch ();		
				return false;
			});
			idle.attach (null);
		});
		glyph_expander.add_tool (curve_orientation);

		Tool search_glyph = new Tool ("search", t_("Search"));
		search_glyph.select_action.connect (search_for_glyph);
		glyph_expander.add_tool (search_glyph);

		Tool convert_to_ttf = new Tool ("svg_to_birdfont_overview", t_("Convert SVG file to monochrome glyph"));
		convert_to_ttf.set_icon ("svg_to_birdfont");
		
		convert_to_ttf.select_action.connect ((self) => {
			process_transform (Transform.SVG_TO_TTF);
			self.set_selected (false);
			BirdFont.get_current_font ().touch ();
		});
		
		convert_to_ttf.selected = false;
		convert_to_ttf.set_persistent (false);
		glyph_expander.add_tool (convert_to_ttf);
		
		SpinButton master_size;
		current_master_size = 0;
		master_size = new SpinButton ("master_size", t_("Master Size")); /// Master refers to a glyph master in a multi-master font.
		master_size.set_big_number (false);
		master_size.set_int_value ("0.000");
		master_size.set_int_step (1);
		master_size.set_min (-1);
		master_size.set_max (1);
		master_size.show_icon (true);
		master_size.set_persistent (false);
		master_size.new_value_action.connect ((self) => {
			current_master_size = self.get_value ();
			MainWindow.get_overview ().update_item_list ();
			GlyphCanvas.redraw ();
		});
		multi_master.add_tool (master_size);

		Tool create_new_master = new Tool ("new_master", t_("Create new master font")); /// Master is a master in a multi-master font.
		create_new_master.select_action.connect (create_master);
		multi_master.add_tool (create_new_master);
				
		expanders.add (font_name);
		expanders.add (zoom_expander);
		expanders.add (character_sets);
		expanders.add (transform_slant_expander);
		expanders.add (transform_size_expander);
		expanders.add (glyph_expander);
		
		if (BirdFont.has_argument ("--test")) {
			expanders.add (multi_master);
		}
	}

	void create_master () {
		Font font = BirdFont.get_current_font ();
		int i = 0;
		GlyphCollection glyph_collection;
		GlyphCollection? gc = font.get_glyph_collection_index (i);
		Glyph g;
		
		while (gc != null) {
			glyph_collection = (!) gc;
			
			// FIXME: MASTER NAME
			GlyphMaster master = new GlyphMaster.for_id("Master 2"); 
			g = glyph_collection.get_interpolated (current_master_size);
			master.add_glyph(g);
			glyph_collection.add_master (master);
			glyph_collection.set_selected_master (master);
			
			i++;
			gc = font.get_glyph_collection_index (i);
		}

		MainWindow.get_overview ().update_item_list ();
		GlyphCanvas.redraw ();
	}

	void fix_curve_orientation () {
		OverView o;
		Glyph g;
		OverView.OverViewUndoItem ui;
		
		o = get_overview ();
		ui = new OverView.OverViewUndoItem ();
		
		Font f = BirdFont.get_current_font ();
		ui.alternate_sets = f.alternates.copy ();
		
		foreach (GlyphCollection gc in o.selected_items) {
			if (gc.length () > 0) {
				g = gc.get_current ();
				ui.glyphs.add (gc.copy_deep ());
				g.add_help_lines ();
				g.fix_curve_orientation ();
			}
		}
		
		o.undo_items.add (ui);
		GlyphCanvas.redraw ();
	}
	
	public void search_for_glyph (Tool tool) {
		tool.set_selected (false);
		OverView.search ();
	}
	
	public void add_new_alternate (Tool tool) {
		OverView o = MainWindow.get_overview ();
		OverViewItem oi = o.selected_item;
		GlyphCollection? gc;
		
		tool.set_selected (false);
		
		gc = (!) oi.glyphs;		
		
		if (oi.glyphs != null && ((!) oi.glyphs).is_unassigned ()) {
			gc = null;
		}
		
		MainWindow.tabs.add_tab (new OtfFeatureTable (gc));
	}

	public void process_transform (Transform transform) {	
		TransformTask task = new TransformTask (transform);
		MainWindow.run_blocking_task (task);
	}
	
	public static OverView get_overview () {
		FontDisplay fd = MainWindow.get_current_display ();
		
		if (fd is OverView || fd is GlyphSelection) {
			return (OverView) fd;
		}
		
		warning ("Current tab is not overview.");
		
		return new OverView ();
	}
	
	public static void show_all_available_characters () {
		all_glyphs.select_action (all_glyphs);
	}
	
	public static void update_overview_characterset (OverView? tab = null) {
		GlyphRange gr;
		uint size;
		OverView overview;
		Font font;
		
		// All characters including .notdef
		font = BirdFont.get_current_font ();
		size = font.length ();
		
		if (!font.has_glyph (".notdef")) {
			size++;
		}
		
		all_glyphs.number = get_display_value (size);
		
		// Default
		gr = new GlyphRange ();
		DefaultCharacterSet.use_default_range (gr);
		size = gr.get_length ();
		default_glyphs.number = get_display_value (size);
		
		// Unicode
		gr = new GlyphRange ();
		DefaultCharacterSet.use_full_unicode_range (gr);
		size = gr.get_length ();
		unicode.number = get_display_value (size);
		
		overview = (tab == null) ? MainWindow.get_overview () : (!) tab;
		
		// set selected item
		all_glyphs.set_selected (false);
		default_glyphs.set_selected (false);
		unicode.set_selected (false);
		
		if (overview.all_available) {
			all_glyphs.set_selected (true);
		} else if (overview.glyph_range.name == "Default") {
			default_glyphs.set_selected (true);
		} else if (overview.glyph_range.name == "Unicode") {
			unicode.set_selected (true);
		}
		
		Toolbox.redraw_tool_box ();
	}

	static string get_display_value (uint size) {
		double k;
		string display_size;
		
		if (size >= 1000) {
			k = size / 1000.0;
			size = (uint) Math.rint (k);
			display_size = @"$(size)k";
		} else {
			display_size = @"$(size)";
		}
		
		return display_size;
	}
	
	public override Gee.ArrayList<Expander> get_expanders () {
		return expanders;
	}

	public override Gee.ArrayList<string> get_displays () {
		Gee.ArrayList<string> d = new Gee.ArrayList<string> ();
		d.add ("Overview");
		return d;
	}
}

}
