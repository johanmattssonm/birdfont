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

class Screen {
	public static double get_scale () {
		return MainWindow.native_window.get_screen_scale ();
	}
	
	public static ImageSurface create_background_surface (int w, int h) {
		int width = (int) (get_scale () * w);
		int height = (int) (get_scale () * h);
		return new ImageSurface(Cairo.Format.ARGB32, width, height);
	}
	
	public static void paint_background_surface(Context cr, Surface s, int x, int y) {
		cr.save ();
		cr.set_antialias (Cairo.Antialias.NONE);
		cr.scale (1 / get_scale (), 1 / get_scale ());	
		cr.set_source_surface (s, (int) (x * Screen.get_scale ()), (int) (y * Screen.get_scale ()));
		cr.paint ();
		cr.restore ();
	}

}
	
}
