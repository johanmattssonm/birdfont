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

	public abstract void update_rows ();
	public abstract Gee.ArrayList<Row> get_rows ();
	public abstract void selected_row (Row row, int column, bool delete_button);

	public override void draw (WidgetAllocation allocation, Context cr) {
		double y = 20 * MainWindow.units;
		int s = 0;
		bool color = (scroll + 1 % 2) == 0;
		
		if (allocation.width != this.allocation.width
				|| allocation.height != this.allocation.height) {
			this.allocation = allocation;
			update_rows ();
			update_scrollbar ();
		}
		
		visible_rows = (int) (allocation.height / 18.0);
		
		cr.save ();
		cr.set_source_rgba (1, 1, 1, 1);
		cr.rectangle (0, 0, allocation.width, allocation.height);
		cr.fill ();
		cr.restore ();
		
		cr.save ();
		cr.set_source_rgba (0.3, 0.3, 0.3, 1);
		cr.set_font_size (12);

		foreach (Row r in get_rows ()) {
			if (s++ >= scroll) {
				draw_row (allocation, cr, r, y, color, true);
				y += 18 * MainWindow.units;
				color = !color;
			}
		}
		
		cr.restore ();
	}	

	private static void draw_row (WidgetAllocation allocation, Context cr,
			Row row, double y, bool color, bool dark) {
		
		double margin;
	
		if (color) {
			cr.save ();
			cr.set_source_rgba (224/255.0, 224/255.0, 224/255.0, 1);
			cr.rectangle (0, y - 14 * MainWindow.units, allocation.width, 18 * MainWindow.units);
			cr.fill ();
			cr.restore ();
		}

		if (row.has_delete_button ()) {
			cr.save ();
			cr.set_line_width (1);
			cr.move_to (10 * MainWindow.units, y - 8 * MainWindow.units);
			cr.line_to (15 * MainWindow.units, y - 3 * MainWindow.units);
			cr.move_to (10 * MainWindow.units, y - 3 * MainWindow.units);
			cr.line_to (15 * MainWindow.units, y - 8 * MainWindow.units);		
			cr.stroke ();
			cr.restore ();
		}
		
		for (int i = 0; i < row.columns; i++) {
			cr.save ();
			margin = (row.has_delete_button ()) ? 120 * MainWindow.units : 3* MainWindow.units;
			cr.move_to (margin + i * 120 * MainWindow.units, y);
			cr.set_font_size (12 * MainWindow.units);
			cr.show_text (row.get_column (i));
			cr.restore ();
		}
	}

	public override void button_release (int button, double ex, double ey) {
		int s = 0;
		double y = 0;
		int colum = -1;
		Row? selected = null;
		bool over_delete = false;

		foreach (Row r in get_rows ()) {
			if (s++ >= scroll) {
				y += 18 * MainWindow.units;
				
				if (y - 10 * MainWindow.units <= ey * MainWindow.units <= y + 5 * MainWindow.units) {
					
					if (r.has_delete_button ()) {
						colum = (int) ((ex - 120) / 120 * MainWindow.units);
					} else {
						colum = (int) ((ex) / 120 * MainWindow.units);
					}
					
					over_delete = (ex < 18 && r.has_delete_button ());
					selected = r;
					break;
				}
			}
		}
		
		if (selected != null) {
			selected_row ((!) selected, colum, over_delete);	
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
	
	public void update_scrollbar () {
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
