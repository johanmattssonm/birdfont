/*
    Copyright (C) 2014 Johan Mattsson

    This library is free software; you can redistribute it and/or modify 
    it under the terms of the GNU Lesser General Public License as 
    published by the Free Software Foundation; either version 3 of the 
    License, or (at your option) any later version.

    This library is distributed in the hope that it will be useful, but 
    WITHOUT ANY WARRANTY; without even the implied warranty of 
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU 
    Lesser General Public License for more details.
*/

namespace BirdFont {

public class BackgroundTools : ToolCollection  {
	
	public BackgroundSelectionTool select_background;
	
	Expander files;
	Expander parts;
	public Gee.ArrayList<Expander> expanders = new Gee.ArrayList<Expander> ();
	
	public BackgroundTools () {
		Expander background_tools = new Expander (t_("Background Image"));
		Expander background_selection = new Expander (t_("Images"));
		
		Expander font_name = new Expander ();
		font_name.add_tool (new FontName ());

		select_background = new BackgroundSelectionTool ();

		files = new Expander (t_("Files"));
		files.set_persistent (true);
		files.set_unique (true);

		parts = new Expander (t_("Parts"));
		parts.set_persistent (true);
		parts.set_unique (true);
		
		background_tools.add_tool (select_background);
		
		LabelTool add_new_image = new LabelTool (t_("Add"));
		add_new_image.select_action.connect ((t) => {
			load_image ();
		});
		background_selection.add_tool (add_new_image);

		background_tools.add_tool (DrawingTools.move_background);
		background_tools.add_tool (DrawingTools.move_canvas);
		background_tools.add_tool (DrawingTools.background_scale);

		expanders.add (font_name);
		expanders.add (background_tools);
		expanders.add (DrawingTools.zoombar_tool);
		expanders.add (DrawingTools.guideline_tools);
		expanders.add (background_selection);
		expanders.add (files);
		expanders.add (parts);
	}

	public void remove_images () {
		files.tool.clear ();
		parts.tool.clear ();
	}

	void set_default_canvas () {
		MainWindow.get_tab_bar ().select_tab_name ("Backgrounds");
	}

	public override void selected () {
		// perform update after label selection is done
		IdleSource idle = new IdleSource (); 
		idle.set_callback (() => {
			foreach (Tool t in files.tool) {
				BackgroundSelectionLabel bg = (BackgroundSelectionLabel) t;
				
				if (bg.is_selected ()) {
					update_parts_list (bg.img);
				}
			}
				
			return false;
		});
		idle.attach (null);
	}

	public void update_parts_list (BackgroundImage current_image) {
		parts.tool.clear ();

		foreach (BackgroundSelection selection in current_image.selections) {
			add_part (selection);
		}
		
		parts.redraw ();
	}

	public void add_part (BackgroundSelection selection) {
		BackgroundPartLabel label;
		
		if (selection.assigned_glyph == null) {
			label = new BackgroundPartLabel (selection, t_("Select Glyph"));
		} else {
			label = new BackgroundPartLabel (selection, (!) selection.assigned_glyph);
		}
		
		label.select_action.connect ((t) => {
			BackgroundPartLabel bpl = (BackgroundPartLabel) t;
			GlyphSelection gs = new GlyphSelection ();
			
			gs.selected_glyph.connect ((gc) => {
				GlyphCollection? pgc;
				Font font = BirdFont.get_current_font ();
				
				pgc = font.get_glyph_collection_by_name (bpl.selection.assigned_glyph);
				if (pgc != null) {
					((!) pgc).get_current ().set_background_image (null);
				}		
				
				set_new_background_image (gc, bpl);
			});
			
			gs.open_new_glyph_signal.connect ((character) => {
				GlyphCollection gc = gs.create_new_glyph (character);
				set_new_background_image (gc, bpl);
			});
			
			if (!bpl.deleted) {
				GlyphCanvas.set_display (gs);
				Toolbox.set_toolbox_from_tab ("Overview");
			}			
		});
		
		label.delete_action.connect ((t) => {
			// don't invalidate the toolbox iterator
			IdleSource idle = new IdleSource (); 
			idle.set_callback (() => {
				GlyphCollection? gc;
				BackgroundPartLabel bpl;
				Font font = BirdFont.get_current_font ();
				
				bpl = (BackgroundPartLabel) t;
				bpl.deleted = true;

				gc = font.get_glyph_collection_by_name (bpl.selection.assigned_glyph);
				if (gc != null) {
					((!) gc).get_current ().set_background_image (null);
				}

				parts.tool.remove (bpl);
				bpl.selection.parent_image.selections.remove (bpl.selection);
				MainWindow.get_toolbox ().update_expanders ();
				parts.clear_cache ();
				set_default_canvas ();
				Toolbox.redraw_tool_box ();
				GlyphCanvas.redraw ();
				
				return false;
			});
			idle.attach (null);
		});
		label.has_delete_button = true;
		parts.add_tool (label, 0);
		
		if (!is_null (MainWindow.get_toolbox ())) {
			MainWindow.get_toolbox ().update_expanders ();
			Toolbox.redraw_tool_box ();
		}
		
		parts.redraw ();
	}

