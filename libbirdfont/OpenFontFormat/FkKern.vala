/*
	Copyright (C) 2022 Johan Mattsson

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

public class FkKern : GLib.Object {
	public int left;
	public int right;
	public double kerning;
	
	public FkKern (int l, int r, double k) {
		if (l < 0) {
			warning ("Negative gid (left)");
		}

		if (r < 0) {
			warning ("Negative gid (right)");
		}
		
		left = l;
		right = r;
		kerning = k;
	}
	
	public FkKern copy () {
		return new FkKern (left, right, kerning);
	}
	
	public string to_string () {
		return @"left: $left, right: $right, kerning: $kerning";
	}
}

}
