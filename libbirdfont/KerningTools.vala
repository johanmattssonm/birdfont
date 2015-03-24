/*
    Copyright (C) 2013 2014 2015 Johan Mattsson

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

public class KerningTools : ToolCollection  {
	public static Gee.ArrayList<Expander> expanders;
	public static int next_class = 0;
	public static Expander classes;
	
	public static double font_size = 1;
	public static ZoomBar zoom_bar;
	
	public static Tool previous_kerning_string;
	public static Tool next_kerning_string;
	
	public KerningTools () {
		init ();
	}
	
	public static void init () {
		Expander kerning_tools = new Expander (t_("Kerning Tools"));
		classes = new Expander ();
		expanders = new Gee.ArrayList<Expander> ();

		Expander font_name = new Expander ();
		font_name.add_tool (new FontName ());

		Expander zoom_expander = new Expander (t_("Font Size"));

		zoom_bar = new ZoomBar ();
		zoom_bar.new_zoom.connect ((z) => {
			font_size = 3 * z;
			
			if (font_size < 0.1) {
				font_size = 0.1;
			}
			
			GlyphCanvas.redraw ();
		});
		zoom_expander.add_tool (zoom_bar);
		
		Tool new_kerning_class = new Tool ("kerning_class", t_("Create new kerning class."));
		new_kerning_class.select_action.connect ((self) => {
			Font font = BirdFont.get_current_font ();
			string label = t_("Kerning class");
			KerningRange kr = new KerningRange (font, @"$label $(++next_class)");
			classes.add_tool (kr);
			Toolbox.redraw_tool_box ();
		});
		kerning_tools.add_tool (new_kerning_class);

		Tool text_kerning = new Tool ("kerning_text_input", t_("Use text input to enter kerning values."));
		text_kerning.select_action.connect ((self) => {
			KerningDisplay d = MainWindow.get_kerning_display ();
			d.set_kerning_by_text ();
		});
		kerning_tools.add_tool (text_kerning);

		Tool insert_last = new Tool ("insert_glyph_from_overview", t_("Insert glyph from overview"));
		insert_last.select_action.connect ((self) => {
			KerningDisplay d = MainWindow.get_kerning_display ();
			GlyphSelection gs = new GlyphSelection ();
			
			gs.selected_glyph.connect ((gc) => {
				d.inser_glyph (gc.get_current ());
				MainWindow.get_tab_bar ().select_tab_name ("Kerning");
			});
			
			GlyphCanvas.set_display (gs);
		});
		kerning_tools.add_tool (insert_last);

		Tool insert_unicode = new Tool ("insert_unichar", t_("Insert character by unicode value"));
		insert_unicode.select_action.connect ((self) => {
			KerningDisplay d = MainWindow.get_kerning_display ();
			d.insert_unichar ();
		});
		kerning_tools.add_tool (insert_unicode);

		string empty_kerning_text = t_("Open a text file with kerning strings first.");
		
		previous_kerning_string = new Tool ("previous_kerning_string", t_("Previous kerning string"));
		previous_kerning_string.select_action.connect ((self) => {
			FontDisplay fd = MainWindow.get_current_display ();
			KerningDisplay d = (KerningDisplay) fd;
			Font f = BirdFont.get_current_font ();
			string w = f.kerning_strings.previous ();
			
			if (f.kerning_strings.is_empty ()) {
				MainWindow.show_message (empty_kerning_text);
			} else if (w == "") {
				MainWindow.show_message (t_("You have reached the beginning of the list."));
			} else {
				d.new_line ();
				d.add_text (w);
			}
		});
		kerning_tools.add_tool (previous_kerning_string);

		next_kerning_string = new Tool ("next_kerning_string", t_("Next kerning string"));
		next_kerning_string.select_action.connect ((self) => {
			FontDisplay fd = MainWindow.get_current_display ();
			KerningDisplay d = (KerningDisplay) fd;
			Font f = BirdFont.get_current_font ();
			string w = f.kerning_strings.next ();
			
			if (f.kerning_strings.is_empty ()) {
				MainWindow.show_message (empty_kerning_text);
			} else if (w == "") {
				MainWindow.show_message (t_("You have reached the end of the list."));
			} else {
				d.new_line ();
				d.add_text (w);
			}	
		});
		kerning_tools.add_tool (next_kerning_string);
				
		kerning_tools.set_persistent (false);
		kerning_tools.set_unique (false);

		classes.set_persistent (true);
		classes.set_unique (true);
		
		expanders.add (font_name);
		expanders.add (zoom_expander);
		expanders.add (kerning_tools);
		expanders.add (classes);
	}
	
	public static void add_unique_class (KerningRange kerning_class) {
		KerningRange k;
		
		if (is_null (classes)) { // FIXME: export without tools
			init ();
		}
		
		foreach (Tool t in classes.tool) {
			if (!(t is KerningRange)) {
				warning ("Tool is not kerning range");
				return;
			}
			
			k = (KerningRange) t;
			if (k.glyph_range.get_all_ranges () == kerning_class.glyph_range.get_all_ranges ()) {
				return;
			}
		}
		
		classes.add_tool (kerning_class);
	}
	
	public static GlyphRange get_kerning_class (int index) {
		if (likely (0 <= index < classes.tool.size)) {
			return ((KerningRange) classes.tool.get (index)).glyph_range;
		} else {
			warning ("Index out of bounds.");
			return new GlyphRange ();
		}
	}
	
	public static void update_kerning_classes () {
		Font font = BirdFont.get_current_font ();
		KerningClasses k = font.get_kerning_classes ();
		KerningRange kr;
		GlyphRange r;
		int i;
		
		remove_all_kerning_classes ();
		
		for (i = 0; i < k.classes_first.size; i++) {
			r = k.classes_first.get (i);
			if (r.is_class ()) {
				kr = new KerningRange (font);
				kr.set_ranges (r.get_all_ranges ());
				add_unique_class (kr);
			}
			
			r = k.classes_last.get (i);
			if (r.is_class ()) {
				kr = new KerningRange (font);
				kr.set_ranges (r.get_all_ranges ());
				add_unique_class (kr);
			}
		}
	}

	private static void remove_all_kerning_classes () {
		if (is_null (classes)) { // FIXME: export without tools
			init ();
		}
		
		classes.tool.clear ();
		
		if (!is_null (MainWindow.get_toolbox ())) {
			MainWindow.get_toolbox ().update_expanders ();
		}
	}
	
	public static void remove_empty_classes () {
		KerningRange kr;
		int i;
		
		if (classes.tool.size == 0) {
			return;
		}
		
		i = 0;
		foreach (Tool t in classes.tool) {
			return_if_fail (t is KerningRange);
			
			kr = (KerningRange) t;
			if (kr.glyph_range.is_empty ()) {
				classes.tool.remove_at (i);
				remove_empty_classes ();
				Toolbox.redraw_tool_box ();
				return;
			}
			
			i++;
		}
	}
	
	public override Gee.ArrayList<Expander> get_expanders () {
		return expanders;
	}
	
	public static void update_spacing_classes () {	
		KerningRange kr;
		
		if (classes.tool.size == 0) {
			return;
		}

		foreach (Tool t in classes.tool) {
			return_if_fail (t is KerningRange);
			
			kr = (KerningRange) t;
			kr.update_spacing_class ();
		}
	}

	public override Gee.ArrayList<string> get_displays () {
		Gee.ArrayList<string> d = new Gee.ArrayList<string> ();
		d.add ("Kerning");
		return d;
	}
}

}
