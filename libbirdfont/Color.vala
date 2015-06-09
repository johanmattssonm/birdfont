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

public class Color {
	public double r;
	public double g;
	public double b;
	public double a;
	
	public Color (double r, double g, double b, double a) {
		this.r = r;
		this.g = g;
		this.b = b;
		this.a = a;
	}

	public Color.hsba (double h, double s, double b, double a) {
		double q, p;

		if (s == 0) {
			r = b;
			g = b;
			this.b = b;
		} else {
			q = b < 0.5 ? b * (1 + s) : b + s - b * s;
			p = 2 * b - q;
			r = hue_to_rgb(p, q, h + 1f/3);
			g = hue_to_rgb(p, q, h);
			this.b = hue_to_rgb(p, q, h - 1f/3);
		}
		
		this.a = a;
	}

	static double hue_to_rgb (double p, double q, double t){
		if(t < 0) {
			t += 1;
		}
		
		if(t > 1) {
			t -= 1;
		}
		
		if(t < 1.0 / 6) {
			return p + (q - p) * 6 * t;
		} 
		
		if(t < 1.0 / 2) {
			return q;
		}
		
		if(t < 2.0 / 3) {
			return p + (q - p) * (2f/3 - t) * 6;
		}
		
		return p;
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
	
	public string to_string () {
		return @"r: $r, g: $g, b: $b, a: $a";
	}
	
	public Color copy () {
		return new Color (r, g, b, a);
	}

	public string to_rgb_hex () {
		string s = "#";
		s += Font.to_hex_code ((unichar) Math.rint (r  * 254));
		s += Font.to_hex_code ((unichar) Math.rint (g  * 254));
		s += Font.to_hex_code ((unichar) Math.rint (b  * 254));
		return s;
	}
}

}
