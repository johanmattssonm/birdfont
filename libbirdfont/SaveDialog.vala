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

using Cairo;

namespace BirdFont {

public class SaveDialog : FontDisplay {

	public signal void finished ();

	public SaveDialog () {
		add_html_callback ("save_dialog", (val) => {
			if (val == "save") {
				if (MenuTab.save ()) {
					finished ();
				}
			}
			
			if (val == "save_as") {
				if (MenuTab.save_as ()) {
					finished ();
				}
			}
			
			if (val == "discard") {
				// discard it
				finished ();
			}
			
			if (val == "cancel") {
				MainWindow.get_tab_bar ().close_display (this);
			}			
			
		});
	}

	public override string get_name () {
		return "Save?";
	}

	public override bool is_html_canvas () {
		return true;
	}

	public override string get_html () {
		Font f = BirdFont.get_current_font ();
		string fn = f.get_file_name ();
		
		if (fn == "") {
			fn = f.get_name () + ".ffi";
		}

		// FIXME:
		// tell xgettext to extract this:
		_("Save?");
					
		return """
<html>
<head>
	<script type="text/javascript" src="supplement.js"></script>
	<style type="text/css">@import url("style.css");</style>
</head>
<body>
	
	<div style="width:300px; margin: 50px auto 0 auto;">
		<div class="heading"><h2>""" + _("Save?") + """</h2></div>
		
		<p>""" + fn + """</p>
		
		<form>
			<input class="button" type="button" value=""" + "\"" + _("Save") + "\"" + """    onclick="call ('save_dialog:save');"/>
			<input class="button" type="button" value=""" + "\"" + _("Save as") + "\"" + """ onclick="call ('save_dialog:save_as');"/>
			<input class="button" type="button" value=""" + "\"" + _("Discard") + "\"" + """ onclick="call ('save_dialog:discard');"/>
			<input class="button" type="button" value=""" + "\"" + _("Cancel") + "\"" + """  onclick="call ('save_dialog:cancel');"/>
			<br />
		</form>
	</div>
</body>
</html>""";
	}
}
	
}
