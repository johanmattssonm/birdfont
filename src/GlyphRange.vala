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

class GlyphRange {
	
	List<UniRange> ranges;
	List<unichar> index_start;

	public List<unowned string> unassigned;
	
	unichar len = 0;
	
	public bool is_fill_unicode = false;
	
	public GlyphRange () {
	}
	
	public void use_default_range () {
		add_range ('a', 'z');

		add_single ('å');
		add_single ('ä');
		add_single ('ö');

		add_range ('A', 'Z');

		add_single ('Å');
		add_single ('Ä');
		add_single ('Ö');
		
		add_range ('0', '9');
		
		add_single (' '); // TODO: add all spaces here.
		
		add_single ('.');
		add_single ('?');
		
		add_single (',');
		
		add_single ('’');

		add_range ('“', '”');

		add_single ('&');
		
		add_range (':', ';');
		
		add_single ('/'); 
		
		add_range ('!', '/');
		
		add_single ('-');
		add_range ('‐', '—');
		add_range ('<', '@');
		add_range ('(', ')');
	}
	
	public void use_full_unicode_range () {
		is_fill_unicode = true;
		add_range ('\0', (unichar) 0xA868FE00);
	}
	
	// Todo: complete localized alphabetical sort åäö is the right order for example.
	public void sort () {
		ranges.sort ((a, b) => {
			bool r = a.start > b.start;
			
			return_if_fail (a.start != b.start);
			
			return (r) ? 1 : -1;
		});
	}
	
	public void add_single (unichar c) {
		add_range (c, c);
	}
	
	public unichar get_length () {
		return len + unassigned.length ();
	}
	
	public void add_range (unichar start, unichar stop) {
		if (unique (start, stop)) {
			insert_range(start, stop);
		} else {
			
			unichar b = start;
			unichar s = b;
			while (b < stop) {
				if (unique (b, b)) {
					b++;
				} else {
					if (s != b) {
						insert_range(s, b - 1);
					}
					
					b++;
					s = b;
				}
			}
		}
		
	}

	public string get_char (unichar index) {
		int i = 0;
		unichar next = 0;

		foreach (unichar s in index_start) {
			StringBuilder sbt = new StringBuilder ();
			
			if (!s.validate () && s >= index) {
				sbt.append_unichar (s);
				break;
			} else if (s >= index) {
				sbt.append_unichar (s);
				break;
			}
			
			next = s;
			i++;
		}

		if (index == 0 || !(0 <= i < ranges.length ())) {
			if (index > ranges.length ()) {
				i = (int) (index - ranges.length ());
				
				if (i >= unassigned.length ()) {
					return "\0".dup();
				}
				
				return unassigned.nth (i).data.dup();
			}
		}

		UniRange u = ranges.nth_data (i);
		StringBuilder sb = new StringBuilder ();
		unichar c = u.get_char (index - next - 1);
		
		sb.append_unichar (c);

		return sb.str;
	}
	
	public unichar length () {
		return len;
	}

	private bool unique (unichar start, unichar stop) {
		foreach (UniRange u in ranges) {
			
			if (inside (start, u.start, u.stop)) return false;
			if (inside (stop, u.start, u.stop)) return false;
			if (inside (u.start, start, stop)) return false;
			if (inside (u.stop, start, stop)) return false;

		}

		return true;
	}

	private bool inside (unichar start, unichar u_start, unichar u_stop) {
		return (u_start <= start <= u_stop);
	}
	
	private void insert_range (unichar start, unichar stop) {
		if (unlikely (start > stop)) {
			warning ("start > stop");
			return;
		}
		
		UniRange ur = new UniRange (start, stop);
		len += ur.length ();
		index_start.append (len);
		ranges.append (ur);
	}

class UniRange : GLib.Object {
	
	public unichar start;
	public unichar stop;
	
	public UniRange (unichar start, unichar stop) {
		this.start = start;
		this.stop = stop;
	}
	
	public unichar length () {
		return stop - start + 1;
	}

	public unichar get_char (unichar index) {
		unichar result = start + index;
		
		if (unlikely (index < 0)) {
			warning ("Index is negative in UniRange.");
		}
		
		if (unlikely (!(start <= result <= stop))) {
			warning ("Index out of range in UniRange (%u <= %u <= %u) (index: %u)\n", start, result, stop, index);
		}
		
		return result;
	}
}
	
}

}
