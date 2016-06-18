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
	public Gee.ArrayList<ClipPath> clip_paths = new Gee.ArrayList<ClipPath> ();
	public Gee.ArrayList<Gradient> gradients = new Gee.ArrayList<Gradient> ();
	public Gee.ArrayList<RadialGradient> radial_gradients = new Gee.ArrayList<RadialGradient> ();
	public Gee.ArrayList<LinearGradient> linear_gradients = new Gee.ArrayList<LinearGradient> ();
	public StyleSheet style_sheet = new StyleSheet ();

	public void add_linear_gradient (LinearGradient g) {
		gradients.add (g);
		linear_gradients.add (g);
	}

	public void add_radial_gradient (RadialGradient g) {
		gradients.add (g);
		radial_gradients.add (g);
	}

	public ClipPath? get_clip_path_for_url (string? url) {
		if (url == null) {
			return null;
		}
		
		string tag_id = get_id_from_url ((!) url);
		return get_clip_path_for_id (tag_id);
	} 
	
	public ClipPath? get_clip_path_for_id (string id) {
		string tag_id;
		
		if (id.has_prefix ("#")) {
			tag_id = id.substring ("#".length);
		} else {
			tag_id = id;
		}
		
		foreach (ClipPath clip_path in clip_paths) {
			if (clip_path.id == tag_id) {
				return clip_path;
			}
		}
		
		return null;		
	}
	
	public static string get_id_from_url (string url) {
		if (unlikely (!is_url (url))) {
			return "";
		}

		int p1 = url.index_of ("(");
		if (unlikely (p1 == -1)) {
			warning ("Not an URL: " + url);
			return "";
		}

		int p2 = url.index_of (")");
		if (unlikely (p2 == -1 || p2 < p1)) {
			warning ("Not an URL: " +  url);
			return "";
		}
	
		p1 += "(".length;
		int length = p2 - p1;
		return url.substring (p1, length);
	}
	
	public Gradient? get_gradient_for_url (string? url) {
		if (url == null) {
			return null;
		}
		
		string tag_id = get_id_from_url ((!) url);
		return get_gradient_for_id (tag_id);
	}

	public Gradient? get_gradient_for_id (string id) {
		string tag_id;
		
		if (id.has_prefix ("#")) {
			tag_id = id.substring ("#".length);
		} else {
			tag_id = id;
		}
		
		tag_id = tag_id.down ();
		
		foreach (Gradient gradient in gradients) {
			if (gradient.id.down () == tag_id) {
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

	public Defs shallow_copy () {
		Defs d = new Defs ();
		
		foreach (Gradient g in gradients) {
			d.gradients.add (g);
		}

		foreach (RadialGradient g in radial_gradients) {
			d.radial_gradients.add (g);
		}

		foreach (LinearGradient g in linear_gradients) {
			d.linear_gradients.add (g);
		}
				
		d.style_sheet = style_sheet.shallow_copy ();
		
		return d;
	}

	public Defs copy () {
		Defs d = new Defs ();
		
		foreach (Gradient g in gradients) {
			Gradient gradient_copy = g.copy ();
			d.gradients.add (gradient_copy);
			
			if (gradient_copy is LinearGradient) {
				d.linear_gradients.add ((LinearGradient) gradient_copy);
			}

			if (gradient_copy is RadialGradient) {
				d.radial_gradients.add ((RadialGradient) gradient_copy);
			}
		}
		
		d.style_sheet = style_sheet.copy ();
		
		return d;
	}
}

}
