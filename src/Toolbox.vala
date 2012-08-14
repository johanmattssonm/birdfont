/*
    Copyright (C) 2012 Johan Mattsson

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

using Gtk;
using Gdk;
using Cairo;
using Math;

namespace Supplement {

class Toolbox : DrawingArea {
	GlyphCanvas glyph_canvas;
	
	bool expanded = true;
	
	ToolboxExpander toolbox_expander;
	
	public List<Expander> expanders;
	
	Tool current_tool = new Tool ("no_icon");
	
	Expander draw_tools;
	Expander grid_expander;
		
	BackgroundTool move_background;
	CutBackgroundTool cut_background;
	
	Tool press_tool = new Tool (null); // activate the pressed button on release
	
	public SpinButton background_scale = new SpinButton ();
	
	public Toolbox (GlyphCanvas main_glyph_canvas) {
		glyph_canvas = main_glyph_canvas;
		
		set_size_request (158, 100);

		leave_notify_event.connect ((t, e)=> {
			reset_active_tool ();
			return true;
		});
		
		toolbox_expander = new ToolboxExpander ();
		
		add_expander (toolbox_expander);
		
		draw_tools = new Expander ();
			
		Expander path_tool_modifiers = new Expander ();
		Expander draw_tool_modifiers = new Expander ();
		Expander characterset_tools = new Expander ();
		Expander test_tools = new Expander ();
		Expander guideline_tools = new Expander ();
		Expander view_tools = new Expander ();
		Expander grid = new Expander ();
		Expander background_tools = new Expander ();
		Expander trace = new Expander ();
		
		grid_expander = grid;

		// Draw tools
		PenTool pen_tool = new PenTool ("pen_tool");
		draw_tools.add_tool (pen_tool);
	
		ZoomTool zoom_tool = new ZoomTool ("zoom_tool");
		draw_tools.add_tool (zoom_tool);

		CutTool cut_tool = new CutTool ("cut");
		draw_tools.add_tool (cut_tool);	

		Tool move_tool = new MoveTool ("move");
		draw_tools.add_tool (move_tool);	

		Tool resize_tool = new ResizeTool ("resize");
		// Fixa: draw_tools.add_tool (resize_tool);	

		Tool shrink_tool = new ShrinkTool ("shrink");
		// Fixa: draw_tools.add_tool (shrink_tool);	
		
		// Draw tool modifiers
		Tool new_point = new Tool ("new_point", "Add new points to path", 'a');
		new_point.select_action.connect((self) => {
				select_draw_tool ();
			});
		
		draw_tool_modifiers.add_tool (new_point);

		Tool corner_tool = new Tool ("corner", "Edit corner", 'e');
		corner_tool.select_action.connect((self) => {
				select_draw_tool ();
				pen_tool.edit_active_corner = true;
			});
		corner_tool.deselect_action.connect((self) => {
				pen_tool.edit_active_corner = false;
			});
		draw_tool_modifiers.add_tool (corner_tool);

		Tool insert_point_on_path = new Tool ("insert_point_on_path", "Add new point on path", 'n');
		insert_point_on_path.select_action.connect((self) => {
				select_draw_tool ();
				pen_tool.begin_from_new_point_on_path ();
			});
		draw_tool_modifiers.add_tool (insert_point_on_path);
		
		Tool new_point_on_path = new Tool ("new_point_on_path", "Begin new path from point on path", 'n');
		new_point_on_path.select_action.connect((self) => {
				select_draw_tool ();
				pen_tool.begin_from_new_point_on_path ();
			});
		draw_tool_modifiers.add_tool (new_point_on_path);

		Tool move_point_on_path = new Tool ("move_point", "Move edit point", 'm');
		move_point_on_path.select_action.connect((self) => {
				select_draw_tool ();
				pen_tool.move_point_on_path = true;
			});
		corner_tool.deselect_action.connect((self) => {
				pen_tool.move_point_on_path = false;
			});
		draw_tool_modifiers.add_tool (move_point_on_path);		

		Tool close_paths_tool = new Tool ("close_paths", "Open or close paths", 'c');
		close_paths_tool.select_action.connect((self) => {
				Glyph g = MainWindow.get_current_glyph ();
				
				select_draw_tool ();
				
				// Set direction for inside or outside
				cut_tool.force_direction ();
						
				if (!g.close_path ()) {
					g.open_path ();
				}
								
				TimeoutSource anim = new TimeoutSource (300);
				anim.set_callback(() => {
					select_tool (new_point);
					return false;
				});
				
				anim.attach (null);
				
			});
		draw_tool_modifiers.add_tool (close_paths_tool);	

		Tool tie_editpoint_tool = new Tool ("tie_point", "Tie curve handles for selected edit point", 'w');
		tie_editpoint_tool.select_action.connect((self) => {
				EditPoint ep;
				bool tie;
				
				select_draw_tool ();
				
				ep = pen_tool.selected_corner;
				tie = !ep.tie_handles;

				if (tie) {
					ep.process_tied_handle ();
				}
				
				ep.set_tie_handle (tie);
								
				TimeoutSource anim = new TimeoutSource (300);
				anim.set_callback(() => {
					select_tool (corner_tool);
					return false;
				});
				
				anim.attach (null);
				
			});
		draw_tool_modifiers.add_tool (tie_editpoint_tool);	

		Tool tie_x_or_y = new Tool ("tie_x_or_y", "Tie coordinates to previous edit point", 'q');
		tie_x_or_y.select_action.connect((self) => {
			select_draw_tool ();
			pen_tool.tie_x_or_y_coordinates = !pen_tool.tie_x_or_y_coordinates;
		});
		// Fixa: draw_tool_modifiers.add_tool (tie_x_or_y);	

		Tool erase_tool = new Tool ("erase_tool", "Delete edit points");
		erase_tool.select_action.connect((self) => {
			select_draw_tool ();
		});
		draw_tool_modifiers.add_tool (erase_tool);	
				
		// path tools
		// Tool union_paths_tool = new MergeTool ("union_paths");
		// path_tool_modifiers.add_tool (union_paths_tool);
		// Fixa: write merge tool
		
		Tool reverse_path_tool = new Tool ("reverse_path", "Create counter from outline", 'r');
		reverse_path_tool.select_action.connect((self) => {
				Glyph g = MainWindow.get_current_glyph ();
				Path? p = g.active_path;
				
				if (p != null) {
					((!)p).reverse ();
				}
				
				g.redraw_area (0, 0, g.allocation.width, g.allocation.height);
			});
		path_tool_modifiers.add_tool (reverse_path_tool);

		Tool move_layer = new Tool ("move_layer", "Move to path to bottom layer", 'd');
		move_layer.select_action.connect((self) => {
			Glyph g = MainWindow.get_current_glyph ();
			Path p;
			
			if (g.active_path != null) {
				p = (!) g.active_path;
				
				g.path_list.remove (p);
				g.path_list.prepend (p);
			}
		});
		path_tool_modifiers.add_tool (move_layer);
		
		// Character set tools
		Tool full_unicode = new Tool ("utf_8", "Show full unicode characters set", 'a', CTRL);
		full_unicode.select_action.connect((self) => {
				MainWindow.get_tab_bar ().add_unique_tab (new OverView (), 75, false);	
				OverView o = MainWindow.get_overview ();
				GlyphRange gr = new GlyphRange ();
				gr.use_full_unicode_range ();
				o.set_glyph_range (gr);
				MainWindow.get_tab_bar ().select_tab_name ("Overview");
			});
		characterset_tools.add_tool (full_unicode);

		Tool custom_character_set = new Tool ("custom_character_set", "Show default characters set", 'r', CTRL);
		custom_character_set.select_action.connect((self) => {
				MainWindow.get_tab_bar ().add_unique_tab (new OverView (), 75, false);
				OverView o = MainWindow.get_overview ();
				GlyphRange gr = new GlyphRange ();
				gr.use_default_range ();
				o.set_glyph_range (gr);
				MainWindow.get_tab_bar ().select_tab_name ("Overview");
			});
		characterset_tools.add_tool (custom_character_set);

		Tool avalilable_characters = new Tool ("available_characters", "Show characters in font", 'd', CTRL);
		avalilable_characters.select_action.connect((self) => {
				MainWindow.get_tab_bar ().add_unique_tab (new OverView (), 75, false);
				OverView o = MainWindow.get_overview ();
				o.display_all_available_glyphs ();
				MainWindow.get_tab_bar ().select_tab_name ("Overview");
			});
		characterset_tools.add_tool (avalilable_characters);

		Tool delete_glyph = new Tool ("delete_selected_glyph", "Delete selected glyph or path");
		delete_glyph.select_action.connect((self) => {
					OverView o = MainWindow.get_overview ();
					
					if (MainWindow.get_current_display () is OverView) {
						o.delete_selected_glyph ();
					}
					
					MainWindow.get_tab_bar ().select_tab_name ("Overview");
			});
		characterset_tools.add_tool (delete_glyph);
						
		if (Supplement.has_argument ("--test")) {
			Tool test_case = new Tool ("test_case");
			test_case.select_action.connect((self) => {
					if (self.is_selected ()) {
						if (TestSupplement.is_running ()) {
							TestSupplement.pause ();
						} else {
							TestSupplement.continue ();
						}
					}
				});
			test_tools.add_tool (test_case);

			Tool slow_test = new Tool ("slow_test");
			slow_test.select_action.connect((self) => {
					bool s = TestSupplement.is_slow_test ();
					TestSupplement.set_slow_test (!s);
					s = TestSupplement.is_slow_test ();
					self.set_selected (s);
				});
		
			test_tools.add_tool (slow_test);
					
			// Run from commad line
			string? st = Supplement.get_argument ("--test");
			if (st != null && ((!)st).char_count () > 0) {
				IdleSource idle = new IdleSource ();

				idle.set_callback (() => {			
					select_tool (test_case);
					return false;
				});
				
				idle.attach (null);
			}
			
			if (Supplement.has_argument ("--slow")) {
				select_tool (slow_test);
			}
			
		}
		
		// help lines, grid and other guidlines
		Tool help_lines = new Tool ("help_lines", "Show help lines", 'l');
		help_lines.select_action.connect((self) => {
				bool h;
				h = glyph_canvas.get_current_glyph ().get_show_help_lines ();
				glyph_canvas.get_current_glyph ().set_show_help_lines (!h);
				self.set_selected (!h);
				glyph_canvas.get_current_glyph ().redraw_help_lines ();
			});	

		guideline_tools.add_tool (help_lines);

		Tool xheight_help_lines = new Tool ("show_xheight_helplines", "Show help lines for x-height and baseline", 'x');
		xheight_help_lines.select_action.connect((self) => {
				Glyph g = MainWindow.get_current_glyph ();
				bool v = !g.get_xheight_lines_visible ();
				g.set_xheight_lines_visible (v);
				self.set_selected (v);
				MainWindow.get_glyph_canvas ().redraw ();
				
				if (v && !help_lines.is_selected ()) {
					select_tool (help_lines);
				}
				
			});
		guideline_tools.add_tool (xheight_help_lines);

		Tool background_help_lines = new Tool ("background_help_lines", "Show help lines at top and bottom margin", 't');
		background_help_lines.select_action.connect((self) => {
				Glyph g = MainWindow.get_current_glyph ();
				bool v = !g.get_margin_lines_visible ();
				g.set_margin_lines_visible (v);
				self.set_selected (v);
				MainWindow.get_glyph_canvas ().redraw ();
				
				if (v && !help_lines.is_selected ()) {
					select_tool (help_lines);
				}
			});
		guideline_tools.add_tool (background_help_lines);

		Tool new_grid = new GridTool ("new_grid");
		guideline_tools.add_tool (new_grid);

		// Zoom tools 
		Tool zoom_in = new Tool ("zoom_in", "zoom in", '+', CTRL);
		zoom_in.select_action.connect((self) => {
				zoom_tool.store_current_view ();
				glyph_canvas.get_current_display ().zoom_in ();
			});
		view_tools.add_tool (zoom_in);

		Tool zoom_out = new Tool ("zoom_out", "Zoom out", '-', CTRL);
		zoom_out.select_action.connect((self) => {
				zoom_tool.store_current_view ();
				glyph_canvas.get_current_display ().zoom_out ();
			});
		view_tools.add_tool (zoom_out);

		Tool reset_zoom = new Tool ("zoom_1_1", "Zoom to scale 1:1", '0', CTRL);
		reset_zoom.select_action.connect((self) => {
				zoom_tool.store_current_view ();
				glyph_canvas.get_current_display ().reset_zoom ();
				glyph_canvas.queue_draw_area(0, 0, glyph_canvas.allocation.width, glyph_canvas.allocation.height);
			});
		view_tools.add_tool (reset_zoom);

		Tool full_glyph = new Tool ("full_glyph", "Show full glyph", 'f');
		full_glyph.select_action.connect((self) => {
				zoom_tool.store_current_view ();
				zoom_tool.zoom_full_glyph ();
			});
		view_tools.add_tool (full_glyph);

		Tool zoom_boundries = new Tool ("zoom_boundries", "Zoom in at region boundries", 'v');
		zoom_boundries.select_action.connect((self) => {
				zoom_tool.store_current_view ();
				glyph_canvas.get_current_display ().zoom_max ();
			});
		view_tools.add_tool (zoom_boundries);

		Tool zoom_bg = new Tool ("zoom_background_image", "Zoom in background image", 'b');
		zoom_bg.select_action.connect((self) => {
				if (MainWindow.get_current_glyph ().get_background_image () != null) {
					zoom_tool.store_current_view ();					
					glyph_canvas.get_current_display ().reset_zoom ();
					
					zoom_tool.zoom_full_background_image ();
					
					glyph_canvas.queue_draw_area(0, 0, glyph_canvas.allocation.width, glyph_canvas.allocation.height);
				}
			});
		view_tools.add_tool (zoom_bg);

		Tool zoom_prev = new Tool ("prev", "previous view", 'p', CTRL);
		zoom_prev.select_action.connect((self) => {
				zoom_tool.previous_view ();
			});
		view_tools.add_tool (zoom_prev);

		Tool zoom_next = new Tool ("next", "Next view", 'l', CTRL);
		zoom_next.select_action.connect((self) => {
				zoom_tool.next_view ();
			});
		view_tools.add_tool (zoom_next);
				
		// background tools
		background_scale = new SpinButton ("scale_background", "Set size for background image");
		background_scale.set_value_round (1);
		
		background_scale.new_value_action.connect((self) => {
			background_scale.select_action (self);
		});
		
		background_scale.select_action.connect((self) => {
			SpinButton sb = (SpinButton) self;
			Glyph g = MainWindow.get_current_glyph ();
			GlyphBackgroundImage? img = g.get_background_image ();
			double s = sb.get_value ();
			
			if (MainWindow.get_current_display () is CutBackgroundCanvas) {
				return;
			}
			
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
		
		Tool show_bg = new Tool ("show_background", "Show background image", 'F', SHIFT);
		show_bg.select_action.connect((self) => {
				Glyph g = MainWindow.get_current_glyph ();
				g.set_background_visible (!g.get_background_visible ());
				MainWindow.get_glyph_canvas ().redraw ();
			});
		background_tools.add_tool (show_bg);

		Tool background_size_to_boundries = new Tool ("size_to_boundries", "Fit image between margin lines", 'F', SHIFT);
		background_size_to_boundries.select_action.connect((self) => {
			Glyph g = MainWindow.get_current_glyph ();
			GlyphBackgroundImage? bg = g.get_background_image ();
			GlyphBackgroundImage b = (!) bg;
			
			if (bg != null) {
				
				if (!b.scaled) {
					b.scale_image_proportional_to_boundries (g);
					g.set_background_visible (true);
					MainWindow.get_glyph_canvas ().redraw ();
				} else {
					b.reset_scale (g);
					g.set_background_visible (true);
					MainWindow.get_glyph_canvas ().redraw ();						
				}
				
				b.scaled = !b.scaled;
			}
		});
		// Fixa: remove this tool background_tools.add_tool (background_size_to_boundries);

		Tool bg_selection = new Tool ("insert_background", "Insert new background image");
		bg_selection.select_action.connect((self) => {
			Glyph? g = null;
			FontDisplay fd = MainWindow.get_current_display ();
			TooltipArea tp = MainWindow.get_tool_tip ();
			tp.show_text ("Creating thumbnails");
			
			bg_selection.yield ();
		
			if (fd is Glyph) {
				g = (Glyph) fd;
			} else {
				return;
			}
			
			BackgroundSelection bgs = new BackgroundSelection ((!) g);
			MainWindow.get_tab_bar ().add_unique_tab (bgs , 120, false);
			
			tp.show_text ("");
		});
		bg_selection.set_show_background (true);
		background_tools.add_tool (bg_selection);
		
		SpinButton background_contrast = new SpinButton ("background_contrast", "Set background contrast");
		background_contrast.set_value_round (1);

		background_contrast.new_value_action.connect((self) => {
			background_contrast.select_action (self);
		});
		
		background_contrast.select_action.connect((self) => {		
			Glyph g = MainWindow.get_current_glyph ();
			GlyphBackgroundImage? bg = g.get_background_image ();
			GlyphBackgroundImage b;
			
			if (bg != null) {
				b = (!) bg;
				b.set_contrast (background_contrast.get_value ());
			}
			
		});
		
		// Fixa: background_tools.add_tool (background_contrast);

		SpinButton background_threshold = new SpinButton ("background_threshold", "Set threshold");
		background_threshold.set_value_round (1);

		background_threshold.new_value_action.connect((self) => {
			background_threshold.select_action (self);
		});
		
		background_threshold.select_action.connect((self) => {		
			Glyph g = MainWindow.get_current_glyph ();
			GlyphBackgroundImage? bg = g.get_background_image ();
			GlyphBackgroundImage b;
			
			if (bg != null) {
				b = (!) bg;
				b.set_threshold (background_threshold.get_value ());
			}
			
		});
		trace.add_tool (background_threshold);

		Tool auto_trace = new Tool ("auto_trace", "Auto trace path from background image");
		auto_trace.select_action.connect((self) => {
			Glyph g = MainWindow.get_current_glyph ();
			GlyphBackgroundImage? bg = g.get_background_image ();
			GlyphBackgroundImage b;
			
			if (bg != null) {
				b = (!) bg;
				g.add_path (b.auto_trace ());
			}
		});
		trace.add_tool (auto_trace);
		
		draw_tools.set_open (true);
		draw_tool_modifiers.set_open (true);
		path_tool_modifiers.set_open (true);
		view_tools.set_open (true);
		grid.set_open (true);
		characterset_tools.set_open (true);
		test_tools.set_open (true);
		guideline_tools.set_open (true);
		background_tools.set_open (true);
		trace.set_open (true);
		
		add_expander (draw_tools);
		add_expander (draw_tool_modifiers);
		add_expander (path_tool_modifiers);	
		
		add_expander (characterset_tools);
		add_expander (guideline_tools);
		add_expander (grid);
		add_expander (view_tools);
		
		add_expander (background_tools);
		// Fixa: add_expander (trace);
		
		add_expander (test_tools);
		
		draw_tools.set_persistent (true);
		draw_tools.set_unique (true);
		
		draw_tool_modifiers.set_persistent (true);
		draw_tool_modifiers.set_unique (true);

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
		
		background_tools.set_persistent (true);
		background_tools.set_unique (true);
		
		trace.set_persistent (false);
		trace.set_unique (false);
		
		button_press_event.connect ((se, e)=> {
			foreach (var exp in expanders) {
				foreach (Tool t in exp.tool) {
					if (t.is_over (e.x, e.y)) {
						t.panel_press_action (t, e.button, e.x, e.y);
						press_tool = t;
					}
				}
			}
			
			return true;
		});	
				
		button_release_event.connect ((se, e)=> {
			release (e.button, e.x, e.y);
			return true;
		});

		motion_notify_event.connect ((sen, e)=> {
			move (e.x, e.y);
			return true;
		});
		
		expose_event.connect ((t, e)=> {
				Allocation allocation;
				get_allocation (out allocation);
				
				Context cw = cairo_create(get_window());
				draw (allocation, cw);
				
				return true;
			});
		
		add_events (EventMask.BUTTON_PRESS_MASK | EventMask.BUTTON_RELEASE_MASK | EventMask.POINTER_MOTION_MASK | EventMask.LEAVE_NOTIFY_MASK);
		
		update_expanders ();
		reset_active_tool ();

		// Default selection
		var idle = new IdleSource();
		idle.set_callback (() => {
			new_point.set_selected (true);
			pen_tool.set_selected (true);
			
			if (glyph_canvas.get_current_glyph ().get_show_help_lines ()) {
				help_lines.set_selected (true);
				help_lines.set_active (false);
			}

			add_new_grid ();
			
			move (0, 0);
			
			return false;
		});
		idle.attach (null);
	}
	
	private void release (uint button, double x, double y) {
		foreach (var exp in expanders) {
			if (exp.is_over (x, y)) {
				exp.set_open (! exp.is_open ());					
				if (exp is ToolboxExpander) {
					if (is_expanded ()) minimize ();
					else maximize ();
				}

				update_expanders ();
				
				Allocation allocation;
				get_allocation (out allocation);
				queue_draw_area ((int) exp.x - 10, (int) exp.y - 10, allocation.width, (int) (allocation.height - exp.y + 10));
			}
			
			if (exp.is_open ()) {
				foreach (Tool t in exp.tool) {
					bool active = t.is_over (x, y);
					
					if (active) {
						if (press_tool == t) {
							select_tool (t);
						}
					}
					
					t.panel_release_action (t, button, x, y);
				}
			}
		}
	}
	
	private void select_draw_tool () {
		if (current_tool is PenTool || current_tool is CutTool) {
			return;
		}
		
		select_tool_by_name ("pen_tool");
	}
	
	private void move (double x, double y) {
		bool update;
		bool a;
		foreach (var exp in expanders) {
			a = exp.is_over (x, y);
			update = exp.set_active (a);
			
			if (update) {
				queue_draw_area ((int) exp.x - 10, (int) exp.y - 10, (int) (exp.x + exp.w + 10), (int) (exp.y + exp.h + 10));
			}
			
			if (exp.is_open ()) {
				foreach (Tool t in exp.tool) {
					bool active = t.is_over (x, y);
					TooltipArea? tpa = null;
					
					update = t.set_active (active);
					tpa = MainWindow.get_tool_tip ();
					
					if (active && tpa != null) {
						((!)tpa).update_text ();
					}
					
					if (update) {
						queue_draw_area (0, 0, allocation.width, allocation.height);
					}
					
					t.panel_move_action (t, x, y);
				}
			}
		}
	}
	
	public void remove_all_grid_buttons () {
		while (grid_expander.tool.length () > 2) {
			grid_expander.tool.remove_link (grid_expander.tool.last ());
		}
		
		while (GridTool.sizes.length () > 0) {
			GridTool.sizes.remove_link (GridTool.sizes.first ());
		}
		
		grid_expander.set_open (true);
		update_expanders ();
		MainWindow.get_toolbox ().queue_draw_area (0, 0, allocation.width, allocation.height);		
	}
	
	public void parse_grid (string spin_button_value) {
		SpinButton sb = add_new_grid ();
		sb.set_value (spin_button_value);
		select_tool (sb);
	}

	public SpinButton add_new_grid () {
		SpinButton grid_width = new SpinButton ("grid_width", "Set size for grid");
		
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
		update_expanders ();
		
		MainWindow.get_toolbox ().queue_draw_area (0, 0, allocation.width, allocation.height);
		
		select_tool (grid_width);
		grid_width.set_active (false);
		
		return grid_width;
	}

	public void remove_current_grid () {
		Tool grid_width;
		
		foreach (Tool t in grid_expander.tool) {
			if (t.is_selected () && t is SpinButton) {
				GridTool.sizes.remove ((SpinButton)t);
				grid_expander.tool.remove (t);
				break;
			}
		}
		
		if (grid_expander.tool.length () > 0) {
			grid_width = grid_expander.tool.last ().data;
			select_tool (grid_width);
			grid_width.set_active (false);
		}
		
		update_expanders ();
		MainWindow.get_toolbox ().queue_draw_area (0, 0, allocation.width, allocation.height);
	}

	public void reset_active_tool () {
		foreach (var exp in expanders) {
			foreach (Tool t in exp.tool) {
				t.set_active (false);
			}
		}
	}

	public Tool? get_active_tool () {
		foreach (var exp in expanders) {
			foreach (Tool t in exp.tool) {
				if (t.is_active ()) {
					return t;
				}
			}
		}
		
		// FIXA:
		/*
		foreach (Tool t in MainWindow.get_content_display ().tools) {
			if (t.is_active ()) {
				return t;
			}	
		}
		*/
		
		return null;
	}

	public Tool get_current_tool () {
		return current_tool;
	}
	
	public void select_tool (Tool tool) {
		foreach (var exp in expanders) {
			
			foreach (Tool t in exp.tool) {
				if (tool.get_id () == t.get_id ()) {
					exp.set_open (true);
					
					bool update;
					
					update = tool.set_selected (true);
					update = tool.set_active (true);
					
					tool.select_action (tool); // execute command
					
					if (update) {							
						queue_draw_area ((int) exp.x - 10, (int) exp.y - 10, allocation.width, (int) (allocation.height - exp.y + 10));
					}
					
					if (exp == draw_tools || t == move_background || t == cut_background) {
						current_tool = tool;
					}
				}
			}
			
		}
	}
	
	public Tool get_tool (string name) {
		foreach (var e in expanders) {
			foreach (var t in e.tool) {
				if (t.get_name () == name) {
					return t;
				}
			}
		}

		if (name == cut_background.get_name ()) {
			return cut_background;
		}
				
		warning ("No tool found for name \"%s\".\n", name);
		
		return new Tool ("no_icon");
	}
	
	public void select_tool_by_name (string name) {
		select_tool (get_tool (name));
	}
		
	private void update_expanders () {
		Expander? p = null; 
		Expander pp;
		foreach (var e in expanders) {
			if (p != null) {
				pp = (!) p;
				e.set_offset (pp.y + pp.margin + 12);
			}
			
			p = e;
		}
	}
	
	private void add_expander (Expander e) {
		expanders.append (e);
	}
	
	private void draw_expanders (Allocation allocation, Context cr) {
		foreach (Expander e in expanders) {
			e.draw (allocation, cr);
			if (e.is_open ()) {
				e.draw_content (allocation, cr);
			}
		}
	}
	
	public void draw (Allocation allocation, Context cr) { 
		cr.save ();
		
		cr.rectangle(0, 0, allocation.width, allocation.height);
		cr.set_line_width(0);
		cr.set_source_rgba(124/255.0, 124/255.0, 124/255.0, 1);
		cr.fill();

		cr.rectangle(0, 0, 1, allocation.height);
		cr.set_line_width(0);
		cr.set_source_rgba(0/255.0, 0/255.0, 0/255.0, 1);
		cr.fill();

		draw_expanders (allocation, cr);
		
		cr.restore ();
	}
				
	public bool is_expanded () {
		return expanded;
	}
	
	public void maximize () {
		Allocation a;
		get_allocation (out a);
		expanded = true;
		toolbox_expander.set_open (expanded);
		set_size_request (158, a.height);
	}
	
	public void minimize () {
		Allocation a;
		get_allocation (out a);
		expanded = false;
		toolbox_expander.set_open (expanded);
		set_size_request (18, a.height);	
	}
}

