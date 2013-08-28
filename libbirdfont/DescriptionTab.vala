/*
    Copyright (C) 2012 2013 Johan Mattsson

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

/** Names and description for the TTF Name table.
 * The actual tab is implemented in the GTK window.
 */
public class DescriptionTab : FontDisplay {	
	public DescriptionTab () {
	}
	
	public override string get_name () {
		return "Description";
	}

	public override string get_label () {
		return _("Description");
	}

	public override string get_html () {
		return "".dup ();
	}
}

}
