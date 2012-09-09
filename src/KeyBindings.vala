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

using Gdk;

namespace Supplement {

enum Key {
	NONE = 0,
	UP = 65362,
	RIGHT = 65363,
	DOWN = 65364,
	LEFT = 65361,
	PG_UP = 65365,
	PG_DOWN = 65366,
	ENTER = 65293,
	BACK_SPACE = 65288,
	SHIFT_LEFT = 65505,
	SHIFT_RIGHT = 65506,
	CTRL_LEFT = 65507,
	CTRL_RIGHT = 65508,
	CAPS_LOCK = 65509,
	ALT_LEFT = 65513,
	ALT_RIGHT = 65514,
	ALT_GR = 65027,
	LOGO_LEFT = 65515,
	LOGO_RIGHT = 65516,
	CONTEXT_MENU = 65383,
	TAB = 65289,
	DEL = 65535
}

bool is_modifier_key (uint i) {
	return Key.UP == i ||
		Key.RIGHT == i ||
		Key.DOWN == i ||
		Key.LEFT == i ||
		Key.PG_UP == i ||
		Key.PG_DOWN == i ||
		Key.ENTER == i ||
		Key.BACK_SPACE == i ||
		Key.SHIFT_LEFT == i ||
		Key.SHIFT_RIGHT == i ||
		Key.CTRL_LEFT == i ||
		Key.CTRL_RIGHT == i ||
		Key.ALT_LEFT == i ||
		Key.ALT_RIGHT == i ||
		Key.ALT_GR == i || 
		Key.LOGO_LEFT == i || 
		Key.LOGO_RIGHT == i || 
		Key.TAB == i || 
		Key.CAPS_LOCK == i || 
		Key.LOGO_RIGHT == i;
}

/** Modifier flags */
internal static const uint NONE  = 0;
internal static const uint CTRL  = 1 << 0;
internal static const uint ALT   = 1 << 2;
internal static const uint SHIFT = 1 << 3;

internal bool is_mod (EventKey e) {
	return (e.keyval == Key.CTRL_RIGHT || e.keyval == Key.CTRL_LEFT || e.keyval == Key.ALT_RIGHT || e.keyval == Key.ALT_LEFT);
}

/** A list of all valid key bindings. */
class BindingList {
	static ShortCut[]? nc = null;
	
	public static ShortCut[] get_default_bindings () {	
		
		if (nc == null) {
		
			// add all bindings to this list
			ShortCut[] default_bindings = { 
				new ShowMenu (),
				new ToggleToolBar (),
				new NextTab (),
				new PreviousTab (),
				new CloseTab (),
				new UndoAction (),
				new Copy (),
				new Paste (),
				new Save (),
				new NewFile (),
				new Load (),
				new ShowKerningContext (),
				new ShowPreview ()
			};

			nc = default_bindings;
		}
		return nc;
	}
}

class ExportFonts : ShortCut {
	
	public override void run () {
		ExportTool.export_all ();
	}
	
	public override uint get_default_modifier ()      { return CTRL; }
	public override uint get_default_key ()           { return 'e';	}	
	public override unowned string get_description () { return "Export"; }
}

class ShowPreview : ShortCut {
	
	public override void run () {
		MenuTab.preview ();
	}
	
	public override uint get_default_modifier ()      { return CTRL; }
	public override uint get_default_key ()           { return 'p';	}	
	public override unowned string get_description () { return "Preview"; }
}


class ShowKerningContext : ShortCut {
	
	public override void run () {
		MenuTab.show_kerning_context ();
	}
	
	public override uint get_default_modifier ()      { return CTRL; }
	public override uint get_default_key ()           { return 'k';	}	
	public override unowned string get_description () { return "Kerning context"; }
}

class Load : ShortCut {
	
	public override void run () {
		MenuTab.load ();
	}
	
	public override uint get_default_modifier ()      { return CTRL; }
	public override uint get_default_key ()           { return 'o';	}	
	public override unowned string get_description () { return "Open file"; }
}

class NewFile : ShortCut {
	
