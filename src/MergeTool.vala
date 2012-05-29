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
}

}
