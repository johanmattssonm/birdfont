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
	public GlyphRange glyph_range; 
	bool malformed = false;
	Font font;
	
	public KerningRange (Font f, string? name = null, string tip = "") {
		base (null , tip);

		font = f;
		
		glyph_range = new GlyphRange (); 
		
		if (name != null) {
			base.name = (!) name;
		}
		
		panel_press_action.connect ((selected, button, tx, ty) => {
			KerningDisplay kerning_display = MainWindow.get_kerning_display ();
			
			if (button == 3 || KeyBindings.modifier == CTRL) {
				update_kerning_classes ();
			} else if (malformed) {
				kerning_display.show_parse_error ();
			} else if (button == 1 && !glyph_range.is_empty ()) {
				kerning_display.add_range (glyph_range);
			}
		});

		panel_move_action.connect ((selected, button, tx, ty) => {
			return false;
		});

		panel_release_action.connect ((selected, button, tx, ty) => {
		});
	}
	
	public void update_spacing_class () {
		set_ranges (ranges);
	}
	
	public void set_ranges (string r) {
		GlyphRange glyph_range = new GlyphRange ();
		SpacingData spacing = font.get_spacing ();
		string new_range;
		string ch;
		
		try {
			glyph_range.parse_ranges (r);
			new_range = glyph_range.get_all_ranges ();
			
			malformed = false;
			
			for (int i = 0; i < glyph_range.get_length (); i++) {
				ch = glyph_range.get_char (i);
				
				foreach (string c in spacing.get_all_connections (ch)) {
					if (!glyph_range.has_character (c) && c != "" && c != "?") {
						new_range += " " + GlyphRange.serialize (c);
					}
				}
				
				if (!font.has_glyph (ch)) {
					malformed = true;
				}
			}
			
			set_one_range (new_range);
		} catch (GLib.MarkupError e) {
			warning (e.message);
			malformed = true;
		}
	}
		
	private void set_one_range (string r) throws MarkupError {
		GlyphRange old = new GlyphRange ();
		
		old.parse_ranges (ranges);
		old.set_class (true);
		
		ranges = r;
		name = r;

		glyph_range.empty ();
		glyph_range.parse_ranges (r);
		glyph_range.set_class (true);

		font.spacing.kerning_classes.update_range (old, glyph_range);
	}
	
	public void update_kerning_classes () {
		KerningDisplay kerning_display = MainWindow.get_kerning_display ();
		TextListener listener = new TextListener (t_("Kerning class"), ranges, t_("Set"));
		listener.signal_text_input.connect ((text) => {
			set_ranges (text);
			Toolbox.redraw_tool_box ();
		});
		
		listener.signal_submit.connect (() => {
			MainWindow.get_kerning_display ().suppress_input = false;
			TabContent.hide_text_input ();
			
			// remove all empty classes
			if (ranges == "") {
				glyph_range.empty ();
				KerningTools.remove_empty_classes ();
			}
		});
		
		kerning_display.suppress_input = true;
		
		TabContent.show_text_input (listener);
	}
	
	public override void draw (Context cr) {
		double xt, yt;
		Text label_text;

		xt = x + 5;
		yt = y + 10;
		
		cr.save ();
	
		label_text = new Text ();
		label_text.set_text (name);
		Theme.text_color (label_text, "Text Foreground");
		label_text.set_font_size (18);
		label_text.widget_x = x;
		label_text.widget_y = y;
		label_text.draw (cr);
		
		cr.restore ();
	}
}

}
