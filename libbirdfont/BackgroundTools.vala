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
	Expander files;
	public Gee.ArrayList<Expander> expanders = new Gee.ArrayList<Expander> ();
	
	public BackgroundTools () {
		Expander background_selection = new Expander (t_("Images"));
		Expander background_tools = new Expander ();

		Expander font_name = new Expander ();
		font_name.add_tool (new FontName ());
		font_name.draw_separator = false;

		files = new Expander (t_("Files"));
		files.set_persistent (true);
		files.set_unique (true);

		LabelTool add_new_image = new LabelTool (t_("Add"));
		add_new_image.select_action.connect ((t) => {
			load_image ();
		});
		background_selection.add_tool (add_new_image);

		LabelTool remove_image = new LabelTool (t_("Remove"));
		background_selection.add_tool (remove_image);
		
		Tool select_background = new Tool ("select_background", t_("Select Background"));
		select_background.select_action.connect ((self) => {
		});
		
		select_background.editor_events = true;
		select_background.persistent = true;
		background_tools.add_tool (select_background);

		background_tools.add_tool (DrawingTools.move_background);
		background_tools.add_tool (DrawingTools.move_canvas);
		background_tools.add_tool (DrawingTools.background_scale);

		expanders.add (font_name);
		expanders.add (background_tools);
		expanders.add (DrawingTools.view_tools);
		expanders.add (DrawingTools.guideline_tools);
		expanders.add (background_selection);
		expanders.add (files);
	}

	public void remove_images () {
		files.tool.clear ();
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
		
		MainWindow.file_chooser (t_("Open"), fc, FileChooser.LOAD);
	}
	
	void add_image_file (string file_path) {
		Font font = BirdFont.get_current_font ();
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
		font.add_background_image (image);
		GlyphCanvas.redraw ();
		Toolbox.redraw_tool_box ();
	}
	
	public void add_image (BackgroundImage image) {
		LabelTool image_selection;
		double xc, yc;
		BackgroundTab bt;

		image_selection = new BackgroundSelection (image, image.name);
		image_selection.select_action.connect ((t) => {
			BackgroundTab background_tab = BackgroundTab.get_instance ();
			BackgroundSelection bg = (BackgroundSelection) t;
			background_tab.set_background_image (bg.img);
			background_tab.set_background_visible (true);
			ZoomTool.zoom_full_background_image ();
			GlyphCanvas.redraw ();		
		});
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
	}
	
	class BackgroundSelection : LabelTool {
		public BackgroundImage img;
		public BackgroundSelection (BackgroundImage img, string base_name) {
			base (base_name);
			this.img = img;
		}
	}
}

}
