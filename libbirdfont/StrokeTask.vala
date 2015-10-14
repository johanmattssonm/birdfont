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
	
public class StrokeTask : Task {
	Path original; // path in gui thread
	Path background_path; // path in background thread
	
	public StrokeTask (Path path) {
		base (null);
		original = path;
		background_path = path.copy ();
	}

	public StrokeTask.none () {
		base (null);
		original = new Path ();
		background_path = new Path ();
	}
		
	public override void run () {
		PathList stroke;
		double w;
		StrokeTool tool = new StrokeTool.with_task (this);
		
		w = background_path.stroke;
		
		Test t = new Test.time ("full stroke");
		stroke = tool.get_stroke (background_path, w);
		t.print ();
		print(@"Cancelled: $(is_cancelled ())\n");
		
		IdleSource idle = new IdleSource (); 
		idle.set_callback (() => {	
			if (!is_cancelled ()) {
				original.full_stroke = stroke;
				GlyphCanvas.redraw ();
			}

			return false;
		});
		idle.attach (null);		
	}
}

}
