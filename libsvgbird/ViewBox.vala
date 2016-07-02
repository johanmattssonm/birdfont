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

	public ViewBox (double minx, double miny, double width, double height,
		uint alignment, bool slice) {
			
		this.minx = minx;
		this.miny = miny;
		this.width = width;
		this.height = height;
		
		this.alignment = alignment;
		this.slice = slice;
	}
	
}

}
