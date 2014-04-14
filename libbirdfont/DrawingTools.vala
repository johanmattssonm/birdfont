/*
    Copyright (C) 2012, 2013, 2014 Johan Mattsson

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
	
	public static SpinButton precision;
	
	public static PointType point_type = PointType.DOUBLE_CURVE;
	
	public static SpinButton object_stroke;
	
	public static Tool move_tool;
	public static PenTool pen_tool;

	PointTool point_tool;
	ZoomTool zoom_tool;
	Tool resize_tool;
	Tool stroke_tool;
	TrackTool track_tool;
	
	Tool quadratic_points;
	Tool cubic_points;
	Tool double_points;
	Tool convert_points;

	BackgroundTool move_background;
	CutBackgroundTool cut_background;
	Tool show_bg;
	Tool bg_selection;
	SpinButton background_contrast;
	public SpinButton background_scale = new SpinButton ();

	Tool rectangle;
	Tool circle;

	Tool help_lines;
	Tool xheight_help_lines;
	Tool background_help_lines;
		
	public DrawingTools (GlyphCanvas main_glyph_canvas) {
		glyph_canvas = main_glyph_canvas;
		
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
		pen_tool = new PenTool ("pen_tool");
		pen_tool.select_action.connect ((self) => {
			update_drawing_and_background_tools (self);
		});
		draw_tools.add_tool (pen_tool);

		point_tool = new PointTool ("point_tool");
		point_tool.select_action.connect ((self) => {
			update_drawing_and_background_tools (self);
		});
		draw_tools.add_tool (point_tool);

		zoom_tool = new ZoomTool ("zoom_tool");
		zoom_tool.select_action.connect ((self) => {
			update_drawing_and_background_tools (self);
		});
		draw_tools.add_tool (zoom_tool);

		move_tool = new MoveTool ("move");
		move_tool.select_action.connect ((self) => {
			update_drawing_and_background_tools (self);
		});
		draw_tools.add_tool (move_tool);
		
		resize_tool = new ResizeTool ("resize");
		resize_tool.select_action.connect ((self) => {
			update_drawing_and_background_tools (self);
		});
		draw_tools.add_tool (resize_tool);

		stroke_tool = new StrokeTool ("stroke"); // create outline from path
		stroke_tool.select_action.connect ((self) => {
			update_drawing_and_background_tools (self);
		});
		
		if (BirdFont.has_argument ("--test")) {
			draw_tools.add_tool (stroke_tool);
		}
		
		track_tool = new TrackTool ("track"); // draw outline on freehand
		track_tool.select_action.connect ((self) => {
			update_drawing_and_background_tools (self);
		});
		draw_tools.add_tool (track_tool);
		
		// quadratic Bézier points
		quadratic_points = new Tool ("quadratic_points", t_("Create quadratic Bézier curves"));
		quadratic_points.select_action.connect ((self) => {
			point_type = PointType.QUADRATIC;
			Preferences.set ("point_type", "quadratic_points");
			update_type_selection ();
		});
		draw_tool_modifiers.add_tool (quadratic_points);		

		// cubic Bézier points
		cubic_points = new Tool ("cubic_points", t_("Create cubic Bézier curves"));
		cubic_points.select_action.connect ((self) => {
			point_type = PointType.CUBIC;
			Preferences.set ("point_type", "cubic_points");
			update_type_selection ();
		});
		draw_tool_modifiers.add_tool (cubic_points);

		// two quadratic points off curve points for each quadratic control point
		double_points = new Tool ("double_points", t_("Quadratic path with two line handles"));
		double_points.select_action.connect ((self) => {
			point_type = PointType.DOUBLE_CURVE;
			Preferences.set ("point_type", "double_points");
			update_type_selection ();
		});
		draw_tool_modifiers.add_tool (double_points);

		// convert point
		convert_points = new Tool ("convert_point", t_("Convert selected points"));
		convert_points.select_action.connect ((self) => {
			PenTool.convert_point_types ();
			MainWindow.get_current_glyph ().update_view ();
			update_type_selection ();
		});
		convert_points.set_persistent (false);
		draw_tool_modifiers.add_tool (convert_points);

		// edit stroke width
		object_stroke = new SpinButton ("object_stroke", t_("Stroke width"));
		object_stroke.set_int_value ("0.000");
		object_stroke.set_int_step (0.015);
		
		object_stroke.new_value_action.connect((self) => {
			if (move_tool.is_selected () && object_stroke.is_selected ()) {
				StrokeTool.set_stroke_for_selected_paths (object_stroke.get_value ());
			}
			
			if (track_tool.is_selected ()) {
				track_tool.set_stroke_width (object_stroke.get_value ());
			}
			
			if (pen_tool.is_selected ()) {
				pen_tool.set_stroke_width (object_stroke.get_value ());
			}
		});
		
		if (BirdFont.has_argument ("--test")) {
			draw_tool_modifiers.add_tool (object_stroke);
		}

		// tie edit point handles
		Tool tie_handles = new Tool ("tie_point", t_("Tie curve handles for the selected edit point"), 'w');
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
				
				PenTool.handle_selection.path.update_region_boundaries ();
			} else {
				foreach (PointSelection ep in PenTool.selected_points) {
					tie = !ep.point.tie_handles;
					
					if (tie) {
						ep.point.process_tied_handle ();
						ep.point.set_reflective_handles (false);
					}
				
					ep.point.set_tie_handle (tie);
					ep.path.update_region_boundaries ();
				}
			}
			
			MainWindow.get_current_glyph ().update_view ();
		});
		edit_point_modifiers.add_tool (tie_handles);
		
		// symmetrical handles
		Tool reflect_handle = new Tool ("symmetric", t_("Symmetrical handles"), 'r');
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
					
					p.path.update_region_boundaries ();
				}
				MainWindow.get_current_glyph ().update_view ();
			}
		});
		edit_point_modifiers.add_tool (reflect_handle);

		Tool create_line = new Tool ("create_line", t_("Convert segment to line."), 'r');
		create_line.select_action.connect ((self) => {
			PenTool.convert_segment_to_line ();
			MainWindow.get_current_glyph ().update_view ();
		});
		edit_point_modifiers.add_tool (create_line);
	
		// path tools
		Tool union_paths_tool = new Tool ("union_paths", t_("Merge paths"));
		union_paths_tool.select_action.connect ((self) => {
			Glyph g = MainWindow.get_current_glyph ();
			g.merge_all ();
		});
		path_tool_modifiers.add_tool (union_paths_tool);
		
		Tool reverse_path_tool = new Tool ("reverse_path", t_("Create counter from outline"));
		reverse_path_tool.select_action.connect ((self) => {
			Glyph g = MainWindow.get_current_glyph ();
			
			foreach (Path p in g.active_paths) {
				p.reverse ();
			}
		
			g.redraw_area (0, 0, g.allocation.width, g.allocation.height);
		});
		path_tool_modifiers.add_tool (reverse_path_tool);

		Tool move_layer = new Tool ("move_layer", t_("Move to path to the bottom layer"), 'd');
		move_layer.select_action.connect ((self) => {
			Glyph g = MainWindow.get_current_glyph ();

			foreach (Path p in g.active_paths) {
				g.path_list.remove (p);
				g.path_list.insert (0, p);
			}
		});
		path_tool_modifiers.add_tool (move_layer);

		Tool flip_vertical = new Tool ("flip_vertical", t_("Flip path vertically"));
		flip_vertical.select_action.connect ((self) => {
			MoveTool.flip_vertical ();
			MainWindow.get_current_glyph ().update_view ();
		});
		path_tool_modifiers.add_tool (flip_vertical);

		Tool flip_horizontal = new Tool ("flip_horizontal", t_("Flip path horizontally"));
		flip_horizontal.select_action.connect ((self) => {
			MoveTool.flip_horizontal ();
			MainWindow.get_current_glyph ().update_view ();
		});
		path_tool_modifiers.add_tool (flip_horizontal);
		
		// Character set tools
		Tool full_unicode = new Tool ("utf_8", t_("Show full unicode characters set"));
		full_unicode.select_action.connect ((self) => {
				MainWindow.get_tab_bar ().add_unique_tab (new OverView ());	
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

		Tool custom_character_set = new Tool ("custom_character_set", t_("Show default characters set"), 'r', CTRL);
		custom_character_set.select_action.connect ((self) => {
			MainWindow.get_tab_bar ().add_unique_tab (new OverView ());
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

		Tool avalilable_characters = new Tool ("available_characters", t_("Show all characters in the font"), 'd', CTRL);
		avalilable_characters.select_action.connect ((self) => {
			MainWindow.get_tab_bar ().add_unique_tab (new OverView ());
			OverView o = MainWindow.get_overview ();
			
			if (!BirdFont.get_current_font ().initialised) {
				MenuTab.new_file ();
			}
			
			o.display_all_available_glyphs ();
			MainWindow.get_tab_bar ().select_tab_name ("Overview");
		});
		characterset_tools.add_tool (avalilable_characters);

		Tool delete_glyph = new Tool ("delete_selected_glyph", t_("Delete selected glyph"));
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
		help_lines = new Tool ("help_lines", t_("Show guidelines"), 'l');
		help_lines.select_action.connect ((self) => {
				bool h;
				h = GlyphCanvas.get_current_glyph ().get_show_help_lines ();
				GlyphCanvas.get_current_glyph ().set_show_help_lines (!h);
				self.set_selected (!h);
				GlyphCanvas.get_current_glyph ().redraw_help_lines ();
			});	

		guideline_tools.add_tool (help_lines);

		xheight_help_lines = new Tool ("show_xheight_helplines", t_("Show guidelines for x-height and baseline"), 'x');
		xheight_help_lines.select_action.connect ((self) => {
			Glyph g = MainWindow.get_current_glyph ();
			bool v = !g.get_xheight_lines_visible ();
			g.set_xheight_lines_visible (v);
			self.set_selected (v);
			GlyphCanvas.redraw ();
			
			if (v && !help_lines.is_selected ()) {
				MainWindow.get_toolbox ().select_tool (help_lines);
			}
		});
		guideline_tools.add_tool (xheight_help_lines);

		background_help_lines = new Tool ("background_help_lines", t_("Show guidelines at top and bottom margin"), 't');
		background_help_lines.select_action.connect ((self) => {
			Glyph g = MainWindow.get_current_glyph ();
			bool v = !g.get_margin_lines_visible ();
			g.set_margin_lines_visible (v);
			self.set_selected (v);
			GlyphCanvas.redraw ();
			
			if (v && !help_lines.is_selected ()) {
				MainWindow.get_toolbox ().select_tool (help_lines);
			}
		});
		guideline_tools.add_tool (background_help_lines);

		Tool new_grid = new GridTool ("new_grid");
		guideline_tools.add_tool (new_grid);

		// Zoom tools 
		Tool zoom_in = new Tool ("zoom_in", t_("Zoom in"), '+', CTRL);
		zoom_in.select_action.connect ((self) => {
			zoom_tool.store_current_view ();
			glyph_canvas.get_current_display ().zoom_in ();
		});
		view_tools.add_tool (zoom_in);

		Tool zoom_out = new Tool ("zoom_out", t_("Zoom out"), '-', CTRL);
		zoom_out.select_action.connect ((self) => {
			zoom_tool.store_current_view ();
			glyph_canvas.get_current_display ().zoom_out ();
		});
		view_tools.add_tool (zoom_out);

		Tool reset_zoom = new Tool ("zoom_1_1", t_("Use one pixel per unit"), '0', CTRL);
		reset_zoom.select_action.connect ((self) => {
				zoom_tool.store_current_view ();
				glyph_canvas.get_current_display ().reset_zoom ();
				glyph_canvas.redraw_area(0, 0, GlyphCanvas.allocation.width, GlyphCanvas.allocation.height);
			});
		view_tools.add_tool (reset_zoom);

		Tool full_glyph = new Tool ("full_glyph", t_("Show full glyph"));
		full_glyph.select_action.connect((self) => {
			zoom_tool.store_current_view ();
			zoom_tool.zoom_full_glyph ();
		});
		view_tools.add_tool (full_glyph);

		Tool zoom_boundaries = new Tool ("zoom_boundaries", t_("Zoom in on region boundaries"), 'v');
		zoom_boundaries.select_action.connect((self) => {
			zoom_tool.store_current_view ();
			glyph_canvas.get_current_display ().zoom_max ();
		});
		view_tools.add_tool (zoom_boundaries);

		Tool zoom_bg = new Tool ("zoom_background_image", t_("Zoom in on background image"));
		zoom_bg.select_action.connect((self) => {
			if (MainWindow.get_current_glyph ().get_background_image () != null) {
				zoom_tool.store_current_view ();					
				glyph_canvas.get_current_display ().reset_zoom ();
				
				zoom_tool.zoom_full_background_image ();
				
				glyph_canvas.redraw_area(0, 0, GlyphCanvas.allocation.width, GlyphCanvas.allocation.height);
			}
		});
		view_tools.add_tool (zoom_bg);

		Tool zoom_prev = new Tool ("prev", t_("Previous view"), 'j', CTRL);
		zoom_prev.select_action.connect((self) => {
			zoom_tool.previous_view ();
		});
		view_tools.add_tool (zoom_prev);

		Tool zoom_next = new Tool ("next", t_("Next view"), 'l', CTRL);
		zoom_next.select_action.connect((self) => {
			zoom_tool.next_view ();
		});
		view_tools.add_tool (zoom_next);
		
		// shape tools 
		circle = new CircleTool ("circle");
		circle.select_action.connect ((self) => {
			update_drawing_and_background_tools (self);
		});
		shape_tools.add_tool (circle);
		
		rectangle = new RectangleTool ("rectangle");
		rectangle.select_action.connect ((self) => {
			update_drawing_and_background_tools (self);
		});
		shape_tools.add_tool (rectangle);
								
		// background tools
		background_scale = new SpinButton ("scale_background", t_("Set size for background image"));
		background_scale.select_action.connect ((self) => {
			update_drawing_and_background_tools (self);
		});
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
			
			GlyphCanvas.redraw ();
		});
		
		background_tools.add_tool (background_scale);		

		move_background = new BackgroundTool ("move_background");
		move_background.select_action.connect ((self) => {
			update_drawing_and_background_tools (self);
		});	
		background_tools.add_tool (move_background);
		
		cut_background = new CutBackgroundTool ("cut_background");
		cut_background.select_action.connect ((self) => {
			update_drawing_and_background_tools (self);
		});	
		background_tools.add_tool (cut_background);
		
		show_bg = new Tool ("show_background", t_("Show/hide background image"));
		show_bg.select_action.connect ((self) => {
			update_drawing_and_background_tools (self);
		});	
		show_bg.select_action.connect ((self) => {
			Glyph g = MainWindow.get_current_glyph ();
			g.set_background_visible (!g.get_background_visible ());
			GlyphCanvas.redraw ();
		});
		background_tools.add_tool (show_bg);
		
		bg_selection = new Tool ("insert_background", t_("Insert a new background image"));
		bg_selection.select_action.connect ((self) => {
			update_drawing_and_background_tools (self);
		});	
		
		bg_selection.select_action.connect((self) => {
			Glyph? g = null;
			FontDisplay fd = MainWindow.get_current_display ();
			TooltipArea.show_text (t_("Creating thumbnails"));
			
			Tool.yield ();
		
			if (fd is Glyph) {
				g = (Glyph) fd;
			} else {
				return;
			}
			
			BackgroundSelection bgs = new BackgroundSelection ();
			MainWindow.get_tab_bar ().add_unique_tab (bgs);
			
			TooltipArea.show_text ("");
		});
		
		bg_selection.set_show_background (true);
		background_tools.add_tool (bg_selection);
		
		background_contrast = new SpinButton ("background_contrast", t_("Set contrast for background image"));
		background_contrast.select_action.connect ((self) => {
			update_drawing_and_background_tools (self);
		});	
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

		// settings
		ColorTool stroke_color = new ColorTool (t_("Stroke color"));
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
		style_tools.add_tool (stroke_color);
		
		SpinButton stroke_width = new SpinButton ("stroke_width", t_("Stroke width"));

		style_tools.add_tool (stroke_width);
		
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
		
		ColorTool handle_color = new ColorTool (t_("Handle color"));
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
		precision = new SpinButton ("precision", t_("Set precision"));
		
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
			pen_tool.set_precision (((SpinButton)self).get_value ());
		});
		
		precision.set_min (0.001);
		precision.set_max (1);
		
		style_tools.add_tool (precision);

		Tool show_all_line_handles = new Tool ("show_all_line_handles", t_("Show all control point handles or only handles for the selected points."));
		show_all_line_handles.select_action.connect((self) => {
			Path.show_all_line_handles = !Path.show_all_line_handles;
			Glyph g = MainWindow.get_current_glyph ();
			g.redraw_area (0, 0, g.allocation.width, g.allocation.height);			
		});
		style_tools.add_tool (show_all_line_handles);

		// fill color
		ColorTool fill_color = new ColorTool (t_("Object color"));
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

		Tool fill_open_path = new Tool ("fill_open_path", t_("Set fill color for open paths."));
		fill_open_path.select_action.connect((self) => {
			Path.fill_open_path = !Path.fill_open_path;
			Glyph g = MainWindow.get_current_glyph ();
			g.redraw_area (0, 0, g.allocation.width, g.allocation.height);			
		});
		style_tools.add_tool (fill_open_path);

		Tool ttf_units = new Tool ("ttf_units", t_("Use TTF units."));
		ttf_units.select_action.connect((self) => {
			GridTool.ttf_units = !GridTool.ttf_units;
			Preferences.set ("ttf_units", @"$(GridTool.ttf_units)");
		});
		style_tools.add_tool (ttf_units);

		SpinButton freehand_samples = new SpinButton ("freehand_samples_per_point", t_("Adjust the number of samples per point in the freehand tool."));

		style_tools.add_tool (freehand_samples);
		
		freehand_samples.set_max (9);
		freehand_samples.set_min (0.002);
		freehand_samples.set_value_round (1);

		if (Preferences.get ("stroke_width") != "") {
			freehand_samples.set_value (Preferences.get ("stroke_width"));
			track_tool.set_samples_per_point (freehand_samples.get_value ());
		}

		freehand_samples.new_value_action.connect ((self) => {
			track_tool.set_samples_per_point (freehand_samples.get_value ());
		});

		
#if ANDROID
		string delayed_response_value = Preferences.get ("response_delay");
		SpinButton delayed_response = new SpinButton ("response_delay", t_("Delay response for editing tools"));

		delayed_response.set_min (0);
		delayed_response.set_max (9);
				
		if (delayed_response_value != "") {
			delayed_response.set_value (delayed_response_value);
		} else {
			delayed_response.set_value_round (4);
		}
		
		delayed_response.new_value_action.connect ((self) => {
			MainWindow.get_toolbox ().select_tool (delayed_response);
			Preferences.set ("response_delay", self.get_display_value ());
			MainWindow.get_toolbox ().redraw ((int) delayed_response.x, (int) delayed_response.y, 70, 70);
		});

		delayed_response.select_action.connect((self) => {
			pen_tool.set_response_delay (((SpinButton)self).get_value ());
		});
		
		pen_tool.set_response_delay (delayed_response.get_value ());
		style_tools.add_tool (delayed_response);
#endif

		// selection policy
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
		draw_tools.set_unique (false);
		
		draw_tool_modifiers.set_persistent (true);
		draw_tool_modifiers.set_unique (false);

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
		background_tools.set_unique (false);
	
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
		
		// update selelction when the user switches tab
		MainWindow.get_tab_bar ().signal_tab_selected.connect((tab) => {
			Glyph glyph;
			
			if (tab.get_display () is Glyph) {
				glyph = (Glyph) tab.get_display ();
				show_bg.set_selected (glyph.get_background_visible ());
				update_line_selection (glyph);
			}
		});
	}

	void update_line_selection (Glyph glyph) {
		help_lines.set_selected (glyph.get_show_help_lines ());
		xheight_help_lines.set_selected (glyph.get_xheight_lines_visible ());
		background_help_lines.set_selected (glyph.get_margin_lines_visible ());
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
	
	void update_drawing_and_background_tools (Tool current_tool) {
		IdleSource idle = new IdleSource ();
		
		idle.set_callback (() => {
			Glyph g = MainWindow.get_current_glyph ();

			move_background.set_selected (false);
			cut_background.set_selected (false);
			
			pen_tool.set_selected (false);
			point_tool.set_selected (false);
			zoom_tool.set_selected (false);
			move_tool.set_selected (false);
			resize_tool.set_selected (false);
			stroke_tool.set_selected (false);
			track_tool.set_selected (false);
			
			show_bg.set_selected (g.get_background_visible ());
			show_bg.set_active (false);
			bg_selection.set_selected (false);
			background_scale.set_active (false);

			rectangle.set_selected (false);
			circle.set_selected (false);
		
			current_tool.set_selected (true);
			Toolbox.redraw_tool_box ();
			
			return false;
		});
		
		idle.attach (null);
	}
	
	void update_type_selection () {
		IdleSource idle = new IdleSource ();

		// Do this in idle, after the animation
		idle.set_callback (() => {			
			quadratic_points.set_selected (false);
			cubic_points.set_selected (false);
			double_points.set_selected (false);

			switch (point_type) {
				case PointType.QUADRATIC:
					quadratic_points.set_selected (true);
					break;
				case PointType.CUBIC:
					cubic_points.set_selected (true);
					break;
				case PointType.DOUBLE_CURVE:
					double_points.set_selected (true);
					break;			
			}

			convert_points.set_selected (false);
			
			Toolbox.redraw_tool_box ();
			return false;
		});
		
		idle.attach (null);
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
		MainWindow.get_toolbox ().redraw (0, 0, Toolbox.allocation_width, Toolbox.allocation_height);		
	}
	
	public void parse_grid (string spin_button_value) {
		SpinButton sb = add_new_grid ();
		sb.set_value (spin_button_value);
		MainWindow.get_toolbox ().select_tool (sb);
	}

	public SpinButton add_new_grid () {
		SpinButton grid_width = new SpinButton ("grid_width", t_("Set size for grid"));
		Toolbox tb = MainWindow.get_toolbox ();
		
		grid_width.new_value_action.connect((self) => {
			grid_width.select_action (grid_width);
		});

		grid_width.select_action.connect((self) => {
			SpinButton sb = (SpinButton) self;
			GridTool.set_grid_width (sb.get_value ());
			GlyphCanvas.redraw ();
		});
				
		grid_expander.add_tool (grid_width);

		GridTool.sizes.append (grid_width);

		grid_expander.set_open (true);
		tb.update_expanders ();
		
		tb.redraw (0, 0, Toolbox.allocation_width, Toolbox.allocation_height);
		
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
		tb.redraw (0, 0, Toolbox.allocation_width, Toolbox.allocation_height);
	}
	
	private void add_expander (Expander e) {
		expanders.append (e);
	}
}

}
