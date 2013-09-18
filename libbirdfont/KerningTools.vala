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
	public static List<Expander> expanders;
	public static int next_class = 0;
	public static Expander classes;
	
	public KerningTools () {
		init ();
	}
	
	public static void init () {
		Expander class_tools = new Expander ();
		classes = new Expander ();
		
		Tool new_kerning_class = new Tool ("kerning_class", t_("Create new kerning class"));
		new_kerning_class.select_action.connect ((self) => {
			classes.add_tool (new KerningRange (@"Kerning class $(++next_class)"));
			Toolbox.redraw_tool_box ();
		});
		class_tools.add_tool (new_kerning_class);

		class_tools.set_persistent (false);
		class_tools.set_unique (false);
		class_tools.set_open (true);

		classes.set_persistent (true);
		classes.set_unique (true);
		classes.set_open (true);
		
		expanders.append (class_tools);
		expanders.append (classes);
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
	
	public static void update_kerning_classes () {
		KerningClasses k = KerningClasses.get_instance ();
		KerningRange kr;
		GlyphRange r;
		int i;
		
		remove_all_kerning_classes ();
		
		for (i = 0; i < k.classes_first.length (); i++) {
			r = k.classes_first.nth (i).data;
			if (r.is_class ()) {
				kr = new KerningRange ();
				kr.set_ranges (r.get_all_ranges ());
				add_unique_class (kr);
			}
			
			r = k.classes_last.nth (i).data;
			if (r.is_class ()) {
				kr = new KerningRange ();
				kr.set_ranges (r.get_all_ranges ());
				add_unique_class (kr);
			}
		}
	}

	private static void remove_all_kerning_classes () {
		while (classes.tool.length () > 0) {
			classes.tool.remove_link (classes.tool.first ());
		}
		
		if (!is_null (MainWindow.get_toolbox ())) {
			MainWindow.get_toolbox ().update_expanders ();
		}
	}
		
	public static void remove_empty_classes () {
		unowned List<Tool> t = classes.tool.first ();
		KerningRange kr;
		
		if (classes.tool.length () == 0) {
			return;
		}
		
		while (true) {
			return_if_fail (!is_null (t) && t.data is KerningRange);
			
			kr = (KerningRange) t.data;
			if (kr.glyph_range.is_empty ()) {
				classes.tool.remove_link (t);
				remove_empty_classes ();
				Toolbox.redraw_tool_box ();
				return;
			}
			
			if (is_null (t.next)) {
				break;
			} else {
				t = t.next;
			}
		}
	}
	
	public override unowned List<Expander> get_expanders () {
		return expanders;
	}
}

}
