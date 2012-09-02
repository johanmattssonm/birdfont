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

/** A sorted table of glyphs with search index. */
class GlyphTable : GLib.Object {
	List<Item> data = new List<Item> ();
	
	List<RowItem> row1 = new List<RowItem> ();
	List<RowItem> row2 = new List<RowItem> ();
	List<RowItem> row3 = new List<RowItem> ();
	
	public GlyphTable () {
	}

	public void remove_all () {
		while (data.length () > 0) {
			data.remove_link (data.first ());
		}
	}

	public void @for_each (Func<GlyphCollection> func) {
		data.foreach ((v) => {
			func (v.glyph_collection);
		});
	}

	unowned List<Item>? find (string n) {
		return find_index (n);
	}

	unowned List<Item>? find_next (string n) {
		return find_next_index (n);
	}
		
	public void remove (string name) {
		unowned List<Item>? d = find (name);
		
		if (d == null) {
			warning (@"did not find $name");
			return;
		}
		
		data.remove_link ((!) d);
		build_index ();
	}

	public GlyphCollection? nth (uint i) {
		unowned List<Item>? d = data.nth (i);
		
		if (d == null) {
			warning (@"no glyph for index $i");
			return null;
		}
		
		return ((!) d).data.glyph_collection;
	}

	public uint length () {
		return data.length ();
	}

	public new GlyphCollection? @get (string name) {
		unowned List<Item>? d = find_index (name);
		
		if (d == null) {
			return null;
		}
		
		return ((!) d).data.glyph_collection;
	}

	public bool insert (GlyphCollection g) {
		Item item;
		unowned List<Item>? next;
		
		if (g.get_name () == "") {
			warning (@"No proper name for glyph collection. g.get_name (): \"$(g.get_name ())\"");
			return false;
		}

		if (find (g.get_name ()) != null) {
			warning (@"Table does already contain character \"$(g.get_name ())\".");
			return false;
		}
				
		next = find_next (g.get_name ());
		
		item = new Item (g.get_name (), g);
		
		if (next == null) {
			data.append (item);
		} else {
			data.insert_before ((!) next, item); // _sorted
		}
		
		build_index ();
		
		if (find (g.get_name ()) == null) {
			warning (@"Can not find glyph \"$(g.get_name ())\".");
			print_all ();
			return false;
		}
		
		return true;
	}

	public void print_all () {
		int indice = 0;
		foreach (Item i in data) {
			print (@"$(i.name) indice: $(indice)\n");
			indice++;
		}
		
		print ("Index:\n");
		print ("\n");
		print ("row3\n");
		foreach (RowItem i in row3) {
			print (@"$(i.item.data.name)\n");
		}
		
		print ("\n");
		print ("row2\n");
		foreach (RowItem i in row2) {
			print (@"$(i.item.data.name)\n");
		}
		
		print ("\n");
		print ("row1\n");
		foreach (RowItem i in row1) {
			print (@"$(i.item.data.name)\n");
		}		
	}

	static int compare (string an, Item b) {
		string? bt = b.glyph_collection.get_name ();
		string bn = (!) bt;
		
		uint32 ac = 0;
		uint32 bc = 0;
				
		int i1 = 0;
		int i2 = 0;
		
		return_if_fail (bt != null);
		
		int ca = an.char_count ();
		int cb = bn.char_count ();
		
		if (ca != cb) {
			return ca < cb ? 1 : -1;
		}
		
		while (true) {
			an.get_next_char (ref i1, out ac);
			bn.get_next_char (ref i2, out bc);
			
			if (ac == bc && ac != 0) {
				continue;
			}
			
			if (ac == bc) return 0;
			
			return (ac < bc) ? 1 : -1;
		}
		
		if (ac == bc) {
			return 0;
		}
		
		return (ac < bc) ? 1 : -1;
	}
	
