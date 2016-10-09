/*
	Copyright (C) 2012, 2013, 2014, 2015 Johan Mattsson

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

public interface NativeWindow : GLib.Object {
	
	public static const int HIDDEN = 0;
	public static const int VISIBLE = 1;

	public abstract void file_chooser (string title, FileChooser file_chooser_callback, uint flags);
	
	public abstract void update_window_size ();

	public abstract string get_clipboard_data ();
	public abstract void set_clipboard (string data);
	public abstract void set_inkscape_clipboard (string data);

	/** Notify the UI about the new font. */
	public abstract void font_loaded ();

	/** Exit the application. */
	public abstract void quit ();

	/** Convert an image to PNG format. */
	public abstract bool convert_to_png (string from, string to);
	
	/** Export fonts in a background thread. */
	public abstract void export_font ();

	/** Load font in a background thread. */
	public abstract void load ();
	
	/** Save font in a background thread. */
	public abstract void save ();
	
	/** Load images in a background thread. */
	public abstract void load_background_image ();

	/** Run a background thread and block the gui. */
	public abstract void run_background_thread (Task t);
	
	/** Run a background thread without blocking the gui. */
	public abstract void run_non_blocking_background_thread (Task t);
	
	/** Copy text to clipboard. */
	public abstract void set_clipboard_text (string text);
	
	/** Get text from clipboard. */
	public abstract string get_clipboard_text ();
	
	/** @return true if the current font can be exported. */
	public abstract bool can_export ();

	/** Set cursor visibility */
	public abstract void set_cursor (int visible);

	/** Scale all offscreen buffers by this factor in order to 
	 * support high resolution screens.
	 */
	public abstract double get_screen_scale ();

}

}
