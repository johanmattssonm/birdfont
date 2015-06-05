/*
    Copyright (C) 2015 Johan Mattsson

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

public class LayerLabel : Tool {

	public bool selected_layer { get; set; }
	public string label { get; set; }
	
	public Layer layer;
	Text label_text;

	/** Add margin when layer is moves. */
	bool active_layer = false;
	
	public LayerLabel (Layer layer) {
		base ();

		this.layer = layer;
		this.label = layer.name;
		
		selected_layer = false;
		
		set_text ();

		panel_press_action.connect ((selected, button, tx, ty) => {	
			if (y <= ty <= y + h) {
				if (tx >= w - 30 * Toolbox.get_scale ()) {
					DrawingTools.deselect_layers ();
					remove_layer ();
				} if (tx < 25 * Toolbox.get_scale ()) {
					layer.visible = !layer.visible;
					GlyphCanvas.redraw ();
					BirdFont.get_current_font ().touch ();
					MainWindow.get_current_glyph ().clear_active_paths ();
				} else {
					active_layer = true;
					select_layer ();
				}
			} else {
				selected_layer = false;
			}
		});
		
		panel_double_click_action.connect ((selected, button, tx, ty) => {
			if (y <= ty <= y + h) {
				if (25 * Toolbox.get_scale () <= tx <= w - 30 * Toolbox.get_scale ()) {
					set_layer_name ();
				}
			}
		});

		panel_move_action.connect ((selected, button, tx, ty) => {
			if (active_layer) {
				if (ty > y) {
					move_layer_down ();
				} else if (ty < y - h) {
					move_layer_up ();
				}
				
				MainWindow.get_toolbox ().update_expanders ();
				redraw ();
			}
			
			return false;
		});

		panel_release_action.connect ((selected, button, tx, ty) => {
			active_layer = false;
		});
	}
	
	void move_layer_up () {
		int i;
		Glyph g = MainWindow.get_current_glyph ();

		// g.layers is ordered from bottom to top
		i = DrawingTools.layer_tools.tool.size - g.current_layer - 1;
		g.move_layer_up ();
		
		DrawingTools.update_layers ();
		
		if (i < 0) {
			i = 0;
		}
		
		set_moving_label (i);
	}

	void move_layer_down () {
		int i;
		Glyph g = MainWindow.get_current_glyph ();

		i = DrawingTools.layer_tools.tool.size - g.current_layer + 1;
		g.move_layer_down ();
		
		DrawingTools.update_layers ();
		
		if (i >= DrawingTools.layer_tools.tool.size) {
			i = DrawingTools.layer_tools.tool.size - 1;
		}
		
		set_moving_label (i);
	}
		
	void set_moving_label (int i) {
		LayerLabel label;
		int j = 0;
		foreach (Tool layer in DrawingTools.layer_tools.tool) {
			label = (LayerLabel) layer;
			if (i == j) {
				label.active_layer = true;
			}
			j++;
		}		
	}
	
	void set_text () {
		double text_height;
		
		label_text = new Text ();
		label_text.set_text (label);
		text_height = 17 * Toolbox.get_scale ();
		label_text.set_font_size (text_height);	
	}
	
	void set_layer_name () {
		TextListener listener;
		
		listener = new TextListener (t_("Layer"), layer.name, t_("Set"));
		
		listener.signal_text_input.connect ((text) => {
			layer.name = text;
			label = text;
			set_text ();
			redraw ();
		});
		
		listener.signal_submit.connect (() => {
			TabContent.hide_text_input ();
		});
		
		TabContent.show_text_input (listener);
	}
	
	public void select_layer () {
		MainWindow.get_current_glyph ().set_current_layer (layer);
		DrawingTools.deselect_layers ();
		selected_layer = true;
		MainWindow.get_current_glyph ().clear_active_paths ();
		GlyphCanvas.redraw ();
	}
	
	public void remove_layer () {
		// remove layer after the click loop
		IdleSource idle = new IdleSource ();

		idle.set_callback (() => {	
			Glyph g = MainWindow.get_current_glyph ();
			g.store_undo_state ();
			g.layers.remove_layer (layer);
			DrawingTools.update_layers ();
			BirdFont.get_current_font ().touch ();
			g.clear_active_paths ();
			GlyphCanvas.redraw ();
			return false;
		});
		
		idle.attach (null);
	}
	
	public override void draw_tool (Context cr, double px, double py) {
		Text visibility_icon;
		double x = this.x - px;
		double y = this.y - py;
		double text_width;
		string visibility;
		
		// background
		if (selected_layer) {
			cr.save ();
			Theme.color (cr, "Menu Background");
			cr.rectangle (0, y - 2 * Toolbox.get_scale (), w, h); // labels overlap with 2 pixels
			cr.fill ();
			cr.restore ();		
		}
		
		// tab label
		cr.save ();
		
		text_width = Toolbox.allocation_width;
		text_width -= 30 * Toolbox.get_scale (); // delete button
		text_width -= 20 * Toolbox.get_scale (); // visibility
		
		label_text.truncate (text_width);
		Theme.text_color (label_text, "Text Tool Box");
		label_text.draw_at_top (cr, x + 20 * Toolbox.get_scale (), y);
		
		visibility = layer.visible ? "layer_visible" : "layer_hidden";
		visibility_icon = new Text (visibility, 30 * Toolbox.get_scale ());
		visibility_icon.load_font ("icons.bf");
		Theme.text_color (visibility_icon, "Text Tool Box");
		visibility_icon.draw_at_top (cr, x, y + h / 2 - (30 * Toolbox.get_scale ()) / 2);
		
		cr.restore ();

		cr.save ();
		Theme.color (cr, "Text Tool Box");
		cr.set_line_width (1);
		cr.move_to (w - 20, y + h / 2 - 2.5 - 2);
		cr.line_to (w - 25, y + h / 2 + 2.5 - 2);
		cr.move_to (w - 20, y + h / 2 + 2.5 - 2);
		cr.line_to (w - 25, y + h / 2 - 2.5 - 2);
		cr.stroke ();
		cr.restore ();
	}
}

}
