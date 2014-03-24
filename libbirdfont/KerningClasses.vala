/*
    Copyright (C) 2013, 2014 Johan Mattsson

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
using Gee;

namespace BirdFont {

public class KerningClasses : GLib.Object {
	
	// kerning for classes
	public GLib.List<GlyphRange> classes_first;
	public GLib.List<GlyphRange> classes_last;
	public GLib.List<Kerning> classes_kerning;

	// kerning for single glyphs
	Gee.HashMap<string, double?> single_kerning;
	public GLib.List<string> single_kerning_letters_left; // FIXME: this needs to be fast and sorted
	public GLib.List<string> single_kerning_letters_right; 
	
	public delegate void KerningIterator (KerningPair list);
	public delegate void KerningClassIterator (string left, string right, double kerning);

	public KerningClasses () {
		classes_first = new GLib.List<GlyphRange> ();
		classes_last = new GLib.List<GlyphRange> ();
		classes_kerning = new GLib.List<Kerning> ();
		
		single_kerning = new HashMap<string, double?> ();
	}
	
	public static KerningClasses get_instance () {
		return BirdFont.get_current_font ().get_kerning_classes ();
	}
	
	public double? get_kerning_for_single_glyphs (string l, string r) {
		string left = GlyphRange.serialize (l);
		string right = GlyphRange.serialize (r);
		return single_kerning.get (@"$left - $right");
	} 

	public void set_kerning_for_single_glyphs (string l, string r, double k) {
		string left = GlyphRange.serialize (l);
		string right = GlyphRange.serialize (r);
		string cleft = (!)GlyphRange.unserialize (left).get_char ().to_string ();
		string cright = (!)GlyphRange.unserialize (right).get_char ().to_string ();
		
		if (single_kerning_letters_left.index (cleft) < 0) {
			single_kerning_letters_left.append (cleft);
		}

		if (single_kerning_letters_right.index (cright) < 0) {
			single_kerning_letters_right.append (cright);
		}
				
		single_kerning.set (@"$left - $right", k);
	} 

	public void set_kerning (GlyphRange left_range, GlyphRange right_range, double k) {
		int index;
		
		if (left_range.get_length () == 0 || right_range.get_length () == 0) {
			warning ("no glyphs");
			return;
		}

		if (!left_range.is_class () && !right_range.is_class ()) {
			set_kerning_for_single_glyphs (left_range.get_all_ranges (), right_range.get_all_ranges (), k);
			return;
		}
		
		index = get_kerning_item_index (left_range, right_range);
		
		// keep the list sorted (classes first then single glyphs)
		if (index == -1) {
			classes_first.append (left_range);
			classes_last.append (right_range);
			classes_kerning.append (new Kerning (k));
		} else {
			return_if_fail (0 <= index <= classes_first.length ());
			classes_kerning.nth (index).data.val = k;
		}
	}

	public double get_kerning_for_range (GlyphRange range_first, GlyphRange range_last) {
		unowned GLib.List<GlyphRange> r;
		unowned GLib.List<GlyphRange> l;
		int len = (int) classes_first.length ();
		
		len = (int) classes_first.length ();
		return_val_if_fail (len == classes_last.length (), 0);
		return_val_if_fail (len == classes_kerning.length (), 0);

		if (!(range_first.is_class () || range_last.is_class ())) {
			get_kerning_for_single_glyphs (range_first.get_all_ranges (), range_last.get_all_ranges ());
			return 0;
		}
		
		for (int i = len - 1; i >= 0; i--) {
			l = classes_first.nth (i);
			r = classes_last.nth (i);
	
			if (l.data.get_all_ranges () == range_first.get_all_ranges ()
				&& r.data.get_all_ranges () == range_last.get_all_ranges ()) {
				return classes_kerning.nth (i).data.val;
			}
		}
		
		return 0;
	}

	public int get_kerning_item_index (GlyphRange range_first, GlyphRange range_last) {
		unowned GLib.List<GlyphRange> r;
		unowned GLib.List<GlyphRange> l;
		int len = (int) classes_first.length ();
		
		len = (int)classes_first.length ();
		return_val_if_fail (len == classes_last.length (), 0);
		return_val_if_fail (len == classes_kerning.length (), 0);

		if (!(range_first.is_class () || range_last.is_class ())) {
			warning (@"Expecting a class, $(range_first.get_all_ranges ()) and $(range_last.get_all_ranges ())");
			return -1;
		}
		
		for (int i = len - 1; i >= 0; i--) {
			l = classes_first.nth (i);
			r = classes_last.nth (i);
			
			if (l.data.get_all_ranges () == range_first.get_all_ranges ()
				&& r.data.get_all_ranges () == range_last.get_all_ranges ()) {
				return i;
			}
		}

		return -1;
	}
		
	public double get_kerning (string left_glyph, string right_glyph) {
		unowned GLib.List<GlyphRange> r;
		unowned GLib.List<GlyphRange> l;
		int len = (int) classes_first.length ();
		double? d;
		double time;
		
		d = get_kerning_for_single_glyphs (left_glyph, right_glyph);
		if (d != null) {
			return (!)d;
		}

		time = GLib.get_real_time ();
		
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

	public double get_kern_for_range_to_char (GlyphRange left_range, string right_char) {
		unowned GLib.List<GlyphRange> r;
		unowned GLib.List<GlyphRange> l;
		int len = (int) classes_first.length ();
		
		len = (int)classes_first.length ();
		return_val_if_fail (len == classes_last.length (), 0);
		return_val_if_fail (len == classes_kerning.length (), 0);
		
		if (!left_range.is_class ()) {
			warning ("Expecting a class");
			return -1;
		}
		
		for (int i = len - 1; i >= 0; i--) {
			l = classes_first.nth (i);
			r = classes_last.nth (i);
			
			if (l.data.get_all_ranges () == left_range.get_all_ranges ()
				&& r.data.has_character (right_char)) {
				return classes_kerning.nth (i).data.val;
			}
		}
		
		return 0;
	}

	public double get_kern_for_char_to_range (string left_char, GlyphRange right_range) {
		unowned GLib.List<GlyphRange> r;
		unowned GLib.List<GlyphRange> l;
		int len = (int) classes_first.length ();

		len = (int)classes_first.length ();
		return_val_if_fail (len == classes_last.length (), 0);
		return_val_if_fail (len == classes_kerning.length (), 0);
		
		if (!right_range.is_class ()) {
			warning ("Expecting a class");
			return 0;
		}
		
		for (int i = len - 1; i >= 0; i--) {
			l = classes_first.nth (i);
			r = classes_last.nth (i);
			
			if (l.data.has_character (left_char)
				&& r.data.get_all_ranges () == right_range.get_all_ranges ()) {
				return classes_kerning.nth (i).data.val;
			}
		}
		
		return 0;
	}
	
	public void print_all () {
		print ("Kernings classes:\n");
		for (int i = 0; i < classes_first.length (); i++) {
			print (classes_first.nth (i).data.get_all_ranges ());
			print ("\t\t");
			print (classes_last.nth (i).data.get_all_ranges ());
			print ("\t\t");
			print (@"$(classes_kerning.nth (i).data.val)");
			print ("\t\t");
			
			if (classes_first.nth (i).data.is_class () || classes_last.nth (i).data.is_class ()) {
				print ("class");
			}
			
			print ("\n");
		}
		
		print ("\n");
		print ("Kernings for pairs:\n");
		foreach (string key in single_kerning.keys) {
			print (key);
			print ("\t\t");
			print (@"$((!) single_kerning.get (key))\n");
		}
	}

	public void get_classes (KerningClassIterator kerningIterator) {
		for (int i = 0; i < classes_first.length (); i++) {
			kerningIterator (classes_first.nth (i).data.get_all_ranges (),
				classes_last.nth (i).data.get_all_ranges (),
				classes_kerning.nth (i).data.val);
		}
	}
	
	public void get_single_position_pairs (KerningClassIterator kerningIterator) {
		double k = 0;
		
		foreach (string key in single_kerning.keys) {
			var chars = key.split (" - ");
			
			if (chars.length != 2) {
				warning (@"Can not parse characters from key: $key");
			} else {
				k = (!) single_kerning.get (key);
				kerningIterator (chars[0], chars[1], k);
			}
		}
	}
	
	public void each_pair (KerningClassIterator iter) {
		all_pairs ((kl) => {
			Glyph g2;
			KerningPair kerning_list = kl;
			string g1 = kerning_list.character.get_name ();
			unowned GLib.List<Kerning> kerning = kerning_list.kerning.first ();
			
			if (unlikely (is_null (kerning))) {
				warning ("No kerning values.");
			}
			
			foreach (Kerning k in kerning_list.kerning) {
				g2 = k.get_glyph ();
				iter (g1, g2.get_name (), kerning.data.val);
				kerning = kerning.next;
			}
		});
	}
	
	public void all_pairs (KerningIterator kerningIterator) {
		Font font = BirdFont.get_current_font ();
		GLib.List<Glyph> left_glyphs = new GLib.List<Glyph> ();
		GLib.List<KerningPair> pairs = new GLib.List<KerningPair> ();
		double kerning;
		string right;
		
		// Create a list of first glyph in all pairs
		foreach (GlyphRange r in classes_first) {
			foreach (UniRange u in r.ranges) {
				for (unichar c = u.start; c <= u.stop; c++) {
					string name = (!)c.to_string ();
					Glyph? g = font.get_glyph (name);
					if (g != null && left_glyphs.index ((!) g) < 0) {
						left_glyphs.append ((!) g);
					}
				}
			}
				
			// TODO: GlyphRange.unassigned
		}
		
		foreach (string name in single_kerning_letters_left) {
			Glyph? g = font.get_glyph (name);
			if (g != null && left_glyphs.index ((!) g) < 0) {
				left_glyphs.append ((!) g);
			}
		}
		
		left_glyphs.sort ((a, b) => {
			return strcmp (a.get_name (), b.get_name ());
		});

		// add the right hand glyph and the kerning value
		foreach (Glyph character in left_glyphs) {
			KerningPair kl = new KerningPair (character);
			pairs.append (kl);

			foreach (GlyphRange r in classes_last) {
				foreach (UniRange u in r.ranges) {
					for (unichar c = u.start; c <= u.stop; c++) {
						right = (!)c.to_string ();
						
						if (font.has_glyph (right)) {
							kerning = get_kerning (character.get_name (), right);
							kl.add_unique ((!) font.get_glyph (right), kerning);
						}
					}
				}
				// TODO: GlyphRange.unassigned
			}

			// TODO: The get_kerning () function is still rather slow. Optimize it.
			foreach (string right_glyph_name in single_kerning_letters_right) {
				Glyph? gl = font.get_glyph (right_glyph_name);
				if (gl != null) {
					kerning = get_kerning (character.get_name (), right_glyph_name);
					kl.add_unique ((!) gl , kerning);
				}
			}
			
			kl.sort ();
		}
		
		// obtain the kerning value
		foreach (KerningPair p in pairs) {
			kerningIterator (p);
		}
	}

	public void remove_all_pairs () {
		print ("Remove all kerning pairs\n");
		
		while (classes_first.length () > 0) {
			classes_first.remove_link (classes_first.first ());
		}

		while (classes_last.length () > 0) {
			classes_last.remove_link (classes_last.first ());
		}
		
		while (classes_kerning.length () > 0) {
			classes_kerning.remove_link (classes_kerning.first ());
		}

		while (single_kerning_letters_left.length () > 0) {
			single_kerning_letters_left.remove_link (single_kerning_letters_left.first ());
		}		

		while (single_kerning_letters_right.length () > 0) {
			single_kerning_letters_right.remove_link (single_kerning_letters_right.first ());
		}		
		
				
		GlyphCanvas.redraw ();
		
		if (!is_null (MainWindow.get_toolbox ())) { // FIXME: reorganize
			Toolbox.redraw_tool_box ();
		}
		
		single_kerning.clear ();
	}
	
	public uint get_number_of_pairs () {
		return single_kerning.keys.size + classes_first.length ();
	}
}

}