	public void build_index () {
		uint len;
		RowItem r;
		
		while (row1.length () > 0) {
			row1.remove_link (row1.first ());
		}

		while (row2.length () > 0) {
			row2.remove_link (row2.first ());
		}

		while (row3.length () > 0) {
			row3.remove_link (row3.first ());
		}

		if (data.length () == 0) {
			return;
		}
				
		// row 1
		len = data.length () / 5;
		if (len == 0) len++;
		for (int i = 0; i < len; i++) {
			r = new RowItem ();
			r.item = data.nth (i * 5);
			r.level = 1;
			row1.append (r);
		}
		r = new RowItem ();
		r.item = data.last ();
		r.level = 1;
		r.last = true;
		row1.append (r);	
		
		// row 2
		len = row1.length () / 5;
		if (len == 0) len++;
		for (int i = 0; i < len; i++) {
			r = new RowItem ();
			r.next_row = row1.nth (i * 5);
			r.item = r.next_row.data.item; 
			r.level = 2;
			row2.append (r);
		}
		r = new RowItem ();
		r.item = data.last ();
		r.level = 2;
		r.next_row = row1.last ();		
		r.last = true;
		row2.append (r);
		
		// row 3
		len = row2.length () / 5;
		if (len == 0) len++;
		for (int i = 0; i < len; i++) {
			r = new RowItem ();
			r.next_row = row2.nth (i * 5);
			r.item = r.next_row.data.item; 
			r.level = 3;
			row3.append (r);
		}
		r = new RowItem ();
		r.item = data.last ();
		r.level = 3;
		r.next_row = row2.last ();
		r.last = true;	
		row3.append (r);
	}

	unowned List<Item>? find_next_index (string n) {
		unowned List<Item>? next = find_next_via_index (n);
		return next;
	}

	unowned List<Item>? find_index (string n) {
		unowned List<Item>? next = find_next_via_index (n);
		
		if (next == null) {
			return null;
		}
		
		if (compare (n, ((!)next).data) == 0) {
			return next;
		}
	
		if (((!)next) != data.first () && compare (n, ((!)next).prev.data) == 0) {
			return ((!)next).prev; // fetch previous since we are searching for the next one
		}
				
		return null; 
	}
	
	unowned List<Item>? find_next_via_index (string n) {
		unowned List<Item> i = data.first ();
		unowned List<RowItem> r;
		unowned List<Item> start, stop;
		int cmp;
		
		if (data.length () == 0) {
			return null;
		}

		r = row3.first ();
		int ti = 0;
		while (true) {
			cmp = compare (n, r.data.item.data);
			
			ti++;
			
			if (cmp == 1) {
				break;
			}
			
			if (cmp == 0) {
				return r.data.item;
			}
			
			if (r != row3.last ()) {
				r = r.next;
			} else {
				return null;
			}
		} 
		r = r.data.next_row;

		while (true) {
			cmp = compare (n, r.data.item.data);
			if (cmp == -1) {
				break;
			}

			if (cmp == 0) {
				return r.data.item;
			}
						
			if (r == row2.first ()) {;
				return r.data.item;
			} else r = r.prev;
		}
		r = r.data.next_row;
		
		while (true) {
			cmp = compare (n, r.data.item.data);
			if (cmp == 1) {
				break;
			}
			
			if (cmp == 0) {
				return r.data.item;
			}
								
			if (r == row1.last ()) return null;
			else r = r.next;
		}
		i = r.data.item;
		
		
		while (true) {
			cmp = compare (n, i.data);

			if (cmp == -1) {
				// null?
				return i.next;
			}

			if (cmp == 0) {
				return i;
			}
						
			if (i == data.first ()) {
				return i;
			} else { 
				i = i.prev;
			}
		}
		
		return null;				
	}

	public bool validate_index () {
		int cmp;
		Item prev;
		int index;
		
		if (data.length () == 0) {
			return true;
		}
		
		prev = data.first ().data;
		index = 0;
		foreach (Item i in data) {
			cmp = compare (prev.name, i);
		
			if (cmp == 1) {
				continue;
			}
						
			if (cmp == 0 && index != 0) {
				warning (@"Value is not unique: $(i.name).");
				return false;
			}

			if (cmp == -1) {
				warning (@"Value is not sorted: $cmp == cmp $(prev.name) $(i.name).");
				return false;
			}
			
			index++;
		}
	
		return true;
	}

	class Item : GLib.Object {
		public string name;
		public GlyphCollection glyph_collection;
		
		public Item (string n, GlyphCollection gc) {
			glyph_collection = gc;
			name = n;
		}
	}

	class RowItem : GLib.Object {
		public unowned List<RowItem> next_row;
		public unowned List<Item> item;
		public int level = 0;
		public bool last = false;
	}
}

}
