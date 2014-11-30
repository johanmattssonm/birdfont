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

public class SettingsDisplay : FontDisplay {
	
	double scroll = 0;
	double content_height = 1;
	WidgetAllocation allocation;
	Gee.ArrayList<SettingsItem> tools;

	public static SpinButton precision;
	
	SettingsItem new_key_bindings = new SettingsItem.head_line ("");
	bool update_key_bindings = false;
	
	public SettingsDisplay () {
		allocation = new WidgetAllocation ();
		tools = new Gee.ArrayList<SettingsItem> ();
		content_height = 200;
		
		// setting items
		tools.add (new SettingsItem.head_line (t_("Settings")));
		
		ColorTool stroke_color = new ColorTool ();
		stroke_color.color_updated.connect (() => {
			Path.line_color_r = stroke_color.color_r;
			Path.line_color_g = stroke_color.color_g;
			Path.line_color_b = stroke_color.color_b;
			Path.line_color_a = stroke_color.color_a;

			if (Path.line_color_a == 0) {
				Path.line_color_a = 1;
			}

			Preferences.set ("line_color_r", @"$(Path.line_color_r)");
			Preferences.set ("line_color_g", @"$(Path.line_color_g)");
			Preferences.set ("line_color_b", @"$(Path.line_color_b)");
			Preferences.set ("line_color_a", @"$(Path.line_color_a)");

			Glyph g = MainWindow.get_current_glyph ();
			g.redraw_area (0, 0, g.allocation.width, g.allocation.height);
		});
		stroke_color.set_r (double.parse (Preferences.get ("line_color_r")));
		stroke_color.set_g (double.parse (Preferences.get ("line_color_g")));
		stroke_color.set_b (double.parse (Preferences.get ("line_color_b")));
		stroke_color.set_a (double.parse (Preferences.get ("line_color_a")));
		tools.add (new SettingsItem (stroke_color, t_("Stroke color")));
		
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
		
		ColorTool handle_color = new ColorTool ();
		handle_color.color_updated.connect (() => {
			Path.handle_color_r = handle_color.color_r;
			Path.handle_color_g = handle_color.color_g;
			Path.handle_color_b = handle_color.color_b;
			Path.handle_color_a = handle_color.color_a;

			Preferences.set ("handle_color_r", @"$(Path.handle_color_r)");
			Preferences.set ("handle_color_g", @"$(Path.handle_color_g)");
			Preferences.set ("handle_color_b", @"$(Path.handle_color_b)");
			Preferences.set ("handle_color_a", @"$(Path.handle_color_a)");

			Glyph g = MainWindow.get_current_glyph ();
			g.redraw_area (0, 0, g.allocation.width, g.allocation.height);
		});
		handle_color.set_r (double.parse (Preferences.get ("handle_color_r")));
		handle_color.set_g (double.parse (Preferences.get ("handle_color_g")));
		handle_color.set_b (double.parse (Preferences.get ("handle_color_b")));
		handle_color.set_a (double.parse (Preferences.get ("handle_color_a")));
		
		tools.add (new SettingsItem (handle_color, t_("Handle color")));

		// adjust precision
		string precision_value = Preferences.get ("precision");
		precision = new SpinButton ("precision");
		
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

		// fill color
		ColorTool fill_color = new ColorTool ();
		fill_color.color_updated.connect (() => {
			Path.fill_color_r = fill_color.color_r;
			Path.fill_color_g = fill_color.color_g;
			Path.fill_color_b = fill_color.color_b;
			Path.fill_color_a = fill_color.color_a;

			Preferences.set ("fill_color_r", @"$(Path.fill_color_r)");
			Preferences.set ("fill_color_g", @"$(Path.fill_color_g)");
			Preferences.set ("fill_color_b", @"$(Path.fill_color_b)");
			Preferences.set ("fill_color_a", @"$(Path.fill_color_a)");

			Glyph g = MainWindow.get_current_glyph ();
			g.redraw_area (0, 0, g.allocation.width, g.allocation.height);
		});
		fill_color.set_r (double.parse (Preferences.get ("fill_color_r")));
		fill_color.set_g (double.parse (Preferences.get ("fill_color_g")));
		fill_color.set_b (double.parse (Preferences.get ("fill_color_b")));
		fill_color.set_a (double.parse (Preferences.get ("fill_color_a")));
		tools.add (new SettingsItem (fill_color, t_("Object color")));

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
		
		tools.add (new SettingsItem.head_line (t_("Key Bindings")));
		
		foreach (MenuItem menu_item in MainWindow.get_menu ().sorted_menu_items) {
			tools.add (new SettingsItem.key_binding (menu_item));
		}
	}

	public override void draw (WidgetAllocation allocation, Context cr) {		
		this.allocation = allocation;
		
		layout ();
		
		// background
		cr.save ();
		cr.rectangle (0, 0, allocation.width, allocation.height);
		cr.set_line_width (0);
		cr.set_source_rgba (51 / 255.0, 54 / 255.0, 59 / 255.0, 1);
		cr.fill ();
		cr.stroke ();
		cr.restore ();
		
		foreach (SettingsItem s in tools) {
			if (-20 * MainWindow.units <= s.y <= allocation.height + 20 * MainWindow.units) {
				s.draw (allocation, cr);
			}
		}
	}	

