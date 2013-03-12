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

namespace BirdFont {

class ZoomView : GLib.Object {
	public double x;
	public double y;
	public double zoom;
	public Allocation allocation;
	
	public ZoomView (double x, double y, double zoom, Allocation allocation) {
		this.x = x;
		this.y = y;
		this.zoom = zoom;
		this.allocation = allocation;
	}
}

}
