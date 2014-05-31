/*
    Copyright (C) 2013 Johan Mattsson

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

/** Default character sets for several languages. */
public class DefaultCharacterSet {
	
	public static DefaultLanguages languages;
	
	public static void create_default_character_sets () {
		languages = new DefaultLanguages ();
		
		add_language (t_("Default language"), "", "");
		add_language (t_("Private use area"), "PRIVATE_USE", "");
		
		add_language (t_("Chinese"), "zh", "");
		add_language (t_("English"), "en", "A B C D E F G H I J K L M N O P Q R S T U V W X Y Z a b c d e f g h i j k l m n o p q r s t u v w x y z");
		add_language (t_("Greek"), "el", "Α Β Γ Δ Ε Ζ Η Θ Ι Κ Λ Μ Ν Ξ Ο Π Ρ Σ Τ Υ Φ Χ Ψ Ω α β γ δ ε ζ η θ ι κ λ μ ν ξ ο π ρ σ ς τ υ φ χ ψ ω");
		add_language (t_("Japanese"), "ja", "");
		add_language (t_("Javanese"), "jv", "ꦀ ꦁ ꦂ ꦃ ꦄ ꦅ ꦆ ꦇ ꦈ ꦉ ꦊ ꦋ ꦌ ꦍ ꦎ ꦏ ꦐ ꦑ ꦒ ꦓ ꦔ ꦕ ꦖ ꦗ ꦘ ꦙ ꦚ ꦛ ꦜ ꦝ ꦞ ꦟ ꦠ ꦡ ꦢ ꦣ ꦤ ꦥ ꦦ ꦧ ꦨ ꦩ ꦪ ꦫ ꦬ ꦭ ꦮ ꦯ ꦰ ꦱ ꦲ ꦳ ꦴ ꦵ ꦶ ꦷ ꦸ ꦹ ꦺ ꦻ ꦼ ꦽ ꦾ ꦿ ꧀ ꧁ ꧂ ꧃ ꧄ ꧅ ꧆ ꧇ ꧈ ꧉ ꧊ ꧋ ꧌ ꧍ ꧏ ꧐ ꧑ ꧒ ꧓ ꧔ ꧕ ꧖ ꧗ ꧘ ꧙ ꧞ ꧟ A B C D E F G H I J K L M N O P Q R S T U V W X Y Z a b c d e f g h i j k l m n o p q r s t u v w x y z");
		add_language (t_("Russian"), "ro", "А Б В Г Д Е Ё Ж З И Й К Л М Н О П Р С Т У Ф Х Ц Ч Ш Щ Ъ Ы Ь Э Ю Я а б в г д е ё ж з и й к л м н о п р с т у ф х ц ч ш щ ъ ы ь э ю я");
		add_language (t_("Swedish"), "sv", "A B C D E F G H I J K L M N O P Q R S T U V W X Y Z Å Ä Ö a b c d e f g h i j k l m n o p q r s t u v w x y z å ä ö");
	}
	
