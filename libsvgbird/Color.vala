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

namespace SvgBird {

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

	public static Color? parse (string? svg_color) {
		if (svg_color == null) {
			return null;
		}
		
		string color = ((!) svg_color).replace ("#", "");
		uint32 c;
		string[] arguments;
		Color parsed = new Color (0, 0, 0, 1);

		if (color == "none") {
			return null;
		}
		
		if (color.char_count () == 6) {
			color.scanf ("%x", out c);
			parsed.r = (uint8)((c & 0xFF0000) >> 16) / 254.0;
			parsed.g = (uint8)((c & 0x00FF00) >> 8)/ 254.0;
			parsed.b = (uint8)(c & 0x0000FF) / 254.0;
		} else if (color.char_count () == 3) {
			color.scanf ("%x", out c);
			parsed.r = (uint8)(((c & 0xF00) >> 4) | ((c & 0xF00) >> 8)) / 254.0;
			parsed.g = (uint8)((c & 0x0F0) | ((c & 0x0F0) >> 4)) / 254.0;
			parsed.b = (uint8)(((c & 0x00F) << 4) | (c & 0x00F)) / 254.0;
		} else if (color.index_of ("%") > -1) {
			color = color.replace ("rgb", "");
			color = color.replace (" ", "");
			color = color.replace ("\t", "");
			color = color.replace ("%", "");
			arguments = color.split (",");
			
			return_val_if_fail (arguments.length == 3, parsed);
			arguments[0].scanf ("%lf", out parsed.r);
			arguments[1].scanf ("%lf", out parsed.g);
			arguments[2].scanf ("%lf", out parsed.b);
		} else if (color.index_of ("rgb") > -1) {
			color = color.replace ("rgb", "");
			color = color.replace (" ", "");
			color = color.replace ("\t", "");
			arguments = color.split (",");
			
			return_val_if_fail (arguments.length == 3, parsed);
			
			int r, g, b;
			arguments[0].scanf ("%d", out r);
			parsed.r = r / 254.0;
			
			arguments[1].scanf ("%d", out g);
			parsed.g = g / 254.0;
			
			arguments[2].scanf ("%d", out b);
			parsed.b = b / 254.0;
		} else {
			warning ("Unknown color type: " + color);
		}
		
		
		return parsed;
 	}

	public string to_rgb_hex () {
		StringBuilder rgb = new StringBuilder ();
		rgb.append ("#");
		rgb.append_printf ("%x", (int) Math.rint (r  * 254));
		rgb.append_printf ("%x", (int) Math.rint (g  * 254));
		rgb.append_printf ("%x", (int) Math.rint (b  * 254));
		return rgb.str;
	}

	public string to_string () {
		StringBuilder rgba = new StringBuilder ();
		rgba.append (to_rgb_hex ());
		rgba.append_printf ("%x", (int) Math.rint (a  * 254));
		return rgba.str;
	}


	public Color copy () {
		return new Color (r, g, b, a);
	}

}

}
