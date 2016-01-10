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
		
		string color = (!) svg_color;
		uint32 c;
		string[] arguments;
		Color parsed = new Color (0, 0, 0, 1);

		if (color == "none") {
			return null;
		}
		
		if (!color.has_prefix ("#")) {
			color = get_hex_for_name (color);
		}
		
		color = color.replace ("#", "");
			
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
	
	public static string get_hex_for_name (string name) {
		string color = name.down ();
		
		if (color == "black") return "#000000";
		if (color == "silver") return "#C0C0C0";
		if (color == "gray") return "#808080";
		if (color == "maroon") return "#800000";
		if (color == "red") return "#FF0000";
		if (color == "purple") return "#800080";
		if (color == "white") return "#FFFFFF";
		if (color == "fuchsia") return "#FF00FF";
		if (color == "green") return "#008000";
		if (color == "lime") return "#00FF00";
		if (color == "olive") return "#808000";
		if (color == "yellow") return "#FFFF00";
		if (color == "navy") return "#000080";
		if (color == "blue") return "#0000FF";
		if (color == "teal") return "#008080";
		if (color == "aqua") return "#00FFFF";
		if (color == "aliceblue") return "#f0f8ff";
		if (color == "antiquewhite") return "#faebd7";
		if (color == "aqua") return "#00ffff";
		if (color == "aquamarine") return "#7fffd4";
		if (color == "azure") return "#f0ffff";
		if (color == "beige") return "#f5f5dc";
		if (color == "bisque") return "#ffe4c4";
		if (color == "black") return "#000000";
		if (color == "blanchedalmond") return "#ffebcd";
		if (color == "blue") return "#0000ff";
		if (color == "blueviolet") return "#8a2be2";
		if (color == "brown") return "#a52a2a";
		if (color == "burlywood") return "#deb887";
		if (color == "cadetblue") return "#5f9ea0";
		if (color == "chartreuse") return "#7fff00";
		if (color == "chocolate") return "#d2691e";
		if (color == "coral") return "#ff7f50";
		if (color == "cornflowerblue") return "#6495ed";
		if (color == "cornsilk") return "#fff8dc";
		if (color == "crimson") return "#dc143c";
		if (color == "cyan") return "#00ffff";
		if (color == "darkblue") return "#00008b";
		if (color == "darkcyan") return "#008b8b";
		if (color == "darkgoldenrod") return "#b8860b";
		if (color == "darkgray") return "#a9a9a9";
		if (color == "darkgreen") return "#006400";
		if (color == "darkgrey") return "#a9a9a9";
		if (color == "darkkhaki") return "#bdb76b";
		if (color == "darkmagenta") return "#8b008b";
		if (color == "darkolivegreen") return "#556b2f";
		if (color == "darkorange") return "#ff8c00";
		if (color == "darkorchid") return "#9932cc";
		if (color == "darkred") return "#8b0000";
		if (color == "darksalmon") return "#e9967a";
		if (color == "darkseagreen") return "#8fbc8f";
		if (color == "darkslateblue") return "#483d8b";
		if (color == "darkslategray") return "#2f4f4f";
		if (color == "darkslategrey") return "#2f4f4f";
		if (color == "darkturquoise") return "#00ced1";
		if (color == "darkviolet") return "#9400d3";
		if (color == "deeppink") return "#ff1493";
		if (color == "deepskyblue") return "#00bfff";
		if (color == "dimgray") return "#696969";
		if (color == "dimgrey") return "#696969";
		if (color == "dodgerblue") return "#1e90ff";
		if (color == "firebrick") return "#b22222";
		if (color == "floralwhite") return "#fffaf0";
		if (color == "forestgreen") return "#228b22";
		if (color == "fuchsia") return "#ff00ff";
		if (color == "gainsboro") return "#dcdcdc";
		if (color == "ghostwhite") return "#f8f8ff";
		if (color == "gold") return "#ffd700";
		if (color == "goldenrod") return "#daa520";
		if (color == "gray") return "#808080";
		if (color == "green") return "#008000";
		if (color == "greenyellow") return "#adff2f";
		if (color == "grey") return "#808080";
		if (color == "honeydew") return "#f0fff0";
		if (color == "hotpink") return "#ff69b4";
		if (color == "indianred") return "#cd5c5c";
		if (color == "indigo") return "#4b0082";
		if (color == "ivory") return "#fffff0";
		if (color == "khaki") return "#f0e68c";
		if (color == "lavender") return "#e6e6fa";
		if (color == "lavenderblush") return "#fff0f5";
		if (color == "lawngreen") return "#7cfc00";
		if (color == "lemonchiffon") return "#fffacd";
		if (color == "lightblue") return "#add8e6";
		if (color == "lightcoral") return "#f08080";
		if (color == "lightcyan") return "#e0ffff";
		if (color == "lightgoldenrodyellow") return "#fafad2";
		if (color == "lightgray") return "#d3d3d3";
		if (color == "lightgreen") return "#90ee90";
		if (color == "lightgrey") return "#d3d3d3";
		if (color == "lightpink") return "#ffb6c1";
		if (color == "lightsalmon") return "#ffa07a";
		if (color == "lightseagreen") return "#20b2aa";
		if (color == "lightskyblue") return "#87cefa";
		if (color == "lightslategray") return "#778899";
		if (color == "lightslategrey") return "#778899";
		if (color == "lightsteelblue") return "#b0c4de";
		if (color == "lightyellow") return "#ffffe0";
		if (color == "lime") return "#00ff00";
		if (color == "limegreen") return "#32cd32";
		if (color == "linen") return "#faf0e6";
		if (color == "magenta") return "#ff00ff";
		if (color == "maroon") return "#800000";
		if (color == "mediumaquamarine") return "#66cdaa";
		if (color == "mediumblue") return "#0000cd";
		if (color == "mediumorchid") return "#ba55d3";
		if (color == "mediumpurple") return "#9370db";
		if (color == "mediumseagreen") return "#3cb371";
		if (color == "mediumslateblue") return "#7b68ee";
		if (color == "mediumspringgreen") return "#00fa9a";
		if (color == "mediumturquoise") return "#48d1cc";
		if (color == "mediumvioletred") return "#c71585";
		if (color == "midnightblue") return "#191970";
		if (color == "mintcream") return "#f5fffa";
		if (color == "mistyrose") return "#ffe4e1";
		if (color == "moccasin") return "#ffe4b5";
		if (color == "navajowhite") return "#ffdead";
		if (color == "navy") return "#000080";
		if (color == "oldlace") return "#fdf5e6";
		if (color == "olive") return "#808000";
		if (color == "olivedrab") return "#6b8e23";
		if (color == "orange") return "#ffa500";
		if (color == "orangered") return "#ff4500";
		if (color == "orchid") return "#da70d6";
		if (color == "palegoldenrod") return "#eee8aa";
		if (color == "palegreen") return "#98fb98";
		if (color == "paleturquoise") return "#afeeee";
		if (color == "palevioletred") return "#db7093";
		if (color == "papayawhip") return "#ffefd5";
		if (color == "peachpuff") return "#ffdab9";
		if (color == "peru") return "#cd853f";
		if (color == "pink") return "#ffc0cb";
		if (color == "plum") return "#dda0dd";
		if (color == "powderblue") return "#b0e0e6";
		if (color == "purple") return "#800080";
		if (color == "red") return "#ff0000";
		if (color == "rosybrown") return "#bc8f8f";
		if (color == "royalblue") return "#4169e1";
		if (color == "saddlebrown") return "#8b4513";
		if (color == "salmon") return "#fa8072";
		if (color == "sandybrown") return "#f4a460";
		if (color == "seagreen") return "#2e8b57";
		if (color == "seashell") return "#fff5ee";
		if (color == "sienna") return "#a0522d";
		if (color == "silver") return "#c0c0c0";
		if (color == "skyblue") return "#87ceeb";
		if (color == "slateblue") return "#6a5acd";
		if (color == "slategray") return "#708090";
		if (color == "slategrey") return "#708090";
		if (color == "snow") return "#fffafa";
		if (color == "springgreen") return "#00ff7f";
		if (color == "steelblue") return "#4682b4";
		if (color == "tan") return "#d2b48c";
		if (color == "teal") return "#008080";
		if (color == "thistle") return "#d8bfd8";
		if (color == "tomato") return "#ff6347";
		if (color == "turquoise") return "#40e0d0";
		if (color == "violet") return "#ee82ee";
		if (color == "wheat") return "#f5deb3";
		if (color == "white") return "#ffffff";
		if (color == "whitesmoke") return "#f5f5f5";
		if (color == "yellow") return "#ffff00";
		if (color == "yellowgreen") return "#9acd32";
		
		return "#000000";
	}
}

}