	/** Add a new language to the menu for default character set.
	 * @param language A localized string for the name of the language.
	 * @param language_code ISO code
	 * @param characters all characters (including characters with diacritical marks).
	 * For languages with too many glyphs should this string be left empty. 
	 * See the functions for chinese and japanese.
	 */
	public static void add_language (string language, string language_code, string characters) {
		DefaultLanguages.names.add (language);
		DefaultLanguages.codes.add (language_code);
		DefaultLanguages.characters.add (characters);
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
	
	public static string get_characters_for_prefered_language () {
		string lang = get_prefered_language_code ();
		int i = 0;
		string characters = "";
		
		foreach (string code in DefaultLanguages.codes) {
			if (lang.has_prefix (code)) {
				characters = DefaultLanguages.characters.get (i);
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
		
		all_characters = get_characters_for_prefered_language ();
		if (all_characters != "") {
			foreach (string c in all_characters.split (" ")) {
				gr.add_single (c.get_char ());
			}
		} else {			
			/// All lower case letters in alphabetic order separated by space
			lower_case = t_("a b c d e f g h i j k l m n o p q r s t u v w x y z");
			
			/// All upper case letters in alphabetic order separated by space
			upper_case = t_("A B C D E F G H I J K L M N O P Q R S T U V W X Y Z");

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
			try {
				gr.parse_ranges ("null-ͷ ͺ-; ΄-Ί Ό Ύ-Ρ Σ-ԧ Ա-Ֆ ՙ-՟ ա-և ։-֊ ֏ ֑-ׇ א-ת װ-״ ؀-؄ ؆-؛ ؞-܍ ܏-݊ ݍ-ޱ ߀-ߺ ࠀ-࠭ ࠰-࠾ ࡀ-࡛ ࡞ ࢠ ࢢ-ࢬ ࣤ-ࣾ ऀ-ॷ ॹ-ॿ ঁ-ঃ অ-ঌ এ-ঐ ও-ন প-র ল শ-হ ়-ৄ ে-ৈ ো-ৎ ৗ ড়-ঢ় য়-৻ ਁ-ਃ ਅ-ਊ ਏ-ਐ ਓ-ਨ ਪ-ਰ ਲ-ਲ਼ ਵ-ਸ਼ ਸ-ਹ ਼ ਾ-ੂ ੇ-ੈ ੋ-੍ ੑ ਖ਼-ੜ ਫ਼ ੤-ੵ ઁ-ઃ અ-ઍ એ-ઑ ઓ-ન પ-ર લ-ળ વ-હ ઼-ૅ ે-ૉ ો-્ ૐ ૠ-૱ ଁ-ଃ ଅ-ଌ ଏ-ଐ ଓ-ନ ପ-ର ଲ-ଳ ଵ-ହ ଼-ୄ େ-ୈ ୋ-୍ ୖ-ୗ ଡ଼-ଢ଼ ୟ-୷ ஂ-ஃ அ-ஊ எ-ஐ ஒ-க ங-ச ஜ ஞ-ட ண-த ந-ப ம-ஹ ா-ூ ெ-ை ொ-் ௐ ௗ ௤-௺ ఁ-ః అ-ఌ ఎ-ఐ ఒ-న ప-ళ వ-హ ఽ-ౄ ె-ై ొ-్ ౕ-ౖ ౘ-ౙ ౠ-౯ ౸-౿ ಂ-ಃ ಅ-ಌ ಎ-ಐ ಒ-ನ ಪ-ಳ ವ-ಹ ಼-ೄ ೆ-ೈ ೊ-್ ೕ-ೖ ೞ ೠ-೯ ೱ-ೲ ം-ഃ അ-ഌ എ-ഐ ഒ-ഺ ഽ-ൄ െ-ൈ ൊ-ൎ ൗ ൠ-൵ ൹-ൿ ං-ඃ අ-ඖ ක-න ඳ-ර ල ව-ෆ ් ා-ු ූ ෘ-ෟ ෲ-෴ ก-ฺ ฿-๛ ກ-ຂ ຄ ງ-ຈ ຊ ຍ ດ-ທ ນ-ຟ ມ-ຣ ລ ວ ສ-ຫ ອ-ູ ົ-ຽ ເ-ໄ ໆ ່-ໍ ໐-໙ ໜ-ໟ ༀ-ཇ ཉ-ཬ ཱ-ྗ ྙ-ྼ ྾-࿌ ࿎-࿚ က-Ⴥ Ⴧ Ⴭ ა-ቈ ቊ-ቍ ቐ-ቖ ቘ ቚ-ቝ በ-ኈ ኊ-ኍ ነ-ኰ ኲ-ኵ ኸ-ኾ ዀ ዂ-ዅ ወ-ዖ ዘ-ጐ ጒ-ጕ ጘ-ፚ ፝-፼ ᎀ-᎙ Ꭰ-Ᏼ ᐀-᚜ ᚠ-ᛰ ᜀ-ᜌ ᜎ-᜔ ᜠ-᜶ ᝀ-ᝓ ᝠ-ᝬ ᝮ-ᝰ ᝲ-ᝳ ក-៝ ០-៩ ៰-៹ ᠀-᠎ ᠐-᠙ ᠠ-ᡷ ᢀ-ᢪ ᢰ-ᣵ ᤀ-ᤜ ᤠ-ᤫ ᤰ-᤻ ᥀ ᥄-ᥭ ᥰ-ᥴ ᦀ-ᦫ ᦰ-ᧉ ᧐-᧚ ᧞-ᨛ ᨞-ᩞ ᩠-᩼ ᩿-᪉ ᪐-᪙ ᪠-᪭ ᬀ-ᭋ ᭐-᭼ ᮀ-᯳ ᯼-᰷ ᰻-᱉ ᱍ-᱿ ᳀-᳇ ᳐-ᳶ ᴀ-ᷦ ᷼-ἕ Ἐ-Ἕ ἠ-ὅ Ὀ-Ὅ ὐ-ὗ Ὑ Ὓ Ὕ Ὗ-ώ ᾀ-ᾴ ᾶ-ῄ ῆ-ΐ ῖ-Ί ῝-` ῲ-ῴ ῶ-῾  -⁤ ⁪-₎ ₐ-ₜ ₠-₹ ⃐-⃰ ℀-↉ ←-⏳ ␀-␦ ⑀-⑊ ①-⛿ ✁-⭌ ⭐-⭙ Ⰰ-Ⱞ ⰰ-ⱞ Ⱡ-ⳳ ⳹-ⴥ ⴧ ⴭ ⴰ-ⵧ ⵯ-⵰ ⵿-ⶖ ⶠ-ⶦ ⶨ-ⶮ ⶰ-ⶶ ⶸ-ⶾ ⷀ-ⷆ ⷈ-ⷎ ⷐ-ⷖ ⷘ-ⷞ ⷠ-⸻ ⺀-⺙ ⺛-⻳ ⼀-⿕ ⿰-⿻ 　-〿 ぁ-ゖ ゙-ヿ ㄅ-ㄭ ㄱ-ㆎ ㆐-ㆺ ㇀-㇣ ㇰ-㈞ ㈠-㋾ ㌀-㏿ ䷀-䷿ ꀀ-ꒌ ꒐-꓆ ꓐ-ꘫ Ꙁ-ꚗ ꚟ-꛷ ꜀-ꞎ Ꞑ-ꞓ Ꞡ-Ɦ ꟸ-꠫ ꠰-꠹ ꡀ-꡷ ꢀ-꣄ ꣎-꣙ ꣠-ꣻ ꤀-꥓ ꥟-ꥼ ꦀ-꧍ ꧏ-꧙ ꧞-꧟ ꨀ-ꨶ ꩀ-ꩍ ꩐-꩙ ꩜-ꩻ ꪀ-ꫂ ꫛ-꫶ ꬁ-ꬆ ꬉ-ꬎ ꬑ-ꬖ ꬠ-ꬦ ꬨ-ꬮ ꯀ-꯭ ꯰-꯹ ힰ-ퟆ ퟋ-ퟻ 豈-舘 並-龎 ﬀ-ﬆ ﬓ-ﬗ יִ-זּ טּ-לּ מּ נּ-סּ ףּ-פּ צּ-﯁ ﯓ-﴿ ﵐ-ﶏ ﶒ-ﷇ ﷰ-﷽ ︀-︙ ︠-︦ ︰-﹒ ﹔-﹦ ﹨-﹫ ﹰ-ﹴ ﹶ-ﻼ ！-ﾾ ￂ-ￇ ￊ-ￏ ￒ-ￗ ￚ-ￜ ￠-￦ ￨-￮ ￹-� 𐀀-𐀋 𐀍-𐀦 𐀨-𐀺 𐀼-𐀽 𐀿-𐁍 𐁐-𐁝 𐂀-𐃺 𐄀-𐄂 𐄇-𐄳 𐄷-𐆊 𐆐-𐆛 𐇐-𐇽 𐊀-𐊜 𐊠-𐋐 𐌀-𐌞 𐌠-𐌣 𐌰-𐍊 𐎀-𐎝 𐎟-𐏃 𐏈-𐏕 𐐀-𐒝 𐒠-𐒩 𐠀-𐠅 𐠈 𐠊-𐠵 𐠷-𐠸 𐠼 𐠿-𐡕 𐡗-𐡟 𐤀-𐤛 𐤟-𐤹 𐤿 𐦀-𐦷 𐦾-𐦿 𐨀-𐨃 𐨅-𐨆 𐨌-𐨓 𐨕-𐨗 𐨙-𐨳 𐨸-𐨺 𐨿-𐩇 𐩐-𐩘 𐩠-𐩿 𐬀-𐬵 𐬹-𐭕 𐭘-𐭲 𐭸-𐭿 𐰀-𐱈 𐹠-𐹾 𑀀-𑁍 𑁒-𑁯 𑂀-𑃁 𑃐-𑃨 𑃰-𑃹 𑄀-𑄴 𑄶-𑅃 𑆀-𑇈 𑇐-𑇙 𑚀-𑚷 𑛀-𑛉 𒀀-𒍮 𒐀-𒑢 𒑰-𒑳 𓀀-𓐮 𖠀-𖨸 𖼀-𖽄 𖽐-𖽾 𖾏-𖾟 𛀀-𛀁 𝀀-𝃵 𝄀-𝄦 𝄩-𝇝 𝈀-𝉅 𝌀-𝍖 𝍠-𝍱 𝐀-𝚥 𝚨-𝟋 𝟎-𝟿 𞸀-𞸃 𞸅-𞸟 𞸡-𞸢 𞸤 𞸧 𞸩-𞸲 𞸴-𞸷 𞸹 𞸻 𞹂 𞹇 𞹉 𞹋 𞹍-𞹏 𞹑-𞹒 𞹔 𞹗 𞹙 𞹛 𞹝 𞹟 𞹡-𞹢 𞹤 𞹧-𞹪 𞹬-𞹲 𞹴-𞹷 𞹹-𞹼 𞹾 𞺀-𞺉 𞺋-𞺛 𞺡-𞺣 𞺥-𞺩 𞺫-𞺻 𞻰-𞻱 🀀-🀫 🀰-🂓 🂠-🂮 🂱-🂾 🃁-🃏 🃑-🃟 🄀-🄊 🄐-🄮 🄰-🅫 🅰-🆚 🇦-🈂 🈐-🈺 🉀-🉈 🉐-🉑 🌀-🌠 🌰-🌵 🌷-🍼 🎀-🎓 🎠-🏄 🏆-🏊 🏠-🏰 🐀-🐾 👀 👂-📷 📹-📼 🔀-🔽 🕀-🕃 🕐-🕧 🗻-🙀 🙅-🙏 🚀-🛅 🜀-🝳 丽-𪘀 󠀁 󠀠-󠁿 󠄀-󠇯");
			} catch (MarkupError e) {
				warning (e.message);
				gr.add_range ('\0', (unichar) 0xFFF8);
			}
		}
	}
	
	public static DefaultLanguages get_default_languages () {
		return languages;
	}
}

public class DefaultLanguages {
	public static Gee.ArrayList<string> names;
	public static Gee.ArrayList<string> codes;
	public static Gee.ArrayList<string> characters;
	
	public DefaultLanguages () {
		names = new Gee.ArrayList<string> ();
		codes = new Gee.ArrayList<string> ();
		characters = new Gee.ArrayList<string> ();		
	}

	public string? get_name (int index) {
		if (0 <= index < names.size) {
			return names.get (index);
		}
		
		return null;
	}

	public string? get_code (int index) {
		if (0 <= index < codes.size) {
			return codes.get (index);
		}
		
		return null;
	}
}

}
