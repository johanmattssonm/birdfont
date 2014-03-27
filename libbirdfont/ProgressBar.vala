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

namespace BirdFont {

/** Progress bar */
class ProgressBar {
	
	static double current_progress = 0;
	public signal void new_progress ();
	static ProgressBar? singleton = null;

	public ProgressBar () {
		singleton = this;
	}

	public static void set_progress (double d) {
		ProgressBar p;
		
		if (singleton == null) {
			return;
		}
		
		p = (!) singleton;
		current_progress = d;
		p.new_progress ();
		
		if (is_null (MainWindow.get_tooltip ())) {
			MainWindow.get_tooltip ().redraw ();
		}
	}

	public static double get_progress () {
		ProgressBar p;
		
		if (singleton == null) {
			return 0;
		}
		
		p = (!) singleton;
		
		return ProgressBar.current_progress;
	}
}

}
