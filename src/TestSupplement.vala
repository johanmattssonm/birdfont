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

class Test : Object {
	public Callback callback;
	public string name;
	
	public Test (Callback callback, string name) {
		this.callback = callback;
		this.name = name;
	}
}

/** All the things we might want to test is here. */
class TestCases {
	
	public List<Test> test_cases;

	public TestCases () {
		add (test_active_edit_point, "Active edit point");
		add (test_hex, "Unicode hex values");
		add (test_reverse_path, "Reverse path");
		add (test_reverse_random_paths, "Reverse random paths");
		add (test_coordinates, "Coordinates");
		add (test_drawing, "Pen tool");
		add (test_view_result, "View result in web browser");
		add (test_save_backup, "Save backup");
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

/** Class for executing tests cases. */
class TestSupplement : GLib.Object {

	const int NOT_STARTED = 0;
	const int RUNNING = 1;
	const int PAUSED = 2;
	const int DONE = 3;
	
	static int state = NOT_STARTED;

	TestCases tests;
	
	unowned List<Test> test_cases;
	unowned List<Test?>? current_case = null;

	unowned List<Test> passed;
	unowned List<Test> failed;

	static TestSupplement? singleton = null;

	bool has_failed = false;
	
	static bool slow_test = false;
	
	public TestSupplement () {
		assert (singleton == null);
		tests = new TestCases ();
		test_cases = tests.get_test_functions ();
		current_case = test_cases.first ();
		
		from_command_line ();
	}
	
	public static bool is_slow_test () {
		return slow_test;
	}
	
	public static void set_slow_test (bool s) {
		slow_test = s;
	}
	
	public static TestSupplement get_singleton () {
		if (singleton == null) {
			singleton = new TestSupplement ();
		}
		
		return (!) singleton;
	}

	private bool has_test_case (string s) {
		foreach (var t in test_cases) {
			if (t.name == s) return true;
		}	
		
		if (s == "") {
			print ("No speceific tescase given run all test cases.\n");
			return true;
		}
		
		return false;
	}

	/** Run only test specified on the command line. */
	private void from_command_line () {
		string? stn = Supplement.get_argument ("--test");
	
		if (stn != null) {
			string st = (!)stn;
			
			if (!has_test_case (st)) {
				stderr.printf (@"Test case $st does not exist.\n");
				stderr.printf ("\nAvaliable cases:\n");
				foreach (var t in test_cases) {
					stderr.printf (t.name);
					stderr.printf ("\n");
				}
				
				assert (false);
			}

			if (st == "All" || st == "") {
				return;
			} else {
				stderr.printf  (@"Run only test case \"$st\" \n");
			}
			
		}
	}

	public static void log (string? log_domain, LogLevelFlags log_levels, string message) {		
		Test t = (!)((!)get_singleton ().current_case).data;
		
		if (log_domain != null) {
			stderr.printf ("%s: \n", (!) log_domain);
		}
		
		stderr.printf ("Testcase \"%s\" failed because:\n", t.name);
		stderr.printf ("%s\n\n", message);	
		
		get_singleton ().has_failed = true;
	}

	public static void @continue () {
		int s = AtomicInt.get (ref state);
		if (s == DONE) {
			singleton = null;
		}

		TestSupplement t = get_singleton ();
		
		LogLevelFlags levels = LogLevelFlags.LEVEL_ERROR | LogLevelFlags.LEVEL_CRITICAL | LogLevelFlags.LEVEL_WARNING;
		Log.set_handler (null, levels, log);
				
		AtomicInt.set (ref state, RUNNING);
		t.run_all_tests ();
	}

	public static bool is_running () {
		int r = AtomicInt.get (ref state);
		return (r == RUNNING);
	}

	public static void pause () {
		AtomicInt.set (ref state, PAUSED);
		Log.set_handler (null, LogLevelFlags.LEVEL_MASK, Log.default_handler);
	}

	private static void pad (int t) {
		for (int i = 0; i < t; i++) stdout.printf (" ");
	}

	public void print_result () {
		stdout.printf ("\n");
		stdout.printf ("Testcase results:\n");

		foreach (var t in passed) {
			stdout.printf ("%s", t.name);
			pad (40 - t.name.char_count());
			stdout.printf ("Passed\n");
		}
		
		foreach (var t in failed) {
			stdout.printf ("%s", t.name);
			pad (40 - t.name.char_count());
			stdout.printf ("Failed\n");
		}
		
		stdout.printf ("\n");
		
		stdout.printf ("Total %u test cases executed, %u passed and %u failed.\n", (passed.length () + failed.length ()), passed.length (), failed.length ());
	}

	/** Run tests in main loop. */
	public void run_all_tests () {
		var idle = new TimeoutSource (20);
		
		idle.set_callback(() => {
			int s = AtomicInt.get (ref state);
			
			if (s != RUNNING || current_case == null) {
				return false;
			}

			Test test = (!)((!) current_case).data;

			has_failed = false;
			
			test.callback ();

			if (has_failed) {
				failed.append ((!)test);
				
				if (Supplement.has_argument ("--exit")) {
					print_result ();
					
					bool test_case_will_not_fail = false;
					assert (test_case_will_not_fail);
				}
	
			} else {
				passed.append ((!)test);
			}

			if (unlikely (current_case == test_cases.last ())) {
				stderr.printf ("Finished running test suite.\n");			
				AtomicInt.set (ref state, DONE);
				Log.set_handler (null, LogLevelFlags.LEVEL_MASK, Log.default_handler);

				print_result ();
				return false;
			}
			
			current_case = ((!) current_case).next;
			
			return true;
		});
    
		idle.attach (null);
	}

}

}
