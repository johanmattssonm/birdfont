/*
    Copyright (C) 2012 Johan Mattsson

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

using Cairo;
using Gtk;
using Gdk;

namespace Supplement {

public abstract class FontDisplay : GLib.Object {
	
	/** Queue redraw area */
	public signal void redraw_area (double x, double y, double w, double h);
	
	/** Name of symbol or set of symbols in display selections like the tab panel. */
	public virtual string get_name () {
		return "";
	}
	
	public virtual void draw (Allocation allocation, Context cr) {
	}
	
	public virtual void selected_canvas (){
	}
	
	public virtual void key_press (EventKey e){
	}
	
	public virtual void key_release (EventKey e) {
	}
	
	public virtual void motion_notify (EventMotion e) {
	}
	
	public virtual void button_release (EventButton event) {
	}
	
	public virtual void leave_notify (EventCrossing e) {
	}
	
	public virtual void button_press (EventButton e) {
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
		warning ("store_current_view not implemented for this class.");
	}
	
	public virtual void restore_last_view () {
		warning ("restore_last_view not implemented for this class.");
	}

	public virtual void next_view () {
		warning ("next_view not implemented for this class.");
	}
	
	public virtual void scroll_wheel_up (Gdk.EventScroll e) {
	}
	
	public virtual void scroll_wheel_down (Gdk.EventScroll e) {
	}

	public virtual void undo () {
	}
}

}
