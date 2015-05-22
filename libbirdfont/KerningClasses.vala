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
using Bird;
using Math;
using Gee;

namespace BirdFont {

public class KerningClasses : GLib.Object {
	
	// kerning for classes
	public Gee.ArrayList<GlyphRange> classes_first;
	public Gee.ArrayList<GlyphRange> classes_last;
	public Gee.ArrayList<Kerning> classes_kerning;

	// kerning for single glyphs
	Gee.HashMap<string, double?> single_kerning;
	public Gee.ArrayList<string> single_kerning_letters_left;
	public Gee.ArrayList<string> single_kerning_letters_right; 
	
	public delegate void KerningIterator (KerningPair list);
	public delegate void KerningClassIterator (string left, string right, double kerning);

	/** Ensure that map iterator is not invalidated because of inserts. */
	bool protect_map = false;

	public unowned Font font;

	public KerningClasses (Font font) {
		this.font = font;
		
		classes_first = new Gee.ArrayList<GlyphRange> ();
		classes_last = new Gee.ArrayList<GlyphRange> ();
		classes_kerning = new Gee.ArrayList<Kerning> ();
		
		single_kerning_letters_left = new Gee.ArrayList<string> ();
		single_kerning_letters_right = new Gee.ArrayList<string> ();
		
		single_kerning = new HashMap<string, double?> ();
	}

	public void update_range (GlyphRange old, GlyphRange new_range) {
		string o = old.get_all_ranges ();
		
		foreach (GlyphRange gr in classes_first) {
			try {
				if (gr.get_all_ranges () == o) {
					gr.parse_ranges (new_range.get_all_ranges ());
				}
			} catch (GLib.MarkupError e) {
				warning (e.message);
			}
		}
		
		foreach (GlyphRange gr in classes_last) {
			try {
				if (gr.get_all_ranges () == o) {
					gr.parse_ranges (new_range.get_all_ranges ());
				}
			} catch (GLib.MarkupError e) {
				warning (e.message);
			}
		}
	}

	/** Class based gpos kerning. */
	public double get_kerning_for_pair (string a, string b, GlyphRange? gr_left, GlyphRange? gr_right) {
		double k = 0;
		GlyphRange grl, grr;
		
		try {
			if (gr_left == null) {
				grl = new GlyphRange ();
				grl.parse_ranges (a);
			} else {
				grl = (!) gr_left;
			}

			if (gr_right == null) {
				grr = new GlyphRange ();
				grr.parse_ranges (a);
			} else {
				grr = (!) gr_right;
			}

			if (gr_left == null && gr_right == null) {
				k = get_kerning (a, b);
				return k;
			}
						
			if (gr_left != null && gr_right != null) {
				return get_kerning_for_range (grl, grr);
			}
			
			if (gr_left != null && gr_right == null) {
				return get_kern_for_range_to_char (grl, b);
			}
			
			if (gr_left == null && gr_right != null) {
				return get_kern_for_char_to_range (a, grr);
			}
		} catch (MarkupError e) {
			warning (e.message);
		}
		
		if (unlikely (k == 0)) {
			warning ("no kerning found");
		}
		
		return 0;
	}

	public void update_space_class (string c) {
		double? k;
		
		foreach (string l in single_kerning_letters_left) {	
			k = get_kerning_for_single_glyphs (l, c);
			
			if (k != null) {
				set_kerning_for_single_glyphs (l, c, (!) k);
			}
		}

		foreach (string r in single_kerning_letters_right) {	
			k = get_kerning_for_single_glyphs (c, r);
			
			if (k != null) {
				set_kerning_for_single_glyphs (c, r, (!) k);
			}
		}		
	}

	public double? get_kerning_for_single_glyphs (string first, string next) {
		double? k = null;
		string left = GlyphRange.serialize (first);
		string right = GlyphRange.serialize (next);

		foreach (string l in get_spacing_class (left)) {
			foreach (string r in get_spacing_class (right)) {
				k = single_kerning.get (@"$l - $r");
			}
		}
		
		return k;
	} 

	private Gee.ArrayList<string> get_spacing_class (string c) {
		return font.get_spacing ().get_all_connections (c);
	}

	public void set_kerning_for_single_glyphs (string le, string ri, double k) {
		string left = GlyphRange.serialize (le);
		string right = GlyphRange.serialize (ri);
		string cleft = (!)GlyphRange.unserialize (left);
		string cright = (!)GlyphRange.unserialize (right); // FIXME: get_char? 
		
		if (protect_map) {
			warning ("Map is protected.");
			return;
		}

		foreach (string l in get_spacing_class (cleft)) {
			foreach (string r in get_spacing_class (cright)) {
				if (!single_kerning_letters_left.contains (cleft)) {
					single_kerning_letters_left.add (cleft);
				}

				if (!single_kerning_letters_right.contains (cright)) {
					single_kerning_letters_right.add (cright);
				}

				left = GlyphRange.serialize (l);
				right = GlyphRange.serialize (r);
				single_kerning.set (@"$left - $right", k);
			}
		}
	} 

