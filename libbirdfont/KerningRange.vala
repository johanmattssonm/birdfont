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

namespace BirdFont {

/** Representation of a kerning class. */
public class KerningRange : Tool {
	
	public string ranges = "";
	public GlyphRange glyph_range = new GlyphRange (); 
	bool malformed = false;
	
	public KerningRange (string? name = null, string tip = "", unichar key = '\0', uint modifier_flag = 0) {
		base (null , tip, key, modifier_flag);
		
		if (name != null) {
			base.name = (!) name;
		}
		
		panel_press_action.connect ((selected, button, tx, ty) => {
			KerningDisplay kerning_display = KerningDisplay.get_singleton ();
			
			if (button == 3) {
				update_kerning_classes ();
			}
			
			if (malformed) {
				kerning_display.show_parse_error ();
			} else if (button == 1 && !glyph_range.is_empty ()) {
				kerning_display.add_range (glyph_range);
			}
		});

		panel_move_action.connect ((selected, button, tx, ty) => {
			active = is_over (tx, ty);
			
			if (active) {
				MainWindow.get_tool_tip ().show_text (_("Right click to edit the class and left click to kern glyphs in the class."));
			}
		});

		panel_release_action.connect ((selected, button, tx, ty) => {
		});
		
		w = 200;
		h = 17;
	}
	
	public void set_ranges (string r) {
			ranges = r;
			name = r;

			try {
				glyph_range.empty ();
				glyph_range.parse_ranges (r);
				glyph_range.set_class (true);
				
				malformed = false;
				
				// FIXME: create gui tool
				KerningClasses.get_instance ().print_all ();
			} catch (MarkupError e) {
				KerningClasses.get_instance ().print_all ();
				warning (e.message);
				malformed = true;
			}
	}
	
	public void update_kerning_classes () {
		KerningDisplay kerning_display = KerningDisplay.get_singleton ();
		TextListener listener = new TextListener (_("Kerning class"), ranges, _("Set"));
		listener.signal_text_input.connect ((text) => {
			set_ranges (text);
			Toolbox.redraw_tool_box ();
		});
		
		listener.signal_submit.connect (() => {
			KerningDisplay.get_singleton ().suppress_input = false;
			MainWindow.native_window.hide_text_input ();
			
			// remove all empty classes
			if (ranges == "") {
				glyph_range.empty ();
				KerningTools.remove_empty_classes ();
			}
		});
		
		kerning_display.suppress_input = true;
		
		MainWindow.native_window.set_text_listener (listener);
	}
	
	public override void draw (Context cr) {
		double xt, yt;

		xt = x + 27;
		yt = y + 53;
		
		cr.save ();
	
		if (malformed) { 
			cr.set_source_rgba (108/255.0, 0/255.0, 0/255.0, 1);
		} else if (!active) {
			cr.set_source_rgba (99/255.0, 99/255.0, 99/255.0, 1);
		} else {
			cr.set_source_rgba (0, 0, 0, 1);
		}
		
		cr.set_font_size (10);
		cr.select_font_face ("Cantarell", FontSlant.NORMAL, FontWeight.NORMAL);
		cr.move_to (xt, yt);
		cr.show_text (name);
		cr.restore ();
	}
}

}
