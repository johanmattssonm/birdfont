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
using Gdk;
using Gtk;

namespace Supplement {

public class TooltipArea : GLib.Object {

	string tool_tip;
	public signal void redraw ();

	public TooltipArea () {
		set_text_from_tool ();
	}

	public void update_text () {
		set_text_from_current_tool ();
		redraw ();
	}
	
	public void show_text (string text) {
		tool_tip = text;
		redraw ();
	}
	
	public void set_text_from_tool () {
		set_text_from_current_tool ();
		redraw ();
	}
	
	private void set_text_from_current_tool () {
		Toolbox? tb = MainWindow.get_toolbox ();
		Tool? t;
		Tool tool;
		StringBuilder sb;
		
		if (tb == null) {
			return;
		}
		
		t = ((!)tb).get_active_tool ();
		
		if (t == null) {
			return;
		}
		
		tool = (!) t;
		
		if (tool.key != '\0') {
			sb = new StringBuilder ();

			sb.append ("(");
			
			if (tool.modifier_flag == CTRL) {
				sb.append ("Ctrl+");
			} else if (tool.modifier_flag == SHIFT) {
				sb.append ("Shift+");
			} 

			sb.append_unichar (tool.key);
			sb.append (") ");
			sb.append (tool.get_tip ());
			
			show_text (sb.str);
		} else {
			show_text (tool.get_tip ());
		}
		
	}
	
	public void draw (Context cr, Allocation alloc) {
		cr.save ();
		cr.rectangle (0, 0, alloc.width, alloc.height);
		cr.set_line_width (0);
		cr.set_source_rgba (183/255.0, 200/255.0, 223/255.0, 1);
		cr.fill_preserve ();
		cr.stroke ();
		cr.restore ();

		cr.save ();
		cr.rectangle (0, 0, alloc.width, 1);
		cr.set_line_width (0);
		cr.set_source_rgba (107/255.0, 127/255.0, 168/255.0, 1);
		cr.fill_preserve ();
		cr.stroke ();
		cr.restore ();
		
		cr.save ();
		cr.rectangle (0, 1, alloc.width, 1);
		cr.set_line_width (0);
		cr.set_source_rgba (145/255.0, 160/255.0, 190/255.0, 1);
		cr.fill_preserve ();
		cr.stroke ();
		cr.restore ();
		
		cr.save ();
		cr.set_font_size (14);
		cr.move_to (5, 15);
		cr.show_text (tool_tip);
		cr.restore ();

	}
}

}
