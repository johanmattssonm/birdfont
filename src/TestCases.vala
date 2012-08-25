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

/** All the things we want to test listed is here. */
class TestCases {
	
	public List<Test> test_cases;

	public TestCases () {
		add (test_overview, "Overview");
		add (test_data_reader, "Font data reader");
		add (test_argument, "Argument list");
		add (test_glyph_ranges, "Glyph ranges");
		add (test_glyph_table, "Glyph table");
		add (test_active_edit_point, "Active edit point");
		add (test_hex, "Unicode hex values");
		add (test_reverse_path, "Reverse path");
		add (test_reverse_random_paths, "Reverse random paths");
		add (test_coordinates, "Coordinates");
		add (test_drawing, "Pen tool");
		add (test_delete_points, "Delete edit points");
		add (test_view_result, "View result in web browser");
		add (test_save_backup, "Save backup");
		add (test_convert_to_quadratic_bezier_path, "Convert to quadratic path");
		add (test_notdef, "Notdef");
	}

	public static void test_notdef () {
		Font f = Supplement.get_current_font ();
		Glyph n = f.get_not_def_character ();
		Glyph g;
		Path pn;
		
		f.add_glyph (n);
		
		Tool.test_open_next_glyph ();
		g = MainWindow.get_current_glyph ();
		foreach (Path p in n.path_list) {
			pn = p.copy ().get_quadratic_points ();
			g.path_list.append (pn);
			pn.move (50, 0);
			g.path_list.append (p.copy ());
		}
	}

	public static void test_convert_to_quadratic_bezier_path () {
		Glyph g;
		Path gqp;
		Path gqp_points;
		
		Path p = new Path ();
		Path p1 = new Path ();
		List<Path> qpl = new List<Path> (); 
		
		EditPoint e0, e1, e2, e3;
		
		g = MainWindow.get_current_glyph ();
		
		// split_all_cubic_in_half
		foreach (Path gp in g.path_list) {
			gqp_points = gp.copy ();
			gqp_points.split_cubic_in_parts (gqp_points);
			gqp_points.move (50, 0);
			qpl.append (gqp_points);
		}
		
		// convert to quadratic points
		foreach (Path gp in g.path_list) {
			gqp = gp.get_quadratic_points ();
			gqp.move (100, 0);
			qpl.append (gqp);
		}

		foreach (Path gp in qpl) {
			g.add_path (gp);
		}

		Tool.test_open_next_glyph ();
		
		g = MainWindow.get_current_glyph ();
		
		p.add (-10, 10);
		p.add (10, 10);
		p.add (10, -10);
		p.add (-10, -10);
		p.close ();
		g.add_path (p);
		g.add_path (p1.get_quadratic_points ());

		e0 = new EditPoint (20, 40);
		e1 = new EditPoint (40, 40);
		e2 = new EditPoint (40, 20);
		e3 = new EditPoint (20, 20);

		p1.add_point (e0);
		p1.add_point (e1);
		p1.add_point (e2);
		p1.add_point (e3);
		p1.close ();

		e0.set_tie_handle (true);
		e1.set_tie_handle (true);
		e2.set_tie_handle (true);
		e3.set_tie_handle (true);

		e0.process_tied_handle ();
		e1.process_tied_handle ();
		e2.process_tied_handle ();
		e3.process_tied_handle ();

		g.add_path (p1);
		g.add_path (p1.get_quadratic_points ());
	}

	public static void test_overview () {
		OverView o = MainWindow.get_overview ();

		warn_if_fail (o.selected_char_is_visible ());
	
		for (int i = 0; i < 10; i++) {
			o.key_down ();
			warn_if_fail (o.selected_char_is_visible ());
		}

		for (int i = 0; i < 15; i++) {
			o.key_up ();
			warn_if_fail (o.selected_char_is_visible ());
		}

		for (int i = 0; i < 6; i++) {
			o.key_down ();
			warn_if_fail (o.selected_char_is_visible ());
		}

		for (int i = 0; i < 3; i++) {
			o.key_down ();
			warn_if_fail (o.selected_char_is_visible ());
		}
		
		for (int i = 0; i < 2000; i++) {
			o.scroll_adjustment (5);
		}

		for (int i = 0; i < 2000; i++) {
			o.scroll_adjustment (-5);
		}
	}

