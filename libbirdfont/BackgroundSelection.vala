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

public class BackgroundSelection : GLib.Object {
	
	public Glyph? assigned_glyph;
	public BackgroundImage image;
	public BackgroundImage parent_image;
	
	public double x;
	public double y;
	public double w;
	public double h;
	
	public BackgroundSelection (BackgroundImage img, BackgroundImage parent_img,
		double x, double y, double w, double h) {
			
		assigned_glyph = null;
		parent_image = parent_img;
		image = img;
		this.x = x;
		this.y = y;
		this.w = w;
		this.h = h;
	}
}

}