	public void set_kerning (GlyphRange left_range, GlyphRange right_range, double k, int class_index = -1) {
		int index;
		
		if (left_range.get_length () == 0 || right_range.get_length () == 0) {
			warning ("no glyphs");
			return;
		}

		if (protect_map) {
			warning ("Map is protected.");
			return;
		}

		if (!left_range.is_class () && !right_range.is_class ()) {
			set_kerning_for_single_glyphs (left_range.get_all_ranges (), right_range.get_all_ranges (), k);
			return;
		}
		
		index = get_kerning_item_index (left_range, right_range);
		
		// keep the list sorted (classes first then single glyphs)
		if (index == -1) {
			if (class_index < 0) {
				classes_first.add (left_range);
				classes_last.add (right_range);
				classes_kerning.add (new Kerning (k));
			} else {
				classes_first.insert (class_index, left_range);
				classes_last.insert (class_index, right_range);
				classes_kerning.insert (class_index, new Kerning (k));
			}
		} else {
			return_if_fail (0 <= index < classes_first.size);
			classes_kerning.get (index).val = k;
		}
	}

	public bool has_kerning (string first, string next) {
		string f = "";
		string n = "";
		GlyphRange gr;
		GlyphRange gl;
		int len;
		
		foreach (string l in get_spacing_class (first)) {
			foreach (string r in get_spacing_class (next)) {
				f = GlyphRange.serialize (l);
				n = GlyphRange.serialize (r);	
				if (single_kerning.has_key (@"$f - $n")) {
					return true;
				}
			}
		}
		
		len = (int) classes_first.size;
		
		return_val_if_fail (len == classes_last.size, false);
		return_val_if_fail (len == classes_kerning.size, false);
		
		for (int i = len - 1; i >= 0; i--) {
			gl = classes_first.get (i);
			gr = classes_last.get (i);
			
			if (gl.has_character (first)
				&& gr.has_character (next)) {

				return true;
			}
		}
		
		return false;
	}

	public double get_kerning_for_range (GlyphRange range_first, GlyphRange range_last) {
		GlyphRange r;
		GlyphRange l;
		int len = (int) classes_first.size;
		
		len = (int) classes_first.size;
		return_val_if_fail (len == classes_last.size, 0);
		return_val_if_fail (len == classes_kerning.size, 0);

		if (!(range_first.is_class () || range_last.is_class ())) {
			get_kerning_for_single_glyphs (range_first.get_all_ranges (), range_last.get_all_ranges ());
			return 0;
		}
		
		for (int i = len - 1; i >= 0; i--) { // last class is applied first
			l = classes_first.get (i);
			r = classes_last.get (i);
	
			if (l.get_all_ranges () == range_first.get_all_ranges ()
				&& r.get_all_ranges () == range_last.get_all_ranges ()) {
				return classes_kerning.get (i).val;
			}
		}
		
		return 0;
	}

	public int get_kerning_item_index (GlyphRange range_first, GlyphRange range_last) {
		GlyphRange r;
		GlyphRange l;
		int len = (int) classes_first.size;
		
		len = (int) classes_first.size;
		return_val_if_fail (len == classes_last.size, 0);
		return_val_if_fail (len == classes_kerning.size, 0);

		if (!(range_first.is_class () || range_last.is_class ())) {
			warning (@"Expecting a class, $(range_first.get_all_ranges ()) and $(range_last.get_all_ranges ())");
			return -1;
		}
		
		for (int i = len - 1; i >= 0; i--) {
			l = classes_first.get (i);
			r = classes_last.get (i);
			
			if (l.get_all_ranges () == range_first.get_all_ranges ()
				&& r.get_all_ranges () == range_last.get_all_ranges ()) {
				return i;
			}
		}

		return -1;
	}
		
	public double get_kerning (string left_glyph, string right_glyph) {
		GlyphRange r;
		GlyphRange l;
		int len = (int) classes_first.size;
		double? d;
		
		d = get_kerning_for_single_glyphs (left_glyph, right_glyph);
		if (d != null) {
			return (!)d;
		}
		
		len = (int)classes_first.size;
		return_val_if_fail (len == classes_last.size, 0);
		return_val_if_fail (len == classes_kerning.size, 0);
		
		for (int i = len - 1; i >= 0; i--) {
			l = classes_first.get (i);
			r = classes_last.get (i);
			
			if (l.has_character (left_glyph)
				&& r.has_character (right_glyph)) {

				return classes_kerning.get (i).val;
			}
		}

		return 0;
	}