	public static void test_data_reader () {
		FontData fd = new FontData ();
		uint len;
		
		fd.add (7);
		fd.add_ulong (0x5F0F3CF5);
		fd.add_ulong (9);
		
		warn_if_fail (fd.table_data[0] == 7);
		warn_if_fail (fd.read () == 7);
		warn_if_fail (fd.read_ulong () == 0x5F0F3CF5);
		warn_if_fail (fd.read_ulong () == 9);
		
		fd = new FontData ();
		for (int16 i = 0; i < 2048; i++) {
			fd.add_short (i);
		}
		
		fd.seek (2 * 80);
		warn_if_fail (fd.read_short () == 80);
		
		fd.seek (100);
		fd.add_short (7);
		fd.seek (100);
		warn_if_fail (fd.read_short () == 7);
		
		fd.seek_end ();
		len = fd.length ();
		fd.add (0);
		warn_if_fail (len + 1 == fd.length ());
	}

	public static void test_argument () {
		Argument arg = new Argument ("supplement -t \"Argument list\" --unknown -unknown --help -s");
		
		return_if_fail (arg.has_argument ("--test"));
		return_if_fail ((!) arg.get_argument ("--test") == "\"Argument list\"" );
		return_if_fail (arg.has_argument ("--unknown"));
		return_if_fail (arg.has_argument ("--help"));
		return_if_fail (arg.has_argument ("--slow"));
		return_if_fail (arg.validate () != 0);

		arg = new Argument ("supplement --test \"Argument list\"");
		return_if_fail ((!) arg.get_argument ("--test") == "\"Argument list\"" );
		return_if_fail (!arg.has_argument ("--help"));
		return_if_fail (!arg.has_argument ("--slow"));
		return_if_fail (arg.validate () == 0);
		
	}

	public static void test_glyph_ranges () {
		GlyphRange gr = new GlyphRange ();
		
		gr.add_range ('b', 'c');
		gr.add_single ('d');
		gr.add_range ('e', 'h');
		gr.add_range ('k', 'm');
		gr.add_range ('o', 'u');
		gr.add_range ('a', 'd');
		gr.add_range ('f', 'z');
		gr.add_range ('b', 'd');
			
		return_if_fail (gr.length () == 'z' - 'a' + 1);
		return_if_fail (gr.get_ranges ().length () == 1);
		return_if_fail (gr.get_ranges ().first ().data.length () == 'z' - 'a' + 1);
		
		for (unichar i = 'a'; i <= 'z'; i++) {
			uint index = i - 'a';
			string c = gr.get_char (index);
			StringBuilder s = new StringBuilder ();
			s.append_unichar (i);
			
			if (c != s.str) {
				warning (@"wrong glyph in glyph range got \"$c\" expected \"$(s.str)\" for index $(index).");
			}
		}
		
		gr = new GlyphRange ();
		gr.add_single ('a');
		gr.add_range ('c', 'e');
		gr.add_single ('◊');
		return_if_fail (gr.get_char (0) == "a");
		return_if_fail (gr.get_char (1) == "c");
		return_if_fail (gr.get_char (2) == "d");
		return_if_fail (gr.get_char (3) == "e");
		return_if_fail (gr.get_char (4) == "◊");
	}

