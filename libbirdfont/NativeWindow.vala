/*
    Copyright (C) 2012, 2013, 2014 Johan Mattsson

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
	public abstract void file_chooser (string title, FileChooser file_chooser_callback, uint flags);
	
	public abstract void update_window_size ();

	public abstract string get_clipboard_data ();
	public abstract void set_clipboard (string data);
	public abstract void set_inkscape_clipboard (string data);

	public abstract void color_selection (ColorTool color_tool);

	public abstract void set_scrollbar_size (double size);
	public abstract void set_scrollbar_position (double position);
	
	/** Request text input from the UI. */
	public abstract void set_text_listener (TextListener listener);
	
	/** Remove the text listener and hode the text area. */
	public abstract void hide_text_input ();

	/** Show overwrite dialog */
	public abstract void set_overwrite_dialog (OverWriteDialogListener dialog);
	
	/** Notify the UI about the new font. */
	public abstract void font_loaded ();

	/** Exit the application. */
	public abstract void quit ();

	/** Convert an image to PNG format. */
	public abstract bool convert_to_png (string from, string to);

	/** Show help text. */
	public abstract void show_tooltip (string tooltip, int x, int y);
	
	/** Hide help text. */
	public abstract void hide_tooltip ();
	
	/** Export fonts in a background thread. */
	public abstract void export_font ();

	/** Load font in a background thread. */
	public abstract void load ();
	
	/** Save font in a background thread. */
	public abstract void save ();
	
	/** Load images in a background thread. */
	public abstract void load_background_image ();

	/** Load images in a background thread. */
	public abstract void run_background_thread (Task t);
	
	/** Copy text to clipboard. */
	public abstract void set_clipboard_text (string text);
	
	/** Get text from clipboard. */
	public abstract string get_clipboard_text ();
	
	/** @return true if the current font can be exported. */
	public abstract bool can_export ();
}

}
