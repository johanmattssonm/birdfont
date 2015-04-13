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

	double scroll = 0;
	double page_height = 0;
	Gee.ArrayList<int> column_width = new Gee.ArrayList<int> ();
	
	public WidgetAllocation allocation = new WidgetAllocation ();

	public abstract void update_rows ();
	public abstract Gee.ArrayList<Row> get_rows ();
	public abstract void selected_row (Row row, int column, bool delete_button);

	Gee.ArrayList<Row> rows = new Gee.ArrayList<Row> ();

	public override void draw (WidgetAllocation allocation, Context cr) {
		bool color = (scroll + 1 % 2) == 0;

		if (allocation.width != this.allocation.width
				|| allocation.height != this.allocation.height) {
			this.allocation = allocation;
			update_rows ();
			update_scrollbar ();
		}
		
		layout ();
		
		cr.save ();
		Theme.color (cr, "Background 1");
		cr.rectangle (0, 0, allocation.width, allocation.height);
		cr.fill ();
		cr.restore ();
		
		foreach (Row r in rows) {
			if (scroll < r.y < scroll + allocation.height
				|| scroll < r.y + r.get_height () < scroll + allocation.height) {
					
				if (r.is_headline) { 
					draw_headline (allocation, cr, r, r.y - scroll);
				} else {
					draw_row (allocation, cr, r, r.y - scroll, color, true);
				}
				
				color = !color;
			}
		}
	}	

	public void layout () {
		int width;
		
		rows = get_rows ();
		
		column_width.clear ();
		
		for (int i = 0; i <= Row.MAX_COLUMNS; i++) {
			column_width.add (0);
		}
		
		page_height = 0;
		foreach (Row row in rows) {
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
			
			row.y = page_height;
			page_height += row.get_height ();
		}
	}

	private void draw_headline (WidgetAllocation allocation, Context cr,
			Row row, double y) {
		
		Text t;

		cr.save ();
		Theme.color (cr, "Foreground 1");
		t = row.get_column (0);
		t.widget_x = 40 * MainWindow.units;;
		t.widget_y = y + 45 * MainWindow.units;
		t.draw (cr);		
		cr.restore ();
		
	}

	private void draw_row (WidgetAllocation allocation, Context cr,
			Row row, double y, bool color, bool dark) {
		
		Text t;
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
		double x = 0;
		int column = -1;
		Row? selected = null;
		bool over_delete = false;

		if (button != 1) {
			return;
		}
		
		foreach (Row r in rows) {
			if (r.y <= ey + scroll <= r.y + r.get_height ()) {
				
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

				if (!r.is_headline) {
					selected = r;
				}
				
				break;
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
		scroll += 30;

		if (scroll > page_height - allocation.height) {
			scroll = page_height - allocation.height;
		}
		
		if (allocation.height > page_height) {
			scroll = 0;
		} 
		
		update_scrollbar ();
		redraw_area (0, 0, allocation.width, allocation.height);
	}
	
	public override void scroll_wheel_up (double x, double y) {
		scroll -= 30;
		
		if (scroll < 0) {
			scroll = 0;
		}
		
		update_scrollbar ();
		redraw_area (0, 0, allocation.width, allocation.height);
	}
	
	public override void update_scrollbar () {
		if (page_height == 0 || allocation.height >= page_height) {
			MainWindow.set_scrollbar_size (0);
			MainWindow.set_scrollbar_position (0);
		} else {
			MainWindow.set_scrollbar_size (allocation.height / page_height);
			MainWindow.set_scrollbar_position (scroll /  (page_height - allocation.height));
		}
	}

	public override void scroll_to (double percent) {
		scroll = percent * (page_height - allocation.height);
		
		if (scroll > page_height) {
			scroll = (int) (page_height - allocation.height);
		}
		
		redraw_area (0, 0, allocation.width, allocation.height);
	}

	public override void selected_canvas () {
		update_rows ();
		update_scrollbar ();
	}
}

}
