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

using Gtk;
using Gdk;
using Cairo;

namespace Supplement {

class SaveDialog : FontDisplay {

	public signal void finished ();

	public Tool save = new Tool ("save");
	public Tool discard = new Tool ("no_icon");
	public Tool cancel = new Tool ("cancel_save");
	public Tool file_selection_dialog = new Tool ("file_selection");
	
	FileSelection file_selection = new FileSelection ();

	int selected_index = 0;
	
	public SaveDialog () {
		save.select_action.connect (() => {
			
			if (file_selection.path.len < 4 || file_selection.path.str.substring (-4) != ".ffi") {
				file_selection.path.append (".ffi");
			}
			
			bool s = Supplement.get_current_font ().save (file_selection.path.str);
			
			Preferences.set_last_file (file_selection.path.str);
			Preferences.add_recent_files (file_selection.path.str);
			
			if (s) {
				MainWindow.get_tab_bar ().close_display (this);
				finished ();
			} else {
				stderr.printf ("Failed to save $(file_selection.path.str)\n");
			}
		});

		discard.select_action.connect (() => {
			MainWindow.get_tab_bar ().close_display (this);
			finished ();
		});

		file_selection.redraw.connect (() => {
			redraw_area (file_selection.x - 50, file_selection.y - 50, 500, 500);
		});
		
		cancel.select_action.connect (() => {
			MainWindow.get_tab_bar ().close_display (this);
		});
		
		file_selection_dialog.select_action.connect (() => {
			show_file_selection ();
		});
		
		save.set_default_color (1, 1, 1);
		discard.set_default_color (1, 1, 1);
		cancel.set_default_color (1, 1, 1);
		file_selection_dialog.set_default_color (1, 1, 1);
	}

	public override string get_name () {
		return "Save?";
	}
	
	public override void draw (Allocation allocation, Context cr) {
		double xc, yc, d;
		
		cr.save ();
		cr.set_line_width (0);
		cr.set_source_rgba (1, 1, 1, 1);
		cr.rectangle (0, 0, allocation.width, allocation.height);
		cr.fill_preserve ();
		
		xc = allocation.width / 2.0;
		yc = allocation.height / 2.0;
				
		cr.set_source_rgba (0/255.0, 0/255.0, 0/255.0, 1);

		d = 130;

		cr.move_to (xc - d, yc - 100);
		cr.set_font_size (16);
		cr.select_font_face ("Cantarell", FontSlant.NORMAL, FontWeight.NORMAL);
		cr.show_text ("Do you want to save your work?");
		
		file_selection.x = xc - d;
		file_selection.y = yc - 70;
		file_selection.draw (allocation, cr);
		
		if (selected_index == 0) save.set_active (true);
		if (selected_index == 1) discard.set_active (true);
		if (selected_index == 2) cancel.set_active (true);
		if (selected_index == 3) file_selection_dialog.set_active (true);
		
		save.x = xc - d;
		save.y = yc - 40;
		save.draw (allocation, cr);

		discard.x = xc - d + 40;
		discard.y = yc - 40;		
		discard.draw (allocation, cr);

		cancel.x = xc - d + 80;
		cancel.y = yc - 40;		
		cancel.draw (allocation, cr);

		file_selection_dialog.x = xc - d + 120;
		file_selection_dialog.y = yc - 40;		
		file_selection_dialog.draw (allocation, cr);

		cr.restore ();

		cr.save ();
	
		cr.restore ();
	}

	private void show_file_selection () {
		string? fn;
		Font font = Supplement.get_current_font ();
		FileChooserDialog file_chooser = new FileChooserDialog ("Save", MainWindow.get_current_window (), FileChooserAction.SAVE, Stock.CANCEL, ResponseType.CANCEL, Stock.SAVE, ResponseType.ACCEPT);
		
		try {
			file_chooser.set_current_folder_file (font.get_folder ());
		} catch (GLib.Error e) {
			stderr.printf (e.message);
		}
		
		if (file_chooser.run () == ResponseType.ACCEPT) {	
			MainWindow.get_glyph_canvas ().redraw ();
	
			fn = file_chooser.get_filename ();

			if (fn != null) {
				file_selection.set_path ((!) fn);
			}
		}
		
		file_chooser.destroy ();
	}
		
	public override void selected_canvas () {
	}
	
	public override void key_press (EventKey e) {
		if (e.type != EventType.KEY_PRESS) {
			return;
		}
	
		if (e.keyval == Key.LEFT) {
			selected_index--;
		}

		if (e.keyval == Key.RIGHT) {
			selected_index++;
		}
		
		if (e.keyval == Key.ENTER) {
			if (selected_index == 0) save.select_action (save);
			if (selected_index == 1) discard.select_action (discard);
			if (selected_index == 2) cancel.select_action (cancel);
			else file_selection_dialog.select_action (file_selection_dialog);
		}
		
		file_selection.key_press (e);

		// keyboard moves selection
		save.set_active (false);
		discard.set_active (false);
		cancel.set_active (false);
		file_selection_dialog.set_active (false);
		
		if (selected_index < 0) selected_index = 0;
		if (selected_index > 3) selected_index = 3;
		
		if (selected_index == 0) save.set_active (true);
		if (selected_index == 1) discard.set_active (true);
		if (selected_index == 2) cancel.set_active (true);
		if (selected_index == 3) file_selection_dialog.set_active (true);
		
		redraw_area (file_selection.x - 20, file_selection.y - 20, 500, 200);
	}
	
	public override void key_release (EventKey e) {
		file_selection.key_release (e);
	}
	
	public override void motion_notify (EventMotion e) {
		bool a, u;
		a = save.is_over (e.x, e.y);
		u = save.set_active (a);
		
		a = discard.is_over (e.x, e.y);
		u = discard.set_active (a);

		a = cancel.is_over (e.x, e.y);
		u = cancel.set_active (a);

		a = file_selection_dialog.is_over (e.x, e.y);
		u = file_selection_dialog.set_active (a);
		
		redraw_area (save.x - 10, save.y - 10, 200, 100);
	}
	
	public override void button_release (EventButton e) {
		bool a;
		
		a = save.is_over (e.x, e.y);
		if (a) {
			save.select_action (save);
		}

		a = discard.is_over (e.x, e.y);
		if (a) {
			discard.select_action (discard);
		}
		
		a = cancel.is_over (e.x, e.y);
		if (a) {
			cancel.select_action (cancel);
		}
		
		a = file_selection_dialog.is_over (e.x, e.y);
		if (a) {
			file_selection_dialog.select_action (file_selection_dialog);
		}
		
				
	}
	
	public override void leave_notify (EventCrossing e) {
	}
	
	public override void button_press (EventButton e) {
	}

}
	
}
