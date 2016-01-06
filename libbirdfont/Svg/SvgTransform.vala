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

namespace BirdFont {

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
}

}
