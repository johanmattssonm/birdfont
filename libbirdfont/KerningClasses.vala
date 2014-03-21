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
using Gee;

namespace BirdFont {

public class KerningClasses : GLib.Object {
	
	// kerning for classes
	public GLib.List<GlyphRange> classes_first;
	public GLib.List<GlyphRange> classes_last;
	public GLib.List<Kerning> classes_kerning;

	// kerning for single glyphs
	Gee.HashMap<string, double?> single_kerning;
	
	public delegate void KerningIterator (string left, string right, double kerning);

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
		single_kerning.set (@"$l - $r", k);
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
		
		d = get_kerning_for_single_glyphs (left_glyph, right_glyph);
		if (d != null) {
			return (!)d;
		}

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

	public void get_classes (KerningIterator kerningIterator) {
		for (int i = 0; i < classes_first.length (); i++) {
			kerningIterator (classes_first.nth (i).data.get_all_ranges (),
				classes_last.nth (i).data.get_all_ranges (),
				classes_kerning.nth (i).data.val);
		}
	}
	
	public void get_single_position_pairs (KerningIterator kerningIterator) {
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
	
	public void all_pairs (KerningIterator kerningIterator) {
		// FIXME: THIS CODE IS TOO SLOW
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
				
				k = KerningClasses.get_instance ().get_kerning (glyph1.get_name (), glyph2.get_name ());
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