class ToolboxExpander : Expander {
	
	public ToolboxExpander () {
	}
	
	public override bool set_open (bool o) {
		bool r = (open != o);
		rotation = (o) ? 0 : Math.PI;
		open = o;
		return r;
	}
}

class Expander : GLib.Object {
	
	public double x = 7;
	public double y = 5;

	public double w = 6;
	public double h = 5;
	
	public double margin = 0;
	
	protected double rotation = 0;
	protected double opacity = 0.5;
	
	protected bool active = false;
	protected bool open = false;

	public List<Tool> tool;

	bool persist = false;
	bool unique = false;
	
	public Expander () {
	}

	/** Returns true if tools can be used with the current canvas after
	 * they have been selectes and false if they are a commands to be executed.
	 */
	public bool is_persistent () {
		return persist;
	}

	/** Returns true if all other tools in thid expander should be deselected 
	 * when a tool is selected.
	 */
	public bool is_unique () {
		return unique;
	}

	public void set_persistent (bool p) {
		persist = p;
	}

	public void set_unique (bool u) {
		unique = u;
	}
	
	private void update_tool_position () {
		int i = 0;
		double xt = x + 10;
		double yt = y - 4;
		foreach (var t in tool) {
			t.set_properties (xt, yt, w, h);
			
			if (i == 3) {
				yt += 31;
				i = 0;
				xt = x + 10;
			} else {
				i++;
				xt += w + 3 + 25;
			}
		}
	}
	
