/* Copyright (C) 1999 The Free Software Foundation
 *
 * Authors: Simon Budig <Simon.Budig@unix-ag.org> (original code)
 *          Federico Mena-Quintero <federico@gimp.org> (cleanup for GTK+)
 *          Jonathan Blandford <jrb@redhat.com> (cleanup for GTK+)
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the
 * Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 * Boston, MA 02111-1307, USA.
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

	public Color.hsba (double h, double s, double v, double a) {
		double hue, saturation, value;
		double f, p, q, t;

		this.a = a;

		if (s == 0.0) {
			r = v;
			g = v;
			b = v;
		} else {
			hue = h * 6.0;
			saturation = s;
			value = v;

			if (hue == 6.0) {
				hue = 0.0;
			}

			f = hue - (int) hue;
			p = value * (1.0 - saturation);
			q = value * (1.0 - saturation * f);
			t = value * (1.0 - saturation * (1.0 - f));

			switch ((int) hue) {
			case 0:
				r = value;
				g = t;
				b = p;
				break;

			case 1:
				r = q;
				g = value;
				b = p;
				break;

			case 2:
				r = p;
				g = value;
				b = t;
				break;

			case 3:
				r = p;
				g = q;
				b = value;
				break;

			case 4:
				r = t;
				g = p;
				b = value;
				break;

			case 5:
				r = value;
				g = p;
				b = q;
				break;

			default:
				assert_not_reached ();
			}
		}
	}

	public void to_hsva (out double h, out double s, out double v, out double a) {
		double red, green, blue;
		double min, max;
		double delta;

		a = this.a;
		
		red = r;
		green = g;
		blue = b;

		h = 0.0;

		if (red > green) {
			if (red > blue)
				max = red;
			else
				max = blue;

			if (green < blue)
				min = green;
			else
				min = blue;
		} else {
			if (green > blue)
				max = green;
			else
				max = blue;

			if (red < blue)
				min = red;
			else
				min = blue;
		}

		v = max;

		if (max != 0.0)
			s = (max - min) / max;
		else
			s = 0.0;

		if (s == 0.0)
			h = 0.0;
		else {
			delta = max - min;

			if (red == max)
				h = (green - blue) / delta;
			else if (green == max)
				h = 2 + (blue - red) / delta;
			else if (blue == max)
				h = 4 + (red - green) / delta;

			h /= 6.0;

			if (h < 0.0)
				h += 1.0;
			else if (h > 1.0)
				h -= 1.0;
		}
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
		s += Font.to_hex_code ((unichar) Math.rint (r * 255));
		s += Font.to_hex_code ((unichar) Math.rint (g * 255));
		s += Font.to_hex_code ((unichar) Math.rint (b * 255));
		return s;
	}
}

}
