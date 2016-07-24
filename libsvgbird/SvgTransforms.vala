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
	public Matrix size_matrix;
	public Gee.ArrayList<SvgTransform> transforms;
	
	public double rotation = 0;
	public double total_rotation = 0;
	public double translate_x = 0;
	public double translate_y = 0;
	
	public SvgTransforms () {
		transforms = new Gee.ArrayList<SvgTransform> ();
		rotation_matrix = Matrix.identity ();
		size_matrix = Matrix.identity ();
	}

	public void clear_rotation () {
		rotation = 0;
		total_rotation = 0;
		rotation_matrix = Matrix.identity ();	
	}

	public double get_rotation () {
		Matrix m = get_matrix ();
		double w = 1;
		double h = 1;
		m.transform_distance (ref w, ref h);
		return Math.atan2 (h, w);
	}

	public void collapse_transforms () {
		Matrix collapsed = get_matrix ();
		
		translate_x	= 0;
		translate_y	= 0;

		rotation_matrix = Matrix.identity ();
		rotation = 0;

		size_matrix = Matrix.identity ();
		
		clear ();
		
		SvgTransform collapsed_transform = new SvgTransform.for_matrix (collapsed);
		add (collapsed_transform);
	}

	public void clear () {
		transforms.clear ();
		
		rotation_matrix = Matrix.identity ();
		rotation = 0;
		
		size_matrix = Matrix.identity ();
		
		translate_x = 0;
		translate_y = 0;
	}

	public void translate (double x, double y) {
		translate_x += x;
		translate_y += y;
	}

	public void rotate (double theta, double x, double y) {
		rotation += theta;
		total_rotation += theta;
		
		while (rotation > 2 * Math.PI) {
			rotation -= 2 * Math.PI;
		}

		while (rotation < -2 * Math.PI) {
			rotation += 2 * Math.PI;
		}

		while (total_rotation > 2 * Math.PI) {
			total_rotation -= 2 * Math.PI;
		}

		while (total_rotation < -2 * Math.PI) {
			total_rotation += 2 * Math.PI;
		}

		rotation_matrix = Matrix.identity ();
		rotation_matrix.translate (x, y);
		rotation_matrix.rotate (rotation);
		rotation_matrix.translate (-x, -y);
	}

	public void resize (double scale_x, double scale_y, double x, double y) {
		if (scale_x <= 0 || scale_y <= 0) {
			return;
		}
		
		double x2 = x;
		double y2 = y;
		
		size_matrix = Matrix.identity ();
		size_matrix.scale (scale_x, scale_y);
		size_matrix.transform_point (ref x2, ref y2);

		double dx = x - x2;
		double dy = y - y2;
		
		size_matrix.translate (dx / scale_x, dy / scale_y);
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

		transformation_matrix.translate (translate_x, translate_y);

		transformation_matrix.multiply (transformation_matrix, rotation_matrix);
		transformation_matrix.multiply (transformation_matrix, size_matrix);

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
		bool first = true;
		
		foreach (SvgTransform transform in transforms) {
			if (!first) {
				svg.append (" ");
			}
			
			svg.append (transform.get_xml ());
			first = false;
		}
		
		return svg.str;
	}
}

}
