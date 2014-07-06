/*
    Copyright (C) 2012 Johan Mattsson

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

public abstract class FontDisplay : GLib.Object {
	
	/** Queue redraw area */
	public signal void redraw_area (double x, double y, double w, double h);
	
	public virtual string get_name () {
		warning ("No name.");
		return "";
	}

	public virtual string get_label () {
		warning ("No label.");
		return "";
	}
		
	public virtual void close () {
	}
	
	public virtual bool has_scrollbar () {
		return false;
	}
	
	public virtual void scroll_to (double percent) {
	}
	
	public virtual void draw (WidgetAllocation allocation, Context cr) {
	}
	
	public virtual void selected_canvas () {
	}
	
	public virtual void key_press (uint keyval) {
	}
	
	public virtual void key_release (uint keyval) {
	}
	
	public virtual void motion_notify (double x, double y) {
	}
	
	public virtual void button_release (int button, double x, double y) {
	}
	
	public virtual void button_press (uint button, double x, double y) {
	}

	public virtual void double_click (uint button, double ex, double ey) {
	}	

	public virtual void zoom_in () {
	}
	
	public virtual void zoom_out () {
	}
	
	public virtual void zoom_max () {
	}
	
	public virtual void zoom_min () {
	}
	
	public virtual void reset_zoom () {
	}
	
	public virtual void store_current_view () {
	}
	
	public virtual void restore_last_view () {
	}

	public virtual void next_view () {
	}
	
	public virtual void scroll_wheel_up (double x, double y) {
	}
	
	public virtual void scroll_wheel_down (double x, double y) {
	}

	public virtual void undo () {
	}

	public static File find_file (string? dir, string name) {
		return SearchPaths.find_file (dir, name);	
	}
}

}
