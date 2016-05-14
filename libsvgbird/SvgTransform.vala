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
using Cairo;

namespace SvgBird {

public enum TransformType {
	NONE,
	TRANSLATE,
	MATRIX,
	SCALE
}

public class SvgTransform : GLib.Object {
	public TransformType type = TransformType.NONE;
	public Doubles arguments = new Doubles.for_capacity (10);
	
	public SvgTransform () {
	}

	public SvgTransform copy () {
		SvgTransform transform = new SvgTransform ();
		transform.type = type;
		transform.arguments = arguments.copy ();
		return transform;
	}

	public string to_string () {
		StringBuilder sb = new StringBuilder ();
		
		sb.append (@"$type");
		sb.append (" ");
		
		for (int i = 0; i < arguments.size; i++) {
			sb.append (@"$(arguments.get_double (i)) ");
		}

		return sb.str;
	}
		
	public Matrix get_matrix () {
		Matrix matrix;
		
		matrix = Matrix.identity ();
		
		if (type == TransformType.SCALE) {
			if (arguments.size == 1) {
				double s = arguments.get_double (0);
				matrix.scale (s, s);
				return matrix;
			} else if (arguments.size == 2) {
				double s0 = arguments.get_double (0);
				double s1 = arguments.get_double (1);
				matrix.scale (s0, s1);
			}
		} else if (type == TransformType.TRANSLATE) {
			if (arguments.size == 1) {
				double s = arguments.get_double (0);
				matrix.translate (s, 0);
			} else if (arguments.size == 2) {
				double s0 = arguments.get_double (0);
				double s1 = arguments.get_double (1);
				matrix.translate (s0, s1);
			}
		} else if (type == TransformType.MATRIX) {
			if (arguments.size == 6) {
				double s0 = arguments.get_double (0);
				double s1 = arguments.get_double (1);
				double s2 = arguments.get_double (2);
				double s3 = arguments.get_double (3);					
				double s4 = arguments.get_double (4);
				double s5 = arguments.get_double (5);
				
				matrix = Matrix (s0, s1, s2, s3, s4, s5);
			}
		}
		
		return matrix;
	}
}

}
