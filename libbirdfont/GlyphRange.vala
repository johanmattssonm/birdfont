/*
	Copyright (C) 2012 2014 2015 Johan Mattsson

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

public class GlyphRange {
	
	public string name {get; set;}
	
	public Gee.ArrayList<UniRange> ranges;
	
	/** Glyphs without a corresponding unicode value (ligatures). */
	public Gee.ArrayList<string> unassigned;
	
	uint32 len = 0;
	
	bool range_is_class = false;
	uint32* range_index = null;
	int index_size = 0;
	
	public GlyphRange () {
		ranges = new Gee.ArrayList<UniRange> ();
		unassigned = new Gee.ArrayList<string> ();
		name = "No name";
	}
	
	~GlyphRange () {
		if (range_index != null) {
			delete range_index;
		}
	}
	
	private void generate_unirange_index () {
		if (range_index != null) {
			delete range_index;
		}
		
		index_size = ranges.size;
		range_index = new uint32[index_size];
		
		int i = 0;
		uint32 next_index = 0;
		
		foreach (UniRange range in ranges) {
			range_index[i] = next_index;
			next_index += (uint32) range.length ();
			i++;
		}
	}
	
	public void add_unassigned (string glyph_name) {
		unassigned.add (glyph_name);
	}
	
	public bool is_class () {
		return range_is_class || len > 1;
	}
	
	public void set_class (bool c) {
		range_is_class = true;
	}
	
	public bool is_empty () {
		return len == 0;
	}
	
	public void empty () {
		unassigned.clear ();
		ranges.clear ();
		len = 0;
		generate_unirange_index ();
	}
	
	public unowned Gee.ArrayList<UniRange> get_ranges () {
		return ranges;
	}
		
	// sort by unicode value
	public void sort () {
		ranges.sort ((a, b) => {
			UniRange first, next;
			bool r;
			
			first = (UniRange) a;
			next = (UniRange) b;
			
			r = first.start > next.start;
			return_val_if_fail (first.start != next.start, 0);
			
			return (r) ? 1 : -1;
		});
		
		generate_unirange_index ();
	}
	
	public void add_single (unichar c) {
		add_range (c, c);
	}
	
	public uint32 get_length () {
		uint32 l = len;
		l += unassigned.size;
		return l;
	}
	
	public void add_range (unichar start, unichar stop) {
		unichar b, s;
		if (unique (start, stop)) {
			append_range (start, stop);
		} else {
			
			// make sure this range does not overlap existing ranges
			b = start;
			s = b;
			if (!unique (b, b)) {			
				while (b < stop) {
					if (!unique (b, b)) {
						b++;
					} else {
						if (s != b) {
							add_range (b, stop);
						}
						
						b++;
						s = b;
					}
				}
			} else {
				while (b < stop) {
					if (unique (b, b)) {
						b++;
					} else {
						if (s != b) {
							add_range (start, b - 1);
						}
						
						b++;
						s = b;
					}
				}				
			}
		}
		
		generate_unirange_index ();
	}
	
	/** Parse ranges on the form a-z. Single characters can be added as well as 
	 * multiple ranges separated by space. The word "space" is used to kern against 
	 * the space character and the word "divis" is used to kern against "-".
	 * @param ranges unicode ranges
	 */
	public void parse_ranges (string ranges) throws MarkupError {
		parse_range_string (ranges);
		generate_unirange_index ();
	}
	
	private void parse_range_string (string ranges) throws MarkupError {
		string[] r;
				
		if (ranges == " ") {
			add_single (' ');
		}
		
		r = ranges.split (" ");
		
		foreach (string w in r) {
			w = w.replace (" ", "");
			
			if (w == "") {
				continue;
			}
			
			if (w.char_count () == 1) {
				unichar c = w.get_char_validated ();
				
				if (c > 0) {
					add_single (c);
				}
			} else if (w == "space") {
				add_single (' ');
			} else if (w == "divis") {
				add_single ('-');
			} else if (w == "null") {
				add_single ('\0');
			} else if (w.index_of ("-") > -1) {
				parse_range (w);
			} else if (w == "quote") {
				add_single ('"');
			} else if (w == "ampersand") {
				add_single ('&');
			} else {
				unassigned.add (w);
			}
		}
	}

	/** A readable representation of ranges, see parse_ranges for parsing 
	 * this string. This function is used for storing ranges in th .bf format.
	 */
	public string get_all_ranges () {
		bool first = true;
		StringBuilder s = new StringBuilder ();
		foreach (UniRange u in ranges) {
			if (!first) {
				s.append (" ");
			}
			
			if (u.start == u.stop) {
				s.append (get_serialized_char (u.start));
			} else {
				s.append (get_serialized_char (u.start));
				s.append ("-");
				s.append (get_serialized_char (u.stop));
			}
			
			first = false;
		}

		foreach (string ur in unassigned) {
			if (!first) {
				s.append (" ");
			}
			
			s.append (ur);
			
			first = false;
		}
		
		return s.str;
	}
	
	public static string serialize (string s) {
		if (s == "space") {
			return s;
		}

		if (s == "divis") {
			return s;
		}

		if (s == "null") {
			return s;
		}

		if (s == "quote") {
			return s;
		}

		if (s == "ampersand") {
			return s;
		}

		if (s == "&quot;") {
			return s;
		}

		if (s == "&amp;") {
			return s;
		}

		if (s == "&lt;") {
			return s;
		}

		if (s == "&gt;") {
			return s;
		}
									
		if (s.char_count () > 1) {
			return s; // ligature
		}
		
		return get_serialized_char (s.get_char (0));
	}
	
	public static string get_serialized_char (unichar c) {
		StringBuilder s = new StringBuilder ();

		if (c == '&') {
			return "&amp;";
		}

		if (c == '<') {
			return "&lt;";
		}

		if (c == '>') {
			return "&gt;";
		}
		
		if (c == ' ') {
			return "space";
		}

		if (c == '-') {
			return "divis";
		}

		if (c == '\0') {
			return "null";
		}

		if (c == '"') {
			return "quote";
		}

		if (c == '&') {
			return "ampersand";
		}

		s.append_unichar (c);	
		return s.str;	
	}
	
	public static string unserialize (string c) {
		if (c == "&quot;") {
			return "\"";
		}

		if (c == "&amp;") {
			return "&";
		}

		if (c == "&lt;") {
			return "<";
		}

		if (c == "&gt;") {
			return ">";
		}
		
		if (c == "space") {
			return " ";
		}

		if (c == "divis") {
			return "-";
		}

		if (c == "null") {
			return "\0";
		}

		if (c == "quote") {
			return "\"";
		}

		if (c == "ampersand") {
			return "&";
		}
				
		return c;
	}
	
	private void parse_range (string s) throws MarkupError {
		string[] r = s.split ("-");
		bool null_range = false;
	
		if (r.length == 2 && r[0] == "null" && r[1] == "null") {
			null_range = true;
		} else if (r.length == 2 && r[0] == "null" &&  unserialize (r[1]).char_count () == 1) {
			null_range = true;
		} 
		
		if (!null_range) {
			if (r.length != 2
				|| unserialize (r[0]).char_count () != 1 
				|| unserialize (r[1]).char_count () != 1) {
				throw new MarkupError.PARSE (@"$s is not a valid range, it should be on the form A-Z.");
			}
		}
		
		append_range (unserialize (r[0]).get_char (), unserialize (r[1]).get_char ());
	}
	
	private void append_range (unichar start, unichar stop) {
		UniRange r;
		r = insert_range (start, stop); // insert a unique range
		merge_range (r);
	}
	
	private void merge_range (UniRange r) {
		Gee.ArrayList<UniRange> deleted = new Gee.ArrayList<UniRange>  ();
		Gee.ArrayList<UniRange> merged = new Gee.ArrayList<UniRange>  ();
		bool updated = false;
		
		foreach (UniRange u in ranges) {
			if (u == r) {
				continue;
			}
			
			if (u.start == r.stop + 1) {
				u.start = r.start;
				deleted.add (r);
				merged.add (u);
				break;
			}
			
			if (u.stop == r.start - 1) {
				u.stop = r.stop;
				deleted.add (r);
				merged.add (u);
				break;
			}
		}

		updated = merged.size > 0;

		foreach (UniRange m in deleted) {
			while (ranges.remove (m));
		}
				
		foreach (UniRange m in merged) {
			merge_range (m);
		}
		
		if (updated) {
			merge_range (r);
		}
	}
	
	/** Find a range which contains index. */
	private void get_unirange_index (uint32 index, out UniRange? range, out uint32 range_start_index) {
		int lower = 0;
		int upper = index_size - 1;
		int i = (lower + upper) / 2;
		int end = index_size - 1;
		
		range_start_index = -1;
		range = null;
		
		if (unlikely (ranges.size != index_size)) {
			warning (@"Range size does not match index size: $(ranges.size) != $index_size");
		}
		
		while (true) {
			if (i == end && range_index[i] <= index) {
				range_start_index = range_index[i];
				range = ranges.get (i);
				break;
			} else if (i != end && range_index[i] <= index && range_index[i + 1] > index) {
				range_start_index = range_index[i];
				range = ranges.get (i);
				break;
			}
			
			if (lower >= upper) {
				break;
			}
			
			if (range_index[i] < index) {
				lower = i + 1;
			} else {
				upper = i - 1;
			}
			
			i = (lower + upper) / 2;
		}
	}
	
	public string get_char (uint32 index) {
		StringBuilder sb;
		
		sb = new StringBuilder ();
		sb.append_unichar (get_character (index));
		
		return sb.str;
	}
	
	public unichar get_character (uint32 index) {
		string chr;
		UniRange r;
		unichar c;		
		UniRange? range;
		uint32 range_start_index;
		
		if (unlikely (index > len + unassigned.size)) {
			return '\0';
		}
		
		if (index >= len) {
			if (unlikely (index - len >= unassigned.size)) {
				return '\0';
			} 
			
			chr = unassigned.get ((int) (index - len));
			return chr.get_char ();
		}
		
		get_unirange_index (index, out range, out range_start_index);
		
		if (unlikely (range == null)) {
			warning (@"No range found for index $index");
			return '\0';
		} 
		
		if (unlikely (range_start_index > index || range_start_index == -1)) {
			warning (@"Index out of bounds in glyph range, range_start_index: $range_start_index index: $index");
			return '\0';
		}
		
		r = (!) range;
		c = r.get_char ((unichar) (index - range_start_index));
		
		if (unlikely (!c.validate ())) {
			warning ("Not a valid unicode character.");
			return '\0';
		}
		
		return c;
	}
	
	public uint32 length () {
		return len;
	}

	public bool has_character (string c) {
		unichar s;
		string uns;
		
		if (unassigned.index_of (c) != -1) {
			return true;
		}
		
		uns = unserialize (c);
		
		if (uns.char_count () != 1) {
			// the glyph was not found by its name because it is not in the list of
			// unassigned characters
			return false; 
		}
		
		s = uns.get_char ();
		return !unique (s, s);
	}

	public bool has_unichar (unichar c) {
		return !unique (c, c);
	}
	
	private bool unique (unichar start, unichar stop) {
		foreach (UniRange u in ranges) {
			if (inside (start, u.start, u.stop)) {
				return false;
			}
			
			if (inside (stop, u.start, u.stop)) {
				return false;
			}
			
			if (inside (u.start, start, stop)) {
				return false;
			}
			
			if (inside (u.stop, start, stop)) {
				return false;
			}
		}

		return true;
	}

	private static bool inside (unichar start, unichar u_start, unichar u_stop) {
		return (u_start <= start <= u_stop);
	}
	
	private UniRange insert_range (unichar start, unichar stop) {
		if (unlikely (start > stop)) {
			warning ("start > stop");
			stop = start;
		}
		
		UniRange ur = new UniRange (start, stop);
		len += ur.length ();
		ranges.add (ur);
		
		return ur;
	}

	public void print_all () {
		stdout.printf ("Ranges:\n");
		stdout.printf (get_all_ranges ());
		stdout.printf ("\n");
	}
	
	public string to_string () {
		return get_all_ranges ();
	}
}

}
