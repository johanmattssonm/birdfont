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

public class ObjectGroup : GLib.Object {
	public Gee.ArrayList<Object> objects;
	
	public ObjectGroup () {
		 objects = new Gee.ArrayList<Object> ();
	}

	public Gee.Iterator<Object> iterator () {
		return objects.iterator ();
	}

	public void remove (Object p) {
		objects.remove (p);
	}
	
	public void add (Object p) {
		objects.add (p);
	}
	
	public void clear () {
		objects.clear ();
	}

	public void append (ObjectGroup group) {
		foreach (Object o in group.objects) {
			objects.add (o);
		}
	}
	
	public ObjectGroup copy () {
		ObjectGroup objects_copy = new ObjectGroup ();
		
		foreach (Object o in objects) {
			objects_copy.add (o.copy ());
		}
		
		return objects_copy;
	}
}

}
