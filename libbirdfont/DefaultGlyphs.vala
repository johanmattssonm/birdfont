/*
    Copyright (C) 2013 Johan Mattsson

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

/** Default character sets for several languages. */
public class DefaultGlyphs {
	
	public static DefaultLanguages languages;
	
	public static void create_default_character_sets () {
		languages = new DefaultLanguages ();
		
		add_language (_("Default language"), "", "");
		add_language (_("Private use area"), "PRIVATE_USE", "");
		
		add_language (_("Chinese"), "zh", "");
		add_language (_("English"), "en", "A B C D E F G H I J K L M N O P Q R S T U V W X Y Z a b c d e f g h i j k l m n o p q r s t u v w x y z");
		add_language (_("Japanese"), "jp", "");
		add_language (_("Javanese"), "jv", "ꦀ ꦁ ꦂ ꦃ ꦄ ꦅ ꦆ ꦇ ꦈ ꦉ ꦊ ꦋ ꦌ ꦍ ꦎ ꦏ ꦐ ꦑ ꦒ ꦓ ꦔ ꦕ ꦖ ꦗ ꦘ ꦙ ꦚ ꦛ ꦜ ꦝ ꦞ ꦟ ꦠ ꦡ ꦢ ꦣ ꦤ ꦥ ꦦ ꦧ ꦨ ꦩ ꦪ ꦫ ꦬ ꦭ ꦮ ꦯ ꦰ ꦱ ꦲ ꦳ ꦴ ꦵ ꦶ ꦷ ꦸ ꦹ ꦺ ꦻ ꦼ ꦽ ꦾ ꦿ ꧀ ꧁ ꧂ ꧃ ꧄ ꧅ ꧆ ꧇ ꧈ ꧉ ꧊ ꧋ ꧌ ꧍ ꧏ ꧐ ꧑ ꧒ ꧓ ꧔ ꧕ ꧖ ꧗ ꧘ ꧙ ꧞ ꧟ A B C D E F G H I J K L M N O P Q R S T U V W X Y Z a b c d e f g h i j k l m n o p q r s t u v w x y z");
		add_language (_("Russian"), "ro", "А Б В Г Д Е Ё Ж З И Й К Л М Н О П Р С Т У Ф Х Ц Ч Ш Щ Ъ Ы Ь Э Ю Я а б в г д е ё ж з и й к л м н о п р с т у ф х ц ч ш щ ъ ы ь э ю я");
		add_language (_("Swedish"), "sv", "A B C D E F G H I J K L M N O P Q R S T U V W X Y Z Å Ä Ö a b c d e f g h i j k l m n o p q r s t u v w x y z å ä ö");
	}
	
	/** Add a new language to the menu for default character set.
	 * @param language A localized string of the language.
	 * @param language_code ISO code
	 * @param characters all characters and including characters with diacritical marks for the language. For languages with too many glyphs should this string be left empty. See the functions for chinese and japanese.
	 */
	public static void add_language (string language, string language_code, string characters) {
		DefaultLanguages.names.append (language);
		DefaultLanguages.codes.append (language_code);
		DefaultLanguages.characters.append (characters);
	}
	
	/** Add all glyphs for the current locale settings to this glyph range. */
	public static void use_default_range (GlyphRange gr) {
		string language = get_prefered_language_code ();
		
		if (language == "PRIVATE_USE") {
			use_private_area (gr);
		} else if (language.has_prefix ("ja")) {
			use_default_range_japanese (gr);
		} else if (language.has_prefix ("zh")) { // TODO: not just simplified chinese
			use_default_range_chinese (gr);
		} else {
			use_default_range_alphabetic (gr);
		}
	}
	
	private static string get_prefered_language_code () {
		string prefered_language;
		string[] languages = Intl.get_language_names ();
		
		prefered_language = Preferences.get ("language");
		
		if (prefered_language != "") {
			return prefered_language;
		}
		
		if (languages.length == 0) {
			return "";
		}
		
		return languages[0];
	}
	
	public static string get_glyphs_for_prefered_language () {
		string lang = get_prefered_language_code ();
		int i = 0;
		string characters = "";
		
		foreach (unowned string code in DefaultLanguages.codes) {
			if (lang.has_prefix (code)) {
				characters = DefaultLanguages.characters.nth (i).data;
				// Compiler bug, this line causes trouble:
				// return default_characters.nth (i).data;
			}
			i++;
		}
		
		return characters;
	}
	
	private static void use_private_area (GlyphRange gr) {
		gr.add_range (0xe000, 0xf8ff);
	}
	
