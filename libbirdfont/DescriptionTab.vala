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

namespace BirdFont {

/** Names and description for the TTF Name table. */
public class DescriptionTab : FontDisplay {	

	Font font;

	public DescriptionTab () {
		font = BirdFont.get_current_font ();
		
		add_html_callback ("postscript_name", (val) => {
			font.postscript_name = val;
		});

		add_html_callback ("name", (val) => {
			font.name = val;
		});
		
		add_html_callback ("subfamily", (val) => {
			font.subfamily = val;
		});		

		add_html_callback ("full_name", (val) => {
			font.full_name = val;
		});

		add_html_callback ("unique_identifier", (val) => {
			font.unique_identifier = val;
		});

		add_html_callback ("version", (val) => {
			font.version = val;
		});

		add_html_callback ("description", (val) => {
			font.description = val;
		});

		add_html_callback ("copyright", (val) => {
			font.copyright = val;
		});
	}

	public override string get_name () {
		return _("Description");
	}
	
	public override bool is_html_canvas () {
		return true;
	}

	public override string get_html () {
		StringBuilder c = new StringBuilder (); 

		// TODO: trademark, prefered family etc. 
		// or maybe not, many fields in the name table seems to be irrelevant.
		
		// TODO: provide good explenations of these fields	

		c.append (
"""
<html>
<head>
	<script type="text/javascript" src="supplement.js"></script>
	<style type="text/css">@import url("style.css");</style>
	<script type="text/javascript">
		document.onkeyup = update_name_fields; 
	</script>
</head>
<body>
	<div class="naming_box">
		<form>
			<h3>""" + _("Postscript name") + """</h3>
			<input class="text" type="text" id="postscript_name" value=""" + "\"" + font.postscript_name + "\"" + """ onchange="update_name_fields ();"/><br />

			<h3>""" + _("Name") + """</h3>
			<input class="text" type="text" id="name" value=""" + "\"" + font.name + "\"" + """ onchange="update_name_fields ();"/><br />

			<h3>""" + _("Subfamily name") + " (Regular/Bold/Italic)" + """</h3>
			<input class="text" type="text" id="subfamily" value=""" + "\"" + font.subfamily + "\"" + """ onchange="update_name_fields ();"/><br />

			<h3>""" + _("Full name (name & subfamily)") + """</h3>
			<input class="text" type="text" id="full_name" value=""" + "\"" + font.full_name + "\"" + """ onchange="update_name_fields ();"/><br />

			<h3>""" + _("Unique identifier") + """</h3>
			<input class="text" type="text" id="unique_identifier" value=""" + "\"" + font.unique_identifier + "\"" + """ onchange="update_name_fields ();"/><br />

			<h3>""" + _("Version") + """</h3>
			<input class="text" type="text" id="version" value=""" + "\"" + font.version + "\"" + """ onchange="update_name_fields ();"/><br />

""");

	// There is a bug in webkit on windows that makes it imposible
	// to display textareas.
	if (BirdFont.win32) {
		c.append ("""<div style="visibility: hidden;">""");
	}
	
c.append (
"""
			<h3>""" + _("Description") + """</h3>
			<textarea rows="4" cols="50" id="description" name="description" onchange="update_name_fields ();">""" + font.description + """</textarea>

			<h3>""" + _("Copyright") + """</h3>
			<textarea rows="4" cols="50" id="copyright" name="copyright" onchange="update_name_fields ();">""" + font.copyright + """</textarea>
""");

	if (BirdFont.win32) {
		c.append ("</div>");
	}

c.append (
"""
		</form>
	</div>
</body>
</html>
""");

#if translations 
	// for xgettext:
	_("Postscript name");
	_("Name");
	_("Subfamily name");
	_("Full name (name & subfamily)");
	_("Unique identifier");
	_("Version");
	_("Description");
	_("Copyright");
#endif
		return c.str;
	}
}

}
