/*
	Copyright (C) 2012, 2014 Johan Mattsson

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

public class SpinButton : Tool {

	public signal void new_value_action (SpinButton selected);
	
	bool negative = false;
	
	public int8 n0 = 2;
	public int8 n1 = 0;
	public int8 n2 = 0;
	public int8 n3 = 0;
	public int8 n4 = 0;
	
	bool value_from_motion = false;
	double begin_y = 0;
	int begin_value = 0;
	
	int max = 99999;
	int min = 0;
	int step = 1;
	
	bool big_number = false;
	
	double last_active_time = 0;
	bool waiting_for_icon_switch = false;
	bool show_icon_tool_icon = false;
	
	/** Lock the button to a fixed value. */
	public bool locked = false;

	static Gee.ArrayList<Text> digits;
	static double text_height = 14;
	static Text period;
	static Text comma;
	static Text minus;
	
	public SpinButton (string? name = null, string tip = "") {
		base (null , tip);
		
		if (name != null) {
			base.name = (!) name;
		}

		set_icon ("spin_button");
	
		panel_press_action.connect ((selected, button, tx, ty) => {
			double py = Math.fabs (y - ty);
			int n = 0;
			
			if (button == 3 || KeyBindings.modifier != NONE) {
				set_from_text ();
				n = 0;
				set_selected (false);
				return;
			}
				
			if (is_selected ()) {
				if (button == 1) {
					n = 1;
				} else if (button == 2) {
					n = 10;
				} 
					
				for (int i = 0; i < n; i++) {
					if (py < 9 && !locked) {
						increase ();
					}
					
					if (py > 25 && !locked) {
						decrease ();
					}
				}
			}
			
			value_from_motion = !locked;
			
			begin_y = ty;
			
			begin_value = get_int_value ();
			
			if (button == 1) {
				set_selected (true);
			}
			
			redraw ();
		});

		panel_move_action.connect ((selected, button, tx, ty) => {
			double d;
			int new_value;
			
			if (is_active ()) {
				show_adjustmet_icon ();
			}
			
			if (value_from_motion && is_selected ()) {
				d = (begin_y - ty) / 200;
				d = (d < 0) ? -Math.pow (d, 2) : Math.pow (d, 2);
				d *= 1000;

				new_value = (int)(begin_value + d);
				
				if (new_value < min) {
					set_int_value (@"$min");
				} else if (new_value > max) {
					set_int_value (@"$max");
				} else {
					set_int_value (@"$new_value");
				}
				
				redraw ();
			}
			
			return value_from_motion;
		});

		panel_release_action.connect ((selected, button, tx, ty) => {
			value_from_motion = false;
			
			if (button == 1) {
				set_selected (false);
			}
			
			redraw ();
		});
		
		scroll_wheel_up_action.connect ((selected) => {
			increase ();
			return true;
		});

		scroll_wheel_down_action.connect ((selected) => {
			decrease ();
			return true;
		});

		if (is_null (digits)) {
			add_digits ();
		}
	}
	
	void add_digits () {
		digits = new Gee.ArrayList<Text> ();
		
		for (int i = 0; i < 10; i++) {
			Text digit = new Text (@"$i", text_height);
			digits.add (digit);
		}
		
		period = new Text (".", text_height);
		comma = new Text (",", text_height);
		minus = new Text ("-", text_height);
	}
	
	public void show_icon (bool i) {
		show_icon_tool_icon = i;
		
		if (!show_icon_tool_icon) {
			set_icon ("spin_button");
		} else {
			set_icon ((!) base.name);
		}
	}
	
	public void hide_value () {
		set_icon (base.name);
		waiting_for_icon_switch = false;
		redraw ();
	}
	
	void show_adjustmet_icon () {
		TimeoutSource timer;
		
		set_icon ("spin_button");
		redraw ();
		
		last_active_time = GLib.get_real_time ();
		
		if (show_icon_tool_icon && !waiting_for_icon_switch) {
			waiting_for_icon_switch = true;
			
			timer = new TimeoutSource (100);
			timer.set_callback (() => {
				if (GLib.get_real_time () - last_active_time > 4000000) {
					set_icon (base.name);
					redraw ();
					waiting_for_icon_switch = false;
				}
				
				return waiting_for_icon_switch;
			});

			timer.attach (null);
		}
	}
	
	public void set_big_number (bool b) {
		big_number = b;
	}
	
	public static string convert_to_string (double val) {
		SpinButton sb = new SpinButton ();
		sb.set_value_round (val);
		return sb.get_display_value ();
	}

	public static double convert_to_double (string val) {
		SpinButton sb = new SpinButton ();
		sb.set_int_value (val);
		return sb.get_value ();
	}
	
	public void set_from_text () {
		TextListener listener = new TextListener (t_("Set"), get_display_value (), t_("Close"));
		
		listener.signal_text_input.connect ((text) => {
			set_value (text);
			redraw ();
		});

		listener.signal_submit.connect (() => {
			TabContent.hide_text_input ();
			redraw ();
		});

		TabContent.show_text_input (listener);
	}
	
	public void set_max (double max) {
		if (big_number) {
			max /= 100;
		}
		this.max = (int) Math.rint (max * 10000);
	}

	public void set_min (double min) {
		if (big_number) {
			min /= 100;
		}
		this.min = (int) Math.rint (min * 10000);
	}
	
	public void set_int_step (double step) {
		if (big_number) {
			step /= 100;
		}		
		this.step = (int) Math.rint (step * 10000);
	}
	
	public void increase () {	
		int v;
		
		v = get_int_value ();
		v += step;
		
		if (v > max) {
			set_int_value (@"$max");
		} else {
			set_int_value (@"$v");
		}

		new_value_action (this);
		redraw ();
	}

	public void decrease () {
		int v;
		
		v = get_int_value ();
		v -= step;

		if (v <= min) {
			set_int_value (@"$min");
		} else {
			set_int_value (@"$v");
		}
				
		new_value_action (this);
		redraw ();
	}

	public void set_int_value (string new_value) {
		string v = new_value;
		
		negative = v.has_prefix ("-");
		if (negative) {
			v = v.replace ("-", "");
		}
		
		while (!(v.char_count () >= 5)) {
			v = "0" + v;
		}
		
		n0 = parse (v.substring (v.index_of_nth_char (0), 1));
		n1 = parse (v.substring (v.index_of_nth_char (1), 1));
		n2 = parse (v.substring (v.index_of_nth_char (2), 1));
		n3 = parse (v.substring (v.index_of_nth_char (3), 1));
		n4 = parse (v.substring (v.index_of_nth_char (4), 1));
		
		show_adjustmet_icon ();
		new_value_action (this);
	}

	int8 parse (string s) {
		int v = int.parse (s);
		if (v < 0) {
			warning ("Failed to parse integer.");
			return 0;
		}
		return (int8) v;
	}

	public void set_value (string new_value, bool check_boundaries = true, bool emit_signal = true) {
		string v = new_value.replace (",", ".");
		int fv;
		string separator = "";
		
		negative = v.has_prefix ("-");
		if (negative) {
			v = v.replace ("-", "");
		}
		
		if (big_number) {
			if (v == "" || v == "0") {
				v = "0.0000";
			}
			
			while (v.has_prefix ("0") && !v.has_prefix ("0.")) {
				v = v.substring (v.index_of_nth_char (1));
			}
			
			fv = int.parse (v);
			fv = (fv < 0) ? -fv : fv;
		
			if (fv < 10) {
				v = @"00$v";
			} else if (fv < 100) {
				v = @"0$v";
			}
			
			v = @"$v";
		}

		while (v.char_count () < 6) {
			if (v.index_of (".") == -1) {
				v += ".";
			} else {
				v += "0";
			}
		}

		if (!big_number) {
			n0 = (int8) int.parse (v.substring (v.index_of_nth_char (0), 1));
			separator = v.substring (v.index_of_nth_char (1), 1);
			n1 = (int8) int.parse (v.substring (v.index_of_nth_char (2), 1));
			n2 = (int8) int.parse (v.substring (v.index_of_nth_char (3), 1));
			n3 = (int8) int.parse (v.substring (v.index_of_nth_char (4), 1));
			n4 = (int8) int.parse (v.substring (v.index_of_nth_char (5), 1));
		} else {
			n0 = (int8) int.parse (v.substring (v.index_of_nth_char (0), 1));
			n1 = (int8) int.parse (v.substring (v.index_of_nth_char (1), 1));
			n2 = (int8) int.parse (v.substring (v.index_of_nth_char (2), 1));
			separator = v.substring (v.index_of_nth_char (3), 1);
			n3 = (int8) int.parse (v.substring (v.index_of_nth_char (4), 1));
			n4 = (int8) int.parse (v.substring (v.index_of_nth_char (5), 1));
		}
		
		if (separator != ".") {
			warning (@"Expecting \".\" $new_value -> ($(v))");
		}
		
		if (check_boundaries && get_int_value () > max) {
			warning (@"Out of bounds ($new_value > $max).");
			set_value_round (max, false);
		}

		if (check_boundaries && get_int_value () < min) {
			warning (@"Out of bounds ($new_value < $min).");
			set_value_round (min, false);
		}

		if (emit_signal) {
			new_value_action (this);
		}
		
		show_adjustmet_icon ();
	}

	public void set_value_round (double v, bool check_boundaries = true, bool emit_signal = true) {
		if (v == -0) {
			v = 0;
		}
			
		set_value (@"$v".replace (",", "."), check_boundaries, emit_signal);
	}
	
	public double get_value () {
		double r;
		
		if (!big_number) {
			r = n0 + (n1 / 10.0) + (n2 / 100.0) + (n3 / 1000.0) + (n4 / 1000.0);
		} else {
			r = (n0 * 100) + (n1 * 10) + n2 + (n3 / 10.0) + (n4 / 100.0);
		}
		
		return (negative) ? -r : r;
	}
	
	private int get_int_value () {
		int r = n0 * 10000 + n1 * 1000 + n2 * 100 + n3 * 10 + n4;
		return (negative) ? -r : r;
	}

	public string get_short_display_value () {	
		if (!big_number) {
			return @"$n0.$n1$n2$n3";
		}
		
		if (negative) {
			if (n0 == 0 && n1 == 0) {
				return @"-$n2.$n3$n4";
			}
			
			if (n0 == 0) {
				return @"-$n1$n2.$n3";
			}
			
			return @"-$n0$n1$n2";
		}

		if (n0 == 0 && n1 == 0) {
			return @"$n2.$n3$n4";
		}
		
		if (n0 == 0) {
			return @"$n1$n2.$n3$n4";
		}
					
		return @"$n0$n1$n2.$n3";
	}

	public string get_display_value () {
		string v;
		
		if (!big_number) {
			return @"$n0.$n1$n2$n3$n4";
		}
		
		v = (negative) ? "-" : "";
			
		if (n0 == 0 && n1 == 0) {
			v = @"$v$n2.$n3$n4";
		} else if (n0 == 0) {
			v =  @"$v$n1$n2.$n3$n4";
		} else {
			v = @"$v$n0$n1$n2.$n3$n4";
		}
		
		return v;
	}
	
	Text get_glyph (unichar character) {
		Text text;
		
		if ('0' <= character <= '9') {
			int digit_index = int.parse ((!) character.to_string ());
			text = digits.get (digit_index);
		} else if (character == '.') {
			text = period;
		} else if (character == ',') {
			text = comma;
		} else if (character == '-') {
			text = minus;
		} else {
			text = new Text ((!) character.to_string (), text_height);
		}
		
		return text;
	}
	
	public override void draw_tool (Context cr, double px, double py) {
		double x = x - px;
		double y = y - py;
		string display_value = get_short_display_value ();

		if (!show_icon_tool_icon || waiting_for_icon_switch) {
			if (is_selected ()) {
				base.icon_color = "Active Spin Button";
			} else {
				base.icon_color = "Spin Button";
			}
		} else {
			if (is_selected ()) {
				base.icon_color = "Selected Tool Foreground";
			} else {
				base.icon_color = "Tool Foreground";
			}	
		}
		
		base.draw_tool (cr, px, py);
	
		if (!show_icon_tool_icon || waiting_for_icon_switch) {
			unichar digit;
			int index;
			Text text;
			double extent = 0;
			double decender = 0;
			double carret = 0;
			double total_extent = 0;
			double x_offset;
			
			index = 0;
			while (display_value.get_next_char (ref index, out digit)) {
				text = get_glyph (digit);
				total_extent += text.get_sidebearing_extent ();
			}
			
			x_offset = (w - total_extent) / 2 + 1;
			
			index = 0;
			while (display_value.get_next_char (ref index, out digit)) {
				text = get_glyph (digit);
				extent = text.get_sidebearing_extent ();
				
				if (decender < text.get_decender ()) {
					decender = text.get_decender ();
				}

				if (is_selected ()) {
					Theme.text_color (text, "Selected Tool Foreground");
				} else {
					Theme.text_color (text, "Tool Foreground");
				}

				double text_x = x + carret + x_offset;;
				double text_y = y + (h - text_height) / 2;

				text.widget_x = text_x;
				text.widget_y = text_y + decender;
				text.draw (cr);
				
				carret += extent;
				
			}			
		}
	}
}

}
