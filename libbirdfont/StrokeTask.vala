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

namespace BirdFont {
	
class StrokeTask : Task {
	bool cancelled = false;
	Path original; // path in gui thread
	Path background_path; // path in background thread
	
	public StrokeTask (Path path) {
		base (null);
		original = path;
		background_path = path.copy ();
	}
	
	public void cancel () {
		lock (cancelled) {	
			cancelled = true;
		}
	}
	
	public override void run () {
		PathList stroke;
		double w;
		
		w = background_path.stroke;
		stroke = StrokeTool.get_stroke (background_path, w);

		IdleSource idle = new IdleSource (); 
		idle.set_callback (() => {
			
			lock (cancelled) {			
				if (!cancelled) {
					original.full_stroke = stroke;
					GlyphCanvas.redraw ();
				}
			}
			
			return false;
		});
		idle.attach (null);		
	}
}

}
