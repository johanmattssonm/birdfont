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

public class ThemeTools : ToolCollection  {
	public static Gee.ArrayList<Expander> expanders;
	public static ColorPicker color_picker;

	public ThemeTools () {
		expanders = new Gee.ArrayList<Expander> ();

		Expander font_name = new Expander ();
		font_name.add_tool (new FontName ());

		Expander color_tools = new Expander (t_("Color"));
		color_picker = new ColorPicker ();
		
		color_picker.fill_color_updated.connect (() => {
			Color	c = color_picker.get_fill_color ();
			ThemeTab.get_instance ().color_updated (c);
		});
		
		color_tools.add_tool (color_picker);
		
		expanders.add (font_name);					
		expanders.add (color_tools);
	}

	public override Gee.ArrayList<string> get_displays () {
		Gee.ArrayList<string> d = new Gee.ArrayList<string> ();
		return d;
	}
	
	public override Gee.ArrayList<Expander> get_expanders () {
		return expanders;
	}
}

}
