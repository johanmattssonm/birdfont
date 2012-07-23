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

class ContentDisplay : FontDisplay {

	List<Font> recent_fonts = new List<Font> ();

	int recent_active = -1;
	int open_active = -1;

	const int NEW_FONT = 0;
	const int LOAD_FONT = 1;
	const int SAVE_FONT = 2;

	Allocation allocation;
	int num_collumns = 0;

	Tool new_file_tool;
	Tool open_tool;
	Tool save_tool;
	Tool browser_tool;
	
	ExportTool export_tool;

	Tool kerning_context_tool;

	Tool add_new_grid_tool;
	Tool delete_grid_tool;
	
	public List<Tool> tools;
	
	StringBuilder name;
	int has_modifier = 0;
	bool marker = true;
	bool show_marker = true;
	TimeoutSource marker_blink;
	
	public ContentDisplay () {
		new_file_tool = new Tool ("new_file", "New file", 'n', CTRL);
		new_file_tool.x = 15;
		new_file_tool.y = 25;
		new_file_tool.select_action.connect((self) => {
			new_file ();
		});
		
		open_tool = new Tool ("open", "Open", 'o', CTRL);
		open_tool.x = 50;
		open_tool.y = 25;
		open_tool.select_action.connect((self) => {
			load ();
		});

		save_tool = new Tool ("save", "Save", 's', CTRL);
		save_tool.x = 85;
		save_tool.y = 25;
		save_tool.select_action.connect((self) => {
			save ();
		});
		
		browser_tool = new Tool ("view_result", "Export font and view result in web browser", ',', CTRL);
		browser_tool.x = 120;
		browser_tool.y = 25;
		browser_tool.select_action.connect((self) => {
			export_to_browser ();
		});

		export_tool = new ExportTool ("export");
		export_tool.x = 155;
		export_tool.y = 25;
		
		kerning_context_tool = new Tool ("kerning_context", "Show kerning context", 'k', CTRL);
		kerning_context_tool.x = 200;
		kerning_context_tool.y = 25;
		kerning_context_tool.select_action.connect((self) => {
			MainWindow.get_tab_bar ().add_unique_tab (new ContextDisplay (), 65, false);
		});
		
		add_new_grid_tool = new Tool ("add_new_grid", "Add new grid");
		add_new_grid_tool.x = 15;
		add_new_grid_tool.y = 95;
		add_new_grid_tool.select_action.connect((self) => {
			MainWindow.get_toolbox ().add_new_grid ();
		});
		
		delete_grid_tool = new Tool ("delete_grid", "Remove grid");
		delete_grid_tool.x = 50;
		delete_grid_tool.y = 95;
		delete_grid_tool.select_action.connect((self) => {
			MainWindow.get_toolbox ().remove_current_grid ();
		});
					
		tools = new List<Tool> ();
		tools.append (new_file_tool);
		tools.append (open_tool);
		tools.append (save_tool);
		tools.append (browser_tool);
		tools.append (kerning_context_tool);
		tools.append (add_new_grid_tool);
		tools.append (delete_grid_tool);
		tools.append (export_tool);
		
		name = new StringBuilder ();
		name.append (Supplement.get_current_font ().get_name ());
		
		marker = true;
		marker_blink = new TimeoutSource (1200);
		marker_blink.set_callback (() => {
			show_marker = !show_marker;
			MainWindow.get_glyph_canvas ().redraw ();	
			return marker;
		});
		marker_blink.attach (null);
		
		propagate_recent_files ();
		
		foreach (Tool t in tools) {
			t.set_default_color (1, 1, 1);
		}
	}

	private void save () {
		SaveDialog s = new SaveDialog ();
		save_dialog (s);
	}

	private void save_dialog (SaveDialog s) {
		FontDisplay fd = MainWindow.get_current_display ();
		
		// display save tab or save font if save dialog is open 
		if (fd is SaveDialog) {
			s = ((SaveDialog) fd);
			s.save.select_action (s.save);
		} else if (Supplement.get_current_font ().is_modified ()) {
			MainWindow.get_tab_bar ().add_unique_tab (s, 50);
		} else {
			s.finished ();
		}
	}

