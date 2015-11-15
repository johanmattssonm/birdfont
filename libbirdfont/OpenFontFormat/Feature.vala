/*
	Copyright (C) 2015 Johan Mattsson

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

public class Feature : GLib.Object {
	
	public string tag;
	public Lookups lookups;
	public Gee.ArrayList<string> public_lookups = new Gee.ArrayList<string> ();
	
	public Feature (string tag, Lookups lookups) {
		this.tag = tag;
		this.lookups = lookups;
	}
	
	public void add_feature_lookup (string lookup_token) {
		public_lookups.add (lookup_token);
	}
	
	public int get_public_lookups () {
		return public_lookups.size;
	}
}

}
