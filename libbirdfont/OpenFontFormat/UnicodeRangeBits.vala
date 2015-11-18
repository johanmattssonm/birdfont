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

	Gee.ArrayList<RangeBit> bits = new Gee.ArrayList<RangeBit> ();

	public UnicodeRangeBits () {
		add_ranges ();
	}
	
	public void get_ranges (Font font, out uint32 r0, out uint32 r1, out uint32 r2, out uint32 r3) {
		uint32 index;
		GlyphCollection? gl;
		GlyphCollection g;
		int bit;
		
		r0 = 0;
		r1 = 0;
		r2 = 0;
		r3 = 0;
		
		for (index = 0; (gl = font.get_glyph_collection_index (index)) != null; index++) {		
			g = (!) gl;
			if (!g.is_unassigned ()) {
				bit = get_bit (g.get_unicode_character ());
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
	
	void add_range (int bit, unichar start, unichar stop) {
		bits.add (new RangeBit (bit, start, stop));
	}
	
	void add_ranges () {
		add_range (0, 0x0000, 0x007F); // Basic Latin 
		add_range (1, 0x0080, 0x00FF); // Latin-1 Supplement 
		add_range (2, 0x0100, 0x017F); // Latin Extended-A 
		add_range (3, 0x0180, 0x024F); // Latin Extended-B 
		add_range (4, 0x0250, 0x02AF); // IPA Extensions 
		add_range (4, 0x1D00, 0x1D7F); // Phonetic Extensions 
		add_range (4, 0x1D80, 0x1DBF); // Phonetic Extensions Supplement 
		add_range (4, 0x02B0, 0x02FF); // Spacing Modifier Letters 
		add_range (4, 0xA700, 0xA71F); // Modifier Tone Letters 
		add_range (4, 0x0300, 0x036F); // Combining Diacritical Marks 
		add_range (4, 0x1DC0, 0x1DFF); // Combining Diacritical Marks Supplement 
		add_range (7, 0x0370, 0x03FF); // Greek and Coptic 
		add_range (8, 0x2C80, 0x2CFF); // Coptic 
		add_range (9, 0x0400, 0x04FF); // Cyrillic 
		add_range (9, 0x0500, 0x052F); // Cyrillic Supplement 
		add_range (9, 0x2DE0, 0x2DFF); // Cyrillic Extended-A 
		add_range (9, 0xA640, 0xA69F); // Cyrillic Extended-B 
		add_range (10, 0x0530, 0x058F); // Armenian 
		add_range (11, 0x0590, 0x05FF); // Hebrew 
		add_range (12, 0xA500, 0xA63F); // Vai 
		add_range (13, 0x0600, 0x06FF); // Arabic 
		add_range (13, 0x0750, 0x077F); // Arabic Supplement 
		add_range (14, 0x07C0, 0x07FF); // NKo 
		add_range (15, 0x0900, 0x097F); // Devanagari 
		add_range (16, 0x0980, 0x09FF); // Bengali 
		add_range (17, 0x0A00, 0x0A7F); // Gurmukhi 
		add_range (18, 0x0A80, 0x0AFF); // Gujarati 
		add_range (19, 0x0B00, 0x0B7F); // Oriya 
		add_range (20, 0x0B80, 0x0BFF); // Tamil 
		add_range (21, 0x0C00, 0x0C7F); // Telugu 
		add_range (22, 0x0C80, 0x0CFF); // Kannada 
		add_range (23, 0x0D00, 0x0D7F); // Malayalam 
		add_range (24, 0x0E00, 0x0E7F); // Thai 
		add_range (25, 0x0E80, 0x0EFF); // Lao 
		add_range (26, 0x10A0, 0x10FF); // Georgian 
		add_range (26, 0x2D00, 0x2D2F); // Georgian Supplement 
		add_range (27, 0x1B00, 0x1B7F); // Balinese 
		add_range (28, 0x1100, 0x11FF); // Hangul Jamo 
		add_range (29, 0x1E00, 0x1EFF); // Latin Extended Additional 
		add_range (29, 0x2C60, 0x2C7F); // Latin Extended-C 
		add_range (29, 0xA720, 0xA7FF); // Latin Extended-D 
		add_range (30, 0x1F00, 0x1FFF); // Greek Extended 
		add_range (31, 0x2000, 0x206F); // General Punctuation 
		add_range (31, 0x2E00, 0x2E7F); // Supplemental Punctuation 
		add_range (32, 0x2070, 0x209F); // Superscripts And Subscripts 
		add_range (33, 0x20A0, 0x20CF); // Currency Symbols 
		add_range (34, 0x20D0, 0x20FF); // Combining Diacritical Marks For Symbols 
		add_range (35, 0x2100, 0x214F); // Letterlike Symbols 
		add_range (36, 0x2150, 0x218F); // Number Forms 
		add_range (37, 0x2190, 0x21FF); // Arrows 
		add_range (37, 0x27F0, 0x27FF); // Supplemental Arrows-A 
		add_range (37, 0x2900, 0x297F); // Supplemental Arrows-B 
		add_range (37, 0x2B00, 0x2BFF); // Miscellaneous Symbols and Arrows 
		add_range (37, 0x2200, 0x22FF); // Mathematical Operators 
		add_range (37, 0x2A00, 0x2AFF); // Supplemental Mathematical Operators 
		add_range (37, 0x27C0, 0x27EF); // Miscellaneous Mathematical Symbols-A 
		add_range (37, 0x2980, 0x29FF); // Miscellaneous Mathematical Symbols-B 
		add_range (39, 0x2300, 0x23FF); // Miscellaneous Technical 
		add_range (40, 0x2400, 0x243F); // Control Pictures 
		add_range (41, 0x2440, 0x245F); // Optical Character Recognition 
		add_range (42, 0x2460, 0x24FF); // Enclosed Alphanumerics 
		add_range (43, 0x2500, 0x257F); // Box Drawing 
		add_range (44, 0x2580, 0x259F); // Block Elements 
		add_range (45, 0x25A0, 0x25FF); // Geometric Shapes 
		add_range (46, 0x2600, 0x26FF); // Miscellaneous Symbols 
		add_range (47, 0x2700, 0x27BF); // Dingbats 
		add_range (48, 0x3000, 0x303F); // CJK Symbols And Punctuation 
		add_range (49, 0x3040, 0x309F); // Hiragana 
		add_range (50, 0x30A0, 0x30FF); // Katakana 
		add_range (50, 0x31F0, 0x31FF); // Katakana Phonetic Extensions 
		add_range (50, 0x3100, 0x312F); // Bopomofo 
		add_range (50, 0x31A0, 0x31BF); // Bopomofo Extended 
		add_range (52, 0x3130, 0x318F); // Hangul Compatibility Jamo 
		add_range (53, 0xA840, 0xA87F); // Phags-pa 
		add_range (54, 0x3200, 0x32FF); // Enclosed CJK Letters And Months 
		add_range (55, 0x3300, 0x33FF); // CJK Compatibility 
		add_range (56, 0xAC00, 0xD7AF); // Hangul Syllables 
		add_range (57, 0xD800, 0xDFFF); // Non-Plane 0 * 
		add_range (58, 0x10900, 0x1091F); // Phoenician 
		add_range (59, 0x4E00, 0x9FFF); // CJK Unified Ideographs 
		add_range (59, 0x2E80, 0x2EFF); // CJK Radicals Supplement 
		add_range (59, 0x2F00, 0x2FDF); // Kangxi Radicals 
		add_range (59, 0x2FF0, 0x2FFF); // Ideographic Description Characters 
		add_range (59, 0x3400, 0x4DBF); // CJK Unified Ideographs Extension A 
		add_range (59, 0x20000, 0x2A6DF); // CJK Unified Ideographs Extension B 
		add_range (59, 0x3190, 0x319F); // Kanbun 
		add_range (60, 0xE000, 0xF8FF); // Private Use Area (plane 0) 
		add_range (61, 0x31C0, 0x31EF); // CJK Strokes 
		add_range (61, 0xF900, 0xFAFF); // CJK Compatibility Ideographs 
		add_range (61, 0x2F800, 0x2Fa1F); // CJK Compatibility Ideographs Supplement 
		add_range (61, 0xFB00, 0xFB4F); // Alphabetic Presentation Forms 
		add_range (63, 0xFB50, 0xFDFF); // Arabic Presentation Forms-A 
		add_range (64, 0xFE20, 0xFE2F); // Combining Half Marks 
		add_range (65, 0xFE10, 0xFE1F); // Vertical Forms 
		add_range (65, 0xFE30, 0xFE4F); // CJK Compatibility Forms 
		add_range (66, 0xFE50, 0xFE6F); // Small Form Variants 
		add_range (67, 0xFE70, 0xFEFF); // Arabic Presentation Forms-B 
		add_range (68, 0xFF00, 0xFFEF); // Halfwidth And Fullwidth Forms 
		add_range (69, 0xFFF0, 0xFFFF); // Specials 
		add_range (70, 0x0F00, 0x0FFF); // Tibetan 
		add_range (71, 0x0700, 0x074F); // Syriac 
		add_range (72, 0x0780, 0x07BF); // Thaana 
		add_range (73, 0x0D80, 0x0DFF); // Sinhala 
		add_range (74, 0x1000, 0x109F); // Myanmar 
		add_range (75, 0x1200, 0x137F); // Ethiopic 
		add_range (75, 0x1380, 0x139F); // Ethiopic Supplement 
		add_range (75, 0x2D80, 0x2DDF); // Ethiopic Extended 
		add_range (76, 0x13A0, 0x13FF); // Cherokee 
		add_range (77, 0x1400, 0x167F); // Unified Canadian Aboriginal Syllabics 
		add_range (78, 0x1680, 0x169F); // Ogham 
		add_range (79, 0x16A0, 0x16FF); // Runic 
		add_range (80, 0x1780, 0x17FF); // Khmer 
		add_range (80, 0x19E0, 0x19FF); // Khmer Symbols 
		add_range (81, 0x1800, 0x18AF); // Mongolian 
		add_range (82, 0x2800, 0x28FF); // Braille Patterns 
		add_range (83, 0xA000, 0xA48F); // Yi Syllables 
		add_range (83, 0xA490, 0xA4CF); // Yi Radicals 
		add_range (83, 0x1700, 0x171F); // Tagalog 
		add_range (83, 0x1720, 0x173F); // Hanunoo 
		add_range (83, 0x1740, 0x175F); // Buhid 
		add_range (83, 0x1760, 0x177F); // Tagbanwa 
		add_range (85, 0x10300, 0x1032F); // Old Italic 
		add_range (86, 0x10330, 0x1034F); // Gothic 
		add_range (87, 0x10400, 0x1044F); // Deseret 
		add_range (88, 0x1D000, 0x1D0FF); // Byzantine Musical Symbols 
		add_range (88, 0x1D100, 0x1D1FF); // Musical Symbols 
		add_range (88, 0x1D200, 0x1D24F); // Ancient Greek Musical Notation 
		add_range (89, 0x1D400, 0x1D7FF); // Mathematical Alphanumeric Symbols 
		add_range (90, 0xFF000, 0xFFFFD); // Private Use (plane 15) 
		add_range (90, 0x100000, 0x10FFFD); // Private Use (plane 16) 
		add_range (90, 0xFE00, 0xFE0F); // Variation Selectors 
		add_range (90, 0xE0100, 0xE01EF); // Variation Selectors Supplement 
		add_range (92, 0xE0000, 0xE007F); // Tags 
		add_range (93, 0x1900, 0x194F); // Limbu 
		add_range (94, 0x1950, 0x197F); // Tai Le 
		add_range (95, 0x1980, 0x19DF); // New Tai Lue 
		add_range (96, 0x1A00, 0x1A1F); // Buginese 
		add_range (97, 0x2C00, 0x2C5F); // Glagolitic 
		add_range (98, 0x2D30, 0x2D7F); // Tifinagh 
		add_range (99, 0x4DC0, 0x4DFF); // Yijing Hexagram Symbols 
		add_range (100, 0xA800, 0xA82F); // Syloti Nagri 
		add_range (101, 0x10000, 0x1007F); // Linear B Syllabary 
		add_range (101, 0x10080, 0x100FF); // Linear B Ideograms 
		add_range (101, 0x10100, 0x1013F); // Aegean Numbers 
		add_range (102, 0x10140, 0x1018F); // Ancient Greek Numbers 
		add_range (103, 0x10380, 0x1039F); // Ugaritic 
		add_range (104, 0x103A0, 0x103DF); // Old Persian 
		add_range (105, 0x10450, 0x1047F); // Shavian 
		add_range (106, 0x10480, 0x104AF); // Osmanya 
		add_range (107, 0x10800, 0x1083F); // Cypriot Syllabary 
		add_range (108, 0x10A00, 0x10A5F); // Kharoshthi 
		add_range (109, 0x1D300, 0x1D35F); // Tai Xuan Jing Symbols 
		add_range (110, 0x12000, 0x123FF); // Cuneiform 
		add_range (110, 0x12400, 0x1247F); // Cuneiform Numbers and Punctuation 
		add_range (111, 0x1D360, 0x1D37F); // Counting Rod Numerals 
		add_range (112, 0x1B80, 0x1BBF); // Sundanese 
		add_range (113, 0x1C00, 0x1C4F); // Lepcha 
		add_range (114, 0x1C50, 0x1C7F); // Ol Chiki 
		add_range (115, 0xA880, 0xA8DF); // Saurashtra 
		add_range (116, 0xA900, 0xA92F); // Kayah Li 
		add_range (117, 0xA930, 0xA95F); // Rejang 
		add_range (118, 0xAA00, 0xAA5F); // Cham 
		add_range (119, 0x10190, 0x101CF); // Ancient Symbols 
		add_range (120, 0x101D0, 0x101FF); // Phaistos Disc 
		add_range (121, 0x102A0, 0x102DF); // Carian 
		add_range (121, 0x10280, 0x1029F); // Lycian 
		add_range (121, 0x10920, 0x1093F); // Lydian 
		add_range (122, 0x1F030, 0x1F09F); // Domino Tiles 
		add_range (122, 0x1F000, 0x1F02F); // Mahjong Tiles 
	}
	
	private class RangeBit: GLib.Object {
		public int32 bit = 0;
		public UniRange range;
		
		public RangeBit (int bit, unichar start, unichar stop) {
			this.range = new UniRange (start, stop);
		}
	}
}

}

