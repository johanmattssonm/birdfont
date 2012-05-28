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

class MergeTool : Tool {

	public MergeTool (string n) {
		base (n, "merge paths");
	
		select_action.connect((self) => {
			warning ("merge is not implemented yet");
		});
	}

	public override bool test () {
		test_merge_second_triangle ();
		test_merge_simple_path_box_and_triangle ();
		test_merge_simple_path_box ();
		test_merge_odd_paths ();
		return true;
	}
	
	private void test_merge_simple_path_box () {
		Tool pen_tool = MainWindow.get_toolbox ().get_tool ("pen_tool");

		this.yield ();
		MainWindow.get_tab_bar ().select_overview ();

		this.yield ();
		MainWindow.get_overview ().open_current_glyph ();
		
		pen_tool.test_select_action ();

		int x_offset = 10;
		int y_offset = 350;
		
		// draw it
		pen_tool.test_click_action (1, 10 + x_offset, 10 + y_offset);
		pen_tool.test_click_action (1, 20 + x_offset, 10 + y_offset);
		pen_tool.test_click_action (1, 20 + x_offset, 20 + y_offset);
		pen_tool.test_click_action (1, 10 + x_offset, 20 + y_offset); 
		pen_tool.test_click_action (3, 0, 0);

		pen_tool.test_press_action (1, 1, 1);
		pen_tool.test_move_action (15 + x_offset, 15 + y_offset);
		pen_tool.test_release_action (1, 15 + x_offset, 15 + y_offset);
				
		pen_tool.test_click_action (1, 25 + x_offset, 15 + y_offset);
		pen_tool.test_click_action (1, 25 + x_offset, 25 + y_offset);
		pen_tool.test_click_action (1, 15 + x_offset, 25 + y_offset); 
		pen_tool.test_click_action (3, 0, 0);
		
		// merge it
		this.test_select_action ();
		
		// test result
		Path merged_outline = new Path ();
		add_point_on_path (merged_outline, 10 + x_offset, 10 + y_offset);
		add_point_on_path (merged_outline, 20 + x_offset, 10 + y_offset);
		add_point_on_path (merged_outline, 20 + x_offset, 15 + y_offset);
		add_point_on_path (merged_outline, 25 + x_offset, 15 + y_offset);
		add_point_on_path (merged_outline, 25 + x_offset, 25 + y_offset);
		add_point_on_path (merged_outline, 15 + x_offset, 25 + y_offset);
		add_point_on_path (merged_outline, 15 + x_offset, 20 + y_offset);
		add_point_on_path (merged_outline, 10 + x_offset, 20 + y_offset);
		merged_outline.close ();
		
		// select path
		pen_tool.test_click_action (3, 12 + x_offset, 12 + y_offset);
		
		Glyph g = MainWindow.get_current_glyph ();
		Path? l = g.get_active_path ();
		
		if (l == null) {
			critical ("No path found in merge test, it did not merge correctly.");
			return;
		}
		
		Path last = (!) l;
		bool merged_path_looks_good = false;
		 merged_path_looks_good = last.test_is_outline (merged_outline);
		
		if (!merged_path_looks_good) critical ("Failed to merge path correctly.");
	}

