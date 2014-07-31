/*
    Copyright (C) 2014 Johan Mattsson

    This library is free software; you can redistribute it and/or modify 
    it under the terms of the GNU Lesser General Public License as 
    published by the Free Software Foundation; either version 3 of the 
    License, or (at your option) any later version.

    This library is distributed in the hope that it will be useful, but 
    WITHOUT ANY WARRANTY; without even the implied warranty of 
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU 
    Lesser General Public License for more details.
*/
using Math;

namespace BirdFont {
	
/** GSUB pairwise positioning format 1. 
 * A class that stores kerning information for one letter. 
 */
public class PairFormat1 : GLib.Object {
	public uint16 left = -1;
	public Gee.ArrayList<Kern> pairs = new Gee.ArrayList<Kern> ();
}

}
