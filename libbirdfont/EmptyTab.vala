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

namespace BirdFont {

public class EmptyTab : FontDisplay {
	
	string name;
	string label;
	
	public EmptyTab (string name, string label) {
		this.name = name;
		this.label = label;
	}
	
	public override string get_name () {
		return name;
	}

	public override string get_label () {
		return label;
	}

	public override void draw (WidgetAllocation allocation, Context cr) {
		cr.save ();
		cr.set_source_rgba (242/255.0, 241/255.0, 240/255.0, 1);
		cr.rectangle (0, 0, allocation.width, allocation.height);
		cr.fill ();
		cr.restore ();
	}	
}

}
