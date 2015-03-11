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
	
	public SpinButton (string? name = null, string tip = "", unichar key = '\0', uint modifier_flag = 0) {
		base (null , tip, key, modifier_flag);
		
		if (name != null) {
			base.name = (!) name;
		}
	
		set_icon ("spin_button");
	
		panel_press_action.connect ((selected, button, tx, ty) => {
			double py = Math.fabs (y - ty);
			int n = 0;
			
			if (button == 3 || KeyBindings.modifier == LOGO) {
				set_from_text ();
				n = 0;
			}
				
			if (is_selected ()) {
				if (button == 1) {
					n = 1;
				} else if (button == 2) {
					n = 10;
				} 
					
				for (int i = 0; i < n; i++) {
					if (py < 9) increase ();
					if (py > 25) decrease ();
				}
			}
			
			value_from_motion = true;
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
			
			if (value_from_motion) {
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
		redraw ();
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
		redraw ();
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
				return @" -$n2.$n3$n4";
			}
			
			if (n0 == 0) {
				return @" -$n1$n2.$n3";
			}
			
			return @" -$n0$n1$n2";
		}

		if (n0 == 0 && n1 == 0) {
			return @" $n2.$n3$n4";
		}
		
		if (n0 == 0) {
			return @"$n1$n2.$n3$n4";
		}
					
		return @"$n0$n1$n2.$n3";
	}

	public string get_display_value () {
		if (!big_number) {
			return @"$n0.$n1$n2$n3$n4";
		}
		
		if (negative) {
			return @"-$n0$n1$n2.$n3$n4";
		}
		
		return @"$n0$n1$n2.$n3$n4";
	}
	
	public override void draw (Context cr) {
		double scale = Toolbox.get_scale ();
		
		double xt = x + w / 2;
		double yt = y + h / 2;

		double text_x = -15 * scale;
		double text_y = 3 * scale;
		
		base.draw (cr);
	
		if (!show_icon_tool_icon || waiting_for_icon_switch) {
			cr.save ();
			Theme.color (cr, "Background 2");
			cr.set_font_size (10 * scale);
			cr.select_font_face ("Cantarell", FontSlant.NORMAL, FontWeight.NORMAL);
			
			if (BirdFont.android) {
				cr.move_to (xt + text_x + 0.6 * MainWindow.units, yt + text_y);
			} else if (BirdFont.mac || BirdFont.win32)  {
				cr.move_to (xt + text_x + 2, yt + text_y);
			} else {
				cr.move_to (xt + text_x, yt + text_y);
			}
			
			cr.show_text (get_short_display_value ());
			
			cr.restore ();
		}
	}
	
	public void redraw () {
		if (!is_null (MainWindow.get_toolbox ())) {
			MainWindow.get_toolbox ().redraw ((int) x, (int) y, 70, 70);
		}
	}
}

}
