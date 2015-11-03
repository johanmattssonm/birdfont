/*
	Copyright (C) 2015 Johan Mattsson

	This library is free software; you can redistribute it and/or modify 
	it under the terms of the GNU Lesser General Public License as 
	published by the Free Software Foundation; either version 3 of the 
	License, or (at your option) any later version.

	This library is distributed in the hope that it will be useful, but 
	WITHOUT ANY WARRANTY; without even the implied warranty of 
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU 
	Lesser General Public License for more details.
*/

using Cairo;

namespace BirdFont {

public class OverwriteBfFile : QuestionDialog {

	Button replace;
	Button cancel;
	
	public OverwriteBfFile (SaveCallback save_callback) {
		base(t_("This file already exists. Do you want to replace it?"), 200);
		
		replace = new Button (t_("Replace"));
		replace.action.connect (() => {
			save_callback.save ();
			MainWindow.hide_dialog ();
		});

		cancel = new Button (t_("Cancel"));
		cancel.action.connect (() => {
			MainWindow.hide_dialog ();
		});
	}
}

}
