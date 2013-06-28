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

namespace BirdFont {

public class GlyphRange {
	
	List<UniRange> ranges;
	
	public unowned List<string> unassigned = new List<string> ();
	
	uint32 len = 0;
	
	public GlyphRange () {
	}
		
	public unowned List<UniRange> get_ranges () {
		return ranges;
	}
	
	public void use_default_range () {
		string[] languages = Intl.get_language_names ();
		
		if (languages.length == 0) {
			use_default_range_alphabetic ();
			return;
		}
		
		if (languages[0].has_prefix ("ja")) {
			use_default_range_japanese ();
		} else if (languages[0].has_prefix ("zh_CN")) {
			use_default_range_chinese ();
		} else {
			use_default_range_alphabetic ();
		}
	}
	
	public void use_default_range_alphabetic () {
		string lower_case, upper_case;
						
		/// All lower case letters and letters with diacritical marks in alphabetic order separated by space
		lower_case = _("a b c d e f g h i j k l m n o p q r s t u v w x y z");
		
		/// All upper case letters and letters with diacritical marks in alphabetic order separated by space
		upper_case = _("A B C D E F G H I J K L M N O P Q R S T U V W X Y Z");

		foreach (string c in lower_case.split (" ")) {
			add_single (c.get_char ());
		}

		foreach (string c in upper_case.split (" ")) {
			add_single (c.get_char ());
		}
				
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
	
	public void  use_default_range_japanese () {
		// hiragana
		add_range ('ぁ', 'ゖ');
		add_range ('゙', 'ゟ');

		// halfwidth and fullwidth forms
		add_range ('!', 'ᄒ');
		add_range ('ￂ', 'ￇ');
		add_range ('ￊ', 'ￏ');
		add_range ('ￒ', 'ￗ');
		add_range ('ￚ', 'ￜ');
		add_range ('¢', '₩');
		add_range ('│', '○');

		// katakana phonetic extensions
		add_range ('ㇰ', 'ㇿ');

		// kana supplement
		add_single ('𛀀');
		add_single ('𛀁');

		// kanbun
		add_range ('㆐', '㆟');
	}
	
	public void use_default_range_chinese () {
		string pinyin_tones;
		
		// pinyin
		pinyin_tones  = "ˇ ˉ ˊ ˋ ˙ ā á ǎ à ō ó ǒ ò ē é ě è ī í ǐ ì ū ú ǔ ù ǖ ǘ ǚ ǜ ü Ā Á Ǎ À Ō Ó Ǒ Ò Ē É Ě È";
		add_range ('a', 'z');
		
		foreach (string c in pinyin_tones.split (" ")) {
			add_single (c.get_char ());
		}		

		// CJK punctuations and symbols
		add_range ('　', '々');
		add_range ('〇', '】');
		add_range ('〓', '〟');
		add_range ('︐', '︙'); 

		// CJK numbers and months
		add_range ('0', '9');
		add_range ('㈠', '㈩');
		add_range ('㋀', '㋋');
		add_range ('㉑', '㉟');
		add_range ('㊱', '㊿');
		add_range ('㊀', '㊉');

		// CJK fullwidth letters and symbols
		add_range ('！', '･');
		add_range ('￠', '￦');
		add_single ('￨');

		// CJK special characters
		add_range ('㍘', '㏿');
		add_range ('㋌', '㋏');

		// CJK strokes
		add_range ('㇀', '㇢');

		// CJK supplements
		add_range ('⺀', '⺙');
		add_range ('⺛', '⻳');

		// GB2312 (punctuations)
		add_single ('―');
		add_single ('¤');
		add_single ('§');
		add_single ('¨');
		add_single ('°');
		add_single ('±');
		add_single ('×');
		add_single ('÷');

		// GB2312 (greek letters)
		add_range ('Α', 'Ω');
		add_range ('α', 'ω');

		// GB2312 (cyrillic letters)
		add_range ('А', 'я');
		add_single ('ё');
		add_single ('Ё');
		
		// GB2312 (U+4e00 to U+fa20)
		add_range ('一', '龥');
		add_single ('郎');
		add_single ('凉');
		add_single ('秊');
		add_single ('裏');
		add_single ('隣');
		
		add_range ('兀', '﨏');
		add_single ('﨑');
		add_single ('﨓');
		add_single ('﨔');
		add_single ('礼');
		add_single ('﨟');
		add_single ('蘒');
		add_single ('﨡');
		add_single ('﨣');
		add_single ('﨤');
		add_single ('﨧');
		add_single ('﨨');
		add_single ('﨩');
	}
	
	public void use_full_unicode_range () {
		CharDatabase.get_full_unicode (this);
		
		if (len == 0) {
			add_range ('\0', (unichar) 0xFFF8);
		}
	}
	
	// Todo: complete localized alphabetical sort åäö is the right order for example.
	public void sort () {
		ranges.sort ((a, b) => {
			bool r = a.start > b.start;
			return_val_if_fail (a.start != b.start, 0);
			return (r) ? 1 : -1;
		});
	}
	
	public void add_single (unichar c) {
		add_range (c, c);
	}
	
	public uint32 get_length () {
		unichar l = len;
		l += unassigned.length ();
		return l;
	}
	
	public void add_range (unichar start, unichar stop) {
		unichar b, s;
		if (unique (start, stop)) {
			append_range (start, stop);
		} else {
			
			// make sure this range does not overlap existing ranges
			b = start;
			s = b;
			if (!unique (b, b)) {			
				while (b < stop) {
					if (!unique (b, b)) {
						b++;
					} else {
						if (s != b) {
							add_range (b, stop);
						}
						
						b++;
						s = b;
					}
				}
			} else {
				while (b < stop) {
					if (unique (b, b)) {
						b++;
					} else {
						if (s != b) {
							add_range (start, b - 1);
						}
						
						b++;
						s = b;
					}
				}				
			}
		}
	}
	
	private void append_range (unichar start, unichar stop) {
		UniRange r;
		StringBuilder s = new StringBuilder ();
		StringBuilder e = new StringBuilder ();
		
		s.append_unichar (start);
		e.append_unichar (stop);
		
		r = insert_range (start, stop); // insert a unique range
		merge_range (r); // join connecting ranges
	}
	
	private void merge_range (UniRange r) {
		foreach (UniRange u in ranges) {
			if (u == r) {
				continue;
			}			
			
			if (u.start == r.stop + 1) {
				u.start = r.start;
				ranges.remove_all (r);
				merge_range (u);
			}
			
			if (u.stop == r.start - 1) {
				u.stop = r.stop;
				ranges.remove_all (r);
				merge_range (u);
			}
		}
	}

	public string get_char (uint32 index) {
		int64 ti;
		string chr;
		UniRange r;
		StringBuilder sb;
		unichar c;
		
		if (index > len + unassigned.length ()) { 
			return "\0".dup();
		}
		
		if (index >= len) {
			
			if (index - len >= unassigned.length ()) {
				return "\0".dup();
			} 
			
			chr = ((!) unassigned.nth (index - len)).data;
			return chr;
		}

		r = ranges.first ().data;
		ti = index;

		foreach (UniRange u in ranges) {
			ti -= u.length ();
			
			if (ti < 0) {
				r = u;
				break;
			}
		}
				
		sb = new StringBuilder ();
		c = r.get_char ((unichar) (ti + r.length ()));
		sb.append_unichar (c);

		return sb.str;
	}
	
	public uint32 length () {
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
	
	private UniRange insert_range (unichar start, unichar stop) {
		if (unlikely (start > stop)) {
			warning ("start > stop");
			stop = start;
		}
		
		UniRange ur = new UniRange (start, stop);
		len += ur.length ();
		ranges.append (ur);
		
		return ur;
	}

	public void print_all () {
		stdout.printf ("Ranges:\n");
		stdout.printf (get_all_ranges ());
	}
	
	public string get_all_ranges () {
		StringBuilder s = new StringBuilder ();
		foreach (UniRange u in ranges) {
			s.append (Font.to_hex_code (u.start));
			s.append (" - ");
			s.append (Font.to_hex_code (u.stop));
			s.append ("\n");
		}
		return s.str;
	}
}

}
