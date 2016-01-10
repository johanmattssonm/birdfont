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

public class SvgTransforms : GLib.Object {
	public Gee.ArrayList<SvgTransform> transforms;
	
	public SvgTransforms () {
		transforms = new Gee.ArrayList<SvgTransform> ();
	}

	public void add (SvgTransform transform) {
		transforms.add (transform);
	}
	
	public Matrix get_matrix () {
		Matrix matrix = Matrix.identity ();
		
		if (transforms.size == 0) {
			return Matrix.identity ();
		}
		
		matrix = transforms.get (0).get_matrix ();
		
		for (int i = 1; i < transforms.size; i++) {
			matrix.multiply (matrix, transforms.get (i).get_matrix ());
		}
		
		return matrix;
	}
}

}
