/*
	Copyright (C) 2012 2013 2015 Johan Mattsson

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

public class PostTable : OtfTable {
	
	GlyfTable glyf_table;
	
	Gee.ArrayList<uint16> index = new Gee.ArrayList<uint16> ();
	Gee.ArrayList<string> names = new Gee.ArrayList<string> ();
	
	public PostTable (GlyfTable g) {
		id = "post";
		glyf_table = g;
	}
	
	// the Macintosh standard order
	private void add_standard_names () {
		names.add (".notdef");
		names.add (".null");
		names.add ("nonmarkingreturn");
		names.add ("space");
		names.add ("exclam");
		names.add ("quotedbl");
		names.add ("numbersign");
		names.add ("dollar");
		names.add ("percent");
		names.add ("ampersand");
		names.add ("quotesingle");
		names.add ("parenleft");
		names.add ("parenright");
		names.add ("asterisk");
		names.add ("plus");
		names.add ("comma");
		names.add ("hyphen");
		names.add ("period");
		names.add ("slash");
		names.add ("zero");
		names.add ("one");
		names.add ("two");
		names.add ("three");
		names.add ("four");
		names.add ("five");
		names.add ("six");
		names.add ("seven");
		names.add ("eight");
		names.add ("nine");
		names.add ("colon");
		names.add ("semicolon");
		names.add ("less");
		names.add ("equal");
		names.add ("greater");
		names.add ("question");
		names.add ("at");
		names.add ("A");
		names.add ("B");
		names.add ("C");
		names.add ("D");
		names.add ("E");
		names.add ("F");
		names.add ("G");
		names.add ("H");
		names.add ("I");
		names.add ("J");
		names.add ("K");
		names.add ("L");
		names.add ("M");
		names.add ("N");
		names.add ("O");
		names.add ("P");
		names.add ("Q");
		names.add ("R");
		names.add ("S");
		names.add ("T");
		names.add ("U");
		names.add ("V");
		names.add ("W");
		names.add ("X");
		names.add ("Y");
		names.add ("Z");
		names.add ("bracketleft");
		names.add ("backslash");
		names.add ("bracketright");
		names.add ("asciicircum");
		names.add ("underscore");
		names.add ("grave");
		names.add ("a");
		names.add ("b");
		names.add ("c");
		names.add ("d");
		names.add ("e");
		names.add ("f");
		names.add ("g");
		names.add ("h");
		names.add ("i");
		names.add ("j");
		names.add ("k");
		names.add ("l");
		names.add ("m");
		names.add ("n");
		names.add ("o");
		names.add ("p");
		names.add ("q");
		names.add ("r");
		names.add ("s");
		names.add ("t");
		names.add ("u");
		names.add ("v");
		names.add ("w");
		names.add ("x");
		names.add ("y");
		names.add ("z");
		names.add ("braceleft");
		names.add ("bar");
		names.add ("braceright");
		names.add ("asciitilde");
		names.add ("Adieresis");
		names.add ("Aring");
		names.add ("Ccedilla");
		names.add ("Eacute");
		names.add ("Ntilde");
		names.add ("Odieresis");
		names.add ("Udieresis");
		names.add ("aacute");
		names.add ("agrave");
		names.add ("acircumflex");
		names.add ("adieresis");
		names.add ("atilde");
		names.add ("aring");
		names.add ("ccedilla");
		names.add ("eacute");
		names.add ("egrave");
		names.add ("ecircumflex");
		names.add ("edieresis");
		names.add ("iacute");
		names.add ("igrave");
		names.add ("icircumflex");
		names.add ("idieresis");
		names.add ("ntilde");
		names.add ("oacute");
		names.add ("ograve");
		names.add ("ocircumflex");
		names.add ("odieresis");
		names.add ("otilde");
		names.add ("uacute");
		names.add ("ugrave");
		names.add ("ucircumflex");
		names.add ("udieresis");
		names.add ("dagger");
		names.add ("degree");
		names.add ("cent");
		names.add ("sterling");
		names.add ("section");
		names.add ("bullet");
		names.add ("paragraph");
		names.add ("germandbls");
		names.add ("registered");
		names.add ("copyright");
		names.add ("trademark");
		names.add ("acute");
		names.add ("dieresis");
		names.add ("notequal");
		names.add ("AE");
		names.add ("Oslash");
		names.add ("infinity");
		names.add ("plusminus");
		names.add ("lessequal");
		names.add ("greaterequal");
		names.add ("yen");
		names.add ("mu");
		names.add ("partialdiff");
		names.add ("summation");
		names.add ("product");
		names.add ("pi");
		names.add ("integral");
		names.add ("ordfeminine");
		names.add ("ordmasculine");
		names.add ("Omega");
		names.add ("ae");
		names.add ("oslash");
		names.add ("questiondown");
		names.add ("exclamdown");
		names.add ("logicalnot");
		names.add ("radical");
		names.add ("florin");
		names.add ("approxequal");
		names.add ("Delta");
		names.add ("guillemotleft");
		names.add ("guillemotright");
		names.add ("ellipsis");
		names.add ("nonbreakingspace");
		names.add ("Agrave");
		names.add ("Atilde");
		names.add ("Otilde");
		names.add ("OE");
		names.add ("oe");
		names.add ("endash");
		names.add ("emdash");
		names.add ("quotedblleft");
		names.add ("quotedblright");
		names.add ("quoteleft");
		names.add ("quoteright");
		names.add ("divide");
		names.add ("lozenge");
		names.add ("ydieresis");
		names.add ("Ydieresis");
		names.add ("fraction");
		names.add ("currency");
		names.add ("guilsinglleft");
		names.add ("guilsinglright");
		names.add ("fi");
		names.add ("fl");
		names.add ("daggerdbl");
		names.add ("periodcentered");
		names.add ("quotesinglbase");
		names.add ("quotedblbase");
		names.add ("perthousand");
		names.add ("Acircumflex");
		names.add ("Ecircumflex");
		names.add ("Aacute");
		names.add ("Edieresis");
		names.add ("Egrave");
		names.add ("Iacute");
		names.add ("Icircumflex");
		names.add ("Idieresis");
		names.add ("Igrave");
		names.add ("Oacute");
		names.add ("Ocircumflex");
		names.add ("apple");
		names.add ("Ograve");
		names.add ("Uacute");
		names.add ("Ucircumflex");
		names.add ("Ugrave");
		names.add ("dotlessi");
		names.add ("circumflex");
		names.add ("tilde");
		names.add ("macron");
		names.add ("breve");
		names.add ("dotaccent");
		names.add ("ring");
		names.add ("cedilla");
		names.add ("hungarumlaut");
		names.add ("ogonek");
		names.add ("caron");
		names.add ("Lslash");
		names.add ("lslash");
		names.add ("Scaron");
		names.add ("scaron");
		names.add ("Zcaron");
		names.add ("zcaron");
		names.add ("brokenbar");
		names.add ("Eth");
		names.add ("eth");
		names.add ("Yacute");
		names.add ("yacute");
		names.add ("Thorn");
		names.add ("thorn");
		names.add ("minus");
		names.add ("multiply");
		names.add ("onesuperior");
		names.add ("twosuperior");
		names.add ("threesuperior");
		names.add ("onehalf");
		names.add ("onequarter");
		names.add ("threequarters");
		names.add ("franc");
		names.add ("Gbreve");
		names.add ("gbreve");
		names.add ("Idotaccent");
		names.add ("Scedilla");
		names.add ("scedilla");
		names.add ("Cacute");
		names.add ("cacute");
		names.add ("Ccaron");
		names.add ("ccaron");
		names.add ("dcroat");
	}
	
	// mapping with char code to standard order
	int get_standard_index (unichar c) {
		switch (c) {
			// entry 0 is the .notdef
			
			case '\0':
				return 1;

			case '\r':
				return 2;

			case ' ': // space
				return 3;

			case '!':
				return 4;

			case '"':
				return 5;

			case '#':
				return 6;

			case '$':
				return 7;

			case '%':
				return 8;

			case '&':
				return 9;

			case '\'':
				return 10;

			case '(':
				return 11;

			case ')':
				return 12;

			case '*':
				return 13;

			case '+':
				return 14;

			case ',':
				return 15;

			case '-':
				return 16;

			case '.':
				return 17;

			case '/':
				return 18;

			case '0':
				return 19;

			case '1':
				return 20;

			case '2':
				return 21;

			case '3':
				return 22;

			case '4':
				return 23;

			case '5':
				return 24;

			case '6':
				return 25;

			case '7':
				return 26;

			case '8':
				return 27;

			case '9':
				return 28;

			case ':':
				return 29;

			case ';':
				return 30;

			case '<':
				return 31;

			case '=':
				return 32;

			case '>':
				return 33;

			case '?':
				return 34;

			case '@':
				return 35;

			case 'A':
				return 36;

			case 'B':
				return 37;

			case 'C':
				return 38;

			case 'D':
				return 39;

			case 'E':
				return 40;

			case 'F':
				return 41;

			case 'G':
				return 42;

			case 'H':
				return 43;

			case 'I':
				return 44;

			case 'J':
				return 45;

			case 'K':
				return 46;

			case 'L':
				return 47;

			case 'M':
				return 48;

			case 'N':
				return 49;

			case 'O':
				return 50;

			case 'P':
				return 51;

			case 'Q':
				return 52;

			case 'R':
				return 53;

			case 'S':
				return 54;

			case 'T':
				return 55;

			case 'U':
				return 56;

			case 'V':
				return 57;

			case 'W':
				return 58;

			case 'X':
				return 59;

			case 'Y':
				return 60;

			case 'Z':
				return 61;

			case '[':
				return 62;

			case '\\':
				return 63;

			case ']':
				return 64;

			case '^':
				return 65;

			case '_':
				return 66;

			case '`':
				return 67;

			case 'a':
				return 68;

			case 'b':
				return 69;

			case 'c':
				return 70;

			case 'd':
				return 71;

			case 'e':
				return 72;

			case 'f':
				return 73;

			case 'g':
				return 74;

			case 'h':
				return 75;

			case 'i':
				return 76;

			case 'j':
				return 77;

			case 'k':
				return 78;

			case 'l':
				return 79;

			case 'm':
				return 80;

			case 'n':
				return 81;

			case 'o':
				return 82;

			case 'p':
				return 83;

			case 'q':
				return 84;

			case 'r':
				return 85;

			case 's':
				return 86;

			case 't':
				return 87;

			case 'u':
				return 88;

			case 'v':
				return 89;

			case 'w':
				return 90;

			case 'x':
				return 91;

			case 'y':
				return 92;

			case 'z':
				return 93;

			case '{':
				return 94;

			case '|':
				return 95;

			case '}':
				return 96;

			case '~':
				return 97;

			case 'Ä':
				return 98;

			case 'Å':
				return 99;

			case 'Ç':
				return 100;

			case 'É':
				return 101;

			case 'Ñ':
				return 102;

			case 'Ö':
				return 103;

			case 'Ü':
				return 104;

			case 'á':
				return 105;

			case 'à':
				return 106;

			case 'â':
				return 107;

			case 'ä':
				return 108;

			case 'ã':
				return 109;

			case 'å':
				return 110;

			case 'ç':
				return 111;

			case 'é':
				return 112;

			case 'è':
				return 113;

			case 'ê':
				return 114;

			case 'ë':
				return 115;

			case 'í':
				return 116;

			case 'ì':
				return 117;

			case 'î':
				return 118;

			case 'ï':
				return 119;

			case 'ñ':
				return 120;

			case 'ó':
				return 121;

			case 'ò':
				return 122;

			case 'ô':
				return 123;

			case 'ö':
				return 124;

			case 'õ':
				return 125;

			case 'ú':
				return 126;

			case 'ù':
				return 127;

			case 'û':
				return 128;

			case 'ü':
				return 129;

			case '†':
				return 130;

			case '°':
				return 131;

			case '¢':
				return 132;

			case '£':
				return 133;

			case '§':
				return 134;

			case '•':
				return 135;

			case '¶':
				return 136;

			case 'ß':
				return 137;

			case '®':
				return 138;

			case '©':
				return 139;

			case '™':
				return 140;

			case '´':
				return 141;

			case '¨':
				return 142;

			case '≠':
				return 143;

			case 'Æ':
				return 144;

			case 'Ø':
				return 145;

			case '∞':
				return 146;

			case '±':
				return 147;

			case '≤':
				return 148;

			case '≥':
				return 149;

			case '¥':
				return 150;

			case 'µ':
				return 151;

			case '∂':
				return 152;

			case '∑':
				return 153;

			case '∏':
				return 154;

			case 'π':
				return 155;

			case '∫':
				return 156;

			case 'ª':
				return 157;

			case 'º':
				return 158;

			case 'Ω':
				return 159;

			case 'æ':
				return 160;

			case 'ø':
				return 161;

			case '¿':
				return 162;

			case '¡':
				return 163;

			case '¬':
				return 164;

			case '√':
				return 165;

			case 'ƒ':
				return 166;

			case '≈':
				return 167;

			case '∆':
				return 168;

			case '«':
				return 169;

			case '»':
				return 170;

			case '…':
				return 171;

			case ' ': // non breaking space
				return 172;
							
			case 'À':
				return 173;

			case 'Ã':
				return 174;

			case 'Õ':
				return 175;

			case 'Œ':
				return 176;

			case 'œ':
				return 177;

			case '–':
				return 178;

			case '—':
				return 179;

			case '“':
				return 180;

			case '”':
				return 181;

			case '‘':
				return 182;

			case '’':
				return 183;

			case '÷':
				return 184;

			case '◊':
				return 185;

			case 'ÿ':
				return 186;

			case 'Ÿ':
				return 187;

			case '⁄':
				return 188;

			case '¤':
				return 189;

			case '‹':
				return 190;

			case '›':
				return 191;

			case 'ﬁ':
				return 192;

			case 'ﬂ':
				return 193;

			case '‡':
				return 194;

			case '·':
				return 195;

			case '‚':
				return 196;

			case '„':
				return 197;

			case '‰':
				return 198;

			case 'Â':
				return 199;

			case 'Ê':
				return 200;

			case 'Á':
				return 201;

			case 'Ë':
				return 202;

			case 'È':
				return 203;

			case 'Í':
				return 204;

			case 'Î':
				return 205;

			case 'Ï':
				return 206;

			case 'Ì':
				return 207;

			case 'Ó':
				return 208;

			case 'Ô':
				return 209;
				
			// Machintosh apple goes here
			// return 210;

			case 'Ò':
				return 211;

			case 'Ú':
				return 212;

			case 'Û':
				return 213;

			case 'Ù':
				return 214;

			case 'ı':
				return 215;

			case 'ˆ':
				return 216;

			case '˜':
				return 217;

			case '¯':
				return 218;

			case '˘':
				return 219;

			case '˙':
				return 220;

			case '˚':
				return 221;

			case '¸':
				return 222;

			case '˝':
				return 223;

			case '˛':
				return 224;

			case 'ˇ':
				return 225;

			case 'Ł':
				return 226;

			case 'ł':
				return 227;

			case 'Š':
				return 228;

			case 'š':
				return 229;

			case 'Ž':
				return 230;

			case 'ž':
				return 231;

			case '¦':
				return 232;

			case 'Ð':
				return 233;

			case 'ð':
				return 234;

			case 'Ý':
				return 235;

			case 'ý':
				return 236;

			case 'Þ':
				return 237;

			case 'þ':
				return 238;

			case '−':
				return 239;

			case '×':
				return 240;

			case '¹':
				return 241;
				
			case '²':
				return 242;

			case '³':
				return 243;

			case '½':
				return 244;

			case '¼':
				return 245;

			case '¾':
				return 246;

			case '₣':
				return 247;

			case 'Ğ':
				return 248;

			case 'ğ':
				return 249;

			case 'İ':
				return 250;

			case 'Ş':
				return 251;

			case 'ş':
				return 252;

			case 'Ć':
				return 253;

			case 'ć':
				return 254;

			case 'Č':
				return 255;

			case 'č':
				return 256;

			case 'đ':
				return 257;
		}
		
		return 0;
	}
	
	public void process () throws Error {
		FontData fd = new FontData ();
		string n;
		int name_index;
		GlyphCollection gc;
		Glyph g;
		string ps_name;
		StringBuilder name;
		
		fd.add_fixed (0x00020000); // Version
		fd.add_fixed (0x00000000); // italicAngle
		
		fd.add_short (-2); // underlinePosition
		fd.add_short (1); // underlineThickness

		fd.add_ulong (0); // non zero for monospaced font
		
		// mem boundaries may be omitted
		fd.add_ulong (0); // min mem for type 42
		fd.add_ulong (0); // max mem for type 42
		
		fd.add_ulong (0); // min mem for Type1
		fd.add_ulong (0); // max mem for Type1

		fd.add_ushort ((uint16) glyf_table.glyphs.size);

		// this part of the spec is so weird
		
		fd.add_ushort ((uint16) 0); // first index is .notdef
		index.add (0);
		
		assert (names.size == 0);
		add_standard_names ();

		for (int i = 1; i < glyf_table.glyphs.size; i++) {
			gc = glyf_table.glyphs.get (i);
			g = gc.get_current ();
			name_index = get_standard_index (g.unichar_code);
			
			if (name_index != 0 && !gc.is_unassigned ()) {
				fd.add_ushort ((uint16) name_index);  // use standard name
			} else {
				printd (@"Adding non standard postscript name $(gc.get_name ())\n");
				
				name_index = (int) names.size; // use font specific name
				fd.add_ushort ((uint16) name_index);
				
				name = new StringBuilder ();
				if (gc.is_unassigned ()) {
					name.append (g.get_name ());
				} else {
					unichar c = gc.get_unicode_character ();
					if (c < 0xFFFF) {
						name.printf ("uni%04x", c);
					} else {
						name.printf ("u%05x", c);
					}
				}
				
				ps_name = create_ps_name (name.str);
				names.add (ps_name);
			}
			
			this.index.add ((uint16) name_index);
		}

		for (int i = 258; i < names.size; i++) {
			n = (!) names.get (i);
			
			if (n.length > 0xFF) {
				warning (@"too long name for glyph $n");
				continue;
			}
			
			fd.add ((uint8) n.length);
			fd.add_str (n);
		}		

		fd.pad ();
		
		this.font_data = fd;
	}

	string create_ps_name (string name) {
		string valid_name = NameTable.name_validation (name, false, 0xFF);
		
		if (valid_name.char_count () == 1) {
			warning (@"Too short name: $valid_name generated from $name");
			valid_name = add_suffix (valid_name);
		}
		
		if (names.index_of (valid_name) > -1) {
			valid_name = add_suffix (valid_name);
		} 
		
		return valid_name;
	}
	
	string add_suffix (string valid_name) {
		int i = 2;
		string s;
		
		s = valid_name + @"_$i";
		while (names.index_of (s) > -1) {
			i++;
			s = valid_name + @"_$i";
		}
		
		return s;
	}
}

}
