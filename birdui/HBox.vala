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
using B;
using SvgBird;

namespace Bird {

class HBox : BoxLayout {
	public HBox (XmlElement layout, Defs defs) {
		base (layout, BoxOrientation.HORIZONTAL, defs);
	}
	
	public override string to_string () {
		return "HBox";
	}
}

}
