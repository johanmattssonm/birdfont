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

namespace Supplement {

public class ColorTool : Tool {
	
	public double color_r = 0;
	public double color_g = 0;
	public double color_b = 0;
	public double color_a = 0;
	
	public signal void color_updated ();
	
	public ColorTool (string tool_tip) {
		base ("color_selection", tool_tip);

		select_action.connect((self) => {
			MainWindow.native_window.color_selection (this);
		});
		
		color_updated.connect (() => {
			MainWindow.get_toolbox ().redraw ((int)x, (int)y, (int)x + 20, (int)y + 20);
		});
	}
	
	public override void draw (Context cr) {
		double xt = x + 4 + w;
		double yt = y + h + 16;
		
		base.draw (cr);
		
		cr.save ();
		cr.set_source_rgba (color_r, color_g, color_b, 1);
		cr.rectangle (xt, yt, 16, 16);
		cr.fill ();
		cr.restore ();
	}
	
	public void set_r (double c) {
		color_r = c;
	}

	public void set_g (double c) {
		color_g = c;
	}

	public void set_b (double c) {
		color_b = c;
	}

	public void set_a (double c) {
		color_a = c;
	}

}

}
