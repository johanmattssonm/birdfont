/*
    Copyright (C) 2015 Johan Mattsson

    This library is free software; you can redistribute it and/or modify 
    it under the terms of the GNU Lesser General Public License as 
    published by the Free Software Foundation; either version 3 of the 
    License, or (at your option) any later version.

    This library is distributed in the hope that it will be useful, but 
    WITHOUT ANY WARRANTY; without even the implied warranty of 
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU 
    Lesser General Public License for more details.
*/

using Gee;

namespace Bird {

public class XmlData : XmlString {
	public Gee.ArrayList<int> start_tags;
	
	public XmlData (char* data, int length) {
		base (data, length);
		start_tags = new Gee.ArrayList<int> ();
		index_start_tags ();
	}
	
	public int get_index (XmlString start) {
		int offset = (int) ((size_t) start.data - (size_t) data);
		return offset;
	}
	
	public int find_next_tag_token (XmlString start, int index) {
		int offset = get_index (start);
		int start_index = offset + index;
		int new_index;
		int j = 0;
		
		if (start_index >= length) {
			return -1;
		}
		
		foreach (int i in start_tags) {
			new_index = i - offset;
			if (new_index > start_index) {
				return new_index;
			}
		}
		
		warning ("No token not found.");
		
		return -1;
	}

	void index_start_tags () {
		const char first_bit = 1 << 7;
		int i = 0;
		char* d = data;
 		
 		while (d[i] != '\0') {
			if ((int) (d[i] & first_bit) == 0) {
				if (d[i] == '<') {
					start_tags.add (i);
				}
			}
			i++;
		}
	}
}

}
