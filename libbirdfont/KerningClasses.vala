/*
    Copyright (C) 2013 Johan Mattsson

    This library is free software; you can redistribute it and/or modify 
    it under the terms of the GNU Lesser General Public License as 
    published by the Free Software Foundation; either version 3 of the 
    License, or (at your option) any later version.

    This library is distributed in the hope that it will be useful, but 
    WITHOUT ANY WARRANTY; without even the implied warranty of 
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU 
    Lesser General Public License for more details.
*/

using Cairo;
using Xml;
using Math;

namespace BirdFont {

public class KerningClasses : GLib.Object {
	
	// kerning for classes
	public static List<GlyphRange> classes_first;
	public static List<GlyphRange> classes_last;
	public static List<Kerning> classes_kerning;

	public delegate void KerningIterator (string left, string right, double kerning);

	public KerningClasses () {
		init ();
	}
	
	public static void init () {
		classes_first = new List<GlyphRange> ();
		classes_last = new List<GlyphRange> ();
		classes_kerning = new List<Kerning> ();
	}
	
	public static void set_kerning (GlyphRange left_range, GlyphRange right_range, double k) {
		int index = get_kerning_item_index (left_range, right_range);
		
		if (is_null (classes_first)) { // FIXME: find a place to run init
			init ();
		}
		
		// keep the list sorted (classes first then single glyphs)
		if (index == -1) {
			classes_first.append (left_range);
			classes_last.append (right_range);
			classes_kerning.append (new Kerning (k));
			update_order (classes_first.length () - 1);
		} else {
			return_if_fail (0 <= index <= classes_first.length ());
			classes_kerning.nth (index).data.val = k;
			update_order (index);
		}
	}
	
	static void update_order (uint i) {
		unowned List<GlyphRange> l;
		unowned List<GlyphRange> r;
		unowned List<Kerning> k;
		int first;
		
		if (!(0 <= i < classes_first.length ())) {
			warning (@"Index is out of range. Index: $i  Length: $(classes_first.length ())");
			return;
		}

		l = classes_first.nth (i);
		r = classes_last.nth (i);
		k = classes_kerning.nth (i);
		first = get_first_non_class ();

		if (first < 0) {
			return;
		}
				
		if (first > classes_first.length ()) {
			warning (@"Index is out of range. Index: $first  Length: $(classes_first.length ())");
			return;
		}
		
		if (l.data.is_class () || r.data.is_class ()) {
			classes_first.insert_before (classes_first.nth (first), l.data);
			classes_last.insert_before (classes_last.nth (first), r.data);
			classes_kerning.insert_before (classes_kerning.nth (first), k.data);

			classes_first.remove_link (l);
			classes_last.remove_link (r);
			classes_kerning.remove_link (k);
		} else {
			classes_first.append (l.data);
			classes_last.append (r.data);
			classes_kerning.append (k.data);

			classes_first.remove_link (l);
			classes_last.remove_link (r);
			classes_kerning.remove_link (k);
		}
	}

	public static double get_kerning_for_range (GlyphRange range_first, GlyphRange range_last) {
		unowned List<GlyphRange> r;
		unowned List<GlyphRange> l;
		int len = (int) classes_first.length ();
		bool search_range_is_class = range_first.is_class () || range_last.is_class ();

		len = (int) classes_first.length ();
		return_val_if_fail (len == classes_last.length (), 0);
		return_val_if_fail (len == classes_kerning.length (), 0);
		
		for (int i = len - 1; i >= 0; i--) {
			l = classes_first.nth (i);
			r = classes_last.nth (i);

			if (search_range_is_class && !l.data.is_class () && !r.data.is_class ()) {
				continue;
			}
				
			if (l.data.get_all_ranges () == range_first.get_all_ranges ()
				&& r.data.get_all_ranges () == range_last.get_all_ranges ()) {
				return classes_kerning.nth (i).data.val;
			}
		}
		
		return 0;
	}

	public static int get_first_non_class () {
		unowned List<GlyphRange> r;
		unowned List<GlyphRange> l;
		int len = (int) classes_first.length ();
		
		len = (int)classes_first.length ();
		return_val_if_fail (len == classes_last.length (), 0);
		return_val_if_fail (len == classes_kerning.length (), 0);
		
		for (int i = 0; i < len; i++) {
			l = classes_first.nth (i);
			r = classes_last.nth (i);
			
			if (!l.data.is_class () && !r.data.is_class ()) {
				return i;
			}
		}

		return -1;
	}

