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

using Cairo;

namespace SvgBird {

public class ClipPath : GLib.Object {
	Layer layer = new Layer ();
	
	public string id {
		get {
			return layer.id;
		}
	}
	
	public ClipPath (Layer layer) {
		this.layer = layer;
	}
	
	public void apply (Context cr) {
		layer.draw_outline (cr);
		cr.clip ();
	}
	
	public ClipPath copy () {
		ClipPath path = new ClipPath (layer);
		return path;
	}
}

}
