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
using Math;

namespace BirdFont {

public class GlyphTab : FontDisplay {

	public GlyphCollection glyphs;

	public GlyphTab (GlyphCollection glyphs) {
		this.glyphs = glyphs;
	}

	public override string get_name () {
		return glyphs.get_current ().get_name ();
	}

	public override string get_label () {
		return glyphs.get_current ().get_label ();
	}

	public override void close () {
		glyphs.get_current ().close ();
	}

	public override bool has_scrollbar () {
		return glyphs.get_current ().has_scrollbar ();
	}

	public override void update_scrollbar () {
		glyphs.get_current ().update_scrollbar ();
	}

	public override void scroll_to (double percent) {
		glyphs.get_current ().scroll_to (percent);
	}

	public override void draw (WidgetAllocation allocation, Context cr) {
		glyphs.get_current ().draw (allocation, cr);
	}

	public override void selected_canvas () {
		glyphs.get_current ().selected_canvas ();
	}

	public override void key_press (uint keyval) {
		glyphs.get_current ().key_press (keyval);
	}

	public override void key_release (uint keyval) {
		glyphs.get_current ().key_release (keyval);
	}

	public override void motion_notify (double x, double y) {
		glyphs.get_current ().motion_notify (x, y);
	}

	public override void button_release (int button, double x, double y) {
		glyphs.get_current ().button_release (button, x, y);
	}

	public override void button_press (uint button, double x, double y) {
		glyphs.get_current ().button_press (button, x, y);
	}

	public override void double_click (uint button, double ex, double ey) {
		glyphs.get_current ().double_click (button, ex, ey);	
	}

	public override void magnify (double magnification) {
		glyphs.get_current ().magnify (magnification);
	}

	public override void tap_down (int finger, int x, int y) {
		glyphs.get_current ().tap_down (finger, x, y);
	}

	public override void tap_up (int finger, int x, int y) {
		glyphs.get_current ().tap_up (finger, x, y);
	}

	public override void tap_move (int finger, int x, int y) {
		glyphs.get_current ().tap_move (finger, x, y);
	}

	public override void zoom_in () {
		glyphs.get_current ().zoom_in ();
	}

	public override void zoom_out () {
		glyphs.get_current ().zoom_out ();
	}

	public override void zoom_max () {
		glyphs.get_current ().zoom_max ();
	}

	public override void zoom_min () {
		glyphs.get_current ().zoom_min ();
	}

	public override void move_view (double x, double y) {
		glyphs.get_current ().move_view (x, y);	
	}

	public override void reset_zoom () {
		glyphs.get_current ().reset_zoom ();
	}

	public override void store_current_view () {
		glyphs.get_current ().store_current_view ();
	}

	public override void restore_last_view () {
		glyphs.get_current ().restore_last_view ();
	}

	public override void next_view () {
		glyphs.get_current ().next_view ();
	}

	public override void scroll_wheel (double x, double y,
		double pixeldelta_x,  double pixeldelta_y) {
			glyphs.get_current ().scroll_wheel (x, y, pixeldelta_x, pixeldelta_y);
	}

	public override void undo () {
		glyphs.get_current ().undo ();
	}

	public override void redo () {
		glyphs.get_current ().redo ();
	}

	/** returns false if bindings to a single key works in the display. */
	public override bool needs_modifier () {
		return glyphs.get_current ().needs_modifier ();
	}
}

}
