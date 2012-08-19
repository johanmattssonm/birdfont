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

namespace Supplement {

class CutTool : Tool {

	PenTool pen;
	
	public CutTool (string n) {
		base (n, "Create counter path", 'u', CTRL);
		
		select_action.connect((self) => {
			pen = (PenTool) MainWindow.get_tool ("pen_tool");
		});
		
		press_action.connect((self, b, x, y) => {
			pen.press_action (pen, b, x, y);
		});

		release_action.connect((self, b, x, y) => {
			pen.release_action (pen, b, x, y);
		});
		
		move_action.connect ((self, x, y)	 => {
			pen.move_action (pen, x, y);
		});
	}

	public static void force_direction () {
		Glyph g = MainWindow.get_current_glyph ();
		Tool current_tool = MainWindow.get_toolbox ().get_current_tool ();
		
		foreach (Path p in g.active_paths) {
			if (p.is_editable () && p.is_open ()) {
				
				if (current_tool is PenTool) {
					p.force_direction (Direction.CLOCKWISE);
				} else if (current_tool is CutTool) {
					p.force_direction (Direction.COUNTER_CLOCKWISE);
				}				
			}
		}
	}
	
}

}
