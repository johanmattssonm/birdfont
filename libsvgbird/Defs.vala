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
using Math;

namespace SvgBird {

public class Defs {
	public Gee.ArrayList<Gradient> gradients = new Gee.ArrayList<Gradient> ();
	public StyleSheet style_sheet = new StyleSheet ();

	public void add (Gradient g) {
		gradients.add (g);
	}
	
	public Gradient? get_gradient_for_url (string? url) {
		if (url == null) {
			return null;
		}
		
		string tag_id = (!) url;

		if (unlikely (!is_url (tag_id))) {
			return null;
		}

		int p1 = tag_id.index_of ("(");
		if (unlikely (p1 == -1)) {
			warning ("Not an URL: " + tag_id);
			return null;
		}

		int p2 = tag_id.index_of (")");
		if (unlikely (p2 == -1 || p2 < p1)) {
			warning ("Not an URL: " +  tag_id);
			return null;
		}
	
		p1 += "(".length;
		int length = p2 - p1;
		tag_id = tag_id.substring (p1, length);
		
		return get_gradient_for_id (tag_id);
	} 

	public Gradient? get_gradient_for_id (string id) {
		string tag_id;
		
		if (id.has_prefix ("#")) {
			tag_id = id.substring ("#".length);
		} else {
			tag_id = id;
		}
		
		foreach (Gradient gradient in gradients) {
			if (gradient.id == tag_id) {
				return gradient;
			}
		}
		
		return null;		
	}

	public static bool is_url (string? attribute) {
		if (attribute == null) {
			return false;
		}
		
		return ((!) attribute).has_prefix ("url");
	}

	public Defs copy () {
		Defs d = new Defs ();
		
		foreach (Gradient g in gradients) {
			d.add (g);
		}
		
		return d;
	}

}

}