	public void set_offset (double ty) {
		y = ty;
		
		if (open) {
			update_tool_position ();
		}
	}
	
	public void add_tool (Tool t) {
		tool.append (t);
		update_tool_position ();
		
		t.select_action.connect ((selected) => {
				if (!selected.new_selection) {
					if (is_persistent ()) {
						selected.set_selected (true);
					} else {
						selected.set_selected (false);
					}
				}
			
				MainWindow.get_toolbox ().queue_draw_area ((int) x, (int) y, (int) w  + 300, (int) (h + margin));
			
				if (is_unique ()) {
					foreach (var deselected in tool) {
						if (selected.get_id () != deselected.get_id ()) {
							deselected.set_selected (false);
						}
					}
				}

				if (!is_persistent ()) {
						var time = new TimeoutSource(200);
						time.set_callback(() => {
							selected.set_selected (false);
							MainWindow.get_toolbox ().queue_draw_area ((int) x, (int) y, (int) w  + 300, (int) (h + margin));
							return false;
						});
						time.attach(null);
				}

				selected.new_selection = false;
			});
	}
	
	public bool is_over (double xp, double yp) {	
		return (x - 7/2.0 <= xp <= x + w  + 7/2.0 && y - 7/2.0<= yp <= y + w + 7/2.0);  
	}
	