	private void new_file () {
		SaveDialog save = new SaveDialog ();
		save.finished.connect (() => {
			Font f = Supplement.get_current_font ();
			f.delete_backup ();
			
			Supplement.new_font ();
			MainWindow.close_all_tabs ();
			
			select_overview ();
		});
		save_dialog (save);	
	}
	
	private void load () {
		SaveDialog save = new SaveDialog ();
		save.finished.connect (() => {
			load_new_font ();
		});
		save_dialog (save);
	}
	
	private void export_to_browser () {
		export_tool.view_result ();
	}
	
	public override string get_name () {
		return "Content";
	}

	public override void draw (Allocation allocation, Context cr) {		
		this.allocation = allocation;
		
		if (num_collumns == 0) {
			propagate_recent_files ();
		}
		
		// bg color
		cr.save ();
		cr.set_source_rgba (1, 1, 1, 1);
		cr.rectangle (0, 0, allocation.width, allocation.height);
		cr.fill ();
		cr.restore ();
		
		// draw recent fonts
		draw_recent_fonts (allocation, cr);
		
		// new and open
		draw_menu (allocation, cr);
		
	}
	
	public override void selected_canvas () {
		KeyBindings.singleton.set_require_modifier (true);
		
		name.erase ();
		name.append (Supplement.get_current_font ().get_name ());
		
		propagate_recent_files ();
	}

	public void propagate_recent_files () {
		Font font;
		this.num_collumns = (int) (allocation.width / 150.0);
		
		while (recent_fonts.length () != 0) {
			recent_fonts.delete_link (recent_fonts.first ());
		}
		
		foreach (var f in Preferences.get_recent_files ()) {
			if (f == "") continue;
			
			File file = File.new_for_path (f);

			font = new Font ();
			
			font.set_font_file (f);
			
			if (file.query_exists ()) { 
				recent_fonts.append (font);
			}
		}
		
		recent_fonts.reverse ();
	}

	private void draw_recent_fonts (Allocation allocation, Context cr) {
		double x = 10;
		double y = 260 + 25;
		int i = 0;
		int columns = (int) (allocation.width / 150.0);
		string fn;
		
		if (recent_fonts.length () == 0) {
			return;
		}
		
		cr.save ();

		cr.set_font_size (14);
		cr.select_font_face ("Cantarell", FontSlant.NORMAL, FontWeight.BOLD);
				
		cr.move_to (x, y);
		cr.show_text ("Recent fonts");

		y = 260 + 45;
		x = 10;
		
		foreach (var font in recent_fonts) {
			string svg = font.get_svg_thumbnail ();
			string font_file = (!) font.font_file;
			
			cr.save ();
			
			if (recent_active == i) 
				cr.set_source_rgba (84/255.0, 134/255.0, 148/255.0, 1);
			else
				cr.set_source_rgba (176/255.0, 211/255.0, 230/255.0, 1);
				
			cr.set_line_join (LineJoin.ROUND);
			cr.set_line_width (7);
			
			cr.rectangle (x, y, 130, 130);
			cr.fill_preserve ();
			cr.stroke ();
			cr.restore ();
	
			Svg.draw_svg_path (cr, svg, x + 40, y + 90);
			
			cr.save ();
			cr.move_to (x + 3, y + 155);
			cr.set_font_size (10);
			cr.set_source_rgba(0, 0, 0, 1);
			
			font_file = (!) font.font_file;
			
			fn = font_file.substring (font_file.replace ("\\", "/").last_index_of ("/") + 1);
			
			if (fn.char_count () > 17) {
				fn = fn.substring (0, 17) + " ...";
			}
			
			cr.show_text (fn);
			cr.restore ();
			
			x += 150;
			i++;
			
			if (--columns <= 0) {
				break;
			}
		}
		
		cr.stroke ();
		cr.restore ();
		
	}

