using BirdFont;

namespace BirdFont {

public class TestRunner : NativeWindow, GLib.Object  {
	public static void fuzz_test (string[] arg) {
		if (arg.length != 3) {
			print ("Usage: " + arg[0] + " TEST FILE\n");
			print ("TEST parameter can be BF or SVG\n");
			Process.exit (0);
		}
		
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
	TestRunner.fuzz_test (arg);
	
	return 0;
}
