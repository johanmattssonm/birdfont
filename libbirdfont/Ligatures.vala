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
	
	public Gee.ArrayList<Ligature> ligatures = new Gee.ArrayList<Ligature> ();
	public Gee.ArrayList<ContextualLigature> contextual_ligatures = new Gee.ArrayList<ContextualLigature> ();
	
	public delegate void LigatureIterator (string substitution, string ligature);
	public delegate void SingleLigatureIterator (GlyphSequence substitution, GlyphSequence ligature);

	public delegate void ContextualLigatureIterator (ContextualLigature lig);

	unowned Font font;

	public Ligatures (Font font) {
		this.font = font;
	}
	
	public void get_ligatures (LigatureIterator iter) {
		foreach (Ligature l in ligatures) {
			iter (l.substitution, l.ligature);
		}	
	}

	public void get_contextual_ligatures (ContextualLigatureIterator iter) {
		foreach (ContextualLigature l in contextual_ligatures) {
			iter (l);
		}	
	}

	public void get_single_substitution_ligatures (SingleLigatureIterator iter) {
		get_ligatures ((substitution, ligature) => {
			GlyphCollection? gc;
			GlyphSequence lig;
			GlyphSequence gs;
			string[] subst_names = substitution.split (" ");
			
			lig = new GlyphSequence ();
			foreach (string n in font.get_names (ligature)) {
				gc = font.get_glyph_collection_by_name (n);
				
				if (gc == null) {
					return;
				}
				
				lig.add (((!) gc).get_current ());
			}
			
			gs = new GlyphSequence ();
			foreach (string s in subst_names) {
				gc = font.get_glyph_collection_by_name (s);
				
				if (gc == null) {
					return;
				}
				
				gs.glyph.add (((!) gc).get_current ());
			}
			
			iter (gs, lig);
		});
	}
		
	public int count () {
		return ligatures.size;
	}

	public int count_contextual_ligatures () {
		return contextual_ligatures.size;
	}
	
	public void remove_at (int i) {
		return_if_fail (0 <= i < ligatures.size);
		ligatures.remove_at (i);
	}

	public void remove_contextual_ligatures_at (int i) {
		return_if_fail (0 <= i < contextual_ligatures.size);
		contextual_ligatures.remove_at (i);
	}
		
	public void set_beginning (int index) {
		ContextualLigature lig;
		TextListener listener;
		
		return_if_fail (0 <= index < contextual_ligatures.size);

		lig = contextual_ligatures.get (index);
		listener = new TextListener (t_("Beginning"), lig.backtrack, t_("Set"));
		
		listener.signal_text_input.connect ((text) => {
			lig.backtrack = text;
		});
		
		listener.signal_submit.connect (() => {
			TabContent.hide_text_input ();
			MainWindow.get_ligature_display ().update_rows ();
			sort_ligatures ();
		});
		
		TabContent.show_text_input (listener);			
	}
	
	public void set_middle (int index) {
		ContextualLigature lig;
		TextListener listener;
		
		return_if_fail (0 <= index < contextual_ligatures.size);

		lig = contextual_ligatures.get (index);
		listener = new TextListener (t_("Middle"), lig.input, t_("Set"));
		
		listener.signal_text_input.connect ((text) => {
			lig.input = text;
		});
		
		listener.signal_submit.connect (() => {
			TabContent.hide_text_input ();
			MainWindow.get_ligature_display ().update_rows ();
			sort_ligatures ();
		});
		
		TabContent.show_text_input (listener);		
	}

	public void set_end (int index) {
		ContextualLigature lig;
		TextListener listener;
		
		return_if_fail (0 <= index < contextual_ligatures.size);

		lig = contextual_ligatures.get (index);
		listener = new TextListener (t_("End"), lig.lookahead, t_("Set"));
		
		listener.signal_text_input.connect ((text) => {
			lig.lookahead = text;
		});
		
		listener.signal_submit.connect (() => {
			TabContent.hide_text_input ();
			MainWindow.get_ligature_display ().update_rows ();
			sort_ligatures ();
		});
		
		TabContent.show_text_input (listener);
	}
				
	public void set_ligature (int index) {
		Ligature lig;
		
		return_if_fail (0 <= index < ligatures.size);
		
		lig = ligatures.get (index);
		lig.set_ligature ();
	}

	public void set_contextual_ligature (int index) {
		ContextualLigature lig;
		TextListener listener;
		
		return_if_fail (0 <= index < contextual_ligatures.size);

		lig = contextual_ligatures.get (index);
		listener = new TextListener (t_("Ligature"), lig.ligatures, t_("Set"));
		
		listener.signal_text_input.connect ((text) => {
			lig.ligatures = text;
		});
		
		listener.signal_submit.connect (() => {
			TabContent.hide_text_input ();
			MainWindow.get_ligature_display ().update_rows ();
			sort_ligatures ();
		});
		
		TabContent.show_text_input (listener);			

	}
		
	public void set_substitution (int index) {
		Ligature lig;
		
		return_if_fail (0 <= index < ligatures.size);
		
		lig = ligatures.get (index);
		lig.set_substitution ();
	}
	
	public void add_ligature (string subst, string liga) {
		ligatures.insert (0, new Ligature (liga, subst));
		sort_ligatures ();
	}

	public void add_contextual_ligature (string ligature, string backtrack, string input, string lookahead) {
		ContextualLigature l = new ContextualLigature (font, ligature, backtrack, input, lookahead);
		contextual_ligatures.insert (0, l);
		sort_ligatures ();
	}
	
	public void sort_ligatures () {
		ligatures.sort ((a, b) => {
			Ligature first, next;
			int chars_first, chars_next;
			
			first = (Ligature) a;
			next = (Ligature) b;
			
			chars_first = first.substitution.split (" ").length;
			chars_next = next.substitution.split (" ").length;
							
			return chars_next - chars_first;
		});
		
		contextual_ligatures.sort ((a, b) => {
			ContextualLigature first, next;
			int chars_first, chars_next;
			
			first = (ContextualLigature) a;
			next = (ContextualLigature) b;
			
			chars_first = first.backtrack.split (" ").length;
			chars_first += first.input.split (" ").length;
			chars_first += first.lookahead.split (" ").length;
			
			chars_next = next.backtrack.split (" ").length;
			chars_next += next.input.split (" ").length;
			chars_next += next.lookahead.split (" ").length;		
								
			return chars_next - chars_first;
		});
	}
}

}
