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

using Gtk;
using Gdk;
using Cairo;

namespace Bird {

class Widget : DrawingArea {
	
	Component component;
	
	public Widget (Component main_component) {		
		component = main_component;

		add_events (EventMask.BUTTON_PRESS_MASK 
			| EventMask.POINTER_MOTION_MASK
			| EventMask.LEAVE_NOTIFY_MASK);
			  
		motion_notify_event.connect ((event)=> {
			component.motion_notify_event (event.x, event.y);
			return true;
		});	
				
		button_press_event.connect ((event)=> {
			component.button_press_event (event.button, event.x, event.y);
			return true;
		});

		draw.connect ((event) => {
			Context cairo_context = cairo_create (get_window ());
			component.draw (cairo_context);
			return true;
		});
	}
	
}

}
