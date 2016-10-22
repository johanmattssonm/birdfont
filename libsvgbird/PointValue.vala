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

namespace SvgBird {

public static const uint32 POINT_NONE = 0;
public static const uint32 POINT_ARC = 1;
public static const uint32 POINT_CUBIC = 1 << 1;
public static const uint32 POINT_LINE = 1 << 2;
public static const uint32 POINT_NEXT_LINE = 1 << 3;
public static const uint32 POINT_PREVIOUS_LINE = 1 << 4;
public static const uint32 POINT_TYPE = POINT_ARC | POINT_CUBIC | POINT_LINE;

}
