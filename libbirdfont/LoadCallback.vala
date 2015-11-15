/*
	Copyright (C) 2014 Johan Mattsson

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
	
public class LoadCallback : GLib.Object {
	SaveDialogListener dialog;
	Font font;

	public signal void file_loaded ();
	
	public LoadCallback () {
		file_loaded.connect (() => {
			Font f = BirdFont.get_current_font ();
			
			if (!f.has_compatible_format ()) {
				if (f.newer_format ()) {
					MainWindow.show_message (t_("This font was made with a newer version of Birdfont.")
						+ " " + t_("You need to upgrade your version of Birdfont."));
				}

				if (f.older_format ()) {
					MainWindow.show_message (t_("This font was made with an old version of Birdfont.")
						+ " " + t_("You need an older version of Birdfont to open it."));
				}
			}
		});
	}

	public void load () {
		if (MenuTab.has_suppress_event ()) {
			warn_if_test ("Event suppressed");
			return;
		}

		dialog = new SaveDialogListener ();
		font = BirdFont.get_current_font ();
		
		dialog.signal_discard.connect (() => {
			MainWindow.close_all_tabs ();
			load_new_font ();
		});

		dialog.signal_save.connect (() => {
			MainWindow.close_all_tabs ();
			MenuTab.set_save_callback (new SaveCallback ());
			MenuTab.save_callback.file_saved.connect (load_new_font);
			MenuTab.save_callback.save (); // background thread
		});

		dialog.signal_cancel.connect (() => {
			MainWindow.hide_dialog ();
		});
				
		if (!font.is_modified ()) {
			dialog.signal_discard ();
		} else {
			MainWindow.show_dialog (new SaveDialog (dialog));
		}
	}

	private void load_new_font () {
		FileChooser fc = new FileChooser ();
		
		if (MenuTab.has_suppress_event ()) {
			warn_if_test ("Event suppressed");
			return;
		}
		
		fc.file_selected.connect((fn) => {
			Font f = BirdFont.get_current_font ();
			
			if (fn != null) {
				f.delete_backup ();
				
				f = BirdFont.new_font ();
				
				MainWindow.clear_glyph_cache ();
				
				f.set_file ((!) fn);
				Preferences.add_recent_files ((!) fn);
				MainWindow.native_window.load ();
				
				file_loaded.connect (() => {
					KerningTools.update_kerning_classes ();
					MenuTab.show_all_available_characters ();
				});
			}
		});
		
		MainWindow.file_chooser (t_("Open"), fc, FileChooser.LOAD);
	}
}
	
}
