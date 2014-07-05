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

using Cairo;

namespace BirdFont {

public class MenuAction : GLib.Object {
	public string label;
	public DropMenu.Selected action;
	public DropMenu? parent = null;
	public int index = -1;
	public bool has_delete_button = true;
	
	bool selected = false;
	static ImageSurface? delete_button = null;
	
	public MenuAction (string label) {
		this.label = label;
		
		if (delete_button == null) {
			delete_button = Icons.get_icon ("delete_menu_item.png");
		}
	}
	
	public void set_selected (bool s) {
		selected = s;
	}
	
	public virtual void draw (double x, double y, Context cr) {
		ImageSurface img;
		
		if (selected) {
			cr.save ();
			cr.set_source_rgba (234/255.0, 234/255.0, 234/255.0, 1);
			cr.rectangle (x - 2, y - 12, 93, 15);
			cr.fill_preserve ();
			cr.stroke ();
			cr.restore ();			
		}

		if (has_delete_button && delete_button != null) {
			img = (!) delete_button;
			cr.save ();
			cr.set_source_surface (img, x - img.get_width () / 2 + 82, y - img.get_height () / 2 - 5);
			cr.paint ();
			cr.restore ();
		}
		
		cr.save ();
		cr.set_source_rgba (0, 0, 0, 1);
		
		cr.set_font_size (12);
		cr.select_font_face ("Cantarell", FontSlant.NORMAL, FontWeight.NORMAL);
		
		cr.move_to (x, y);

		cr.show_text (label);
		cr.restore ();
	}
}

}
