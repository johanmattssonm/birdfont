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
		base (tool.tip, tool.tip); // FIXME: untranslated tip.
		
		this.tool = tool;
		
		modifiers = tool.modifier_flag;
		key = tool.key;
		
		action.connect (() => {
			tool.select_action (tool);
		});
	}
}

}
