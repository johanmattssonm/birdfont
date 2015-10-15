using BirdFont;
using Cairo;

namespace BirdFont {

public class TestRunner : NativeWindow, GLib.Object  {

	public static void run (string[] args) {
		if (args.length < 2) {
			print_usage (args);
			Process.exit (0);
		}
		
		string type = args[1];
		
		if (type == "SVG" || type == "BF") {
			fuzz_test (args);
		} else if (type == "speed") {
			speed_test ();
		} else {
			print_usage (args);
		}
		
	}	
	
	static void print_usage (string[] args) {
		print ("Usage: " + args[0] + " TEST FILE\n");
		print ("TEST parameter can be BF SVG or speed\n");
	}
	
	public static void fuzz_test (string[] arg) {
		return_if_fail (arg.length == 3);
		
		string type = arg[1];
		string file = arg[2];
		
		if (type == "SVG") {
			File f = File.new_for_path (file);
			Font font = new Font ();
			import_svg_file (font, f);
		} else if (type == "BF") {
			Font font = new Font ();
			font.set_font_file (file);
			font.load ();
		}
		
		Process.exit (0);
	}
	
	static void speed_test () {
		Test test_path = new Test.time ("Simple path creation");
		
		for (int i = 0; i < 3000; i++) {
			Path p = new Path ();
			for (int j = 0; j < 300; j++) {
				p.add (0, 0);
			}
		}
		
		test_path.print ();
		
		Test test_cairo = new Test.time ("Simple Cairo");
		
		for (int i = 0; i < 3000; i++) {
			ImageSurface s;
			Context c;
			
			s = Screen.create_background_surface (1000, 1000);
			c = new Context (s);
			
			for (int j = 0; j < 30; j++) {
				c.save ();
				c.rectangle (100, 100, 100, 100);
				c.fill ();
				c.restore ();
			}
		}
		
		test_cairo.print ();		
	}
	
	public void file_chooser (string title, FileChooser file_chooser_callback, uint flags) {
	}
	
	public void update_window_size () {
	}
	
	public string get_clipboard_data (){
		return "";
	}

	public void set_clipboard (string data) {
	}
	
	public void set_inkscape_clipboard (string data) {
	}

	public void set_scrollbar_size (double size) {
	}
	
	public void set_scrollbar_position (double position) {
	}
	
	public void font_loaded () {
	}

	public void quit () {
		Process.exit (0);
	}

	public bool convert_to_png (string from, string to) {
		return false;
	}
	
	public void export_font () {
	}

	public void load () {
	}
	
	public void save () {
	}
	
	public void load_background_image () {
	}

	public void run_background_thread (Task t) {
		unowned Thread<void*> bg;
		
		MenuTab.start_background_thread ();
		
		try {
			bg = Thread.create<void*> (t.perform_task, true);
		} catch (GLib.Error e) {
			warning (e.message);
		}
	}

	public void run_non_blocking_background_thread (Task t) {
		unowned Thread<void*> bg;
		
		try {
			bg = Thread.create<void*> (t.perform_task, true);
		} catch (GLib.Error e) {
			warning (e.message);
		}
	}
	
	public void set_clipboard_text (string text) {
	}
	
	public string get_clipboard_text () {
		return "";
	}
	
	public bool can_export () {
		return true;
	}

	public void set_cursor (int visible) {
	}

	public double get_screen_scale () {
		return 1;
	}
}

}

public static int main (string[] arg) {
	TestRunner runner;
	MainWindow window;
	BirdFont.BirdFont birdfont;
	string[] birdfont_args = new string[1];

	birdfont_args[0] = arg[0];
	birdfont = new BirdFont.BirdFont ();
	birdfont.init (birdfont_args, null, "birdfont");
	
	window = new MainWindow ();
	runner = new TestRunner ();	

	window.set_native (runner);
	TestRunner.run (arg);
	
	return 0;
}
