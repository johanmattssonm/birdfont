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

using SvgBird;

namespace BirdFont {

public class LayerUtils {
	
	public static PathList get_all_paths (Layer layer) {
		ObjectGroup objects = layer.get_all_objects ();
		PathList paths = new PathList ();
		
		foreach (SvgBird.Object o in objects) {
			if (o is PathObject) {
				PathObject p = (PathObject) o;
				paths.add (p.get_path ());
			}
		}
		
		return paths;
	}

	public static PathList get_visible_paths (Layer layer) {
		ObjectGroup objects = layer.get_visible_objects ();
		PathList paths = new PathList ();
		
		foreach (SvgBird.Object o in objects) {
			if (o is PathObject) {
				PathObject p = (PathObject) o;
				paths.add (p.get_path ());
			}
		}
		
		return paths;
	}
	
	public static void add_path (Layer layer, Path path) {
		PathObject p = new PathObject.for_path (path);
		layer.add_object (p);
	}

	public static void append_paths (Layer layer, PathList path_list) {
		foreach (Path p in path_list.paths) {
			add_path (layer, p);
		}
	}

	private static PathObject? get_object_path (Layer layer, Path path) {
		foreach (SvgBird.Object o in layer.objects) {
			if (o is PathObject) {
				PathObject p = (PathObject) o;
				if (p.get_path () == path) {
					return p;
				}
			}
		}
		
		return null;
	}
	
	public static void remove_path (Layer layer, Path path) {
		PathObject? p = get_object_path (layer, path);
		
		if (p != null) {
			layer.objects.remove ((!) p);
		}

		foreach (SvgBird.Layer sublayer in layer.get_sublayers ()) {
			remove_path (sublayer, path);
		}
	}

	public static PathList get_paths_in_layer (Layer layer) {
		PathList paths = new PathList ();
		
		foreach (SvgBird.Object object in layer.objects) {
			if (object is PathObject) {
				paths.add (((PathObject) object).get_path ());
			}
		}
		
		return paths;
	}
}

}
