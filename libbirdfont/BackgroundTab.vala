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

using Math;
using Cairo;

namespace BirdFont {

public class BackgroundTab : Glyph {
	
	static BackgroundTab singleton;
	
	public BackgroundTab () {
		base ("", '\0');
		singleton = this;

		Toolbox tools = MainWindow.get_toolbox ();
		ZoomTool z = (ZoomTool) tools.get_tool ("zoom_tool");
		z.store_current_view ();
		
		layers.add_layer (new Layer ());
	}

	public static BackgroundTab get_instance () {
		if (is_null (singleton)) {
			singleton = new BackgroundTab ();
		}
		return singleton;
	}

	public override string get_name () {
		return "Backgrounds";
	}

	public override string get_label () {
		return t_("Background Image");
	}
	
	public override void selected_canvas () {
		base.selected_canvas ();
		
		GlyphCanvas canvas = MainWindow.get_glyph_canvas ();
		GlyphCollection gc = new GlyphCollection ('\0', "");
		gc.add_glyph (this);
		canvas.set_current_glyph_collection (gc, false);
		DrawingTools.background_scale.set_tool_visibility (true);
		ZoomTool.zoom_full_background_image ();
	}
	
	public override void draw (WidgetAllocation allocation, Context cr) {
		base.draw (allocation, cr);
		Tool t = Toolbox.background_tools.select_background;
		t.draw_action (t, cr, this);
	}
}

}