	private static void use_default_range_alphabetic (GlyphRange gr) {
		string lower_case, upper_case;
		string all_characters;
		
		all_characters = get_glyphs_for_prefered_language ();
		if (all_characters != "") {
			foreach (string c in all_characters.split (" ")) {
				gr.add_single (c.get_char ());
			}
		} else {			
			/// All lower case letters in alphabetic order separated by space
			lower_case = _("a b c d e f g h i j k l m n o p q r s t u v w x y z");
			
			/// All upper case letters in alphabetic order separated by space
			upper_case = _("A B C D E F G H I J K L M N O P Q R S T U V W X Y Z");

			foreach (string c in lower_case.split (" ")) {
				gr.add_single (c.get_char ());
			}

			foreach (string c in upper_case.split (" ")) {
				gr.add_single (c.get_char ());
			}
		}
		
		gr.add_range ('0', '9');
		
		gr.add_single (' '); // TODO: add all spaces here.
		
		gr.add_single ('.');
		gr.add_single ('?');
		
		gr.add_single (',');
		
		gr.add_single ('’');

		gr.add_range ('“', '”');

		gr.add_single ('&');
		
		gr.add_range (':', ';');
		
		gr.add_single ('/'); 
		
		gr.add_range ('!', '/');
		
		gr.add_single ('-');
		gr.add_range ('‐', '—');
		gr.add_range ('<', '@');
		gr.add_range ('(', ')');
	}
	
	public static void  use_default_range_japanese (GlyphRange gr) {
		// hiragana
		gr.add_range ('ぁ', 'ゖ');
		gr.add_range ('゙', 'ゟ');

		// halfwidth and fullwidth forms
		gr.add_range ('!', 'ᄒ');
		gr.add_range ('ￂ', 'ￇ');
		gr.add_range ('ￊ', 'ￏ');
		gr.add_range ('ￒ', 'ￗ');
		gr.add_range ('ￚ', 'ￜ');
		gr.add_range ('¢', '₩');
		gr.add_range ('│', '○');

		// katakana phonetic extensions
		gr.add_range ('ㇰ', 'ㇿ');

		// kana supplement
		gr.add_single ('𛀀');
		gr.add_single ('𛀁');

		// kanbun
		gr.add_range ('㆐', '㆟');
	}
	
	public static void use_default_range_chinese (GlyphRange gr) {
		string pinyin_tones;
		
		// pinyin
		pinyin_tones  = "ˇ ˉ ˊ ˋ ˙ ā á ǎ à ō ó ǒ ò ē é ě è ī í ǐ ì ū ú ǔ ù ǖ ǘ ǚ ǜ ü Ā Á Ǎ À Ō Ó Ǒ Ò Ē É Ě È";
		gr.add_range ('a', 'z');
		
		foreach (string c in pinyin_tones.split (" ")) {
			gr.add_single (c.get_char ());
		}		

		// CJK punctuations and symbols
		gr.add_range ('　', '々');
		gr.add_range ('〇', '】');
		gr.add_range ('〓', '〟');
		gr.add_range ('︐', '︙'); 

		// CJK numbers and months
		gr.add_range ('0', '9');
		gr.add_range ('㈠', '㈩');
		gr.add_range ('㋀', '㋋');
		gr.add_range ('㉑', '㉟');
		gr.add_range ('㊱', '㊿');
		gr.add_range ('㊀', '㊉');

		// CJK fullwidth letters and symbols
		gr.add_range ('！', '･');
		gr.add_range ('￠', '￦');
		gr.add_single ('￨');

		// CJK special characters
		gr.add_range ('㍘', '㏿');
		gr.add_range ('㋌', '㋏');

		// CJK strokes
		gr.add_range ('㇀', '㇢');

		// CJK supplements
		gr.add_range ('⺀', '⺙');
		gr.add_range ('⺛', '⻳');

		// GB2312 (punctuations)
		gr.add_single ('―');
		gr.add_single ('¤');
		gr.add_single ('§');
		gr.add_single ('¨');
		gr.add_single ('°');
		gr.add_single ('±');
		gr.add_single ('×');
		gr.add_single ('÷');

		// GB2312 (greek letters)
		gr.add_range ('Α', 'Ω');
		gr.add_range ('α', 'ω');

		// GB2312 (cyrillic letters)
		gr.add_range ('А', 'я');
		gr.add_single ('ё');
		gr.add_single ('Ё');
		
		// GB2312 (U+4e00 to U+fa20)
		gr.add_range ('一', '龥');
		gr.add_single ('郎');
		gr.add_single ('凉');
		gr.add_single ('秊');
		gr.add_single ('裏');
		gr.add_single ('隣');
		
		gr.add_range ('兀', '﨏');
		gr.add_single ('﨑');
		gr.add_single ('﨓');
		gr.add_single ('﨔');
		gr.add_single ('礼');
		gr.add_single ('﨟');
		gr.add_single ('蘒');
		gr.add_single ('﨡');
		gr.add_single ('﨣');
		gr.add_single ('﨤');
		gr.add_single ('﨧');
		gr.add_single ('﨨');
		gr.add_single ('﨩');
	}
	
	public static void use_full_unicode_range (GlyphRange gr) {
		CharDatabase.get_full_unicode (gr);
		
		if (gr.get_length () == 0) {
			gr.add_range ('\0', (unichar) 0xFFF8);
		}
	}
}

public class DefaultLanguages {
 	public static List<string> names;
	public static List<string> codes;
	public static List<string> characters;
	
	public DefaultLanguages () {
		names = new List<string> ();
		codes = new List<string> ();
		characters = new List<string> ();		
	}
}

}
