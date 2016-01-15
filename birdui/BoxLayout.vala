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
	
	void set_size_limits (Component component) {
		string? min_width = component.style.get_css_property ("min-width");
		if (min_width != null) {
			double w = SvgFile.parse_number (min_width);
			if (component.width < w) {
				component.width = w;
			}
		}

		string? min_height = component.style.get_css_property ("min-height");
		if (min_height != null) {
			double h = SvgFile.parse_number (min_height);
			
			if (component.height < h) {
				component.height = h;
			}
		}
		
		string? max_width = component.style.get_css_property ("max-width");
		if (max_width != null) {
			double w = SvgFile.parse_number (max_width);
			
			if (component.width > w) {
				component.width = w;
			}
		}

		string? max_height = component.style.get_css_property ("max-height");
		if (max_height != null) {
			double h = SvgFile.parse_number (max_height);
			
			if (component.height > h) {
				component.height = h;
			}
		}
	}
	
	public override void layout () {
		double child_x = 0;
		double child_y = 0;
		
		foreach (Component component in components) {
			component.x = child_x;
			component.y = child_y;
			component.layout ();
			component.apply_padding ();
			set_size_limits (component);

			if (orientation == BoxOrientation.HORIZONTAL) {
				child_x += component.padded_width;
				
				if (component.height > height) {
					height = component.height;
				}
			} else {
				child_y += component.padded_height;
							
				if (component.width > width) {
					width = component.width;
				}				
			}
		}
		
		if (orientation == BoxOrientation.HORIZONTAL) {
			width = child_x;
		} else {
			height = child_y;
		}
	}

	public override string to_string () {
		return "BoxLayout";
	}
}

}
