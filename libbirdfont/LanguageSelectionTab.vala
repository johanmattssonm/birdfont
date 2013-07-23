/*
    Copyright (C) 2013 Johan Mattsson

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

public class LanguageSelectionTab : FontDisplay {
	
	public LanguageSelectionTab () {	
		add_html_callback ("select_language", (val) => {
			TabBar tb = MainWindow.get_tab_bar ();
			set_prefered_character_set (val);
			tb.close_display (this);
			Toolbox.select_tool_by_name ("custom_character_set");	
		});
	}

	/** @param iso_code language iso code. */
	public static void set_prefered_character_set (string iso_code) {
		Preferences.set ("language", iso_code);	
	}

	public override string get_name () {
		return _("Character set");
	}

	public override bool is_html_canvas () {
		return true;
	}
	
	public override string get_html () {
		string headline = _("Select default character set");
		StringBuilder c = new StringBuilder ();

		c.append ("""
<html>
<head>
	<script type="text/javascript" src="supplement.js"></script>
	<style type="text/css">@import url("style.css");</style>
</head>
<body>
	
	<div style="width:350px; margin: 50px auto 0 auto;">
		<div class="heading"><h2>""" + headline + """</h2></div>
		
		<form>
		""");
		
		int i = 0;
		string language_code;
		foreach (string language in DefaultLanguages.names) {
			language_code = DefaultLanguages.codes.nth (i).data;
			c.append ("""
				<input class="button" type="button" value=""" + "\"" + language + "\"" 
					+ """ onclick="call ('select_language:""" + language_code + """');"/>
				<br />
			""");
			i++;
		}
		
		c.append ("""
		</form>
	</div>
</body>
</html>""");

		return c.str;
	}	
}

}