	public override void run () {
		MenuTab.new_file ();
	}
	
	public override uint get_default_modifier ()      { return CTRL; }
	public override uint get_default_key ()           { return 'n';	}	
	public override unowned string get_description () { return "New file"; }
}

class Save : ShortCut {
	
	public override void run () {
		MenuTab.save ();
	}
	
	public override uint get_default_modifier ()      { return CTRL; }
	public override uint get_default_key ()           { return 's';	}	
	public override unowned string get_description () { return "Save"; }
}

class Paste : ShortCut {
	
	public override void run () {
		ClipTool.paste ();
	}
	
	public override uint get_default_modifier ()      { return CTRL; }
	public override uint get_default_key ()           { return 'v';	}	
	public override unowned string get_description () { return "Paste"; }
}

class Copy : ShortCut {
	
	public override void run () {
		ClipTool.copy ();
	}
	
	public override uint get_default_modifier ()      { return CTRL; }
	public override uint get_default_key ()           { return 'c';	}	
	public override unowned string get_description () { return "Copy"; }
}

class UndoAction : ShortCut {
	
	public override void run () {
		MainWindow.get_current_display ().undo ();
	}
	
	public override uint get_default_modifier ()      { return CTRL; }
	public override uint get_default_key ()           { return 'z';	}	
	public override unowned string get_description () { return "Undo"; }
}

class ShowMenu : ShortCut {
	
	public override void run () {
		MainWindow.get_tab_bar ().select_tab_name ("Content");
	}
	
	public override uint get_default_modifier ()      { return CTRL; }
	public override uint get_default_key ()           { return 'f';	}	
	public override unowned string get_description () { return "Show menu"; }
}

class ToggleToolBar : ShortCut {
	
	public override void run () {
		Toolbox t = MainWindow.get_toolbox ();
		
		if (t.is_expanded ()) {
			t.minimize ();
		} else {
			t.maximize ();
		}

	}
	
	public override uint get_default_modifier ()      { return CTRL; }
	public override uint get_default_key ()           { return 'b';	}	
	public override unowned string get_description () { return "Show toolbox"; }
}

class NextTab : ShortCut {
		
	public override void run () {
		TabBar tb = MainWindow.get_tab_bar ();
		int n = tb.get_selected () + 1;
		
		if (!(0 <= n < tb.get_length ())) {
			return;
		}
		
		tb.select_tab (n);
	}
	
	public override uint get_default_modifier ()      { return CTRL; }
	public override uint get_default_key ()           { return Key.RIGHT;	}	
	public override unowned string get_description () { return "Next tab"; }
}

class PreviousTab : ShortCut {
		
	public override void run () {
		TabBar tb = MainWindow.get_tab_bar ();
		int n = tb.get_selected () - 1;

		if (!(0 <= n < tb.get_length ())) {
			return;
		}
		
		tb.select_tab (n);
	}
	
	public override uint get_default_modifier ()      { return CTRL; }
	public override uint get_default_key ()           { return Key.LEFT;	}	
	public override unowned string get_description () { return "Previous tab"; }
}

class CloseTab : ShortCut {
		
	public override void run () {
		TabBar tb = MainWindow.get_tab_bar ();
		int n = tb.get_selected ();

		if (!(0 <= n < tb.get_length ())) {
			return;
		}
		
		tb.close_tab (n);
	}
	
	public override uint get_default_modifier ()      { return CTRL; }
	public override uint get_default_key ()           { return (uint) 'w';	}	
	public override unowned string get_description () { return "Close tab"; }
}

/** Function to be executed for each global key binding. */
abstract class ShortCut : GLib.Object {
	uint modifier = 0;
	uint key = 0;
	
	public abstract void run ();
	
	public void set_modifier (uint m) {
		modifier = m;
	}

	public void set_key (uint k) {
		key = k;
	}
	
	public uint get_modifier () {
		return modifier;
	}
	
	public uint get_key () {
		return key;
	}
	
	public abstract uint get_default_modifier ();
	public abstract uint get_default_key ();
	
