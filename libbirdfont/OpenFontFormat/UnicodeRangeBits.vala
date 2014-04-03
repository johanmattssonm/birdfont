/*
    Copyright (C) 2014 Johan Mattsson

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

public class UnicodeRangeBits : GLib.Object {
	
	string ranges = """0 Basic Latin 0000-007F
1 Latin-1 Supplement 0080-00FF
2 Latin Extended-A 0100-017F
3 Latin Extended-B 0180-024F
4 IPA Extensions 0250-02AF
Phonetic Extensions 1D00-1D7F
Phonetic Extensions Supplement 1D80-1DBF
Spacing Modifier Letters 02B0-02FF
Modifier Tone Letters A700-A71F
Combining Diacritical Marks 0300-036F
Combining Diacritical Marks Supplement 1DC0-1DFF
7 Greek and Coptic 0370-03FF
8 Coptic 2C80-2CFF
9 Cyrillic 0400-04FF
Cyrillic Supplement 0500-052F
Cyrillic Extended-A 2DE0-2DFF
Cyrillic Extended-B A640-A69F
10 Armenian 0530-058F
11 Hebrew 0590-05FF
12 Vai A500-A63F
13 Arabic 0600-06FF
Arabic Supplement 0750-077F
14 NKo 07C0-07FF
15 Devanagari 0900-097F
16 Bengali 0980-09FF
17 Gurmukhi 0A00-0A7F
18 Gujarati 0A80-0AFF
19 Oriya 0B00-0B7F
20 Tamil 0B80-0BFF
21 Telugu 0C00-0C7F
22 Kannada 0C80-0CFF
23 Malayalam 0D00-0D7F
24 Thai 0E00-0E7F
25 Lao 0E80-0EFF
26 Georgian 10A0-10FF
Georgian Supplement 2D00-2D2F
27 Balinese 1B00-1B7F
28 Hangul Jamo 1100-11FF
29 Latin Extended Additional 1E00-1EFF
Latin Extended-C 2C60-2C7F
Latin Extended-D A720-A7FF
30 Greek Extended 1F00-1FFF
31 General Punctuation 2000-206F
Supplemental Punctuation 2E00-2E7F
32 Superscripts And Subscripts 2070-209F
33 Currency Symbols 20A0-20CF
34 Combining Diacritical Marks For Symbols 20D0-20FF
35 Letterlike Symbols 2100-214F
36 Number Forms 2150-218F
37 Arrows 2190-21FF
Supplemental Arrows-A 27F0-27FF
Supplemental Arrows-B 2900-297F
Miscellaneous Symbols and Arrows 2B00-2BFF
Mathematical Operators 2200-22FF
Supplemental Mathematical Operators 2A00-2AFF
Miscellaneous Mathematical Symbols-A 27C0-27EF
Miscellaneous Mathematical Symbols-B 2980-29FF
39 Miscellaneous Technical 2300-23FF
40 Control Pictures 2400-243F
41 Optical Character Recognition 2440-245F
42 Enclosed Alphanumerics 2460-24FF
43 Box Drawing 2500-257F
44 Block Elements 2580-259F
45 Geometric Shapes 25A0-25FF
46 Miscellaneous Symbols 2600-26FF
47 Dingbats 2700-27BF
48 CJK Symbols And Punctuation 3000-303F
49 Hiragana 3040-309F
50 Katakana 30A0-30FF
Katakana Phonetic Extensions 31F0-31FF
Bopomofo 3100-312F
Bopomofo Extended 31A0-31BF
52 Hangul Compatibility Jamo 3130-318F
53 Phags-pa A840-A87F
54 Enclosed CJK Letters And Months 3200-32FF
55 CJK Compatibility 3300-33FF
56 Hangul Syllables AC00-D7AF
57 Non-Plane 0 * D800-DFFF
58 Phoenician 10900-1091F
59 CJK Unified Ideographs 4E00-9FFF
CJK Radicals Supplement 2E80-2EFF
Kangxi Radicals 2F00-2FDF
Ideographic Description Characters 2FF0-2FFF
CJK Unified Ideographs Extension A 3400-4DBF
CJK Unified Ideographs Extension B 20000-2A6DF
Kanbun 3190-319F
60 Private Use Area (plane 0) E000-F8FF
61 CJK Strokes 31C0-31EF
CJK Compatibility Ideographs F900-FAFF
CJK Compatibility Ideographs Supplement 2F800-2Fa1F
Alphabetic Presentation Forms FB00-FB4F
63 Arabic Presentation Forms-A FB50-FDFF
64 Combining Half Marks FE20-FE2F
65 Vertical Forms FE10-FE1F
CJK Compatibility Forms FE30-FE4F
66 Small Form Variants FE50-FE6F
67 Arabic Presentation Forms-B FE70-FEFF
68 Halfwidth And Fullwidth Forms FF00-FFEF
69 Specials FFF0-FFFF
70 Tibetan 0F00-0FFF
71 Syriac 0700-074F
72 Thaana 0780-07BF
73 Sinhala 0D80-0DFF
74 Myanmar 1000-109F
75 Ethiopic 1200-137F
Ethiopic Supplement 1380-139F
Ethiopic Extended 2D80-2DDF
76 Cherokee 13A0-13FF
77 Unified Canadian Aboriginal Syllabics 1400-167F
78 Ogham 1680-169F
79 Runic 16A0-16FF
80 Khmer 1780-17FF
Khmer Symbols 19E0-19FF
81 Mongolian 1800-18AF
82 Braille Patterns 2800-28FF
83 Yi Syllables A000-A48F
Yi Radicals A490-A4CF
Tagalog 1700-171F
Hanunoo 1720-173F
Buhid 1740-175F
Tagbanwa 1760-177F
85 Old Italic 10300-1032F
86 Gothic 10330-1034F
87 Deseret 10400-1044F
88 Byzantine Musical Symbols 1D000-1D0FF
Musical Symbols 1D100-1D1FF
Ancient Greek Musical Notation 1D200-1D24F
89 Mathematical Alphanumeric Symbols 1D400-1D7FF
90 Private Use (plane 15) FF000-FFFFD
Private Use (plane 16) 100000-10FFFD
Variation Selectors FE00-FE0F
Variation Selectors Supplement E0100-E01EF
92 Tags E0000-E007F
93 Limbu 1900-194F
94 Tai Le 1950-197F
95 New Tai Lue 1980-19DF
96 Buginese 1A00-1A1F
97 Glagolitic 2C00-2C5F
98 Tifinagh 2D30-2D7F
99 Yijing Hexagram Symbols 4DC0-4DFF
100 Syloti Nagri A800-A82F
101 Linear B Syllabary 10000-1007F
Linear B Ideograms 10080-100FF
Aegean Numbers 10100-1013F
102 Ancient Greek Numbers 10140-1018F
103 Ugaritic 10380-1039F
104 Old Persian 103A0-103DF
105 Shavian 10450-1047F
106 Osmanya 10480-104AF
107 Cypriot Syllabary 10800-1083F
108 Kharoshthi 10A00-10A5F
109 Tai Xuan Jing Symbols 1D300-1D35F
110 Cuneiform 12000-123FF
Cuneiform Numbers and Punctuation 12400-1247F
111 Counting Rod Numerals 1D360-1D37F
112 Sundanese 1B80-1BBF
113 Lepcha 1C00-1C4F
114 Ol Chiki 1C50-1C7F
115 Saurashtra A880-A8DF
116 Kayah Li A900-A92F
117 Rejang A930-A95F
118 Cham AA00-AA5F
119 Ancient Symbols 10190-101CF
120 Phaistos Disc 101D0-101FF
121 Carian 102A0-102DF
Lycian 10280-1029F
Lydian 10920-1093F
122 Domino Tiles 1F030-1F09F
Mahjong Tiles 1F000-1F02F""";
		
	List<RangeBit> bits = new List<RangeBit> ();

	public UnicodeRangeBits () {
		parse_ranges ();
	}
	
	public void get_ranges (Font font, out uint32 r0, out uint32 r1, out uint32 r2, out uint32 r3) {
		uint32 indice;
		Glyph? gl;
		Glyph g;
		int bit;
		
		r0 = 0;
		r1 = 0;
		r2 = 0;
		r3 = 0;
		
		for (indice = 0; (gl = font.get_glyph_indice (indice)) != null; indice++) {		
			g = (!) gl;
			if (!g.is_unassigned ()) {
				bit = get_bit (g.get_unichar ());
				if (likely (bit >= 0)) {
					set_bit (bit, ref r0, ref r1, ref r2, ref r3);
				} else {
					warning (@"Can't find range for character $(g.get_name ()).");
				}
			}
		}
	}
	
	void set_bit (int bit, ref uint32 r0, ref uint32 r1, ref uint32 r2, ref uint32 r3) {
		const int length = 32;
		
		if (0 <= bit <= length) {
			r0 |= 1 << bit;
		} else if (length <= bit <= 2 * length) {
			r1 |= 1 << (bit - length);
		} else if (2 * length <= bit <= 3 * length) {
			r2 |= 1 << (bit - 2 * length);
		} else if (3 * length <= bit <= 122) {
			r3 |= 1 << (bit - 3 * length);
		} else if (unlikely (bit > 122)) {
			warning ("Reserved bit");
		}
	}
	
	int get_bit (unichar c) {
		foreach (RangeBit b in bits) {
			if (b.range.has_character (c)) {
				return b.bit;
			}
		}
		
		return -1;
	}
	
	void parse_ranges () {
		string[] rows = ranges.split ("\n");
		string[] columns;
		int bit = 0;
		RangeBit rb;
		
		foreach (string row in rows) {
			columns = row.split (" ");
			
			return_if_fail (columns.length > 1);
			
			if ('0' <= columns[0].get_char () <= '9') {
				bit = int.parse (columns[0]);
			}
			
			rb = new RangeBit (columns[columns.length - 1], bit);
			bits.append (rb);
		}
	}
	
	private class RangeBit: GLib.Object {
		public int32 bit = 0;
		public UniRange range;
		
		public RangeBit (string range, int bit) {
			string[] s = range.split ("-");
			unichar start = '\0';
			unichar stop = '\0';
						
			this.bit = bit;
			
			if (s.length != 2) {
				warning ("Bad range.");
			} else {
				start = Font.to_unichar (@"U+$(s[0])");
				stop =  Font.to_unichar (@"U+$(s[1])");
			}
			
			this.range = new UniRange (start, stop);
		}
	}
}

}

