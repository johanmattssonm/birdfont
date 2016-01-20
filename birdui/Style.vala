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
using SvgBird;
using Gee;
using Cairo;

namespace Bird {

public class Style : GLib.Object {
	public SvgStyle svg_style;
	
	public Style () {
		svg_style = new SvgStyle ();
	}
	
	public Style.for_svg (SvgStyle svg_style) {
		this.svg_style = svg_style;
	}
}

}