	private void test_merge_simple_path_box_and_triangle () {
		Tool pen_tool = MainWindow.get_toolbox ().get_tool ("pen_tool");

		this.yield ();
		MainWindow.get_tab_bar ().select_overview ();

		this.yield ();
		MainWindow.get_overview ().open_current_glyph ();
		
		pen_tool.test_select_action ();

		int x_offset = 40;
		int y_offset = 350;
		
		// draw it
		pen_tool.test_click_action (1, 0 + x_offset, -50 + y_offset);
		pen_tool.test_click_action (1, 25 + x_offset, -50 + y_offset);
		pen_tool.test_click_action (1, 25 + x_offset, 0 + y_offset);
		pen_tool.test_click_action (1, 0 + x_offset, 0 + y_offset); 
		pen_tool.test_click_action (3, 0, 0);
		
		pen_tool.test_click_action (1, 0 + x_offset, 0 + y_offset);
		pen_tool.test_click_action (1, 50 + x_offset, -50 + y_offset);
		pen_tool.test_click_action (1, 50 + x_offset, 0 + y_offset); 
		pen_tool.test_click_action (3, 0, 0);

		// merge it
		this.test_select_action ();
		
		// test result
		Path merged_outline = new Path ();
		add_point_on_path (merged_outline, 0 + x_offset, -50 + y_offset);
		add_point_on_path (merged_outline, 25 + x_offset, -50 + y_offset);
		add_point_on_path (merged_outline, -50 + x_offset, -50 + y_offset);
		add_point_on_path (merged_outline, -50 + x_offset, 0 + y_offset);
		add_point_on_path (merged_outline, 0 + x_offset, 0 + y_offset);
		merged_outline.close ();

		// select path
		pen_tool.test_click_action (3, 21 + x_offset, -11 + y_offset);
		
		Glyph g = MainWindow.get_current_glyph ();
		Path? l = g.get_active_path ();
		
		if (l == null) {
			critical ("No path found in test_merge_simple_path_box_and_triangle, it did not merge correctly.");
			return;
		}
		
		Path last = (!) l;
		bool merged_path_looks_good = false;
		 merged_path_looks_good = last.test_is_outline (merged_outline);
		
		if (!merged_path_looks_good) critical ("Failed to merge path correctly.");
	}

	private void test_merge_second_triangle () {
		Tool pen_tool = MainWindow.get_toolbox ().get_tool ("pen_tool");

		this.yield ();
		MainWindow.get_tab_bar ().select_overview ();

		this.yield ();
		MainWindow.get_overview ().open_current_glyph ();
		
		pen_tool.test_select_action ();

		int x_offset = 100;
		int y_offset = 350;
		
		// draw it
		pen_tool.test_click_action (1, 25 + x_offset, 0 + y_offset);
		pen_tool.test_click_action (1, 25 + x_offset, -50 + y_offset);
		pen_tool.test_click_action (1, 0 + x_offset, -50 + y_offset);
		pen_tool.test_click_action (1, 0 + x_offset, 0 + y_offset); 

		pen_tool.test_click_action (3, 0, 0);
		
		pen_tool.test_click_action (1, 40 + x_offset, -50 + y_offset);
		pen_tool.test_click_action (1, 10 + x_offset, -20 + y_offset);
		pen_tool.test_click_action (1, 25 + x_offset, -20 + y_offset); 
		pen_tool.test_click_action (3, 0, 0);
		
		// merge it
		this.test_select_action ();
		
		// test result
		Path merged_outline = new Path ();
		add_point_on_path (merged_outline, 0 + x_offset, -50 + y_offset);
		add_point_on_path (merged_outline, 25 + x_offset, -50 + y_offset);
		add_point_on_path (merged_outline, -50 + x_offset, -50 + y_offset);
		add_point_on_path (merged_outline, -50 + x_offset, 0 + y_offset);
		add_point_on_path (merged_outline, 0 + x_offset, 0 + y_offset);
		merged_outline.close ();

		// select path
		pen_tool.test_click_action (3, 21 + x_offset, -11 + y_offset);
		
		Glyph g = MainWindow.get_current_glyph ();
		Path? l = g.get_active_path ();
		
		if (l == null) {
			critical ("No path found in triangle_right, it did not merge correctly.");
			return;
		}
		
		Path last = (!) l;
		bool merged_path_looks_good = false;
		 merged_path_looks_good = last.test_is_outline (merged_outline);
		
		if (!merged_path_looks_good) critical ("Failed to merge path correctly.");
	}
	
