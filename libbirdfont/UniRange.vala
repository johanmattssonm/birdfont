/*
    Copyright (C) 2012, 2014 Johan Mattsson

    This library is free software; you can redistribute it and/or modify 
    it under the terms of the GNU Lesser General Public License as 
    published by the Free Software Foundation; either version 3 of the 
    License, or (at your option) any later version.

    This library is distributed in the hope that it will be useful, but 
    WITHOUT ANY WARRANTY; without even the implied warranty of 
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU 
    Lesser General Public License for more details.
*/

namespace BirdFont {
	
public class UniRange : GLib.Object {
	
	public unichar start;
	public unichar stop;
	
	public UniRange (unichar start, unichar stop) {
		this.start = start;
		this.stop = stop;
	}
	
	public unichar length () {
		return stop - start + 1;
	}

	public bool has_character (unichar c) {
		return (start <= c <= stop);
	}

	public unichar get_char (unichar index) {
		unichar result = start + index;
		
		if (unlikely (!(start <= result <= stop))) {
			warning ("Index out of range in UniRange (%u <= %u <= %u) (index: %u)\n", start, result, stop, index);
		}
		
		return result;
	}
}

}
