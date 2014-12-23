/*
    Copyright (C) 2012, 2014 Johan Mattsson

    This library is free software; you can redistribute it and/or modify 
    it under the terms of the GNU Lesser General Public License as 
    published by the Free Software Foundation; either version 3 of the 
    License, or (at your option) any later version.

    This library is distributed in the hope that it will be useful, but 
    WITHOUT ANY WARRANTY; without even the implied warranty of 
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU 
    Lesser General Public License for more details.
*/

namespace BirdFont {

/** Class for executing tests cases. */
class TestBirdFont : GLib.Object {

	const int NOT_STARTED = 0;
	const int RUNNING = 1;
	const int PAUSED = 2;
	const int DONE = 3;
	
	static int state = NOT_STARTED;

	TestCases tests;
	
	unowned List<Test> test_cases;
	unowned List<Test?>? current_case = null;

	List<Test> passed;
	List<Test> failed;
	List<Test> skipped;

	List<Test> bechmarks;

	static TestBirdFont? singleton = null;

	bool has_failed = false;
	bool has_skipped = false;
		
	static bool slow_test = false;
	
	public string test_cases_to_run; // name of specific test case or all to run all test cases
	
	public TestBirdFont () {
		assert (singleton == null);
		tests = new TestCases ();
		test_cases = tests.get_test_functions ();
		current_case = test_cases.first ();
		test_cases_to_run = "All";
		from_command_line ();
	}
	
	public static bool is_slow_test () {
		return slow_test;
	}
	
	public static void set_slow_test (bool s) {
		slow_test = s;
	}
	
	public static void run_tests () {
		TestBirdFont t = get_singleton ();
		state = RUNNING;
		t.run_all_tests ();
	}
	
	public static TestBirdFont get_singleton () {
		if (singleton == null) {
			singleton = new TestBirdFont ();
		}
		
		return (!) singleton;
	}

	private bool has_test_case (string s) {
		foreach (var t in test_cases) {
			if (t.name == s) return true;
		}	
		
		if (s == "" || s == "All") {
			print ("No specific tescase given run all test cases.\n");
			return true;
		}
		
		return false;
	}

	/** Run only test specified on the command line. */
	private void from_command_line () {
		string? stn = BirdFont.get_argument ("--test");
	
		if (stn != null) {
			string st = (!) stn;
			
			if (!has_test_case (st)) {
				stderr.printf (@"Test case \"$st\" does not exist.\n");
				stderr.printf ("\nAvaliable test cases:\n");
				
				foreach (var t in test_cases) {
					stderr.printf (t.name);
					stderr.printf ("\n");
				}
				
				Process.exit(1);
			}

			if (st == "All" || st == "") {
				return;
			} else {
				stderr.printf  (@"Run test case \"$st\" \n");
			}
			
			test_cases_to_run = st;
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
		
		assert (!BirdFont.fatal_wanings);
	}

	public static void @continue () {
		int s = AtomicInt.get (ref state);
		if (s == DONE) {
			singleton = null;
		}

		TestBirdFont t = get_singleton ();
		
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
		for (int i = 0; i < t; i++) {
			stdout.printf (" ");
		}
	}

	public void print_result () {
		stdout.printf ("\n");
		stdout.printf ("Test case results:\n");

		foreach (Test t in skipped) {
			stdout.printf ("%s", t.name);
			pad (40 - t.name.char_count());
			stdout.printf ("Skipped\n");
		}
		
		if (skipped.length () > 0) {
			stdout.printf ("\n");
		}
		
		foreach (Test t in passed) {
			stdout.printf ("%s", t.name);
			pad (40 - t.name.char_count());
			stdout.printf ("Passed\n");
		}
		
		foreach (Test t in failed) {
			stdout.printf ("%s", t.name);
			pad (40 - t.name.char_count());
			stdout.printf ("Failed\n");
		}

		foreach (Test t in bechmarks) {
			stdout.printf ("%s", t.name);
			pad (40 - t.name.char_count());
			stdout.printf (@"$(t.get_time ())s\n");
		}		

		stdout.printf ("\n");
		
		stdout.printf ("Total %u test cases executed, %u passed and %u failed.\n", (passed.length () + failed.length ()), passed.length (), failed.length ());
	}

	/** Run tests in main loop. */
	public void run_all_tests () {
		TimeoutSource idle = new TimeoutSource (20);
		
		idle.set_callback(() => {
			int s = AtomicInt.get (ref state);
			
			if (s != RUNNING || current_case == null) {
				return false;
			}

			Test test = (!)((!) current_case).data;
					
			has_failed = false;
			has_skipped = false;
			
			if (test_cases_to_run != "All" && test_cases_to_run != test.name) {
				has_skipped = true;
			} else {
				if (test.is_benchmark ()) {
					test.timer_start ();
					test.callback ();
					test.timer_stop ();
				} else {
					test.callback ();
				}
			}
			
			if (test.is_benchmark ()) {
				bechmarks.append ((!) test);
			} else if (has_failed) {
				failed.append ((!) test);
				
				if (BirdFont.has_argument ("--exit")) {
					print_result ();
					Process.exit (1);
				}
	
			} else if (has_skipped) {
				skipped.append ((!) test);
			} else {
				passed.append ((!) test);
			}

			if (unlikely (current_case == test_cases.last ())) {
				stdout.printf ("Finished running test suite.\n");			
				
				AtomicInt.set (ref state, DONE);
				Log.set_handler (null, LogLevelFlags.LEVEL_MASK, Log.default_handler);

				print_result ();
				
				if (BirdFont.has_argument ("--exit")) {
					print_result ();
					Process.exit ((failed.length () == 0) ? 0 : 1);
				}
				return false;
			}
			
			current_case = ((!) current_case).next;
			
			return true;
		});
    
		idle.attach (null);
	}

}

}
