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
using Math;

namespace BirdFont {

public class KerningTools : ToolCollection  {
	public static Gee.ArrayList<Expander> expanders = new Gee.ArrayList<Expander> ();
	public static int next_class = 0;
	public static Expander classes;
	public static bool adjust_side_bearings = false;
	
	public static double font_size = 1;
	
	public KerningTools () {
		init ();
	}
	
	public static void init () {
		Expander kerning_tools = new Expander ();
		classes = new Expander ();
		
		Tool new_kerning_class = new Tool ("kerning_class", t_("Create new kerning class."));
		new_kerning_class.select_action.connect ((self) => {
			classes.add_tool (new KerningRange (@"Kerning class $(++next_class)"));
			Toolbox.redraw_tool_box ();
		});
		kerning_tools.add_tool (new_kerning_class);

		Tool text_kerning = new Tool ("kerning_text_input", t_("Use text input to enter kerning values."));
		text_kerning.select_action.connect ((self) => {
			KerningDisplay d = MainWindow.get_kerning_display ();
			d.set_kerning_by_text ();
		});
		kerning_tools.add_tool (text_kerning);

		Tool side_bearings = new Tool ("side_bearings", t_("Adjust right side bearing."));
		side_bearings.select_action.connect ((self) => {
			KerningTools.adjust_side_bearings = !KerningTools.adjust_side_bearings;
			side_bearings.set_selected (KerningTools.adjust_side_bearings);
		});
		side_bearings.set_persistent (true);
		kerning_tools.add_tool (side_bearings);

		Tool insert_last = new Tool ("insert_last_glyph", t_("Insert last edited glyph"));
		insert_last.select_action.connect ((self) => {
			KerningDisplay d = MainWindow.get_kerning_display ();
			d.inser_glyph (MainWindow.get_current_glyph ());
			GlyphCanvas.redraw ();
		});
		kerning_tools.add_tool (insert_last);
				
		SpinButton font_size1 = new SpinButton ("kerning_font_size_one", t_("Font size"));

		font_size1.set_max (9);
		font_size1.set_min (0.1);
		font_size1.set_value_round (0.5);

		if (Preferences.get ("kerning_font_size_one_settings") != "") {
			font_size1.set_value (Preferences.get ("kerning_font_size_one_settings"));
		}

		font_size1.select_action.connect ((self) => {
			Glyph g = MainWindow.get_current_glyph ();
			KerningTools.font_size = font_size1.get_value ();
			g.update_view ();
		});

		font_size1.new_value_action.connect ((self) => {
			Glyph g = MainWindow.get_current_glyph ();
			KerningTools.font_size = font_size1.get_value ();
			g.update_view ();
			Preferences.set ("kerning_font_size_one_settings", font_size1.get_display_value ());
		});
			
		kerning_tools.add_tool (font_size1);

		SpinButton font_size2 = new SpinButton ("kerning_font_size_two", t_("Font size "));

		font_size2.set_max (9);
		font_size2.set_min (0.1);
		font_size2.set_value_round (1);

		if (Preferences.get ("kerning_font_size_two_settings") != "") {
			font_size2.set_value (Preferences.get ("kerning_font_size_two_settings"));
		}

		font_size2.new_value_action.connect ((self) => {
			Glyph g = MainWindow.get_current_glyph ();
			KerningTools.font_size = font_size2.get_value ();
			g.update_view ();
			Preferences.set ("kerning_font_size_two_settings", font_size2.get_display_value ());
		});

		font_size2.select_action.connect ((self) => {
			Glyph g = MainWindow.get_current_glyph ();
			KerningTools.font_size = font_size2.get_value ();
			g.update_view ();
		});
		kerning_tools.add_tool (font_size2);

		kerning_tools.set_persistent (false);
		kerning_tools.set_unique (false);

		classes.set_persistent (true);
		classes.set_unique (true);
		
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
		KerningClasses k = KerningClasses.get_instance ();
		KerningRange kr;
		GlyphRange r;
		int i;
		
		remove_all_kerning_classes ();
		
		for (i = 0; i < k.classes_first.size; i++) {
			r = k.classes_first.get (i);
			if (r.is_class ()) {
				kr = new KerningRange ();
				kr.set_ranges (r.get_all_ranges ());
				add_unique_class (kr);
			}
			
			r = k.classes_last.get (i);
			if (r.is_class ()) {
				kr = new KerningRange ();
				kr.set_ranges (r.get_all_ranges ());
				add_unique_class (kr);
			}
		}
	}

	private static void remove_all_kerning_classes () {
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
}

}