	private void draw_menu (Allocation allocation, Context cr) {
		draw_file_menu (allocation, cr);
		draw_grid_menu (allocation, cr);
		draw_font_name (allocation, cr);
	}
	
	private void draw_file_menu (Allocation allocation, Context cr) {
		double x;
		double y; 
		
		x = 10;
		y = 25;

		cr.save ();
		
		cr.move_to (x, y);
		
		cr.set_font_size (14);
		cr.select_font_face ("Cantarell", FontSlant.NORMAL, FontWeight.BOLD);
		
		cr.move_to (x, y);
		cr.show_text ("File");
			
		cr.move_to (200, y);
		cr.show_text ("Views");
		
		cr.restore ();

		save_tool.draw (allocation, cr);
		new_file_tool.draw (allocation, cr);
		open_tool.draw (allocation, cr);
		browser_tool.draw (allocation, cr);
		export_tool.draw (allocation, cr);
			
		kerning_context_tool.draw (allocation, cr);
	}
	
	private void draw_grid_menu (Allocation allocation, Context cr) {
		double x;
		double y; 
	
		x = 10;
		y = 95;

		cr.save ();
		
		cr.set_font_size (14);
		cr.select_font_face ("Cantarell", FontSlant.NORMAL, FontWeight.BOLD);
				
		cr.move_to (x, y);
		cr.show_text ("Grid width");

		cr.move_to (x + 100, y);
		cr.show_text (""); // Grid angle
		
		cr.restore ();
		
		add_new_grid_tool.draw (allocation, cr);
		delete_grid_tool.draw (allocation, cr);
	}
	
	private void draw_font_name (Allocation allocation, Context cr) {
		double x;
		double y; 
		string m;
		
		x = 10;
		y = 165;

		cr.save ();
		
		cr.set_font_size (14);
		cr.select_font_face ("Cantarell", FontSlant.NORMAL, FontWeight.BOLD);
				
		cr.move_to (x, y);
		cr.show_text ("Name");

		cr.select_font_face ("Cantarell", FontSlant.NORMAL, FontWeight.NORMAL);
		cr.set_font_size (16);
		cr.move_to (x + 1, y + 20);
		
		m = (show_marker) ? "|" : "";
		
		cr.show_text (name.str + m);
		
		cr.restore ();
		
	}
	
	public override void key_press (EventKey e) {
		unichar c = (unichar) e.keyval;
		Font f;
		
		if (e.type != EventType.KEY_PRESS) { 
			return;
		}
		
		if (is_mod (e)) {
			return;
		}
		
		if (KeyBindings.singleton.modifier != NONE && KeyBindings.singleton.modifier != SHIFT) {
			return;
		}
		
		if (e.keyval == Key.BACK_SPACE) {			
			name.truncate (name.len - 1);
			
			while (!name.str.validate ()) {
				name.truncate (name.len - 1);
				
				if (name.str.length == 0) {
					break;
				}
			}
		}
				
		if (has_modifier == 0 && !is_modifier_key (e.keyval) && c.validate ()) {
			
			// webkit does not allow full unicode characters or space in name
			// replace non-ansi characters with _

			if ('0' <= c <= '9' || 'a' <= c <= 'z' || 'A' <= c <= 'Z') {
				name.append_unichar (c);
			} else {
				name.append_unichar ('_');
			}
			
			f = Supplement.get_current_font ();
			f.set_name (name.str);
			f.touch ();
		}

		MainWindow.get_glyph_canvas ().redraw ();	
	}

	public override void key_release (EventKey e) {
		if (is_mod (e)) {
			has_modifier--;
		}
	}
	