	void set_new_background_image (GlyphCollection gc, BackgroundPartLabel bpl) {
		Glyph g;
		
		g = gc.get_current ();
		bpl.selection.assigned_glyph = gc.get_name ();
		bpl.label = gc.get_name ();
		g.set_background_image (bpl.selection.image);
		g.set_background_visible (true);
		
		if (bpl.selection.image != null) {
			((!) bpl.selection.image).center_in_glyph (gc.get_current ());
		}
		
		set_default_canvas ();
		ZoomTool.zoom_full_background_image ();
		MainWindow.get_toolbox ().update_expanders ();
	}

	public override Gee.ArrayList<Expander> get_expanders () {
		return expanders;
	}

	void load_image () {
		FileChooser fc = new FileChooser ();
		fc.file_selected.connect ((fn) => {
			if (fn != null) {
				add_image_file ((!) fn);
			}
		});
		
		fc.add_extension ("png");
		fc.add_extension ("jpeg");
		fc.add_extension ("jpg");
		fc.add_extension ("gif");
		fc.add_extension ("tiff");
		fc.add_extension ("bmp");
		fc.add_extension ("svg");
		
		MainWindow.file_chooser (t_("Open"), fc, FileChooser.LOAD);
	}
	
	void add_image_file (string file_path) {
		File f = File.new_for_path (file_path);
		string fn = (!) f.get_basename ();
		BackgroundImage image = new BackgroundImage (file_path);
		int i;
		
		i = fn.index_of (".");
		if (i > -1) {
			fn = fn.substring (0, i);
		}
		
		image.name = fn;
		
		add_image (image);
		
		GlyphCanvas.redraw ();
		MainWindow.get_toolbox ().update_expanders ();
		Toolbox.redraw_tool_box ();
	}
	
	public void add_image (BackgroundImage image) {
		LabelTool image_selection;
		double xc, yc;
		BackgroundTab bt;
		Font font;
		
		font = BirdFont.get_current_font ();

		image_selection = new BackgroundSelectionLabel (image, image.name);
		image_selection.select_action.connect ((t) => {
			BackgroundTab background_tab = BackgroundTab.get_instance ();
			BackgroundSelectionLabel bg = (BackgroundSelectionLabel) t;
			
			if (!bg.deleted) {
				background_tab.set_background_image (bg.img);
				background_tab.set_background_visible (true);
				ZoomTool.zoom_full_background_image ();
				update_parts_list (bg.img);
				GlyphCanvas.redraw ();
				Toolbox.redraw_tool_box ();
			}
			
			set_default_canvas ();
		});
		
		image_selection.select_action ((BackgroundSelectionLabel) image_selection);
		
		image_selection.delete_action.connect ((t) => {
			// don't invalidate the toolbox iterator
			IdleSource idle = new IdleSource (); 
			idle.set_callback (() => {
				BackgroundSelectionLabel bsl;
				Font f = BirdFont.get_current_font ();
				
				bsl = (BackgroundSelectionLabel) t;
				bsl.deleted = true;
			
				files.tool.remove (bsl);
				f.background_images.remove (bsl.img);
				
				MainWindow.get_current_glyph ().set_background_image (null);

				MainWindow.get_toolbox ().update_expanders ();
				set_default_canvas ();
				image_selection.redraw ();
				GlyphCanvas.redraw ();
				return false;
			});
			idle.attach (null);
		});
		
		image_selection.has_delete_button = true;
		
		files.add_tool (image_selection);

		bt = BackgroundTab.get_instance ();
		bt.set_background_image (image);
		bt.set_background_visible (true);
		ZoomTool.zoom_full_background_image ();
		
		foreach (Tool t in files.tool) {
			t.set_selected (false);
		}
		image_selection.set_selected (true);

		bt.set_background_image (image);
		bt.set_background_visible (true);

		xc = image.img_middle_x;
		yc = image.img_middle_y;

		image.set_img_scale (0.2, 0.2);
		
		image.img_middle_x = xc;
		image.img_middle_y = yc;
				
		image.center_in_glyph ();
		ZoomTool.zoom_full_background_image ();
		
		font.add_background_image (image);
	}

	public override Gee.ArrayList<string> get_displays () {
		Gee.ArrayList<string> d = new Gee.ArrayList<string> ();
		d.add ("Backgrounds");
		return d;
	}
	
	class BackgroundSelectionLabel : LabelTool {
		public BackgroundImage img;
		public bool deleted;
		public BackgroundSelectionLabel (BackgroundImage img, string base_name) {
			base (base_name);
			this.img = img;
			deleted = false;
		}
	}

	class BackgroundPartLabel : LabelTool {
		public bool deleted;
		public BackgroundSelection selection;
		public BackgroundPartLabel (BackgroundSelection selection, string base_name) {
			base (base_name);
			this.selection = selection;
			deleted = false;
		}
	}
}

}
