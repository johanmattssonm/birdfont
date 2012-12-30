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

using WebKit;

namespace Supplement {

public class MenuTab : FontDisplay {	
	
	List<Font> recent_fonts = new List<Font> ();

	public MenuTab () {
		// html callbacks:
		add_html_callback ("export_name", (val) => {
			Font f = Supplement.get_current_font ();
			f.set_name (val);
			f.touch ();
		});

		add_html_callback ("export", (val) => {
			ExportTool.export_all ();
		});

		add_html_callback ("preview", (val) => {
			preview ();
		});		

		add_html_callback ("load", (val) => {
			load_font (val);
		});	

		add_html_callback ("glyph_sequence", (val) => {
			Preferences.set ("glyph_sequence", val);
		});

		add_html_callback ("help", (val) => {
			MainWindow.get_tool_tip ().show_text (val);
		});
	}
		
	public override string get_name () {
		return "Menu";
	}
	
	public override bool is_html_canvas () {
		return true;
	}

	public override string get_html () {
		Font f = Supplement.get_current_font ();
		StringBuilder c = new StringBuilder ();
		string fn;
		
		propagate_recent_files ();
		
		c.append (
"""
<html>
<head>
	<script type="text/javascript" src="supplement.js"></script>
	<style type="text/css">@import url("style.css");</style>
	<script type="text/javascript">
		document.onkeyup = update_text_fields; 
	</script>
</head>
<body>
	<div class="inner_format_box">
		<div class="content">
			<div class="heading"><h2>""" + _("Preferences") + """</h2></div>
			<form>
""");
				
c.append ("""
				<h3>""" + _("Glyph sequence") + """</h3>
				<input class="text" type="text" id="glyph_sequence" value=""" + "\"" + Preferences.get ("glyph_sequence") + "\"" + """ onchange="update_text_fields ();"/><br />

				<h3>""" + _("Name") + """</h3>
				<input class="text" type="text" id="fontname" value=""" + "\"" + f.get_name () + "\"" + """ onchange="update_text_fields ();"/><br />
				
				<input class="button" type="button" value=""" + "\"" + _("Export") + "\"" + """ id="export_button" onclick="call ('export:fonts');" onmouseover="call ('help:(Ctrl+e) """ + _("Export SVG, TTF & EOT fonts") + """');"/>
				<input class="button" type="button" value=""" + "\"" + _("Preview") + "\"" + """ id="preview_button" onclick="call ('preview:fonts');" onmouseover="call ('help:(Ctrl+p) """ + _("Export SVG font and view the result") + """');"/><br />
""");
	
c.append ("""

			</form> 

		</div>
	</div>
	
	<img src="birdfont_logo.png" alt="" style="float:right;margin: 50px 0 0 0;">
	
	<br class="clearBoth" />
	
	<div class="recent_list">
""");

if (recent_fonts.length () > 0) {
	c.append ("""<div class="heading"><h2>""" + _("Recent files") + """</h2></div>""");
	c.append ("\n");
}

foreach (Font font in recent_fonts) {
	fn = (!) font.font_file;
	fn = fn.substring (fn.replace ("\\", "/").last_index_of ("/") + 1);	
	
	c.append ("""<div class="recent_font" """ + "onclick=\"call ('load:" + ((!) font.font_file).replace ("\\", "\\\\") + "');\">");

	c.append ("<div class=\"one_line\">");
	c.append (fn);
	c.append ("</div>");

	c.append ("<img src=\"");
	c.append (path_to_uri ((!) Supplement.get_thumbnail_directory ().get_path ()));
	c.append ("/");
	c.append (fn);
	c.append (@".png?$(Random.next_int ())\" alt=\"\">");
	
	c.append ("<br /><br />");
	c.append ("</div>\n");
}

c.append ("</div>\n");

c.append ("""
</body>
</html>
""");

		return c.str;
	}
	
	void translations () {
		// xgettext needs these lines in order to extract strings properly
		// TODO: update xgettext to handle vala strings well.
		_("Preferences");
		_("Export SVG, TTF & EOT fonts");
		_("Name");
		_("Glyph sequence");
		_("Export SVG font and view the result");
		_("Export SVG font and view the result");
	}

	public void propagate_recent_files () {
		Font font;

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
	
	public void load_font (string fn) {
		Font font = Supplement.get_current_font ();
			
		SaveDialog save = new SaveDialog ();
		save.finished.connect (() => {
			Font f;
			bool loaded;
			
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
			
			MainWindow.get_toolbox ().remove_all_grid_buttons ();
			foreach (string v in f.grid_width) {
				MainWindow.get_toolbox ().parse_grid (v);
			}
			
			MainWindow.get_toolbox ().background_scale.set_value (f.background_scale);
			
			select_overview ();
		});
		
		if (font.is_modified ()) {
			MainWindow.get_tab_bar ().add_unique_tab (save, 80);
		} else {
			save.finished ();
		}
	}
	
	private static void select_overview () {
		if (Supplement.get_current_font ().is_empty ()) {
			Toolbox.select_tool_by_name ("custom_character_set");
		} else {
			Toolbox.select_tool_by_name ("available_characters");	
		}
	}

	public static bool save_as ()  {
		string? fn = null;
		string f;
		bool saved = false;
		Font font = Supplement.get_current_font ();
		
		fn = MainWindow.file_chooser (_("Save"));
		
		if (fn != null) {
			f = (!) fn;
			
			if (!f.has_suffix (".ffi")) {
				f += ".ffi";
			}
			
			font.font_file = f;
			save ();
			saved = true;
		}

		return saved;
	}

	public static bool save () {
		Font f = Supplement.get_current_font ();
		string fn;
		bool saved = false;
		
		fn = (!) f.font_file;
		
		if (f.font_file != null && fn.has_suffix (".ffi")) {
			f.background_scale = MainWindow.get_toolbox ().background_scale.get_display_value ();
			
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
		Font font = Supplement.get_current_font ();
		SaveDialog save = new SaveDialog ();
		save.finished.connect (() => {
			Font f = Supplement.get_current_font ();
			f.delete_backup ();
			
			Supplement.new_font ();
			MainWindow.close_all_tabs ();
			
			MainWindow.get_toolbox ().remove_all_grid_buttons ();
			MainWindow.get_toolbox ().add_new_grid ();
			MainWindow.get_toolbox ().add_new_grid ();
			
			select_overview ();
		});
		
		MainWindow.get_tab_bar ().add_unique_tab (save, 80);
		
		if (!font.is_modified ()) {
			save.finished ();
		}
	}
	
	public static void load () {
		SaveDialog save = new SaveDialog ();
		Font font = Supplement.get_current_font ();

		save.finished.connect (() => {
			load_new_font ();
		});

		if (font.is_modified ()) {
			MainWindow.get_tab_bar ().add_unique_tab (save, 80);
		} else {
			save.finished ();
		}
	}

	private static void load_new_font () {
		string? fn = MainWindow.file_chooser ("load");
		Font f = Supplement.get_current_font ();
		
		if (fn != null) {
			f.delete_backup ();
			
			MainWindow.clear_glyph_cache ();
			MainWindow.close_all_tabs ();
			f.load ((!)fn);
			
			MainWindow.get_singleton ().set_title (f.get_name ());
			select_overview ();		
		}
	}
	
	public static void show_kerning_context () {
		MainWindow.get_tab_bar ().add_unique_tab (new ContextDisplay (), 85, false);
	}
	
	public static void preview () {
		TabBar t = MainWindow.get_tab_bar ();
		t.add_unique_tab (new Preview (), 80);		
	}
}
}
