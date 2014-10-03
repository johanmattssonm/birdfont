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

using Cairo;
using Math;

namespace BirdFont {

public class Ligatures : GLib.Object {
	
	Gee.ArrayList<Ligature> ligatures = new Gee.ArrayList<Ligature> ();
	
	public delegate void LigatureIterator (string substitution, string ligature);
	public delegate void SingleLigatureIterator (GlyphSequence substitution, GlyphCollection ligature);

	public Ligatures () {
	}
	
	// FIXME: keep ligatures sorted, long strings first
	public void get_ligatures (LigatureIterator iter) {
		foreach (Ligature l in ligatures) {
			iter (l.ligature, l.substitution);
		}	
	}

	public void get_single_substitution_ligatures (SingleLigatureIterator iter) {
		get_ligatures ((substitution, ligature) => {
			Font font = BirdFont.get_current_font ();
			GlyphCollection? gc;
			GlyphCollection li;
			GlyphSequence gs;
			string[] subst_names = substitution.split (" ");
			
			gc = font.get_glyph_collection_by_name (ligature);
			
			if (gc == null) {
				return;
			}
			
			li = (!) gc;
			
			gs = new GlyphSequence ();
			foreach (string s in subst_names) {
				gc = font.get_glyph_collection_by_name (s);
				
				if (gc == null) {
					return;
				}
				
				gs.glyph.add (((!) gc).get_current ());
			}
			
			iter (gs, li);
		});
	}
		
	public int count () {
		return ligatures.size;
	}
	
	public void remove_at (int i) {
		return_if_fail (0 <= i < ligatures.size);
		ligatures.remove_at (i);
	}
	
	public void set_ligature (int index) {
		Ligature lig;
		TextListener listener;
		
		return_if_fail (0 <= index < ligatures.size);
		
		lig = ligatures.get (index);
		listener = new TextListener (t_("Ligature"), "", t_("Set"));
		
		listener.signal_text_input.connect ((text) => {
			lig.ligature = text;
		});
		
		listener.signal_submit.connect (() => {
			MainWindow.native_window.hide_text_input ();
		});
		
		MainWindow.native_window.set_text_listener (listener);
	}
	
	public void set_substitution (int index) {
		Ligature lig;
		TextListener listener;
		
		return_if_fail (0 <= index < ligatures.size);
		
		lig = ligatures.get (index);
		listener = new TextListener (t_("Text"), "", t_("Set"));
		
		listener.signal_text_input.connect ((text) => {
			lig.substitution = text;
			sort_ligatures ();
		});
		
		listener.signal_submit.connect (() => {
			MainWindow.native_window.hide_text_input ();
		});
		
		MainWindow.native_window.set_text_listener (listener);
	}	

	public void add_ligature (string subst, string liga) {
		ligatures.insert (0, new Ligature (liga, subst));
		sort_ligatures ();
	}
	
	void sort_ligatures () {
		print (@"\n");
		ligatures.sort ((a, b) => {
			Ligature first, next;
			bool r;
			int chars_first, chars_next;
			
			first = (Ligature) a;
			next = (Ligature) b;
			
			chars_first = first.substitution.char_count ();
			chars_next = next.substitution.char_count ();
							
			return chars_next - chars_first;
			
			if (first.get_first_char () == next.get_first_char ()) {
				chars_first = first.substitution.char_count ();
				chars_next = next.substitution.char_count ();
				
				
				r = chars_first > chars_next; // DELETE
				print (@"$chars_first $chars_next  $(first.substitution)  $(next.substitution)   $(r) \n");
				
				if (chars_first != chars_next) {
					return 0;
				}
				
				r = chars_first > chars_next;
			} else {			
				r = first.get_first_char () > next.get_first_char ();
			}
			
			return (r) ? 1 : -1;
		});		
	}
}

}
