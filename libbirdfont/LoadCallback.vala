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

	public signal void file_loaded ();
	
	public LoadCallback () {	
	}

	public void load () {
		SaveDialogListener dialog;
		Font font;
		
		if (MenuTab.suppress_event) {
			warn_if_test ("Event suppressed");
			return;
		}

		dialog = new SaveDialogListener ();
		font = BirdFont.get_current_font ();
				
		MainWindow.close_all_tabs ();
		
		dialog.signal_discard.connect (() => {
			load_new_font ();
		});

		dialog.signal_save.connect (() => {
			MenuTab.save ();
			load_new_font ();
		});
		
		if (!font.is_modified ()) {
			dialog.signal_discard ();
		} else {
			MainWindow.native_window.set_save_dialog (dialog);
		}
	}

	private void load_new_font () {
		string? fn;
		Font f;

		if (MenuTab.suppress_event) {
			warn_if_test ("Event suppressed");
			return;
		}
		
		f = BirdFont.get_current_font ();
		fn = MainWindow.file_chooser_open (t_("Open"));
		
		if (fn != null) {
			f.delete_backup ();
			
			f = BirdFont.new_font ();
			
			MainWindow.clear_glyph_cache ();
			
			f.set_file ((!) fn);
			MainWindow.native_window.load ();
			
			file_loaded.connect (() => {
				KerningTools.update_kerning_classes ();
				MenuTab.select_overview ();
			});
		}
	}
}
	
}
