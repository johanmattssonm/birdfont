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

namespace BirdFont {

// FIXME a lot of these things have been replaced and can safely be removed

public enum Key {
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

bool is_arrow_key (uint keyval) {
	return keyval == Key.UP ||
		keyval == Key.DOWN ||
		keyval == Key.LEFT ||
		keyval == Key.RIGHT;
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
public static const uint NONE  = 0;
public static const uint CTRL  = 1 << 0;
public static const uint ALT   = 1 << 2;
public static const uint SHIFT = 1 << 3;
public static const uint LOGO  = 1 << 4;

/** A list of all valid key bindings. */
public class BindingList {
	static ShortCut[]? nc = null;
	
	public static ShortCut[] get_default_bindings () {	
		
		if (nc == null) {
		
			// add all bindings to this list
			ShortCut[] default_bindings = { };

			nc = default_bindings;
		}
		
		return nc;
	}
}


/** Function to be executed for each global key binding. */
public abstract class ShortCut : GLib.Object {
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

public class KeyBindings {
	
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
			File settings = BirdFont.get_settings_directory ();
			File bindings = settings.get_child ("keybindings");
			
			if (bindings.query_exists ()) {
				bindings.delete ();
			}

			DataOutputStream os = new DataOutputStream(bindings.create(FileCreateFlags.REPLACE_DESTINATION));
			uint8[] data;
			long written = 0;
			
			StringBuilder sb = new StringBuilder ();
			
			sb.append_printf ("# BirdFont keybindings\n");
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

	private static uint get_mod_from_key (uint keyval) {
		uint mod = 0;
		mod |= (keyval == Key.CTRL_RIGHT || keyval == Key.CTRL_LEFT) ? CTRL : 0;
		mod |= (keyval == Key.SHIFT_RIGHT || keyval == Key.SHIFT_LEFT) ? SHIFT : 0;
		mod |= (keyval == Key.ALT_LEFT || keyval == Key.ALT_GR) ? ALT : 0;
		return mod;		
	}

	public static void remove_modifier_from_keyval (uint keyval) {
		uint mod = get_mod_from_key (keyval);
		set_modifier (modifier ^ mod);		
	}

	public static void add_modifier_from_keyval (uint keyval) {
		uint mod = get_mod_from_key (keyval);
		set_modifier (modifier | mod);
	}

	public static void set_modifier (uint mod) {
		modifier = mod;

		singleton.modifier_ctrl = ((modifier & CTRL) > 0);
		singleton.modifier_alt = ((modifier & ALT) > 0);
		singleton.modifier_shift = ((modifier & SHIFT) > 0);
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
	}
	
	public void key_press (uint keyval) {
	}
}

}