	public static void test_glyph_table () {
		GlyphTable table = new GlyphTable ();
		List<GlyphCollection> gc = new List<GlyphCollection> ();
		List<unowned GlyphCollection> gc_copy;
		GlyphCollection g;
		
		return_if_fail (table.length () == 0);
		return_if_fail (table.get ("Some glyph") == null);
		
		// generate test data
		for (uint i = 0; i < 1000; i++) {
			gc.append (new GlyphCollection (new Glyph (@"TEST $i", i + 'a')));
		}

		// insert in random order
		gc_copy = gc.copy ();
		for (uint i = 0; gc_copy.length () > 0; i++) {
			int t = (int) ((gc_copy.length () - 1) * Random.next_double ());
			g = gc_copy.nth (t).data;
			
			if (!table.insert (g)) {
				warning (@"Failed to insert $(g.get_name ())");
				return;
			}
			
			gc_copy.remove_all (g);
			
			if (!table.validate_index ()) {
				table.print_all ();
				warning ("index is invalid");
				return;
			}
		}
		
		return_if_fail (table.length () == gc.length ());
		
		// validate table
		for (uint i = 0; i > 1000; i++) {
			g = (!) table.get (gc.nth (i).data.get_name ());
			return_if_fail (gc.nth (i).data == g);
		}
		
		// search 
		for (int i = 0; i < 2000; i++) {
			int t = (int) (999 * Random.next_double ());
			if (table.get (@"TEST $t") == null) {
				table.print_all ();
				warning (@"Did't find TEST $t in glyph table.");
				return;
			}
		}

		// remove
		table.remove ("TEST 0");
		table.remove ("TEST 53");
		return_if_fail (table.get ("TEST 0") == null);
		return_if_fail (table.get ("TEST 53") == null);
		
		// search 
		return_if_fail (table.get ("TEST 52") != null);
		return_if_fail (table.get ("TEST 54") != null);
	}

	public static void test_delete_points () {
		PenTool tool = (PenTool) MainWindow.get_toolbox ().get_tool ("pen_tool");
		tool.test_delete_points ();
	}

	public static void test_active_edit_point () {
		PenTool tool = (PenTool) MainWindow.get_toolbox ().get_tool ("pen_tool");
		tool.test_active_edit_point ();
	}
	
	public static void test_save_backup () {
		// TODO draw various things and assert that they are restored correctly
		Supplement.get_current_font ().save_backup ();
		Supplement.get_current_font ().restore_backup ();
	}

	public static void test_hex () {
		test_hex_conv ('H', "U+48", 72);
		test_hex_conv ('1', "U+31", 49);
		test_hex_conv ('å', "U+e5", 229);
		test_hex_conv ('◊', "U+25ca", 9674);
	}

	private static void test_hex_conv (unichar h, string sr, int r) {
		string s = Font.to_hex (h);
		unichar t = Font.to_unichar (sr);
		
		if (s != sr) warning (@"($s != \"$sr\")");
		if ((int)t != r || t != h) warning (@"$((int)t) != $r || $t != '$h'");
	}

	public static void test_coordinates () {
		PenTool tool = (PenTool) MainWindow.get_toolbox ().get_tool ("pen_tool");
		tool.test_coordinates ();		
	}

	public static void test_view_result () {
		ExportTool tool = (ExportTool) MainWindow.get_toolbox ().get_tool ("export");
		tool.test_view_result ();
	}

	public static void test_reverse_random_paths () {
		PenTool tool = (PenTool) MainWindow.get_toolbox ().get_tool ("pen_tool");
		tool.test_reverse_random_triangles ();		
	}

	public static void test_reverse_path () {
		PenTool tool = (PenTool) MainWindow.get_toolbox ().get_tool ("pen_tool");
		tool.test_reverse_path ();
	}

	public static void test_drawing () {
		Tool tool = MainWindow.get_toolbox ().get_tool ("pen_tool");
		tool.test ();
	}
		
	private void add (Callback callback, string name) {
		test_cases.append (new Test (callback, name));
	}
	
	public unowned List<Test> get_test_functions () {
		return test_cases;
	}
}	
	
}
