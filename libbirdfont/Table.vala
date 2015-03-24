/*
    Copyright (C) 2014 Johan Mattsson

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
using Math;

namespace BirdFont {

/** Table functions. */
public abstract class Table : FontDisplay {

	int scroll = 0;
	int visible_rows = 0;
	WidgetAllocation allocation = new WidgetAllocation ();
	Gee.ArrayList<int> column_width = new Gee.ArrayList<int> ();

	public abstract void update_rows ();
	public abstract Gee.ArrayList<Row> get_rows ();
	public abstract void selected_row (Row row, int column, bool delete_button);

	public override void draw (WidgetAllocation allocation, Context cr) {
		double y = 0;
		int s = 0;
		bool color = (scroll + 1 % 2) == 0;
		
		layout ();
		
		if (allocation.width != this.allocation.width
				|| allocation.height != this.allocation.height) {
			this.allocation = allocation;
			update_rows ();
			update_scrollbar ();
		}
		
		visible_rows = (int) (allocation.height / 18.0);
		
		cr.save ();
		Theme.color (cr, "Background 1");
		cr.rectangle (0, 0, allocation.width, allocation.height);
		cr.fill ();
		cr.restore ();
		
		foreach (Row r in get_rows ()) {
			if (s++ >= scroll) {
				draw_row (allocation, cr, r, y, color, true);
				y += 25 * MainWindow.units;
				color = !color;
			}
		}
	}	

	private void layout () {
		int width;
		
		column_width.clear ();
		
		for (int i = 0; i <= Row.MAX_COLUMNS; i++) {
			column_width.add (0);
		}
		
		foreach (Row row in get_rows ()) {
			return_if_fail (row.columns <= column_width.size);
			
			for (int i = 0; i < row.columns; i++) {
				width = (int) row.get_column (i).get_sidebearing_extent ();
				width +=  (int) (10 * MainWindow.units);
				
				if (width < 100 * MainWindow.units) {
					width = (int) (100 * MainWindow.units);
				}
				
				if (width > column_width.get (i)) {
					column_width.set (i, width);
				}
			}
		}
	}

	private void draw_row (WidgetAllocation allocation, Context cr,
			Row row, double y, bool color, bool dark) {
		
		Text t;
		double margin;
		double x;
		double o;
		
		o = color ? 1 : 0.5;
		cr.save ();
		Theme.color_opacity (cr, "Background 10", o);
		cr.rectangle (0, y * MainWindow.units, allocation.width, 25 * MainWindow.units);
		cr.fill ();
		cr.restore ();

		if (row.has_delete_button ()) {
			cr.save ();
			Theme.color (cr, "Foreground 1");
			cr.set_line_width (1);
			cr.move_to (10 * MainWindow.units, y + 15 * MainWindow.units);
			cr.line_to (15 * MainWindow.units, y + 10 * MainWindow.units);
			cr.move_to (10 * MainWindow.units, y + 10 * MainWindow.units);
			cr.line_to (15 * MainWindow.units, y + 15 * MainWindow.units);		
			cr.stroke ();
			cr.restore ();
		}
		
		return_if_fail (row.columns <= column_width.size);
		
		x = 40 * MainWindow.units;
		for (int i = 0; i < row.columns; i++) {
			cr.save ();
			Theme.color (cr, "Foreground 1");
			t = row.get_column (i);
			t.widget_x = x;
			t.widget_y = y + 3 * MainWindow.units;
			t.draw (cr);
			
			x += column_width.get (i); 
			
			cr.restore ();
		}
	}

	public override void button_release (int button, double ex, double ey) {
		int s = 0;
		double y = 0;
		double x = 0;
		int column = -1;
		Row? selected = null;
		bool over_delete = false;

		if (button != 1) {
			return;
		}

		foreach (Row r in get_rows ()) {
			if (s++ >= scroll) {
				if (y <= ey <= y + 25 * MainWindow.units) {
					
					x = 0;
					for (int i = 0; i < r.columns; i++) {
						return_if_fail (0 <= i < column_width.size);
						
						if (x <= ex < x + column_width.get (i)) {
							column = i;
						}
						
						x += column_width.get (i);
					}
					
					over_delete = (ex < 18 && r.has_delete_button ());
					
					if (over_delete) {
						column = -1;
					}
					
					selected = r;
					
					break;
				}

				y += 25 * MainWindow.units;
			}
		}
		
		if (selected != null) {
			selected_row ((!) selected, column, over_delete);	
		}
		
		update_scrollbar ();
		redraw_area (0, 0, allocation.width, allocation.height);
	}

	public override bool has_scrollbar () {
		return true;
	}
	
	public override void scroll_wheel_down (double x, double y) {
		int nrows = get_rows ().size;
		scroll += 3;

		if (scroll > nrows - visible_rows) {
			scroll = (int) (nrows - visible_rows);
		}
		
		if (visible_rows > nrows) {
			scroll = 0;
		} 
		
		update_scrollbar ();
		redraw_area (0, 0, allocation.width, allocation.height);
	}
	
	public override void scroll_wheel_up (double x, double y) {
		scroll -= 3;
		
		if (scroll < 0) {
			scroll = 0;
		}
		
		update_scrollbar ();
		redraw_area (0, 0, allocation.width, allocation.height);
	}
	
	public override void update_scrollbar () {
		uint rows = get_rows ().size;

		if (rows == 0 || visible_rows == 0) {
			MainWindow.set_scrollbar_size (0);
			MainWindow.set_scrollbar_position (0);
		} else {
			MainWindow.set_scrollbar_size ((double) visible_rows / rows);
			MainWindow.set_scrollbar_position ((double) scroll /  rows);
		}
	}

	public override void scroll_to (double percent) {
		uint rows = get_rows ().size;
		scroll = (int) (percent * rows);
		
		if (scroll > rows - visible_rows) {
			scroll = (int) (rows - visible_rows);
		}
		
		redraw_area (0, 0, allocation.width, allocation.height);
	}

	public override void selected_canvas () {
		update_rows ();
		update_scrollbar ();
	}
}

}
