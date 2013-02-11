/*
    Copyright (C) 2013 Johan Mattsson

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

namespace Supplement {

public class OverwriteDialog : FontDisplay {

	public signal void finished ();
	public static bool ignore = false; // ignore this dialog
	
	public OverwriteDialog () {
		add_html_callback ("overwrite_dialog", (val) => {
			TabBar tb = MainWindow.get_tab_bar ();
			
			if (val == "overwrite") {
				tb.close_display (this);
				finished ();
			}
			
			if (val == "cancel") {
				tb.close_display (this);
			}
			
			if (val == "ignore") {
				ignore = true;
				tb.close_display (this);
				finished ();
			}
		});
	}

	public override string get_name () {
		return "Overwrite?";
	}

	public override bool is_html_canvas () {
		return true;
	}

	public override string get_html () {
		string mess = _("The loaded font will be overwritten if you choose to continue with preview.");
		return """
<html>
<head>
	<script type="text/javascript" src="supplement.js"></script>
	<style type="text/css">@import url("style.css");</style>
</head>
<body>
	
	<div style="width:300px; margin: 50px auto 0 auto;">
		<div class="heading"><h2>""" + _("Overwrite?") + """</h2></div>
		
		<p>""" + mess + """</p>
		
		<form>
			<input class="button" type="button" value=""" + "\"" + _("Continue") + "\"" + """    onclick="call ('overwrite_dialog:overwrite');"/>
			<input class="button" type="button" value=""" + "\"" + _("Cancel") + "\"" + """  onclick="call ('overwrite_dialog:cancel');"/>
			<input class="button" type="button" value=""" + "\"" + _("Continue and don't ask me again.") + "\"" + """  onclick="call ('overwrite_dialog:ignore');"/>
			<br />
		</form>
	</div>
</body>
</html>""";
	}
}
	
}

