/*
	Copyright (C) 2016 Johan Mattsson

	This library is free software; you can redistribute it and/or modify 
	it under the terms of the GNU Lesser General Public License as 
	published by the Free Software Foundation; either version 3 of the 
	License, or (at your option) any later version.

	This library is distributed in the hope that it will be useful, but 
	WITHOUT ANY WARRANTY; without even the implied warranty of 
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU 
	Lesser General Public License for more details.
*/

using Bird;
using Gtk;

int main (string[] args) {
	Gtk.init (ref args);
	
	Window window = new Window ();
	window.set_title ("UI Bird");
	window.destroy.connect (Gtk.main_quit);
	
	Component layout = new Component ();
	layout.load ("test.ui");
	
	Bird.Widget primary_layout = new Bird.Widget (layout);

	Box vbox = new Box (Orientation.VERTICAL, 0);
	vbox.pack_start(primary_layout, true, true, 0);
	window.add (vbox);
	
	window.show_all ();
	
	Gtk.main ();
	return 0;
}