	public static int get_kerning_item_index (GlyphRange range_first, GlyphRange range_last) {
		unowned List<GlyphRange> r;
		unowned List<GlyphRange> l;
		int len = (int) classes_first.length ();
		bool search_range_is_class;
		
		len = (int)classes_first.length ();
		return_val_if_fail (len == classes_last.length (), 0);
		return_val_if_fail (len == classes_kerning.length (), 0);
		
		search_range_is_class = range_first.is_class () || range_last.is_class ();
		
		for (int i = len - 1; i >= 0; i--) {
			l = classes_first.nth (i);
			r = classes_last.nth (i);
			
			print (@"$(r.data.get_all_ranges ()) == $(range_first.get_all_ranges ())\n");
			print (@"$(l.data.get_all_ranges ()) == $(range_last.get_all_ranges ())\n");
			print (@"$(classes_kerning.nth (i).data.val)\n");
			
			if (!l.data.is_class () && !r.data.is_class () && search_range_is_class) {
				continue;
			}
			
			if (l.data.get_all_ranges () == range_first.get_all_ranges ()
				&& r.data.get_all_ranges () == range_last.get_all_ranges ()) {
				return i;
			}
		}

		return -1;
	}
		
	public static double get_kerning (string left_glyph, string right_glyph) {
		unowned List<GlyphRange> r;
		unowned List<GlyphRange> l;
		int len = (int) classes_first.length ();

		len = (int)classes_first.length ();
		return_val_if_fail (len == classes_last.length (), 0);
		return_val_if_fail (len == classes_kerning.length (), 0);
		
		for (int i = len - 1; i >= 0; i--) {
			l = classes_first.nth (i);
			r = classes_last.nth (i);
			
			if (l.data.has_character (left_glyph)
				&& r.data.has_character (right_glyph)) {
				return classes_kerning.nth (i).data.val;
			}
		}
		
		return 0;
	}

	public static double get_kern_for_range_to_char (GlyphRange left_range, string right_char) {
		unowned List<GlyphRange> r;
		unowned List<GlyphRange> l;
		int len = (int) classes_first.length ();
		bool search_range_is_class = left_range.is_class ();
		
		len = (int)classes_first.length ();
		return_val_if_fail (len == classes_last.length (), 0);
		return_val_if_fail (len == classes_kerning.length (), 0);
		
		for (int i = len - 1; i >= 0; i--) {
			l = classes_first.nth (i);
			r = classes_last.nth (i);

			if (!l.data.is_class () && !r.data.is_class () && search_range_is_class) {
				continue;
			}
			
			if (l.data.get_all_ranges () == left_range.get_all_ranges ()
				&& r.data.has_character (right_char)) {
				return classes_kerning.nth (i).data.val;
			}
		}
		
		return 0;
	}

	public static double get_kern_for_char_to_range (string left_char, GlyphRange right_range) {
		unowned List<GlyphRange> r;
		unowned List<GlyphRange> l;
		int len = (int) classes_first.length ();
		bool search_range_is_class = right_range.is_class ();

		len = (int)classes_first.length ();
		return_val_if_fail (len == classes_last.length (), 0);
		return_val_if_fail (len == classes_kerning.length (), 0);
		
		for (int i = len - 1; i >= 0; i--) {
			l = classes_first.nth (i);
			r = classes_last.nth (i);

			if (search_range_is_class && !l.data.is_class () && !r.data.is_class ()) {
				continue;
			}
			
			if (l.data.has_character (left_char)
				&& r.data.get_all_ranges () == right_range.get_all_ranges ()) {
				return classes_kerning.nth (i).data.val;
			}
		}
		
		return 0;
	}
	
	public static void print_all () {
		print ("Kernings:\n");
		for (int i = 0; i < classes_first.length (); i++) {
			print (classes_first.nth (i).data.get_all_ranges ());
			print (@"\t\t");
			print (classes_last.nth (i).data.get_all_ranges ());
			print ("\t\t");
			print (@"$(classes_kerning.nth (i).data.val)");
			print ("\t\t");
			
			if (classes_first.nth (i).data.is_class () || classes_last.nth (i).data.is_class ()) {
				print ("class");
			}
			
			print ("\n");
		}
	}
	
	public static void all_pairs (KerningIterator kerningIterator) {
		Font f = BirdFont.get_current_font ();
		Glyph? g1, g2;
		Glyph glyph1, glyph2;
		double k;
		int i, j;
		
		i = 0;
		g1 = f.get_glyph_indice (i);
		while (g1 != null) {
			glyph1 = (!) g1;
			
			j = 0;
			g2 = f.get_glyph_indice (j);
			while (g2 != null) {
				glyph2 = (!) g2;
				
				k = KerningClasses.get_kerning (glyph1.get_name (), glyph2.get_name ());
				if (k != 0) {
					kerningIterator (glyph1.get_name (), glyph2.get_name (), k);
				}
				
				j++;
				g2 = f.get_glyph_indice (j);
			}
			
			i++;
			g1 = f.get_glyph_indice (i);
		}
	}
}

}
