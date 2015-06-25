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

public class ToolItem : MenuItem {

	public Tool tool;

	public ToolItem (Tool tool) {
		base (tool.tip, tool.name);
		
		this.tool = tool;
		
		action.connect (() => {
			tool.select_action (tool);
		});
	}
	
	public string get_key_binding () {
		StringBuilder sb = new StringBuilder ();
		
		if (key == '\0') {
			return "".dup ();
		}
			
		if ((modifiers & CTRL) > 0) {
			sb.append ("Ctrl");
			sb.append ("+");
		}

		if ((modifiers & SHIFT) > 0) {
			sb.append (t_("Shift"));
			sb.append ("+");
		}

		if ((modifiers & ALT) > 0) {
			sb.append ("Alt");
			sb.append ("+");
		}

		if ((modifiers & LOGO) > 0) {
			sb.append ("Super");
			sb.append ("+");
		}
	
		sb.append_unichar (key);
		
		return sb.str;
	}
}

}
