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

using Cairo;

namespace BirdFont {

public class Scrollbar : GLib.Object {

	public double position = 1;
	public double size = 1;
	public double width = 0;
	public double left_x = 0;
	public double height = 0;
	public double corner = 0;
	public double scroll_max = 1;

	public double motion_x = 0;
	public double motion_y = 0;
	public bool move = false;

	public Scrollbar () {	
	}

	public bool button_press (uint button, double x, double y) {
		double h = height * position * scroll_max;
	
		if (left_x < x < left_x + width &&
			 h < y < h + height * size) {
			 	
			motion_x = x;
			motion_y = y;
			
			move = true;
		}
		
		return left_x < x < left_x + width && 0 < size < 1;
	}

	public bool button_release (uint button, double x, double y) {
		if (move) {
			move = false;
			return true;
		} else if (left_x < x < left_x + width) {
			double h = height * position * scroll_max;
			
			if (y > h + size * height) {
				print (@"down   $position\n");				
				position += size;
			} 
			
			if (y < h) {
				print (@"up   $position\n");
				position -= size;
			}
			
			if (position > 1) {
				position = 1;
				print (@"max $scroll_max\n");
			} else if (position < 0) {
				position = 0;			
			}
			
			TabContent.scroll_to (position);
			GlyphCanvas.redraw ();
			return true;
		}
		
		return false;
	}
	

	public bool motion (double x, double y) {
		if (!move) {
			return false;
			
		}

		double p = (y - motion_y) / (height - size * height);
		position += p;

		if (position > 1) {
			position = 1;
		} else if (position < 0) {
			position = 0;			
		}

		TabContent.scroll_to (position);		

		GlyphCanvas.redraw ();
		
		motion_y = y;
		motion_x = x;

		return false;
	}
	
	public void draw (Context cr, WidgetAllocation content_allocation, double width) {
		cr.save ();

		this.width = width;		
		this.left_x = content_allocation.width;
		this.height = content_allocation.height;
		this.corner = 4 * Screen.get_scale ();
		this.scroll_max = 1 - size - 2 * corner / height;
				
		Theme.color (cr, "Scrollbar Background");	
		cr.rectangle (left_x, 0, width, height);		
		cr.fill ();		

		Theme.color (cr, "Scrollbar Foreground");
		double h = height * position * scroll_max;
		Widget.draw_rounded_rectangle (cr, left_x, h, width, height * size, corner);			
		cr.fill ();
		
		cr.restore ();
	}
	
	public bool is_visible () {
		return true;
	}

	public void set_size (double size) {
		this.size = size; 
	}

	public void set_position (double position) {
		this.position = position;
	}
}

}
 