	public double get_kern_for_range_to_char (GlyphRange left_range, string right_char) {
		GlyphRange r;
		GlyphRange l;
		int len = (int) classes_first.size;
		
		len = (int)classes_first.size;
		return_val_if_fail (len == classes_last.size, 0);
		return_val_if_fail (len == classes_kerning.size, 0);
		
		if (unlikely (!left_range.is_class ())) {
			warning (@"Expecting a class, $(left_range.get_all_ranges ())");
			return -1;
		}
		
		foreach (string right in get_spacing_class (right_char)) {
			for (int i = len - 1; i >= 0; i--) {
				l = classes_first.get (i);
				r = classes_last.get (i);
				
				if (l.get_all_ranges () == left_range.get_all_ranges ()
					&& r.has_character (right)) {
					return classes_kerning.get (i).val;
				}
			}
		}
		
		return 0;
	}
	
	public double get_kern_for_char_to_range (string left_char, GlyphRange right_range) {
		GlyphRange r;
		GlyphRange l;
		int len = (int) classes_first.size;

		len = (int)classes_first.size;
		return_val_if_fail (len == classes_last.size, 0);
		return_val_if_fail (len == classes_kerning.size, 0);
		
		if (!right_range.is_class ()) {
			warning ("Expecting a class");
			return 0;
		}
		
		foreach (string left in get_spacing_class (left_char)) {
			for (int i = len - 1; i >= 0; i--) {
				l = classes_first.get (i);
				r = classes_last.get (i);
				
				if (l.has_character (left)
					&& r.get_all_ranges () == right_range.get_all_ranges ()) {
					return classes_kerning.get (i).val;
				}
			}
		}
		
		return 0;
	}
	
	public void print_all () {
		print ("Kernings classes:\n");
		for (int i = 0; i < classes_first.size; i++) {
			print (classes_first.get (i).get_all_ranges ());
			print ("\t\t");
			print (classes_last.get (i).get_all_ranges ());
			print ("\t\t");
			print (@"$(classes_kerning.get (i).val)");
			print ("\t\t");
			
			if (classes_first.get (i).is_class () || classes_last.get (i).is_class ()) {
				print ("class");
			}
			
			print ("\n");
		}
		
		print ("\n");
		print ("Kernings for pairs:\n");
		if (!set_protect_map (true)) {
			warning ("Map is protected.");
			return;
		}
		
		foreach (string key in single_kerning.keys) {
			print (key);
			print ("\t\t");
			print (@"$((!) single_kerning.get (key))\n");
		}
		
		set_protect_map (false);
		
		print ("\n");
		print ("Generated table:\n");
		all_pairs ((k) => {
			k.print ();
		});
	}

	public void get_classes (KerningClassIterator kerningIterator) {
		for (int i = 0; i < classes_first.size; i++) {
			kerningIterator (classes_first.get (i).get_all_ranges (),
				classes_last.get (i).get_all_ranges (),
				classes_kerning.get (i).val);
		}
	}
	
	public void get_single_position_pairs (KerningClassIterator kerningIterator) {
		double k = 0;
		
		if (!set_protect_map (true)) {
			warning ("Map is protected.");
			return;
		}
		
		foreach (string key in single_kerning.keys) {
			var chars = key.split (" - ");
			
			if (chars.length != 2) {
				warning (@"Can not parse characters from key: $key");
			} else {
				k = (!) single_kerning.get (key);
				kerningIterator (chars[0], chars[1], k);
			}
		}
		
		set_protect_map (false);
	}
	
	public void each_pair (KerningClassIterator iter) {
		all_pairs ((kl) => {
			Glyph g2;
			KerningPair kerning_list = kl;
			string g1 = kerning_list.character.get_name ();
			Kerning kerning;
			int i = 0;
			
			return_if_fail (kerning_list.kerning.size > 0);

			foreach (Kerning k in kerning_list.kerning) {
				g2 = k.get_glyph ();
				kerning = kerning_list.kerning.get (i);
				iter (g1, g2.get_name (), kerning.val);
			}
		});
	}
	
