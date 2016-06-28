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

using Gee;
using SvgBird;
using B;
using Cairo;

namespace Bird {

public enum BoxOrientation {
	HORIZONTAL,
	VERTICAL
}

class BoxLayout : Component {

	public BoxOrientation orientation { get; private set; }
	
	public BoxLayout (XmlElement layout_tag, BoxOrientation orientation, Defs defs) {
		base (layout_tag, defs);
		this.orientation = orientation;
	}

	public override void draw (Context cairo) {
		cairo.save ();
		cairo.translate (x, y);
		clip (cairo);
		
		foreach (Component component in components) {
			component.draw (cairo);
		}

		cairo.restore ();
	}
			
	bool is_width_remainder (Component component) {
		return component.style.property_equals ("width", "remainder");
	}

	bool is_height_remainder (Component component) {
		return component.style.property_equals ("height", "remainder");
	}

	/** The smallest size this layout can be. */
	public override void get_min_size (out double min_width, out double min_height) {
		min_width = 0;
		min_height = 0;
		
		if (orientation == BoxOrientation.HORIZONTAL) {
			foreach (Component component in components) {
				double w, h;
				
				component.get_min_size (out w, out h);
				min_width += w;
				
				if (h > min_height) {
					min_height = h;
				}
			}	
		} else {
			foreach (Component component in components) {
				double w, h;
				
				component.get_min_size (out w, out h);	
				min_height += h;
				
				if (w > min_width) {
					min_width = w;
				}
			}
		}
		
		min_width += get_padding_left ();
		min_width += get_padding_right ();
		min_height += get_padding_top ();
		min_height += get_padding_bottom ();
		
		limit_size (ref min_width, ref min_height);
	}

	public override void layout (double parent_width, double parent_height) {
		double w, h;
		
		get_min_size (out w, out h);
		int remainders = count_remainders ();
		
		if (!is_width_remainder (this)) {
			width = w;
		}
		
		if (!is_height_remainder (this)) {
			height = h;
		}
		
		if (remainders > 0) {
			double remainder_size;
			
			if (orientation == BoxOrientation.HORIZONTAL) {
				remainder_size = (parent_width - w) / remainders;
				layout_variable_size (remainder_size, parent_height);
			} else {
				remainder_size = (parent_height - h) / remainders;
				layout_variable_size (remainder_size, parent_width);
			}
		}
		
		if (orientation == BoxOrientation.HORIZONTAL) {
			foreach (Component component in components) {
				component.layout (parent_width, h);
			}
		} else {
			foreach (Component component in components) {
				component.layout (w, parent_height);
			}
		}
		
		layout_positions ();
	}
	
	int count_remainders () {
		int remainders = 0;
		
		if (orientation == BoxOrientation.HORIZONTAL) {
			foreach (Component component in components) {
				if (is_width_remainder (component)) {
					remainders++;
				}
			}
		} else {
			foreach (Component component in components) {
				if (is_height_remainder (component)) {
					remainders++;
				}
			}
		}
		
		return remainders;
	}
	
	void layout_variable_size (double remainder_size, double fixed_size) {
		double w, h;
		
		w = 0;
		h = 0;
		foreach (Component component in components) {
			bool width_remainder = is_width_remainder (component);
			bool height_remainder = is_height_remainder (component);
			
			if (width_remainder && orientation == BoxOrientation.HORIZONTAL) {
				w = remainder_size;
				w -= component.get_padding_left ();
				w -= component.get_padding_right ();
				h = fixed_size;
			}
			
			if (height_remainder && orientation == BoxOrientation.VERTICAL) {
				w = fixed_size;
				h = remainder_size;
				h -= component.get_padding_top ();
				h -= component.get_padding_bottom ();
			}
			
			if (width_remainder || height_remainder) {
				double min_width, min_height;
				component.get_min_size (out min_width, out min_height);
				
				if (w < min_width) {
					w = min_width;
				}
				
				if (h < min_height) {
					h = min_height;
				}
				
				component.limit_size (ref w, ref h);
				component.width = w;
				component.height = h;
			}
		}
	}

	void layout_positions () {
		double child_x = 0;
		double child_y = 0;

		foreach (Component component in components) {
			component.x = child_x + component.get_padding_left ();
			component.y = child_y + component.get_padding_top ();

			if (orientation == BoxOrientation.HORIZONTAL) {
				child_x = component.x + component.padded_width + get_padding_right ();
			} else {
				child_y = component.y + component.padded_height  + get_padding_bottom ();
			}
		}
	}

	public override string to_string () {
		return "BoxLayout";
	}
}

}
