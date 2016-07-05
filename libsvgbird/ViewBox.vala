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
using Math;

namespace SvgBird {

public class ViewBox : GLib.Object {

	public const uint NONE = 1;
	public const uint XMIN = 1 << 1;
	public const uint XMID = 1 << 2;
	public const uint XMAX = 1 << 3;
	public const uint YMIN = 1 << 4;
	public const uint YMID = 1 << 5;
	public const uint YMAX = 1 << 6;
	
	public const uint XMIN_YMIN = XMIN | YMIN;
	public const uint XMID_YMIN = XMID | YMIN;
	public const uint XMAX_YMIN = XMAX | YMIN;
	public const uint XMIN_YMID = XMIN | YMID;
	public const uint XMID_YMID = XMID | YMID;
	public const uint XMAX_YMID = XMAX | YMID;
	public const uint XMIN_YMAX = XMIN | YMAX;
	public const uint XMID_YMAX = XMID | YMAX;
	public const uint XMAX_YMAX = XMAX | YMAX;

	public double minx = 0;
	public double miny = 0;
	public double width = 0;
	public double height = 0;

	public uint alignment;
	public bool slice;

	public bool preserve_aspect_ratio;

	public ViewBox.empty () {
	}

	public ViewBox (double minx, double miny, double width, double height,
		uint alignment, bool slice, bool preserve_aspect_ratio) {
			
		this.minx = minx;
		this.miny = miny;
		this.width = width;
		this.height = height;
		
		this.alignment = alignment;
		this.slice = slice;
		this.preserve_aspect_ratio = preserve_aspect_ratio;
	}

	public ViewBox copy () {
		ViewBox box = new ViewBox.empty (); 
		
		box.minx = minx;
		box.miny = miny;
		box.width = width;
		box.height = height;
		
		box.alignment = alignment;
		box.slice = slice;
		box.preserve_aspect_ratio = preserve_aspect_ratio;
		
		return box;
	}

	public Matrix get_matrix (double original_width, double original_height) {
		double scale_x = 1;
		double scale_y = 1;
		double scale = 1;

		Matrix matrix = Matrix.identity ();

		if (original_width == 0  || original_height == 0 || width == 0 || height == 0) {
			return matrix;
		}
		
		matrix.translate (minx, miny);
		scale_x = original_width / width;
		scale_y = original_height / height;
		
		bool scale_width = scale_x > scale_y;
		
		if (scale_width) {
			scale = scale_y;
		} else {
			scale = scale_x;
		}
		
		if (preserve_aspect_ratio) {
			if ((alignment & ViewBox.XMID) > 0) {
				matrix.translate ((original_width - width * scale) / 2, 0);
			} else if ((alignment & ViewBox.XMAX) > 0) {
				matrix.translate ((original_width - width * scale), 0);
			}

			if ((alignment & ViewBox.YMID) > 0) {
				matrix.translate ((original_height - height * scale) / 2, 0);
			} else if ((alignment & ViewBox.YMAX) > 0) {
				matrix.translate ((original_height - height * scale), 0);
			}
		}

		if (!preserve_aspect_ratio) {
			matrix.scale (scale_x, scale_y);
		} else if (scale_width) {
			scale = scale_y;
			matrix.scale (scale, scale);
		} else {
			scale = scale_x;
			matrix.scale (scale, scale);
		}
		
		return matrix;
	}	
}

}