	public override void motion_notify (EventMotion e) {
		int column = (int)(e.x / 160);
		bool a;
		
		if (280 < e.y < 280 + 150) {
			recent_active = column;
		} else {
			recent_active = -1;
		}

		if (44 < e.y < 181) {
			open_active = column;
		} else {
			open_active = -1;
		}

		foreach (Tool t in tools) {
			a = t.is_over (e.x, e.y);
			t.set_active (a);
			
			if (a) {
				MainWindow.get_tool_tip ().set_text_from_tool ();
			}
		}

		MainWindow.get_glyph_canvas ().redraw ();
	}

	public override void button_release (EventButton event) {
		int columns = (int) (allocation.width / 150.0) - 1;
		SaveDialog save = new SaveDialog ();
		Font cf = Supplement.get_current_font ();
		string f, f2;
		
		foreach (Tool t in tools) {
			if (t.is_over (event.x, event.y)) {
				activate (t);
			}
		}

		if (0 <= recent_active <= columns) {
			return_if_fail (recent_fonts.nth (recent_active).data.font_file != null);
			
			f = (!) cf.font_file;
			f2 = (!) recent_fonts.nth (recent_active).data.font_file;			

			if (cf.font_file != null && f == f2) { // recent font is already loaded
				MainWindow.get_toolbox ().select_tool_by_name ("available_characters");
			} else {		
				save.finished.connect (() => {
					Supplement.get_current_font ().delete_backup ();
					load_recent_font ();
				});
				save_dialog (save);
			}
		}
	}
	
	private void activate (Tool t) {
		t.select_action (t);
		MainWindow.get_tool_tip ().set_text_from_tool ();
	}
	
	private void load_new_font () {
		string? fn;
		FileChooserDialog file_chooser = new FileChooserDialog ("Open font file", MainWindow.get_current_window (), FileChooserAction.OPEN, Stock.CANCEL, ResponseType.CANCEL, Stock.OPEN, ResponseType.ACCEPT);
		Font f = Supplement.get_current_font ();
		
		try {
			file_chooser.set_current_folder_file (f.get_folder ());
		} catch (GLib.Error e) {
			stderr.printf (e.message);
		}
		
		if (file_chooser.run () == ResponseType.ACCEPT) {	
			MainWindow.get_glyph_canvas ().redraw ();
	
			fn = file_chooser.get_filename ();

			if (fn != null) {
				f.delete_backup ();
				
				MainWindow.clear_glyph_cache ();
				MainWindow.close_all_tabs ();
				f.load ((!)fn);
				
				MainWindow.get_singleton ().set_title (f.get_name ());
				select_overview ();		
				Preferences.add_recent_files ((!) fn);
			}
		}
		
		file_chooser.destroy ();
	}

	private void select_overview () {
		Toolbox tb = MainWindow.get_toolbox ();
		
		if (Supplement.get_current_font ().is_empty ()) {
			tb.select_tool_by_name ("custom_character_set");
		} else {
			tb.select_tool_by_name ("available_characters");	
		}
	}

	private void load_recent_font () {
		string? fnn;
		string fn;
		Font f;
		bool loaded;
		
		if (0 <= recent_active < recent_fonts.length ()) {
			fnn = recent_fonts.nth (recent_active).data.font_file;

			return_if_fail (fnn != null);
			
			fn = (!) fnn; 

			f = Supplement.get_current_font ();
			f.delete_backup ();
			
			MainWindow.clear_glyph_cache ();
			MainWindow.close_all_tabs ();
			
			loaded = f.load (fn);
			
			if (!unlikely (loaded)) {
				warning (@"Failed to load fond $fn");
				return;
			}
			
			MainWindow.get_singleton ().set_title (f.get_name ());
			Preferences.add_recent_files (fn);			
			select_overview ();
		}
	}

	public override void button_press (EventButton event) {
		bool a;
		foreach (Tool t in tools) {
			a = t.is_over (event.x, event.y);
			t.set_active (a);
			
			if (a) {
				MainWindow.get_tool_tip ().set_text_from_tool ();
			}
		}
		
		if (167 < event.y < 193) {
			
		}
	}

}

}
