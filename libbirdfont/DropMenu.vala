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

public enum MenuDirection {
	DROP_DOWN,
	POP_UP;
}

public class DropMenu : GLib.Object {

	public delegate void Selected (MenuAction self);
	public signal void selected (DropMenu self);
	
	double x = -1;
	double y = -1;
	bool menu_visible = false;

	List <MenuAction> actions = new List <MenuAction> ();

	const int item_height = 25;
	
	MenuDirection direction = MenuDirection.DROP_DOWN;
	
	ImageSurface? icon = null;
	
	public DropMenu (string icon_file = "") {
		if (icon_file != "") {
			icon = Icons.get_icon (@"$icon_file.png");
		}
	}
	
	public void deselect_all () {
		foreach (MenuAction m in actions) {
			m.set_selected (false);
		}
	}
	
	public void set_direction (MenuDirection d) {
		direction = d;
	}
	
	public void close () {
		menu_visible = false;
	}
	
	public MenuAction add_item (string label) {
		MenuAction m = new MenuAction (label);
		add_menu_item (m);
		return m;
	}
	
	public void add_menu_item (MenuAction m) {
		m.parent = this;
		actions.append (m);
	}
		
	public bool is_over_icon (double px, double py) {
		if (x == -1 || y == -1) {
			return false;
		}
		
		return x - 5 < px < x + 12 + 5 && y - 5 < py < y + 12 + 5;
	}

	public bool menu_item_action (double px, double py) {
		MenuAction? action;

		if (menu_visible) {
			action = get_menu_action_at (px, py);
			
			if (action != null) {
				((!) action).action ((!)action);
				selected (this);
				menu_visible = false;
				return true;
			}
		}
		
		return false;
	}
	
	public bool menu_icon_action (double px, double py) {		
		menu_visible = is_over_icon (px, py);
		return menu_visible;
	}
	
	MenuAction? get_menu_action_at (double px, double py) {
		double n = 0;
		double ix, iy;
		
		foreach (MenuAction item in actions) {
			ix = x - 100 + 12;
			
			if (direction == MenuDirection.DROP_DOWN) {
				iy = y + 12 + n * item_height;
			} else {
				iy = y - 24 - n * item_height;
			}
	
			if (ix <= px <= ix + 100 && iy <= py <= iy + item_height) {
				return item;
			}
			
			n++;			
		}

		return null;
	}
	
	public void set_position (double px, double py) {
		x = px;
		y = py;
	}
	
	public void draw_menu (Context cr) {
		double ix, iy;
		int n;
		
		if (likely (!menu_visible)) {
			return;
		}
		
		cr.save ();
		cr.set_source_rgba (122/255.0, 150/255.0, 169/255.0, 1);
		cr.set_line_join (LineJoin.ROUND);
		cr.set_line_width (12);
			
		if (direction == MenuDirection.DROP_DOWN)
			cr.rectangle (x - 100 + 18, y + 18, 88, actions.length () * item_height - 12);
		else
			cr.rectangle (x - 100 + 18, y + 6 - actions.length () * item_height, 88, actions.length () * item_height - 12);
			
		cr.fill_preserve ();
		cr.stroke ();
		cr.restore ();
		
		cr.save ();
		
		n = 0;
		foreach (MenuAction item in actions) {
			
			if (direction == MenuDirection.DROP_DOWN)
				iy = y + 33 + n * item_height - 5;
			else 
				iy = y - 8 - n * item_height;
			
			ix = x - 100 + 20;
			
			item.draw (ix, iy, cr);
			n++;
		}
		
		cr.restore ();
	}
	
	public void draw_icon (Context cr) {
		double alpha = 1;
		ImageSurface i = (!) icon;
		
		if (!menu_visible) {
			alpha = 0;
		}
		
		cr.save ();
		
		cr.set_source_rgba (122/255.0, 150/255.0, 169/255.0, alpha);
		
		cr.rectangle (x, y, 12, 12);
		cr.fill_preserve ();
		cr.stroke ();
		
		if (likely (icon != null && i.status () == Cairo.Status.SUCCESS)) {
			cr.set_source_surface (i, x, y + (12 - i.get_height ()) / 2.0);
			cr.paint ();
		} else {
			warning ("Failed to load icon.");
		}
		
		cr.restore ();
	}
}

}
