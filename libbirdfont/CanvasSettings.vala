/*
	Copyright (C) 2016 Johan Mattsson

	This library is free software; you can redistribute it and/or modify 
	it under the terms of the GNU Lesser General Public License as 
	published by the Free Software Foundation; either version 3 of the 
	License, or (at your option) any later version.

	This library is distributed in the hope that it will be useful, but 
	WITHOUT ANY WARRANTY; without even the implied warranty of 
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU 
	Lesser General Public License for more details.
*/

using B;
using Cairo;

namespace BirdFont {

public class CanvasSettings  {

	public static double stroke_width {
		get {
			settings_mutex.lock ();
			double r = stroke_width_setting;
			
			if (unlikely (stroke_width_setting < 1)) {
				string width = Preferences.get ("stroke_width");
				if (width != "") {
					stroke_width_setting = double.parse (width);
				}
			}
			
			if (stroke_width_setting < 1) {
				stroke_width_setting = 1;
			}
		
			settings_mutex.unlock ();
			return r;
		}
		
		set {
			settings_mutex.lock ();
			stroke_width_setting = value;
			settings_mutex.unlock ();
		}
	}
	
	public static bool show_all_line_handles {
		get {
			settings_mutex.lock ();
			bool r = show_all_line_handles_setting;
			settings_mutex.unlock ();
			return r;
		}
		
		set {
			settings_mutex.lock ();
			show_all_line_handles_setting = value;
			settings_mutex.unlock ();
		}
	}
	
	public static bool fill_open_path {
		get {	
			settings_mutex.lock ();
			bool r = fill_open_path_setting;
			settings_mutex.unlock ();
			return r;
		}
		
		set {
			settings_mutex.lock ();
			fill_open_path_setting = value;
			settings_mutex.unlock ();
		}
	}
	
	static Mutex settings_mutex;

	/** The stroke of an outline when the path is not filled. */
	static double stroke_width_setting = 0;
	static bool show_all_line_handles_setting = true;
	static bool fill_open_path_setting = false;

	public static void init () {
		settings_mutex = new Mutex ();
	}

}

}