	public void all_pairs (KerningIterator kerningIterator) {
		Gee.ArrayList<Glyph> left_glyphs = new Gee.ArrayList<Glyph> ();
		Gee.ArrayList<KerningPair> pairs = new Gee.ArrayList<KerningPair> ();
		double kerning;
		string right;
		string name;
		Glyph? g;
		
		// Create a list of first glyph in all pairs
		foreach (GlyphRange r in classes_first) {
			foreach (UniRange u in r.ranges) {
				for (unichar c = u.start; c <= u.stop; c++) {
					name = (!)c.to_string ();
					g = font.get_glyph (name);
					if (g != null && !left_glyphs.contains ((!) g)) {
						left_glyphs.add ((!) g);
					}
				}
			}
			
			foreach (string n in r.unassigned) {
				g = font.get_glyph (n);
				if (g != null && !left_glyphs.contains ((!) g)) {
					left_glyphs.add ((!) g);
				}
			}
		}
		
		foreach (string n in single_kerning_letters_left) {
			g = font.get_glyph (n);
			if (g != null && !left_glyphs.contains ((!) g)) {
				left_glyphs.add ((!) g);
			}
		}

		// add the right hand glyph and the kerning value
		foreach (Glyph character in left_glyphs) {
			KerningPair kl = new KerningPair (character);

			foreach (GlyphRange r in classes_last) {
				foreach (UniRange u in r.ranges) {
					for (unichar c = u.start; c <= u.stop; c++) {
						right = (!)c.to_string ();
						
						if (font.has_glyph (right) && has_kerning (character.get_name (), right)) {
							kerning = get_kerning (character.get_name (), right);
							kl.add_unique ((!) font.get_glyph (right), kerning);
						}
					}
				}

				foreach (string n in r.unassigned) {
					if (font.has_glyph (n) && has_kerning (character.get_name (), n)) {
						kerning = get_kerning (character.get_name (), n);
						kl.add_unique ((!) font.get_glyph (n), kerning);
					}
				}
			}

			// TODO: The get_kerning () function is still slow. Optimize it.
			foreach (string right_glyph_name in single_kerning_letters_right) {
				Glyph? gl = font.get_glyph (right_glyph_name);
				if (gl != null && has_kerning (character.get_name (), right_glyph_name)) {
					kerning = get_kerning (character.get_name (), right_glyph_name);
					kl.add_unique ((!) gl , kerning);
				}
			}
			
			if (kl.kerning.size > 0) {
				pairs.add (kl);
			}
			
			if (kl.kerning.size == 0) {
				warning (@"No kerning pairs for character: $((kl.character.get_name ()))");
			}
					
			kl.sort ();
		}
		
		// obtain the kerning value
		foreach (KerningPair p in pairs) {
			kerningIterator (p);
		}
	}

	private bool set_protect_map (bool p) {
		if (unlikely (p && protect_map)) {
			warning ("Map is already protected.");
			return false;
		}
		
		protect_map = p;
		return true;
	}

	public void delete_kerning_for_class (string left, string right) {
		int i = 0;
		int index = -1;
		
		get_classes ((l, r, kerning) => {
			if (left == l && r == right) {
				index = i;
			}
			i++;
		});
		
		if (unlikely (index < 0)) {
			warning (@"Kerning class not found for $left to $right");
			return;
		}
		
		classes_first.remove_at (index);
		classes_last.remove_at (index);
		classes_kerning.remove_at (index);
	}

	public void delete_kerning_for_pair (string left, string right) {
		foreach (string l in get_spacing_class (left)) {
			foreach (string r in get_spacing_class (right)) {
				delete_kerning_for_one_pair (l, r);
			}
		}
	}

	private void delete_kerning_for_one_pair (string left, string right) {
		bool has_left, has_right;
		string[] p;
		
		single_kerning.unset (@"$left - $right");
		
		has_left = false;
		has_right = false;
		
		foreach (string k in single_kerning.keys) {
			p = k.split (" - ");
			return_if_fail (p.length == 2);
						
			if (p[0] == left) {
				has_left = true;
			}
			
			if (p[1] == right) {
				has_right = true;
			}
		}

		if (!has_left) {
			single_kerning_letters_left.remove (left);
		}
				
		if (!has_right) {
			single_kerning_letters_right.remove (left);
		}
	}

	public void remove_all_pairs () {
		if (protect_map) {
			warning ("Map is protected.");
			return;
		}

		classes_first.clear ();
		classes_last.clear ();
		classes_kerning.clear ();
		single_kerning_letters_left.clear ();
		single_kerning_letters_right.clear ();
				
		GlyphCanvas.redraw ();
		
		if (!is_null (MainWindow.get_toolbox ())) { // FIXME: reorganize
			Toolbox.redraw_tool_box ();
		}
		
		single_kerning.clear ();
	}
	
	public uint get_number_of_pairs () {
		return single_kerning.keys.size + classes_first.size;
	}
}

}
