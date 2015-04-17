/*
    Copyright (C) 2014 2015 Johan Mattsson

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

public class SettingsTab : SettingsDisplay {
	
	public SettingsTab () {
		base ();
		create_setting_items ();
	}
	
	public override void create_setting_items () {
		tools.clear ();
		
		// setting items
		tools.add (new SettingsItem.head_line (t_("Settings")));
		
		SpinButton stroke_width = new SpinButton ("stroke_width");
		tools.add (new SettingsItem (stroke_width, t_("Stroke width")));
		
		stroke_width.set_max (4);
		stroke_width.set_min (0.002);
		stroke_width.set_value_round (1);

		if (Preferences.get ("stroke_width_for_open_paths") != "") {
			stroke_width.set_value (Preferences.get ("stroke_width_for_open_paths"));
		}

		stroke_width.new_value_action.connect ((self) => {
			Glyph g = MainWindow.get_current_glyph ();
			Path.stroke_width = stroke_width.get_value ();
			g.redraw_area (0, 0, g.allocation.width, g.allocation.height);
			Preferences.set ("stroke_width_for_open_paths", stroke_width.get_display_value ());
			MainWindow.get_toolbox ().redraw ((int) stroke_width.x, (int) stroke_width.y, 70, 70);
		});
		
		Path.stroke_width = stroke_width.get_value ();
		
		// adjust precision
		string precision_value = Preferences.get ("precision");

		if (precision_value != "") {
			precision.set_value (precision_value);
		} else {
#if ANDROID
			precision.set_value_round (0.5);
#else
			precision.set_value_round (1);
#endif
		}
		
		precision.new_value_action.connect ((self) => {
			MainWindow.get_toolbox ().select_tool (precision);
			Preferences.set ("precision", self.get_display_value ());
			MainWindow.get_toolbox ().redraw ((int) precision.x, (int) precision.y, 70, 70);
		});

		precision.select_action.connect((self) => {
			DrawingTools.pen_tool.set_precision (((SpinButton)self).get_value ());
		});
		
		precision.set_min (0.001);
		precision.set_max (1);
		
		tools.add (new SettingsItem (precision, t_("Precision for pen tool")));

		Tool show_all_line_handles = new Tool ("show_all_line_handles");
		show_all_line_handles.select_action.connect((self) => {
			Path.show_all_line_handles = !Path.show_all_line_handles;
			Glyph g = MainWindow.get_current_glyph ();
			g.redraw_area (0, 0, g.allocation.width, g.allocation.height);			
		});
		tools.add (new SettingsItem (show_all_line_handles, t_("Show or hide control point handles")));

		Tool fill_open_path = new Tool ("fill_open_path");
		fill_open_path.select_action.connect((self) => {
			Path.fill_open_path = !Path.fill_open_path;
			Glyph g = MainWindow.get_current_glyph ();
			g.redraw_area (0, 0, g.allocation.width, g.allocation.height);			
		});
		tools.add (new SettingsItem (fill_open_path, t_("Fill open paths.")));

		Tool ttf_units = new Tool ("ttf_units");
		ttf_units.select_action.connect((self) => {
			GridTool.ttf_units = !GridTool.ttf_units;
			Preferences.set ("ttf_units", @"$(GridTool.ttf_units)");
		});
		tools.add (new SettingsItem (ttf_units, t_("Use TTF units.")));

		SpinButton freehand_samples = new SpinButton ("freehand_samples_per_point");
		tools.add (new SettingsItem (freehand_samples, t_("Number of points added by the freehand tool")));
		
		freehand_samples.set_max (9);
		freehand_samples.set_min (0.002);
		
		if (BirdFont.android) {
			freehand_samples.set_value_round (2.5);
		} else {
			freehand_samples.set_value_round (1);
		}

		if (Preferences.get ("freehand_samples") != "") {
			freehand_samples.set_value (Preferences.get ("freehand_samples"));
			DrawingTools.track_tool.set_samples_per_point (freehand_samples.get_value ());
		}

		freehand_samples.new_value_action.connect ((self) => {
			DrawingTools.track_tool.set_samples_per_point (freehand_samples.get_value ());
		});

		SpinButton simplification_threshold = new SpinButton ("simplification_threshold");
		simplification_threshold.set_value_round (0.5);
		tools.add (new SettingsItem (simplification_threshold, t_("Path simplification threshold")));
		
		simplification_threshold.set_max (5);
		freehand_samples.set_min (0.002);

		if (Preferences.get ("simplification_threshold") != "") {
			freehand_samples.set_value (Preferences.get ("simplification_threshold"));
			DrawingTools.pen_tool.set_simplification_threshold (simplification_threshold.get_value ());
		}

		freehand_samples.new_value_action.connect ((self) => {
			DrawingTools.pen_tool.set_simplification_threshold (simplification_threshold.get_value ());
		});

		Tool themes = new Tool ("open_theme_tab");
		themes.set_icon ("theme");
		themes.select_action.connect((self) => {
			MenuTab.show_theme_tab ();
		});
		tools.add (new SettingsItem (themes, t_("Color theme")));
		
		tools.add (new SettingsItem.head_line (t_("Key Bindings")));
		
		foreach (MenuItem menu_item in MainWindow.get_menu ().sorted_menu_items) {
			tools.add (new SettingsItem.key_binding (menu_item));
		}	
	}

	public override string get_label () {
		return t_("Settings");
	}

	public override string get_name () {
		return "Settings";
	}
	
}

}