	private void add_point_on_path (Path p, int x, int y) {
		Glyph g = MainWindow.get_current_glyph ();
		p.add (g.path_coordinate_x (x), g.path_coordinate_y (y));
	}
	
	
	private void test_merge_odd_paths () {
		Tool pen_tool = MainWindow.get_toolbox ().get_tool ("pen_tool");

		this.yield ();
		MainWindow.get_tab_bar ().select_overview ();

		this.yield ();
		MainWindow.get_overview ().open_current_glyph ();
		
		pen_tool.test_select_action ();

		// paint
		int x_offset = 100;
		int y_offset = 100;
						
		// rectangle
		pen_tool.test_click_action (1, 100 + x_offset, 100 + y_offset);
		pen_tool.test_click_action (1, 170 + x_offset, 100 + y_offset);
		pen_tool.test_click_action (1, 170 + x_offset, 120 + y_offset);
		pen_tool.test_click_action (1, 100 + x_offset, 120 + y_offset); 
		pen_tool.test_click_action (3, 0, 0); // close
		
		// triangle
		pen_tool.test_click_action (1, 100 + x_offset, 110 + y_offset);
		pen_tool.test_click_action (1, 180 + x_offset, 130 + y_offset);
		pen_tool.test_click_action (1, -10 + x_offset, 140 + y_offset);
		pen_tool.test_click_action (3, 0, 0);

		// several triangles
		pen_tool.test_click_action (1, 198, 379); 
		pen_tool.test_click_action (1, 274, 328); 
		pen_tool.test_click_action (1, 203, 286); 
		pen_tool.test_click_action (3, 230, 333);

		pen_tool.test_click_action (1, 233, 429); 
		pen_tool.test_click_action (1, 293, 382); 
		pen_tool.test_click_action (1, 222, 322); 
		pen_tool.test_click_action (3, 225, 406);

		pen_tool.test_click_action (1, 164, 316); 
		pen_tool.test_click_action (1, 262, 289); 
		pen_tool.test_click_action (1, 203, 260); 
		pen_tool.test_click_action (3, 203, 260); 

		this.yield ();
		
		test_select_action ();
	}
	
	private void test_last_is_counter_clockwise (string name) {
		bool d = ((!)MainWindow.get_current_glyph ().get_last_path ()).is_clockwise ();
		
		if (d) {
				critical (@"\nPath $name is clockwise, in test_last_is_counter_clockwise");
		}		
	}
	
	private void test_last_is_clockwise (string name) {
		bool d = ((!)MainWindow.get_current_glyph ().get_last_path ()).is_clockwise ();
		
		if (!d) {
				critical (@"\nPath $name is counter clockwise, in test_last_is_clockwise");
		}

	}
	
	private bool test_reverse_last (string name) 
		requires (MainWindow.get_current_glyph ().get_last_path () != null)
	{
		Glyph g = MainWindow.get_current_glyph ();
		Path p = (!) g.get_last_path ();
		bool direction = p.is_clockwise ();

		p.reverse ();
		
		if (direction == p.is_clockwise ()) {
			critical (@"Direction did not change after reverseing path \"$name\"\n");
			stderr.printf (@"Path length: $(p.points.length ()) \n");
			return false;
		}

		this.yield ();
		return true;
	}
	
	
	class Point {
		
		public int x;
		public int y;
		
		public Point (int x, int y) {
			this.x = x;
			this.y = y;
		}
	}
	
	private Point p (int x, int y) {
		return new Point (x, y);
	}
	
	private void test_triangle (Point a, Point b, Point c, string name = "") {
		Tool pen_tool = MainWindow.get_toolbox ().get_tool ("pen_tool");
		
		this.yield ();
		MainWindow.get_tab_bar ().select_overview ();

		this.yield ();
		MainWindow.get_overview ().open_current_glyph ();
		
		pen_tool.test_select_action ();
				
		pen_tool.test_click_action (1, a.x, a.y);
		pen_tool.test_click_action (1, b.x, b.y);
		pen_tool.test_click_action (1, c.x, c.y);
		pen_tool.test_click_action (3, 0, 0);
		
		test_reverse_last (@"Triangle reverse \"$name\" ($(a.x), $(a.y)), ($(b.x), $(b.y)), ($(c.x), $(c.y)) failed.");
		
		this.yield ();
	}
	
	private void test_various_triangles () {
		test_triangle (p (287, 261), p (155, 81), p (200, 104), "First");
		test_triangle (p (65, 100), p (168, 100), p (196, 177), "Second");
		test_triangle (p (132, 68), p (195, 283), p (195, 222), "Third");
		test_triangle (p (144, 267), p (147, 27), p (296, 267), "Fourth");
	}
	
