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

namespace BirdFont {

public class Color : SvgBird.Color {
	public Color (double r, double g, double b, double a) {
		base (r, g, b, a);
	}

	public Color.create_copy (SvgBird.Color color) {
		base (color.r, color.g, color.b, color.a);
	}
	
	public Color.hsba (double h, double s, double v, double a) {
		base.hsva (h, s, v, a);
	}

	public static Color black () {
		return new Color (0, 0, 0, 1);
	}

	public static Color red () {
		return new Color (1, 0, 0, 1);
	}

	public static Color green () {
		return new Color (0, 1, 0, 1);
	}

	public static Color blue () {
		return new Color (0, 0, 1, 1);
	}

	public static Color yellow () {
		return new Color (222.0 / 255, 203.0 / 255, 43 / 255.0, 1);
	}

	public static Color brown () {
		return new Color (160.0 / 255, 90.0 / 255, 44.0 / 255, 1);
	}
	
	public static Color pink () {
		return new Color (247.0 / 255, 27.0 / 255, 113 / 255.0, 1);
	}
	
	public static Color white () {
		return new Color (1, 1, 1, 1);
	}
	
	public static Color grey () {
		return new Color (0.5, 0.5, 0.5, 1);
	}
	
	public static Color magenta () {
		return new Color (103.0 / 255, 33.0 / 255, 120.0 / 255, 1);
	}
		
	public new Color copy () {
		return new Color (r, g, b, a);
	}
}

}