	public bool set_active (bool a) {
		bool r = (active != a);
		opacity = (a) ? 1 : 0;
		active = a;
		return r;
	}
	
	public bool is_open () {
		return open;
	}
	
	public virtual bool set_open (bool o) {
		bool r = (open != o);
		rotation = (o) ? Math.PI_2 : 0;
		
		if (o) {
			margin = 35 * (int)((tool.length () / 4.0) + 1) ;
			rotation = Math.PI_2;			
			if (tool.length () % 4 == 0) {
				margin -= 35;
			}
		} else {
			margin = 0;
			rotation = 0; 
		}
		
		open = o;
		return r;
	}
	
	public void draw (Allocation allocation, Context cr) {
		double lx, ly;
		double ih2 = 5.4 / 2;
		double iw2 = 5.4 / 2;
		
		// box
		cr.save ();
		cr.set_line_join (LineJoin.ROUND);
		cr.set_line_width(7);
		cr.set_source_rgba (176/255.0, 211/255.0, 230/255.0, opacity);
		cr.rectangle (x, y, w, h);
		cr.stroke ();
		cr.restore ();
		
		// arrow
		cr.save ();
		
		cr.translate (x + w/2, y + h/2);
		cr.rotate (rotation);

		cr.set_line_width (1);
		cr.set_source_rgba (0, 0, 0, opacity);

		cr.new_path ();
		cr.move_to (-iw2, -ih2);
		cr.line_to (iw2, 0);	
		cr.line_to (-iw2, +ih2);

		cr.close_path();
		cr.stroke ();
		cr.restore ();
		
		// separator
		cr.save ();
		lx = x + w + 7;
		ly = y + ih2;
		if (lx < allocation.width) {
			cr.set_line_width(1);
			cr.set_source_rgba (0, 0, 0, 0.2);
			cr.move_to (lx, ly);
			cr.line_to (allocation.width - w - x + 4, ly);	
			cr.stroke ();
		}
		cr.restore ();

	}
	
	public void draw_content (Allocation allocation, Context cr) {
		if (open) {
			cr.save ();
			foreach (var t in tool) {
				t.draw (allocation, cr);
			}
			cr.restore ();
		}
	}
	
}

}