	void layout () {
		double y = -scroll;
		bool first = true;
		foreach (SettingsItem s in tools) {
			
			if (!first && s.headline) {
				y += 30 * MainWindow.units;
			}
			
			s.y = y;
			
			if (s.button != null) {
				((!) s.button).y = y;
				((!) s.button).x = 20 * MainWindow.units;
			}
			
			if (s.headline) {
				y += 50 * MainWindow.units;
			} else {
				y += 40 * MainWindow.units;
			}
			
			first = false;
		}

		content_height = y + scroll;
	}

	void set_key_bindings (SettingsItem item) {	
		if (new_key_bindings.active) {
			new_key_bindings.active = false;
			update_key_bindings = false;
		} else {	
			new_key_bindings.active = false;
			new_key_bindings = item;
			update_key_bindings = true;
			new_key_bindings.active = true;
		}
	}

	public override void key_release (uint keyval) {
		if (update_key_bindings) {
			if (keyval == Key.BACK_SPACE) {
				update_key_bindings = false;
				new_key_bindings.active = false;
				new_key_bindings.menu_item.modifiers = NONE;
				new_key_bindings.menu_item.key = '\0';	
			} else if (KeyBindings.get_mod_from_key (keyval) == NONE) {
				new_key_bindings.menu_item.modifiers = KeyBindings.modifier;
				new_key_bindings.menu_item.key = (unichar) keyval;
				update_key_bindings = false;
				new_key_bindings.active = false;
			}
			
			MainWindow.get_menu ().write_key_bindings ();
			GlyphCanvas.redraw ();	
		}
	}

	public override void button_press (uint button, double x, double y) {	
		foreach (SettingsItem s in tools) {
			if (s.handle_events && s.button != null) {
				if (((!) s.button).is_over (x, y)) {
					((!) s.button).panel_press_action ((!) s.button, button, x, y);
					((!) s.button).set_selected (! ((!) s.button).selected);
					
					if (((!) s.button).selected) {
						((!) s.button).select_action ((!) s.button);
					}
				}
			}
		}
		GlyphCanvas.redraw ();
	}
	
	public override void button_release (int button, double x, double y) {
		foreach (SettingsItem s in tools) {
			if (s.handle_events && s.button != null) {
				if (((!) s.button).is_over (x, y) || ((!) s.button).is_active ()) {
					((!) s.button).panel_release_action ((!) s.button, button, x, y);
				}
			}
			
			if (s.key_bindings && s.y <= y < s.y + 40 * MainWindow.units && button == 1) {
				set_key_bindings (s);
			}
		}
		GlyphCanvas.redraw ();
	}

	public override void motion_notify (double x, double y) {
		bool consumed = false;
		
		foreach (SettingsItem s in tools) {
			if (s.handle_events && s.button != null) {
				if (((!) s.button).panel_move_action ((!) s.button, x, y)) {
					consumed = true;
				}
			}
		}
		
		// TODO: ignore scrolling if event is consumed
		if (consumed) {
			GlyphCanvas.redraw ();
		}
	}

	public override string get_label () {
		return t_("Settings");
	}

	public override string get_name () {
		return "Settings";
	}

	public override bool has_scrollbar () {
		return true;
	}
	
	public override void scroll_wheel_down (double x, double y) {
		foreach (SettingsItem s in tools) {
			if (s.handle_events && s.button != null) {
				if (((!) s.button).is_over (x, y)) {
					((!) s.button).scroll_wheel_down_action ((!) s.button);
					return;
				}
			}
		}
		
		scroll += 25 * MainWindow.units;

		if (scroll + allocation.height >=  content_height) {
			scroll = content_height - allocation.height;
		}
		
		update_scrollbar ();
		GlyphCanvas.redraw ();
	}
	
	public override void scroll_wheel_up (double x, double y) {
		foreach (SettingsItem s in tools) {
			if (s.handle_events && s.button != null) {
				if (((!) s.button).is_over (x, y)) {
					((!) s.button).scroll_wheel_up_action ((!) s.button);
					return;
				}
			}
		}
		
		scroll -= 25 * MainWindow.units;
		
		if (scroll < 0) {
			scroll = 0;
		}
		
		update_scrollbar ();
		GlyphCanvas.redraw ();
	}

	public override void selected_canvas () {
		MainWindow.get_toolbox ().set_default_tool_size ();
		update_scrollbar ();
		GlyphCanvas.redraw ();
	}
	
	public override void update_scrollbar () {
		double h = content_height - allocation.height;
		MainWindow.set_scrollbar_size (allocation.height / content_height);
		MainWindow.set_scrollbar_position (scroll /  h);
	}

	public override void scroll_to (double percent) {
		double h = content_height - allocation.height;
		scroll = percent * h;
		GlyphCanvas.redraw ();
	}
}

}