	public bool test_reverse_path () {
		// open a new glyph
		Tool pen_tool = MainWindow.get_toolbox ().get_tool ("pen_tool");

		this.yield ();
		MainWindow.get_tab_bar ().select_overview ();

		this.yield ();
		MainWindow.get_overview ().open_current_glyph ();
		
		pen_tool.test_select_action ();
		
		// paint
		int x_offset = 10;
		int y_offset = 10;
		
		test_open_next_glyph ();
		test_various_triangles ();
		
		test_open_next_glyph ();
		// draw clockwise and check direction		

		y_offset += 160;
		pen_tool.test_click_action (1, 10 + x_offset, 20 + y_offset);
		pen_tool.test_click_action (1, 17 + x_offset, 17 + y_offset);
		pen_tool.test_click_action (1, 20 + x_offset, 0 + y_offset);
		pen_tool.test_click_action (3, 0, 0);
		test_last_is_clockwise ("Clockwise triangle 1.2");

		// draw paths clockwise / counter clockwise and reverse them
		
		pen_tool.test_click_action (1, 115, 137);
		pen_tool.test_click_action (1, 89, 74);
		pen_tool.test_click_action (1, 188, 232);
		pen_tool.test_click_action (3, 0, 0);
		test_reverse_last ("Triangle 0");

		// draw incomplete paths
		y_offset += 20;
		pen_tool.test_click_action (1, 10 + x_offset, 20 + y_offset);
		pen_tool.test_click_action (3, 0, 0);
		test_reverse_last ("Point");

		y_offset += 20;
		pen_tool.test_click_action (1, 10 + x_offset, 20 + y_offset);
		pen_tool.test_click_action (1, 10 + x_offset, 20 + y_offset);
		pen_tool.test_click_action (3, 0, 0);
		test_reverse_last ("Double point");

		y_offset += 20;
		pen_tool.test_click_action (1, 10 + x_offset, 30 + y_offset);
		pen_tool.test_click_action (1, 10 + x_offset, 20 + y_offset);
		pen_tool.test_click_action (3, 0, 0);
		test_reverse_last ("Vertical line");

		y_offset += 20;
		pen_tool.test_click_action (1, 30 + x_offset, 20 + y_offset);
		pen_tool.test_click_action (1, 10 + x_offset, 20 + y_offset);
		pen_tool.test_click_action (3, 0, 0);
		test_reverse_last ("Horisontal line");

		// triangle 1
		y_offset += 20;
		pen_tool.test_click_action (1, 10 + x_offset, -10 + y_offset);
		pen_tool.test_click_action (1, 20 + x_offset, 20 + y_offset);
		pen_tool.test_click_action (1, 30 + x_offset, 0 + y_offset);
		pen_tool.test_click_action (3, 0, 0);
		test_reverse_last ("Triangle reverse 1");

		// box
		y_offset += 20;
		pen_tool.test_click_action (1, 100 + x_offset, 150 + y_offset);
		pen_tool.test_click_action (1, 150 + x_offset, 150 + y_offset);
		pen_tool.test_click_action (1, 150 + x_offset, 100 + y_offset);
		pen_tool.test_click_action (1, 100 + x_offset, 100 + y_offset); 
		pen_tool.test_click_action (3, 0, 0); // close
		test_reverse_last ("Box 1");
		
		return true;
	}
	
	private Tool select_pen () {
		Tool pen_tool = MainWindow.get_toolbox ().get_tool ("pen_tool");
		pen_tool.test_select_action ();
		return pen_tool;
	}
	
	public bool test_reverse_random_triangles () {
		Tool pen;
		
		int ax, bx, cx;
		int ay, by, cy;

		bool r = true;

		test_open_next_glyph ();
		pen = select_pen ();

		int skip = 0;
		for (int i = 0; i < 10; i++) {
			this.yield ();
			
			ax = Random.int_range (0, 300);
			bx = Random.int_range (0, 300);
			cx = Random.int_range (0, 300);

			ay = Random.int_range (0, 300);
			by = Random.int_range (0, 300);
			cy = Random.int_range (0, 300);

			pen.test_click_action (1, ax, ay);
			pen.test_click_action (1, bx, by);
			pen.test_click_action (1, cx, cy);
			pen.test_click_action (3, 0, 0);
		
			r = test_reverse_last (@"Random triangle № $(i + 1) ($ax, $ay), ($bx, $by), ($cx, $cy)");
			if (!r) {
				test_open_next_glyph ();
				pen = select_pen ();

				pen.test_click_action (1, ax, ay);
				pen.test_click_action (1, bx, by);
				pen.test_click_action (1, cx, cy);
		
				return false;
			}
			
			if (++skip == 5) {
				test_open_next_glyph ();
				skip = 0;
			}
		}
		
		if (r) test_open_next_glyph ();
		
		return true;
	}
	
}

}
