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

namespace BirdFont {

public class MenuTab : FontDisplay {
	
	/** Ignore actions when export is in progress. */
	public static bool suppress_event = false;

	public MenuTab () {
	}
	
	public static void export_font ()  {
		Font font = BirdFont.get_current_font ();		
		if (font.font_file == null) {
			if (MenuTab.save ()) {
				ExportTool.export_all ();
			}
		} else {
			ExportTool.export_all ();
		}
	}
	
	public static void set_suppress_event (bool e) {
		suppress_event = e;
	}

	public override string get_label () {
		return t_("Menu");
	}
		
	public override string get_name () {
		return "Menu";
	}

	public static void select_overview () {
		if (suppress_event) {
			return;
		}
		
		if (BirdFont.get_current_font ().is_empty ()) {
			Toolbox.select_tool_by_name ("custom_character_set");
		} else {
			Toolbox.select_tool_by_name ("available_characters");	
		}
	}

	public static bool save_as ()  {
		string? fn = null;
		string f;
		bool saved = false;
		Font font = BirdFont.get_current_font ();

		if (suppress_event) {
			return false;
		}
		
		fn = MainWindow.file_chooser_save (t_("Save"));
		
		if (fn != null) {
			f = (!) fn;
			
			if (!f.has_suffix (".bf")) {
				f += ".bf";
			}
			
			font.font_file = f;
			save ();
			saved = true;
		}

		return saved;
	}

	public static bool save () {
		Font f = BirdFont.get_current_font ();
		string fn;
		bool saved = false;

		if (suppress_event) {
			return false;
		}

		f.delete_backup ();
		
		fn = f.get_path ();
		
		if (f.font_file != null && fn.has_suffix (".bf")) {
			f.background_scale = MainWindow.get_drawing_tools ().background_scale.get_display_value ();
			
			while (f.grid_width.length () > 0) {
				f.grid_width.remove_link (f.grid_width.first ());
			}
			
			foreach (SpinButton s in GridTool.sizes) {
				f.grid_width.append (s.get_display_value ());
			}
			
			f.save (fn);
			saved = true;
		} else {
			saved = save_as ();
		}
		
		return saved;
	}
	
	public static void new_file () {
		Font font;
		SaveDialogListener dialog = new SaveDialogListener ();

		if (suppress_event) {
			return;
		}
		
		font = BirdFont.get_current_font ();
		
		dialog.signal_discard.connect (() => {
			BirdFont.new_font ();
			MainWindow.close_all_tabs ();
			
			MainWindow.get_drawing_tools ().remove_all_grid_buttons ();
			MainWindow.get_drawing_tools ().add_new_grid ();
			MainWindow.get_drawing_tools ().add_new_grid ();
			
			KerningTools.update_kerning_classes ();
			
			select_overview ();
		});

		dialog.signal_save.connect (() => {
			MenuTab.save ();
			dialog.signal_discard ();
		});
		
		if (!font.is_modified ()) {
			dialog.signal_discard ();
		} else {
			MainWindow.native_window.set_save_dialog (dialog);
		}
		
		return;
	}
	
	public static void load () {
		SaveDialogListener dialog = new SaveDialogListener ();
		Font font = BirdFont.get_current_font ();
		
		if (suppress_event) {
			return;
		}
		
		dialog.signal_discard.connect (() => {
			load_new_font ();
		});

		dialog.signal_save.connect (() => {
			MenuTab.save ();
			dialog.signal_discard ();
		});
		
		if (!font.is_modified ()) {
			dialog.signal_discard ();
		} else {
			MainWindow.native_window.set_save_dialog (dialog);
		}
	}

	private static void load_new_font () {
		string? fn;
		Font f;

		if (suppress_event) {
			return;
		}
		
		f = BirdFont.get_current_font ();
		fn = MainWindow.file_chooser_open (t_("Open"));
		
		if (fn != null) {
			f.delete_backup ();
			
			f = BirdFont.new_font ();
			
			MainWindow.clear_glyph_cache ();
			MainWindow.close_all_tabs ();
			f.load ((!)fn);
			
			KerningTools.update_kerning_classes ();
			
			select_overview ();		
		}
	}

	public static void quit () {
		SaveDialogListener dialog = new SaveDialogListener ();
		Font font = BirdFont.get_current_font ();
		
		Preferences.save ();
		
		if (suppress_event) {
			return;
		}
		
		dialog.signal_discard.connect (() => {
			MainWindow.native_window.quit ();
		});

		dialog.signal_save.connect (() => {
			MenuTab.save ();
			MainWindow.native_window.quit ();
		});
		
		if (!font.is_modified ()) {
			dialog.signal_discard ();
		} else {
			MainWindow.native_window.set_save_dialog (dialog);
		}
	} 
		
	public static void show_description () {
		MainWindow.get_tab_bar ().add_unique_tab (new DescriptionTab ());
	}
	
	public static void show_kerning_context () {
		KerningDisplay kd = MainWindow.get_kerning_display ();
		MainWindow.get_tab_bar ().add_unique_tab (kd);
	}
	
	public static void preview ()  {
		Font font = BirdFont.get_current_font ();		
		if (font.font_file == null) {
			if (MenuTab.save ()) {
				show_preview_tab ();
			}
		} else {
			show_preview_tab ();
		}
	}
	
	public static void show_preview_tab () {
		OverWriteDialogListener dialog = new OverWriteDialogListener ();
		TabBar tab_bar = MainWindow.get_tab_bar ();
		FontFormat format = BirdFont.get_current_font ().format;
		
		if (suppress_event) {
			return;
		}	
			
		dialog.overwrite_signal.connect (() => {
			tab_bar.add_unique_tab (new Preview (), true);
			PreviewTools.update_preview ();
		});
			
		if ((format == FontFormat.SVG || format == FontFormat.FREETYPE) && !OverWriteDialogListener.dont_ask_again) {
			MainWindow.native_window.set_overwrite_dialog (dialog);
		} else {
			dialog.overwrite ();
		}
	}
	
	/** Display the language selection tab. */
	public static void select_language () {
		MainWindow.get_tab_bar ().add_unique_tab (new LanguageSelectionTab ());
	}

	public static void use_current_glyph_as_background () {
		Glyph.background_glyph = MainWindow.get_current_glyph ();
		
		if (MainWindow.get_current_display () is OverView) {
			Glyph.background_glyph = MainWindow.get_overview ().get_current_glyph ();
		}
	}
	
	public static void reset_glyph_background () {
		Glyph.background_glyph = null;
	}
	
	public static void remove_all_kerning_pairs	() {
		KerningClasses.get_instance ().remove_all_pairs ();
		KerningTools.update_kerning_classes ();
	}
	
	public static void list_all_kerning_pairs () {
		MainWindow.get_tab_bar ().add_unique_tab (new KerningList ());
	}
}
}
