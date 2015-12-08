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
using Gee;

namespace BirdFont {

public class ScaledBackgroundPart : GLib.Object {
	public double scale;
	public int offset_x;
	public int offset_y;
	public ImageSurface image;
	
	public ScaledBackgroundPart (ImageSurface image, double scale, int offset_x, int offset_y) {
		this.image = image;
		this.scale = scale;
		this.offset_x = offset_x;
		this.offset_y = offset_y;
	}

	public double get_scale () {
		return scale;
	}
	
	public ImageSurface get_image () {
		return image;
	}
}

}