	public abstract unowned string get_description ();
	
	public static EqualFunc<ShortCut> equal = (a, b) => {
		if (a.get_key () != b.get_key ()) return false;
		if (a.get_modifier () != b.get_modifier ()) return false;
		if (a.get_description () != b.get_description ()) return false;
		return true;
	};
	
}

class KeyBindings {
	
	bool modifier_ctrl = false;
	bool modifier_alt = false;
	bool modifier_shift = false;
		
	public static uint modifier = 0;
	
	bool require_modifier = false;
	
	/** First uint is modifer flag, second uint is keyval */
	HashTable<uint, HashTable<uint, ShortCut>> short_cuts = new HashTable<uint, HashTable<uint, ShortCut>> (null, null);
	
	public static KeyBindings singleton;
	
	public KeyBindings () {
		
		HashFunc<uint> hash = (v) => {
			return v;
		};
	
		HashTable<uint, ShortCut> alt_ctrl_shift = new HashTable<uint, ShortCut> (hash, ShortCut.equal);
		HashTable<uint, ShortCut> alt_shift      = new HashTable<uint, ShortCut> (hash, ShortCut.equal);
		HashTable<uint, ShortCut> ctrl_shift     = new HashTable<uint, ShortCut> (hash, ShortCut.equal);
		HashTable<uint, ShortCut> alt            = new HashTable<uint, ShortCut> (hash, ShortCut.equal);
		HashTable<uint, ShortCut> ctrl           = new HashTable<uint, ShortCut> (hash, ShortCut.equal);
		
		// Possible modifiers
		short_cuts.insert (ALT|CTRL|SHIFT, alt_ctrl_shift);
		short_cuts.insert (ALT|SHIFT,      alt_shift);
		short_cuts.insert (CTRL|SHIFT,     ctrl_shift);
		short_cuts.insert (ALT,            alt);
		short_cuts.insert (CTRL,           ctrl);
		
		// Add default bindings
		foreach (var b in BindingList.get_default_bindings ()) {
			add_binding (b);
		}
		
		save ();
		load ();
		
		singleton = this;
	}
	
	public void reset () {
		modifier = NONE;
		modifier_ctrl = false;
		modifier_alt = false;
		modifier_shift = false;
	}
	
	public void set_require_modifier (bool m) {
		require_modifier = m;
	}
	
	void load () {
		File home = File.new_for_path (Environment.get_home_dir ());
		File settings = home.get_child (".birdfont");
		File bindings = settings.get_child ("keybindings");

		if (!bindings.query_exists ()) {
			return;
		}

		FileStream? bindings_file = FileStream.open ((!) bindings.get_path (), "r");
		
		if (bindings_file == null) {
			stderr.printf ("Failed to load keybindings from file %s.\n", (!) bindings.get_path ());
			return;
		}
		
		return_if_fail (bindings_file != null);
		
		unowned FileStream b = (!) bindings_file;
		
		string? l;
		l = b.read_line ();
		while ((l = b.read_line ())!= null) {
			string line;
			
			line = (!) l;
			
			if (line.get_char (0) == '#') {
				continue;
			}
			
			int i = 0;
			int s = 0;
			
			i = line.index_of_char(' ', s);
			string mod = line.substring (s, i - s);
			
			s = i + 1;
			i = line.index_of_char(' ', s);
			string key = line.substring (s, i - s);
			
			s = i + 1;
			i = line.index_of_char('\n', s);
			string description = line.substring (s, i - s);

			update_short_cut (mod, key, description);
		}
		
	}
	
