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

[CCode (cheader_filename="point_value.h")]
public extern struct PointValue {
    uchar type;
    double value;
}

public static const uchar NONE = 0;
public static const uchar ARC = 1;
public static const uchar CUBIC = 2;
public static const uchar LINE = 3;

}
