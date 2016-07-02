/*
	Copyright (C) 2016 Johan Mattsson

	This library is free software; you can redistribute it and/or modify 
	it under the terms of the GNU Lesser General Public License as 
	published by the Free Software Foundation; either version 3 of the 
	License, or (at your option) any later version.

	This library is distributed in the hope that it will be useful, but 
	WITHOUT ANY WARRANTY; without even the implied warranty of 
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU 
	Lesser General Public License for more details.
*/


using B;
using Cairo;
using Math;

namespace SvgBird {

public class ViewBox : GLib.Object {

	public double minx = 0;
	public double miny = 0;
	public double width = 0;
	public double height = 0;

	public ViewBox (double minx, double miny, double width, double height) {
		this.minx = minx;
		this.miny = miny;
		this.width = width;
		this.height = height;
	}
	
}

}
