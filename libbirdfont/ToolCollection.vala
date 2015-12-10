/*
	Copyright (C) 2013 Johan Mattsson

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

public abstract class ToolCollection : GLib.Object  {
	public double scroll = 0;
	public double content_height = 0;
	private Tool current_tool = new Tool ("no_icon");
	
	public abstract Gee.ArrayList<Expander> get_expanders ();

	public virtual Gee.ArrayList<string> get_displays () {
		return new Gee.ArrayList<string> ();
	}
	
	public void set_current_tool (Tool tool) {
		current_tool = tool;
	}
	
	public Tool get_current_tool () {
		return current_tool;
	}
	
	public void redraw () {
		foreach (Expander e in get_expanders ()) {
			e.redraw ();
		}
	}
	
	public virtual void selected () {
		reset_selection (current_tool);
		current_tool.set_selected (true);
	}

	public virtual void reset_selection (Tool current_tool) {
	}
}

}
