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

using Cairo;

namespace BirdFont {

public class Dialog : Widget {

	public bool visible { get; set; }

	public Dialog () {
		visible = false;
	}

	public override void draw (Context cr) {	
	}

	public override double get_height () {
		return 0;	
	}

	public override double get_width () {
		return 0;	
	}
	
	public virtual void button_press (uint button, double x, double y) {
	}
	
}

}