	void save () {
		try {
			File settings = Supplement.get_settings_directory ();
			File bindings = settings.get_child ("keybindings");
			
			if (bindings.query_exists ()) {
				bindings.delete ();
			}

			DataOutputStream os = new DataOutputStream(bindings.create(FileCreateFlags.REPLACE_DESTINATION));
			uint8[] data;
			long written = 0;
			
			StringBuilder sb = new StringBuilder ();
			
			sb.append_printf ("# Supplement keybindings\n");
			sb.append_printf ("# Version: 1.0\n");
			
			short_cuts.foreach ( (k, v) => {
				v.foreach ( (k, s) => {
					sb.append_printf ("%u %u %s\n", s.get_modifier (), s.get_key (), s.get_description ());
				});
			});
			
			data = sb.str.data;
			
			while (written < data.length) { 
				written += os.write (data[written:data.length]);
			}
			
		} catch (Error e) {
			stderr.printf ("Can not save key bindings. (%s)", e.message);	
		}
		
	}
	
	void update_short_cut (string mod, string key, string description) {
		ShortCut? sc = null;
		ShortCut binding;
		short_cuts.foreach ( (k, ht) => {
			ht.foreach ((ki, s) => {
				if (s.get_description () == description) {
					sc = s;
				}
				
				// ht.remove (ki); // FIXME! why does it remove all items?
				
			});
		});
		
		if (unlikely (sc == null)) {
			stderr.printf ("Can not set bindings for \"%s-%s-%s-\"\n", mod, key, description);
			return;
		}
		
		binding = (!) sc;

		binding.set_modifier ((uint) uint64.parse (mod));
		binding.set_key ((uint) uint64.parse (key));
		
		add_binding (binding);
	}
	
	void add_binding (ShortCut binding) {
		uint m = binding.get_modifier ();
		
		if (m == 0) {
			m = binding.get_default_modifier ();
			binding.set_modifier (m);
		}

		if (binding.get_key () == 0) {
			binding.set_key (binding.get_default_key ());
		}
		
		HashTable<uint, ShortCut>? e = short_cuts.lookup (m);
		
		if (e == null) {
			stderr.printf ("Invalid modifier in key binding: expecting ctrl, alt or shift. Flag: (%u) \n", modifier);
			return;
		}
		
		var events = (!) e;
		events.insert (binding.get_key (), binding);
	}
	
	bool get_short_cut (uint modifier, uint key, out ShortCut? sc) {
		sc = null;
		
		foreach (var v in BindingList.get_default_bindings ()) {
			if (v.get_default_modifier () == modifier && v.get_default_key () == key) {
				sc = v;
				return true;
			}
		}
		
		return false;
	}
	
	void set_modifier (uint k, bool v) {
		switch (k) {
			case Key.CTRL_LEFT:
				modifier_ctrl = v;
				break;
			case Key.CTRL_RIGHT:
				modifier_ctrl = v;
				break;
			case Key.ALT_LEFT:
				modifier_alt = v;
				break;
			case Key.ALT_GR:
				modifier_alt = v;
				break;
			case Key.SHIFT_LEFT:
				modifier_shift = v;
				break;
			case Key.SHIFT_RIGHT:
				modifier_shift = v;
				break;
		}
		
		modifier = 0;

		if (modifier_ctrl)  modifier |= CTRL;
		if (modifier_alt)   modifier |= ALT;		
		if (modifier_shift) modifier |= SHIFT;
	}

	public static bool has_alt () {
		return singleton.modifier_alt;
	}
	
	public static bool has_shift () {
		return singleton.modifier_shift;
	}
		
	public static bool has_ctrl () {
		return singleton.modifier_ctrl;
	}
	
	public void key_release (uint keyval) {
		set_modifier (keyval, false);
	}
	
	public void key_press (uint keyval) {
		uint key = keyval;
		ShortCut? short_cut;
		
		set_modifier (keyval, true);
	
		if (get_short_cut (modifier, key, out short_cut)) {
			if (short_cut != null)
				((!)short_cut).run ();
		}
				
		foreach (var exp in MainWindow.get_toolbox ().expanders) {
			foreach (Tool t in exp.tool) {
				t.set_active (false);
				
				if (t.key == keyval && t.modifier_flag == modifier) {
					if (!(require_modifier && (modifier == NONE || modifier == SHIFT))) {
						MainWindow.get_toolbox ().select_tool (t);
					}
				}
			}
		}
	}
}

}
