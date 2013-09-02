/*
    Copyright (C) 2012, 2013 Johan Mattsson

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

public class DrawingTools : ToolCollection  {
	GlyphCanvas glyph_canvas;
	
	public List<Expander> expanders;
	
	Expander draw_tools;
	Expander grid_expander;
	Expander shape_tools;
	
	BackgroundTool move_background;
	CutBackgroundTool cut_background;
	
	public SpinButton background_scale = new SpinButton ();
	public static SpinButton precision;
	
	public int allocation_width = 0;
	public int allocation_height = 0;
	
	ImageSurface? toolbox_background = null;
	
	public static PointType point_type = PointType.DOUBLE_CURVE;
	
	public DrawingTools (GlyphCanvas main_glyph_canvas) {
		glyph_canvas = main_glyph_canvas;

		toolbox_background = Icons.get_icon ("toolbox_background.png");
		
		draw_tools = new Expander ();
		shape_tools = new Expander ();
			
		Expander path_tool_modifiers = new Expander ();
		Expander draw_tool_modifiers = new Expander ();
		Expander edit_point_modifiers = new Expander ();
		Expander characterset_tools = new Expander ();
		Expander test_tools = new Expander ();
		Expander guideline_tools = new Expander ();
		Expander view_tools = new Expander ();
		Expander grid = new Expander ();
		
		Expander background_tools = new Expander ();
		Expander style_tools = new Expander ();
		
		grid_expander = grid;

		// Draw tools
		PenTool pen_tool = new PenTool ("pen_tool");
		draw_tools.add_tool (pen_tool);
	
		ZoomTool zoom_tool = new ZoomTool ("zoom_tool");
		draw_tools.add_tool (zoom_tool);

		Tool move_tool = new MoveTool ("move");
		draw_tools.add_tool (move_tool);
		
		Tool resize_tool = new ResizeTool ("resize");
		draw_tools.add_tool (resize_tool);
		
		// quadratic Bézier points
		Tool quadratic_points = new Tool ("quadratic_points", _("Create quadratic Bézier curves"));
		quadratic_points.select_action.connect ((self) => {
			point_type = PointType.QUADRATIC;
			Preferences.set ("point_type", "quadratic_points");
		});
		draw_tool_modifiers.add_tool (quadratic_points);		

		// cubic Bézier points
		Tool cubic_points = new Tool ("cubic_points", _("Create cubic Bézier curves"));
		cubic_points.select_action.connect ((self) => {
			point_type = PointType.CUBIC;
			Preferences.set ("point_type", "cubic_points");
		});
		draw_tool_modifiers.add_tool (cubic_points);

		// two quadratic points off curve points for each quadratic control point
		Tool double_points = new Tool ("double_points", _("Quadratic path with two line handles"));
		double_points.select_action.connect ((self) => {
			point_type = PointType.DOUBLE_CURVE;
			Preferences.set ("point_type", "double_points");
		});
		draw_tool_modifiers.add_tool (double_points);

		// convert point
		Tool convert_points = new Tool ("convert_point", _("Convert selected points"));
		convert_points.select_action.connect ((self) => {
			PenTool.convert_point_types ();
			MainWindow.get_current_glyph ().update_view ();
		});
		convert_points.set_persistent (false);
		draw_tool_modifiers.add_tool (convert_points);

		// tie edit point handles
		Tool tie_handles = new Tool ("tie_point", _("Tie curve handles for the selected edit point"), 'w');
		tie_handles.select_action.connect ((self) => {
			bool tie;
			EditPoint p;
			
			if (PenTool.move_selected_handle) {
				p = PenTool.active_handle.parent;
				tie = !p.tie_handles;
				
				if (tie) {
					p.process_tied_handle ();
					p.set_reflective_handles (false);
				}
				
				p.set_tie_handle (tie);
				
				PenTool.handle_selection.path.update_region_boundries ();
			} else {
				foreach (PointSelection ep in PenTool.selected_points) {
					tie = !ep.point.tie_handles;
					
					if (tie) {
						ep.point.process_tied_handle ();
						ep.point.set_reflective_handles (false);
					}
				
					ep.point.set_tie_handle (tie);
					ep.path.update_region_boundries ();
				}
			}
			
			MainWindow.get_current_glyph ().update_view ();
		});
		edit_point_modifiers.add_tool (tie_handles);
		
		// symmetrical handles
		Tool reflect_handle = new Tool ("symmetric", _("Symmetrical handles"), 'r');
		reflect_handle.select_action.connect ((self) => {
			bool symmetrical;
			PointSelection ep;
			if (PenTool.selected_points.length () > 0) {
				ep = PenTool.selected_points.first ().data;
				symmetrical = ep.point.reflective_handles;
				foreach (PointSelection p in PenTool.selected_points) {
					p.point.set_reflective_handles (!symmetrical);
					p.point.process_symmetrical_handles ();
					
					if (symmetrical) {
						ep.point.set_tie_handle (false);
					}
					
					p.path.update_region_boundries ();
				}
				MainWindow.get_current_glyph ().update_view ();
			}
		});
		edit_point_modifiers.add_tool (reflect_handle);

		Tool create_line = new Tool ("create_line", _("Convert segment to line."), 'r');
		create_line.select_action.connect ((self) => {
			PenTool.convert_segment_to_line ();
			MainWindow.get_current_glyph ().update_view ();
		});
		edit_point_modifiers.add_tool (create_line);
	
		// path tools
		Tool union_paths_tool = new Tool ("union_paths", _("Merge paths"));
		union_paths_tool.select_action.connect ((self) => {
			Glyph g = MainWindow.get_current_glyph ();
			g.merge_all ();
		});
		path_tool_modifiers.add_tool (union_paths_tool);
		
		Tool reverse_path_tool = new Tool ("reverse_path", _("Create counter from outline"));
		reverse_path_tool.select_action.connect ((self) => {
			Glyph g = MainWindow.get_current_glyph ();
			
			foreach (Path p in g.active_paths) {
				p.reverse ();
			}
		
			g.redraw_area (0, 0, g.allocation.width, g.allocation.height);
		});
		path_tool_modifiers.add_tool (reverse_path_tool);

		Tool move_layer = new Tool ("move_layer", _("Move to path to the bottom layer"), 'd');
		move_layer.select_action.connect ((self) => {
			Glyph g = MainWindow.get_current_glyph ();

			foreach (Path p in g.active_paths) {
				g.path_list.remove (p);
				g.path_list.prepend (p);
			}
		});
		path_tool_modifiers.add_tool (move_layer);

		Tool flip_vertical = new Tool ("flip_vertical", _("Flip path vertically"));
		flip_vertical.select_action.connect ((self) => {
			MoveTool.flip_vertical ();
			MainWindow.get_current_glyph ().update_view ();
		});
		path_tool_modifiers.add_tool (flip_vertical);

		Tool flip_horizontal = new Tool ("flip_horizontal", _("Flip path horizontally"));
		flip_horizontal.select_action.connect ((self) => {
			MoveTool.flip_horizontal ();
			MainWindow.get_current_glyph ().update_view ();
		});
		path_tool_modifiers.add_tool (flip_horizontal);
		
		// Character set tools
		Tool full_unicode = new Tool ("utf_8", _("Show full unicode characters set"), 'f', CTRL);
		full_unicode.select_action.connect ((self) => {
				MainWindow.get_tab_bar ().add_unique_tab (new OverView (), 100, false);	
				OverView o = MainWindow.get_overview ();
				GlyphRange gr = new GlyphRange ();
				
				if (!BirdFont.get_current_font ().initialised) {
					MenuTab.new_file ();
				}
				
				DefaultCharacterSet.use_full_unicode_range (gr);
				o.set_glyph_range (gr);
				MainWindow.get_tab_bar ().select_tab_name ("Overview");
			});
		characterset_tools.add_tool (full_unicode);

		Tool custom_character_set = new Tool ("custom_character_set", _("Show default characters set"), 'r', CTRL);
		custom_character_set.select_action.connect ((self) => {
			MainWindow.get_tab_bar ().add_unique_tab (new OverView (), 100, false);
			OverView o = MainWindow.get_overview ();
			GlyphRange gr = new GlyphRange ();

			if (!BirdFont.get_current_font ().initialised) {
				MenuTab.new_file ();
			}
			
			DefaultCharacterSet.use_default_range (gr);
			o.set_glyph_range (gr);
			MainWindow.get_tab_bar ().select_tab_name ("Overview");
		});
		characterset_tools.add_tool (custom_character_set);

		Tool avalilable_characters = new Tool ("available_characters", _("Show all characters in the font"), 'd', CTRL);
		avalilable_characters.select_action.connect ((self) => {
			MainWindow.get_tab_bar ().add_unique_tab (new OverView (), 100, false);
			OverView o = MainWindow.get_overview ();
			
			if (!BirdFont.get_current_font ().initialised) {
				MenuTab.new_file ();
			}
			
			o.display_all_available_glyphs ();
			MainWindow.get_tab_bar ().select_tab_name ("Overview");
		});
		characterset_tools.add_tool (avalilable_characters);

		Tool delete_glyph = new Tool ("delete_selected_glyph", _("Delete selected glyph"));
		delete_glyph.select_action.connect ((self) => {
			OverView o = MainWindow.get_overview ();
			
			if (MainWindow.get_current_display () is OverView) {
				o.delete_selected_glyph ();
			}
			
			MainWindow.get_tab_bar ().select_tab_name ("Overview");
		});
		characterset_tools.add_tool (delete_glyph);

		if (BirdFont.has_argument ("--test")) {
			Tool test_case = new Tool ("test_case");
			test_case.select_action.connect((self) => {
					if (self.is_selected ()) {
						if (TestBirdFont.is_running ()) {
							TestBirdFont.pause ();
						} else {
							TestBirdFont.continue ();
						}
					}
				});
			test_tools.add_tool (test_case);

			Tool slow_test = new Tool ("slow_test");
			slow_test.select_action.connect((self) => {
					bool s = TestBirdFont.is_slow_test ();
					TestBirdFont.set_slow_test (!s);
					s = TestBirdFont.is_slow_test ();
					self.set_selected (s);
				});
		
			test_tools.add_tool (slow_test);
					
			// Run from commad line
			string? st = BirdFont.get_argument ("--test");
			if (st != null && ((!)st).char_count () > 0) {
				IdleSource idle = new IdleSource ();

				idle.set_callback (() => {			
					MainWindow.get_toolbox ().select_tool (test_case);
					return false;
				});
				
				idle.attach (null);
			}
			
			if (BirdFont.has_argument ("--slow")) {
				MainWindow.get_toolbox ().select_tool (slow_test);
			}
			
		}
		
		// guide lines, grid and other guidlines
		Tool help_lines = new Tool ("help_lines", _("Show guidelines"), 'l');
		help_lines.select_action.connect ((self) => {
				bool h;
				h = GlyphCanvas.get_current_glyph ().get_show_help_lines ();
				GlyphCanvas.get_current_glyph ().set_show_help_lines (!h);
				self.set_selected (!h);
				GlyphCanvas.get_current_glyph ().redraw_help_lines ();
			});	

		guideline_tools.add_tool (help_lines);

		Tool xheight_help_lines = new Tool ("show_xheight_helplines", _("Show guidelines for x-height and baseline"), 'x');
		xheight_help_lines.select_action.connect ((self) => {
			Glyph g = MainWindow.get_current_glyph ();
			bool v = !g.get_xheight_lines_visible ();
			g.set_xheight_lines_visible (v);
			self.set_selected (v);
			MainWindow.get_glyph_canvas ().redraw ();
			
			if (v && !help_lines.is_selected ()) {
				MainWindow.get_toolbox ().select_tool (help_lines);
			}
			
		});
		guideline_tools.add_tool (xheight_help_lines);

		Tool background_help_lines = new Tool ("background_help_lines", _("Show guidelines at top and bottom margin"), 't');
		background_help_lines.select_action.connect ((self) => {
			Glyph g = MainWindow.get_current_glyph ();
			bool v = !g.get_margin_lines_visible ();
			g.set_margin_lines_visible (v);
			self.set_selected (v);
			MainWindow.get_glyph_canvas ().redraw ();
			
			if (v && !help_lines.is_selected ()) {
				MainWindow.get_toolbox ().select_tool (help_lines);
			}
		});
		guideline_tools.add_tool (background_help_lines);

		Tool new_grid = new GridTool ("new_grid");
		guideline_tools.add_tool (new_grid);

		// Zoom tools 
		Tool zoom_in = new Tool ("zoom_in", _("Zoom in"), '+', CTRL);
		zoom_in.select_action.connect ((self) => {
			zoom_tool.store_current_view ();
			glyph_canvas.get_current_display ().zoom_in ();
		});
		view_tools.add_tool (zoom_in);

		Tool zoom_out = new Tool ("zoom_out", _("Zoom out"), '-', CTRL);
		zoom_out.select_action.connect ((self) => {
			zoom_tool.store_current_view ();
			glyph_canvas.get_current_display ().zoom_out ();
		});
		view_tools.add_tool (zoom_out);

		Tool reset_zoom = new Tool ("zoom_1_1", _("Zoom to scale 1:1"), '0', CTRL);
		reset_zoom.select_action.connect ((self) => {
				zoom_tool.store_current_view ();
				glyph_canvas.get_current_display ().reset_zoom ();
				glyph_canvas.redraw_area(0, 0, glyph_canvas.allocation.width, glyph_canvas.allocation.height);
			});
		view_tools.add_tool (reset_zoom);

		Tool full_glyph = new Tool ("full_glyph", _("Show full glyph"));
		full_glyph.select_action.connect((self) => {
			zoom_tool.store_current_view ();
			zoom_tool.zoom_full_glyph ();
		});
		view_tools.add_tool (full_glyph);

		Tool zoom_boundries = new Tool ("zoom_boundries", _("Zoom in at region boundries"), 'v');
		zoom_boundries.select_action.connect((self) => {
			zoom_tool.store_current_view ();
			glyph_canvas.get_current_display ().zoom_max ();
		});
		view_tools.add_tool (zoom_boundries);

		Tool zoom_bg = new Tool ("zoom_background_image", _("Zoom in background image"));
		zoom_bg.select_action.connect((self) => {
			if (MainWindow.get_current_glyph ().get_background_image () != null) {
				zoom_tool.store_current_view ();					
				glyph_canvas.get_current_display ().reset_zoom ();
				
				zoom_tool.zoom_full_background_image ();
				
				glyph_canvas.redraw_area(0, 0, glyph_canvas.allocation.width, glyph_canvas.allocation.height);
			}
		});
		view_tools.add_tool (zoom_bg);

		Tool zoom_prev = new Tool ("prev", _("Previous view"), 'j', CTRL);
		zoom_prev.select_action.connect((self) => {
			zoom_tool.previous_view ();
		});
		view_tools.add_tool (zoom_prev);

		Tool zoom_next = new Tool ("next", _("Next view"), 'l', CTRL);
		zoom_next.select_action.connect((self) => {
			zoom_tool.next_view ();
		});
		view_tools.add_tool (zoom_next);
		
		// shape tools 
		Tool circle = new CircleTool ("circle");
		shape_tools.add_tool (circle);
		
		Tool rectangle = new RectangleTool ("rectangle");
		shape_tools.add_tool (rectangle);
								
		// background tools
		background_scale = new SpinButton ("scale_background", _("Set size for background image"));
		background_scale.set_int_value ("1.000");
		
		background_scale.new_value_action.connect((self) => {
			background_scale.select_action (self);
		});
		
		background_scale.select_action.connect((self) => {
			SpinButton sb = (SpinButton) self;
			Glyph g = MainWindow.get_current_glyph ();
			GlyphBackgroundImage? img = g.get_background_image ();
			double s = sb.get_value ();
			
			if (img != null) {
				((!)img).set_img_scale (s, s);
			}
			
			MainWindow.get_glyph_canvas ().redraw ();
		});
		
		background_tools.add_tool (background_scale);		

		BackgroundTool move_background = new BackgroundTool ("move_background");			
		background_tools.add_tool (move_background);
		this.move_background = move_background;
		
		CutBackgroundTool cut_background = new CutBackgroundTool ("cut_background");
		background_tools.add_tool (cut_background);
		this.cut_background = cut_background;
		
		Tool show_bg = new Tool ("show_background", _("Show/hide background image"));
		show_bg.select_action.connect ((self) => {
			Glyph g = MainWindow.get_current_glyph ();
			g.set_background_visible (!g.get_background_visible ());
			MainWindow.get_glyph_canvas ().redraw ();
		});
		background_tools.add_tool (show_bg);

		Tool bg_selection = new Tool ("insert_background", _("Insert a new background image"));
		bg_selection.select_action.connect((self) => {
			Glyph? g = null;
			FontDisplay fd = MainWindow.get_current_display ();
			TooltipArea tp = MainWindow.get_tool_tip ();
			tp.show_text (_("Creating thumbnails"));
			
			Tool.yield ();
		
			if (fd is Glyph) {
				g = (Glyph) fd;
			} else {
				return;
			}
			
			BackgroundSelection bgs = new BackgroundSelection ();
			MainWindow.get_tab_bar ().add_unique_tab (bgs , 120, false);
			
			tp.show_text ("");
		});
		
		bg_selection.set_show_background (true);
		background_tools.add_tool (bg_selection);
		
		SpinButton background_contrast = new SpinButton ("background_contrast", _("Set contrast for background image"));
		background_contrast.set_value_round (1);

		background_contrast.new_value_action.connect ((self) => {
			background_contrast.select_action (self);
		});
		
		background_contrast.select_action.connect ((self) => {		
			Glyph g = MainWindow.get_current_glyph ();
			GlyphBackgroundImage? bg = g.get_background_image ();
			GlyphBackgroundImage b;
			
			if (bg != null) {
				b = (!) bg;
				b.set_contrast (background_contrast.get_value ());
			}
		});

		// color and style
		ColorTool stroke_color = new ColorTool (_("Stroke color"));
		stroke_color.color_updated.connect (() => {
			Path.line_color_r = stroke_color.color_r;
			Path.line_color_g = stroke_color.color_g;
			Path.line_color_b = stroke_color.color_b;
			Path.line_color_a = stroke_color.color_a;

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
		style_tools.add_tool (stroke_color);
		
		SpinButton stroke_width;
		stroke_width = new SpinButton ("stroke_width", _("Stroke width"));
		
		if (Preferences.get ("stroke_width") == "") {
			stroke_width.set_value_round (1);
		} else {
			stroke_width.set_value (Preferences.get ("stroke_width"));
		}
		
		stroke_width.new_value_action.connect((self) => {
			Glyph g = MainWindow.get_current_glyph ();
			Path.stroke_width = stroke_width.get_value ();
			Path.stroke_width = Math.sqrt (Path.stroke_width);
			g.redraw_area (0, 0, g.allocation.width, g.allocation.height);
			Preferences.set ("stroke_width", @"$(Path.stroke_width)");
			MainWindow.get_toolbox ().redraw ((int) stroke_width.x, (int) stroke_width.y, 70, 70);
		});
		style_tools.add_tool (stroke_width);
		stroke_width.set_max (4);
		stroke_width.set_min (0.2);

		ColorTool handle_color = new ColorTool (_("Handle color"));
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
		style_tools.add_tool (handle_color);

		// adjust precision
		string precision_value = Preferences.get ("precision");
		
		precision = new SpinButton ("precision", _("Set precision"));
		
		if (precision_value != "") {
			precision.set_value (precision_value);
		} else {
			precision.set_value_round (1);
		}
		
		precision.new_value_action.connect ((self) => {
			MainWindow.get_toolbox ().select_tool (precision);
			
			Preferences.set ("precision", self.get_display_value ());
			MainWindow.get_toolbox ().redraw ((int) precision.x, (int) precision.y, 70, 70);
		});

		precision.select_action.connect((self) => {
			pen_tool.set_precision (((SpinButton)self).get_value ());
		});
		
		precision.set_min (0.001);
		precision.set_max (1);
		
		style_tools.add_tool (precision);

		Tool show_all_line_handles = new Tool ("show_all_line_handles", _("Show all control point handles or only handles for the selected points."));
		show_all_line_handles.select_action.connect((self) => {
			Path.show_all_line_handles = !Path.show_all_line_handles;
			Glyph g = MainWindow.get_current_glyph ();
			g.redraw_area (0, 0, g.allocation.width, g.allocation.height);			
		});
		style_tools.add_tool (show_all_line_handles);

		// fill color
		ColorTool fill_color = new ColorTool (_("Object color"));
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
		style_tools.add_tool (fill_color);

		Tool fill_open_path = new Tool ("fill_open_path", _("Set fill color for open paths."));
		fill_open_path.select_action.connect((self) => {
			Path.fill_open_path = !Path.fill_open_path;
			Glyph g = MainWindow.get_current_glyph ();
			g.redraw_area (0, 0, g.allocation.width, g.allocation.height);			
		});
		style_tools.add_tool (fill_open_path);
		
		// FIXME transparency on windows

		draw_tools.set_open (true);
		draw_tool_modifiers.set_open (true);
		edit_point_modifiers.set_open (true);
		path_tool_modifiers.set_open (true);
		view_tools.set_open (true);
		grid.set_open (true);
		characterset_tools.set_open (true);
		test_tools.set_open (true);
		guideline_tools.set_open (true);
		shape_tools.set_open (true);
		background_tools.set_open (true);
		style_tools.set_open (true);
		
		add_expander (draw_tools);
		add_expander (draw_tool_modifiers);
		add_expander (edit_point_modifiers);
		add_expander (path_tool_modifiers);	
		
		add_expander (characterset_tools);
		add_expander (guideline_tools);
		add_expander (grid);
		add_expander (view_tools);
		add_expander (shape_tools);
		add_expander (background_tools);
		add_expander (style_tools);
		
		// Fixa: add_expander (trace);
		if (BirdFont.has_argument ("--test")) {
			add_expander (test_tools);
		}
		
		draw_tools.set_persistent (true);
		draw_tools.set_unique (true);
		
		draw_tool_modifiers.set_persistent (true);
		draw_tool_modifiers.set_unique (true);

		edit_point_modifiers.set_persistent (false);
		edit_point_modifiers.set_unique (false);
		
		path_tool_modifiers.set_persistent (false);
		path_tool_modifiers.set_unique (false);

		characterset_tools.set_persistent (true);
		characterset_tools.set_unique (true);
		
		test_tools.set_persistent (true);
	
		guideline_tools.set_persistent (true);
		guideline_tools.set_unique (false);
		
		grid.set_persistent (true);
		grid.set_unique (true);
		grid.set_open (false);
		
		shape_tools.set_persistent (true);
		shape_tools.set_unique (true);
		
		background_tools.set_persistent (true);
		background_tools.set_unique (true);
	
		style_tools.set_persistent (true);
		style_tools.set_unique (true);
		
		// let these tools progagate events even when other tools are selected			
		foreach (Tool t in draw_tools.tool) {
			t.editor_events = true;
		}

		foreach (Tool t in shape_tools.tool) {
			t.editor_events = true;
			t.persistent = true;
		}
		
		move_background.editor_events = true;
		cut_background.editor_events = true;
				
		move_background.persistent = true;
		cut_background.persistent = true;

		precision.persistent = true;
		stroke_width.persistent = true;
		
		// Default selection
		IdleSource idle = new IdleSource ();
		idle.set_callback (() => {
			MainWindow.get_toolbox ().reset_active_tool ();
		
			pen_tool.set_selected (true);
			
			select_draw_tool ();			
			set_point_type_from_preferences ();
			
			if (GlyphCanvas.get_current_glyph ().get_show_help_lines ()) {
				help_lines.set_selected (true);
				help_lines.set_active (false);
			}

			add_new_grid ();
			add_new_grid ();
			
			MainWindow.get_toolbox ().move (0, 0);
			
			return false;
		});
		idle.attach (null);
	}

	public static void set_point_type_from_preferences () {
		string type = Preferences.get ("point_type");
		if (type == "double_points") {
			Toolbox.select_tool_by_name ("double_points");
		} else if (type == "quadratic_points") {
			Toolbox.select_tool_by_name ("quadratic_points");
		} if (type == "cubic_points") {
			Toolbox.select_tool_by_name ("cubic_points");
		}
	}
	
	public override unowned List<Expander> get_expanders () {
		return expanders;
	}
	
	/** Insert new points of this type. */
	public static PointType get_selected_point_type () {
		return point_type;
	}

	private void select_draw_tool () {
		Toolbox.select_tool_by_name ("pen_tool");
	}
	
	public void remove_all_grid_buttons () {
		while (grid_expander.tool.length () > 0) {
			grid_expander.tool.remove_link (grid_expander.tool.last ());
		}
		
		while (GridTool.sizes.length () > 0) {
			GridTool.sizes.remove_link (GridTool.sizes.first ());
		}
		
		grid_expander.set_open (true);
		MainWindow.get_toolbox ().update_expanders ();
		MainWindow.get_toolbox ().redraw (0, 0, allocation_width, allocation_height);		
	}
	
	public void parse_grid (string spin_button_value) {
		SpinButton sb = add_new_grid ();
		sb.set_value (spin_button_value);
		MainWindow.get_toolbox ().select_tool (sb);
	}

	public SpinButton add_new_grid () {
		SpinButton grid_width = new SpinButton ("grid_width", _("Set size for grid"));
		Toolbox tb = MainWindow.get_toolbox ();
		
		grid_width.new_value_action.connect((self) => {
			grid_width.select_action (grid_width);
		});

		grid_width.select_action.connect((self) => {
			SpinButton sb = (SpinButton) self;
			GridTool.set_grid_width (sb.get_value ());
			MainWindow.get_glyph_canvas ().redraw ();
		});
				
		grid_expander.add_tool (grid_width);

		GridTool.sizes.append (grid_width);

		grid_expander.set_open (true);
		tb.update_expanders ();
		
		tb.redraw (0, 0, allocation_width, allocation_height);
		
		tb.select_tool (grid_width);
		grid_width.set_active (false);
		
		return grid_width;
	}

	public void remove_current_grid () {
		Tool grid_width;
		Toolbox tb = MainWindow.get_toolbox ();
		
		foreach (Tool t in grid_expander.tool) {
			if (t.is_selected () && t is SpinButton) {
				GridTool.sizes.remove ((SpinButton)t);
				grid_expander.tool.remove (t);
				break;
			}
		}
		
		if (grid_expander.tool.length () > 0) {
			grid_width = grid_expander.tool.last ().data;
			tb.select_tool (grid_width);
			grid_width.set_active (false);
		}
		
		MainWindow.get_toolbox ().update_expanders ();
		tb.redraw (0, 0, allocation_width, allocation_height);
	}
	
	private void add_expander (Expander e) {
		expanders.append (e);
	}
}

}
