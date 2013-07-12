/*
    Copyright (C) 2012, 2013 Johan Mattsson

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

namespace BirdFont {

public interface NativeWindow : GLib.Object {
	public abstract string? file_chooser_save (string title);
	public abstract string? file_chooser_open (string title);
	
	public abstract string? set_title (string title);

	public abstract void toggle_expanded_margin_bottom ();
	public abstract void toggle_expanded_margin_right ();
	
	public abstract void update_window_size ();

	public abstract string get_clipboard_data ();
	public abstract void set_clipboard (string data);
	public abstract void set_inkscape_clipboard (string data);

	public abstract void color_selection (ColorTool color_tool);

	public abstract void set_scrollbar_size (double size);
	public abstract void set_scrollbar_position (double position);
	
	public abstract void spawn (string command);
	
	/** Request text input from the UI. */
	public abstract void set_text_listener (TextListener listener);
	
	/** Remove the text listener and hode the text area. */
	public abstract void hide_text_input ();
	
	protected void webkit_callback (string s) {
		FontDisplay fd = MainWindow.get_current_display ();
		fd.process_property (s);
	}
}

}
