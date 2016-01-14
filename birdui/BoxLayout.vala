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
	
	public BoxLayout (BoxOrientation orientation) {
		base ();
		this.orientation = orientation;
	}

	public BoxLayout.for_tag (XmlElement layout_tag, BoxOrientation orientation) {
		base.for_tag (layout_tag);
		this.orientation = orientation;
	}
		
	public override void layout () {
		switch (orientation) {
		case BoxOrientation.HORIZONTAL:
			layout_horizontal ();
			break;
		case BoxOrientation.VERTICAL:
			layout_vertical ();
			break;
		}
	}

	void layout_horizontal () {
		double child_x = 0;
		double child_y = 0;
		
		foreach (Component component in components) {
			component.x = child_x;
			component.y = child_y;
			component.layout ();
			component.apply_padding ();
			
			child_x += component.padded_width;
			
			if (component.height > height) {
				height = component.height;
			}
		}
		
		width = child_x;
	}

	void layout_vertical () {
		double child_x = 0;
		double child_y = 0;
		
		foreach (Component component in components) {
			component.x = child_x;
			component.y = child_y;
			component.layout ();
			component.apply_padding ();

			child_y += component.padded_height;
						
			if (component.width > width) {
				width = component.width;
			}
		}
		
		height = child_y;
	}

	public override string to_string () {
		return "BoxLayout";
	}
}

}
