/*
	Copyright (C) 2015 Johan Mattsson

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

public class HiddenTools : ToolCollection  {

	public Gee.ArrayList<Expander> expanders;
	public Expander hidden_expander;

	public static Tool bezier_line;
	public static Tool bezier_corner;
	public static Tool move_along_axis;

	public HiddenTools () {
		hidden_expander = new Expander ();
		expanders = new Gee.ArrayList<Expander> ();
		
		Tool zoom_in = new Tool ("zoom_in", t_("Zoom in"));
		zoom_in.select_action.connect ((self) => {
			DrawingTools.zoom_tool.store_current_view ();
			GlyphCanvas.current_display.zoom_in ();
		});
		hidden_expander.add_tool (zoom_in);
		
		Tool zoom_out = new Tool ("zoom_out", t_("Zoom out"));
		zoom_out.select_action.connect ((self) => {
			DrawingTools.zoom_tool.store_current_view ();
			GlyphCanvas.current_display.zoom_out ();
		});
		hidden_expander.add_tool (zoom_out);

		bezier_line = new Tool ("bezier_line", t_("Convert the last segment to a straight line"));
		bezier_line.select_action.connect ((self) => {
			DrawingTools.bezier_tool.switch_to_line_mode ();
		});
		bezier_line.is_tool_modifier = true;
		hidden_expander.add_tool (bezier_line);
		bezier_line.set_tool_visibility (false);

		bezier_corner = new Tool ("bezier_corner", t_("Convert the last control point to a corner node"));
		bezier_corner.select_action.connect ((self) => {
			DrawingTools.bezier_tool.create_corner ();
		});
		bezier_corner.is_tool_modifier = true;
		hidden_expander.add_tool (bezier_corner);
		bezier_corner.set_tool_visibility (false);

		move_along_axis = new Tool ("bezier", t_("Move handle along axis"));
		move_along_axis.select_action.connect ((self) => {
			Tool t = MainWindow.get_toolbox ().get_current_tool ();
			if (t is BezierTool) {
				DrawingTools.bezier_tool.move_handle_on_axis ();
			} else if (t is PenTool || t is PointTool) {
				PenTool.move_handle_on_axis ();
			}
		});
		move_along_axis.is_tool_modifier = true;
		hidden_expander.add_tool (move_along_axis);
		move_along_axis.set_tool_visibility (false);
								
		expanders.add (hidden_expander);
	}

	public override Gee.ArrayList<Expander> get_expanders () {
		return expanders;
	}
}

}
