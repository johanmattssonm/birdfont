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
	public Matrix rotation_matrix;
	public Gee.ArrayList<SvgTransform> transforms;
	
	public double x = 0;
	public double y = 0;
	public double rotation = 0;
	public double scale_x = 1;
	public double scale_y = 1;
	
	public SvgTransforms () {
		transforms = new Gee.ArrayList<SvgTransform> ();
		rotation_matrix = Matrix.identity ();
	}

	public void collapse_transforms () {
		SvgTransform transform = new SvgTransform.for_matrix (rotation_matrix);
		add (transform);
		
		rotation_matrix = Matrix.identity ();
		rotation = 0;
		
		Matrix collapsed = get_matrix ();
		SvgTransform transform_transform = new SvgTransform.for_matrix (collapsed);
		clear ();
		add (transform_transform);
	}

	public void clear () {
		transforms.clear ();
		rotation_matrix = Matrix.identity ();
		rotation = 0;
	}

	public void rotate (double theta, double x, double y) {
		rotation += theta;
		
		while (rotation > 2 * Math.PI) {
			rotation -= 2 * Math.PI;
		}

		while (rotation < -2 * Math.PI) {
			rotation += 2 * Math.PI;
		}

		rotation_matrix = Matrix.identity ();
		rotation_matrix.translate (x, y);
		rotation_matrix.rotate (rotation);
		rotation_matrix.translate (-x, -y);
	}

	public void resize (double x, double y) {
		scale_x += x;
		scale_y += y;
	}

	public SvgTransforms copy () {
		SvgTransforms copy_transforms = new SvgTransforms ();
		
		foreach (SvgTransform t in transforms) {
			copy_transforms.add (t.copy ());
		}
		
		return copy_transforms;
	}

	public void add (SvgTransform transform) {
		transforms.add (transform);
	}
	
	public Matrix get_matrix () {
		Matrix transformation_matrix = Matrix.identity ();
		
		for (int i = 0; i < transforms.size; i++) {
			Matrix part = transforms.get (i).get_matrix ();
			transformation_matrix.multiply (transformation_matrix, part);
		}

		transformation_matrix.multiply (transformation_matrix, rotation_matrix);

		return transformation_matrix;
	}
	
	public string to_string () {
		StringBuilder sb = new StringBuilder ();

		foreach (SvgTransform t in transforms) {
			sb.append (t.to_string ());
			sb.append (" ");
		}
		
		return sb.str;
	}
	
	public string get_xml () {
		StringBuilder svg = new StringBuilder ();
		
		foreach (SvgTransform transform in transforms) {
			svg.append (transform.get_xml ());
			svg.append (";");
		}
		
		return svg.str;
	}
}

}
